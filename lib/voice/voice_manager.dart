import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import '../brain/llm_provider.dart';
import '../brain/gemini_provider.dart';
import '../brain/conversation_manager.dart';
import '../brain/reasoning_pipeline.dart';
import '../voice/tts_provider.dart';
import '../voice/sapi_tts_provider.dart';
import '../voice/linux_tts_provider.dart';
import '../services/audio_service.dart';

/// PRIME Voice Manager
///
/// Coordinates the brain (LLM) and voice (TTS) layers.
/// Routes commands appropriately.

class VoiceManager {
  VoiceManager._();
  static final VoiceManager instance = VoiceManager._();

  LLMProvider? _llmProvider;
  TTSProvider? _ttsProvider;
  final ConversationManager _conversation = ConversationManager();

  bool _initialized = false;
  bool _llmEnabled = false;

  /// Stream of pipeline steps — listen to this for real-time step updates
  final StreamController<PipelineStep> _stepController =
      StreamController<PipelineStep>.broadcast();
  Stream<PipelineStep> get stepStream => _stepController.stream;

  /// Stream of text chunks as they arrive from the LLM
  final StreamController<String> _chunkController =
      StreamController<String>.broadcast();
  Stream<String> get chunkStream => _chunkController.stream;

  LLMProvider? get llmProvider => _llmProvider;
  TTSProvider? get ttsProvider => _ttsProvider;
  ConversationManager get conversation => _conversation;
  bool get llmEnabled => _llmEnabled;

  Future<void> initialize({
    String? geminiApiKey,
    String? geminiModel,
  }) async {
    if (_initialized) return;

    // Initialize TTS based on platform
    if (Platform.isWindows) {
      _ttsProvider = SapiTTSProvider();
      await (_ttsProvider as SapiTTSProvider).initialize();
    } else if (Platform.isLinux || Platform.isMacOS) {
      _ttsProvider = LinuxTTSProvider();
      await (_ttsProvider as LinuxTTSProvider).initialize();
    } else {
      debugPrint('[VoiceManager] TTS unavailable on ${Platform.operatingSystem}');
    }

    // Initialize LLM if API key provided
    if (geminiApiKey != null && geminiApiKey.isNotEmpty) {
      try {
        _llmProvider = GeminiProvider(
          apiKey: geminiApiKey,
          model: geminiModel ?? 'gemini-3.6-flash',
        );
        _llmEnabled = true;
        debugPrint('[VoiceManager] LLM enabled: ${_llmProvider!.name}');
      } catch (e) {
        debugPrint('[VoiceManager] LLM init failed: $e');
        _llmProvider = null;
      }
    }

    _initialized = true;
    debugPrint('[VoiceManager] Initialized (LLM: $_llmEnabled, TTS: ${_ttsProvider?.name})');
  }

  /// Process user input - route to LLM or handle locally
  Future<VoiceResponse> processInput(String input) async {
    final trimmed = input.trim();
    if (trimmed.isEmpty) {
      return const VoiceResponse(
        text: '',
        type: ResponseType.conversation,
        shouldSpeak: false,
      );
    }

    // Try deterministic commands first
    final localResponse = _handleLocalCommand(trimmed);
    if (localResponse != null) {
      return localResponse;
    }

    // Route to LLM if available
    if (_llmEnabled && _llmProvider != null) {
      return _processWithLLM(trimmed);
    }

    // Fallback when no LLM
    return VoiceResponse(
      text: 'I understand you said: "$trimmed". To have full conversations, please configure a Gemini API key in the .env file.',
      type: ResponseType.conversation,
    );
  }

  VoiceResponse? _handleLocalCommand(String input) {
    final lower = input.toLowerCase();

    if (lower == 'status' || lower == 'system status') {
      return const VoiceResponse(
        text: 'All systems operational.',
        type: ResponseType.commandConfirmation,
      );
    }

    if (lower.startsWith('hello') || lower.startsWith('hi prime') || lower.startsWith('hey prime')) {
      return const VoiceResponse(
        text: 'Hello! How can I help you?',
        type: ResponseType.conversation,
      );
    }

    if (lower.contains('what can you do') || lower.contains('capabilities')) {
      return const VoiceResponse(
        text: 'I can answer questions, help with tasks, and manage your system. Just speak naturally.',
        type: ResponseType.conversation,
      );
    }

    if (lower == 'shutdown' || lower == 'shut down') {
      return const VoiceResponse(
        text: 'Shutting down. Goodbye.',
        type: ResponseType.commandConfirmation,
      );
    }

    return null;
  }

  Future<VoiceResponse> _processWithLLM(String input) async {
    const maxRetries = 1;
    for (var attempt = 0; attempt <= maxRetries; attempt++) {
      try {
        _conversation.addUserMessage(input);

        // Run through the reasoning pipeline (single LLM call, streaming)
        final pipeline = ReasoningPipeline(
          llm: _llmProvider!,
          conversation: _conversation,
          stepController: _stepController,
          chunkController: _chunkController,
        );

        final result = await pipeline.execute(input);

        _conversation.addAssistantMessage(result.finalResponse);

        return VoiceResponse(
          text: result.finalResponse,
          type: ResponseType.conversation,
          shouldSpeak: true,
          steps: result.steps,
          totalDuration: result.totalDuration,
          requestId: result.requestId,
          promptChars: result.promptChars,
          responseChars: result.responseChars,
          responseWords: result.responseWords,
        );
      } catch (e) {
        debugPrint('[VoiceManager] Pipeline error (attempt ${attempt + 1}): $e');
        if (attempt < maxRetries) {
          await Future.delayed(const Duration(seconds: 2));
          continue;
        }
        return const VoiceResponse(
          text: 'I had trouble processing that. Could you try again?',
          type: ResponseType.error,
        );
      }
    }
    return const VoiceResponse(
      text: 'I had trouble processing that. Could you try again?',
      type: ResponseType.error,
    );
  }

  /// Speak text using TTS — NON-BLOCKING (fire and forget)
  void speakAsync(String text) {
    if (text.isEmpty || _ttsProvider == null) return;
    AudioService.instance.playReply();
    // Don't await — TTS should never block the UI
    _ttsProvider!.speak(text).catchError((e) {
      debugPrint('[VoiceManager] TTS error: $e');
    });
  }

  /// Speak text (blocking version, used only when explicitly needed)
  Future<void> speak(String text) async {
    if (text.isEmpty || _ttsProvider == null) return;
    AudioService.instance.playReply();
    await _ttsProvider!.speak(text);
  }

  Future<void> stopSpeaking() async {
    await _ttsProvider?.stop();
  }

  bool get isSpeaking => _ttsProvider?.isSpeaking ?? false;

  void dispose() {
    _stepController.close();
    _chunkController.close();
  }
}

/// Response from the voice manager
class VoiceResponse {
  final String text;
  final ResponseType type;
  final bool shouldSpeak;
  final List<PipelineStep> steps;
  final Duration? totalDuration;
  final String? requestId;
  final int promptChars;
  final int responseChars;
  final int responseWords;

  const VoiceResponse({
    required this.text,
    this.type = ResponseType.conversation,
    this.shouldSpeak = true,
    this.steps = const [],
    this.totalDuration,
    this.requestId,
    this.promptChars = 0,
    this.responseChars = 0,
    this.responseWords = 0,
  });
}
