import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/prime_state.dart';
import '../brain/llm_provider.dart';
import '../brain/conversation_manager.dart';
import '../voice/voice_director.dart';
import '../voice/audio_queue.dart';
import '../providers/factories/provider_factory.dart';
import '../services/settings_service.dart';
import '../services/debug_service.dart';

/// PRIME Core - Conversation Engine
///
/// The unified state machine that orchestrates all conversation flow.
/// Single source of truth for conversation state.

class ConversationEngine extends ChangeNotifier {
  final ProviderFactory _providers;
  final SettingsService _settings;
  final DebugService _debug;
  final ConversationManager _context;
  final VoiceDirector _voiceDirector;
  final AudioQueue _audioQueue;

  ConversationState _state = ConversationState.idle;
  String _currentTranscript = '';
  String _currentResponse = '';
  String _streamingBuffer = '';
  bool _interrupted = false;

  StreamSubscription? _sttSubscription;

  ConversationEngine({
    required ProviderFactory providers,
    required SettingsService settings,
    required DebugService debug,
    ConversationManager? context,
  })  : _providers = providers,
        _settings = settings,
        _debug = debug,
        _context = context ?? ConversationManager(),
        _voiceDirector = VoiceDirector(),
        _audioQueue = AudioQueue() {
    _init();
  }

  ConversationState get state => _state;
  String get currentTranscript => _currentTranscript;
  String get currentResponse => _currentResponse;
  bool get isBusy => _state != ConversationState.idle &&
      _state != ConversationState.offline;
  bool get canInterrupt =>
      _state == ConversationState.speaking ||
      _state == ConversationState.responding;

  Stream<ConversationState> get stateStream =>
      Stream.periodic(const Duration(milliseconds: 100))
          .map((_) => _state)
          .distinct();

  Stream<String> get responseStream => _voiceDirector.chunkStream
      .map((chunk) => chunk.text);

  Future<void> _init() async {
    // Set up TTS provider for audio queue
    final tts = await _providers.getTTSProvider();
    _audioQueue.ttsProvider = tts;

    if (tts != null) {
      _debug.info('ENGINE', 'TTS ready: ${tts.name}');
    } else {
      _debug.warning('ENGINE', 'No TTS available');
    }
  }

  /// Send a text message (from command bar)
  Future<void> sendText(String message) async {
    if (message.trim().isEmpty) return;
    if (_state == ConversationState.offline) {
      _debug.warning('ENGINE', 'Cannot send - offline');
      return;
    }

    _debug.info('ENGINE', 'User: "${message.substring(0, message.length.clamp(0, 50))}..."');
    _setState(ConversationState.thinking);
    _currentResponse = '';
    _streamingBuffer = '';

    // Add to context
    _context.addUserMessage(message);

    // Get LLM response
    await _generateResponse(message);
  }

  /// Start voice listening
  Future<void> startListening() async {
    if (_state == ConversationState.offline) return;

    final stt = await _providers.getSTTProvider();
    if (stt == null) {
      _debug.warning('ENGINE', 'No STT available');
      return;
    }

    _setState(ConversationState.listening);
    _currentTranscript = '';

    // Listen for STT results
    _sttSubscription?.cancel();
    _sttSubscription = stt.resultStream.listen(
      (result) {
        _currentTranscript = result.text;
        if (result.isFinal) {
          _debug.info('ENGINE', 'Final transcript: "${result.text}"');
          _setState(ConversationState.transcribing);
          sendText(result.text);
        }
        notifyListeners();
      },
      onError: (e) {
        _debug.error('ENGINE', 'STT error: $e');
        _setState(ConversationState.error);
      },
    );

    await stt.startListening(language: _settings.sttLanguage);
  }

  /// Stop listening
  Future<void> stopListening() async {
    final stt = await _providers.getSTTProvider();
    await stt?.stopListening();
    _sttSubscription?.cancel();

    if (_state == ConversationState.listening) {
      _setState(ConversationState.idle);
    }
  }

  /// Interrupt current response
  Future<void> interrupt() async {
    if (!canInterrupt) return;

    _interrupted = true;
    _debug.info('ENGINE', 'Interrupted by user');

    // Clear audio queue
    await _audioQueue.clear();
    _voiceDirector.reset();

    // Transition to listening for user's interruption
    _setState(ConversationState.listening);
  }

  /// Cancel response and go idle
  Future<void> cancelResponse() async {
    _interrupted = true;
    await _audioQueue.clear();
    _voiceDirector.reset();
    _setState(ConversationState.idle);
    _debug.info('ENGINE', 'Response cancelled');
  }

  Future<void> _generateResponse(String userMessage) async {
    final llm = await _providers.getLLMProvider();

    if (llm == null) {
      _debug.warning('ENGINE', 'No LLM available');
      _setState(ConversationState.offline);
      return;
    }

    try {
      _setState(ConversationState.responding);

      // Check if LLM supports streaming
      if (llm.supportsStreaming) {
        await _streamingResponse(llm, userMessage);
      } else {
        await _blockingResponse(llm, userMessage);
      }
    } catch (e) {
      _debug.error('ENGINE', 'LLM error: $e');
      _setState(ConversationState.error);
      _currentResponse = 'Error: $e';
      notifyListeners();

      // Auto-recover after brief delay
      await Future.delayed(const Duration(seconds: 2));
      if (_state == ConversationState.error) {
        _setState(ConversationState.idle);
      }
    }
  }

  Future<void> _streamingResponse(LLMProvider llm, String userMessage) async {
    _debug.info('ENGINE', 'Starting streaming response...');
    _interrupted = false;

    final stream = llm.streamGenerate(
      userMessage: userMessage,
      context: _context.getContext(),
    );

    if (stream == null) {
      _debug.warning('ENGINE', 'Streaming not available');
      await _blockingResponse(llm, userMessage);
      return;
    }

    await for (final chunk in stream) {
      if (_interrupted) break;

      _streamingBuffer += chunk.text;

      // Feed tokens to voice director for sentence segmentation
      final speechChunk = _voiceDirector.processToken(chunk.text);
      if (speechChunk != null && !_interrupted) {
        _setState(ConversationState.speaking);
        await _audioQueue.enqueue(speechChunk);
      }

      _currentResponse = _streamingBuffer;
      notifyListeners();

      if (chunk.isComplete) {
        // Flush remaining text
        final remaining = _voiceDirector.flush();
        if (remaining != null && !_interrupted) {
          await _audioQueue.enqueue(remaining);
        }

        // Add to context
        _context.addAssistantMessage(_streamingBuffer);
        _debug.info('ENGINE', 'Response complete (${_streamingBuffer.length} chars)');

        // Wait for audio to finish, then go idle
        _waitForAudioComplete();
      }
    }
  }

  Future<void> _blockingResponse(LLMProvider llm, String userMessage) async {
    _debug.info('ENGINE', 'Starting blocking response...');

    final response = await llm.generate(
      userMessage: userMessage,
      context: _context.getContext(),
    );

    _currentResponse = response.text;
    _context.addAssistantMessage(response.text);
    notifyListeners();

    if (response.text.isNotEmpty) {
      // Segment and speak
      final chunks = _segmentText(response.text);
      _setState(ConversationState.speaking);

      for (final chunk in chunks) {
        if (_interrupted) break;
        await _audioQueue.enqueue(chunk);
      }

      _waitForAudioComplete();
    } else {
      _setState(ConversationState.idle);
    }
  }

  List<SpeechChunk> _segmentText(String text) {
    final chunks = <SpeechChunk>[];
    final sentences = text.split(RegExp(r'(?<=[.!?])\s+'));

    for (final sentence in sentences) {
      if (sentence.trim().isNotEmpty) {
        _voiceDirector.processToken(sentence);
      }
    }

    final remaining = _voiceDirector.flush();
    if (remaining != null) {
      chunks.add(remaining);
    }

    return chunks;
  }

  void _waitForAudioComplete() async {
    // Monitor audio queue state
    await for (final state in _audioQueue.stateStream) {
      if (state == AudioQueueState.idle) {
        if (_state != ConversationState.idle &&
            _state != ConversationState.offline) {
          _setState(ConversationState.idle);
        }
        break;
      }
    }
  }

  void _setState(ConversationState newState) {
    if (_state != newState) {
      _debug.info('ENGINE', 'State: ${_state.label} → ${newState.label}');
      _state = newState;
      notifyListeners();
    }
  }

  /// Refresh providers (e.g., after settings change)
  Future<void> refreshProviders() async {
    await _providers.dispose();
    await _init();
    notifyListeners();
  }

  @override
  void dispose() {
    _sttSubscription?.cancel();
    _voiceDirector.dispose();
    _audioQueue.dispose();
    super.dispose();
  }
}
