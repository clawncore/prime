import 'dart:async';
import 'package:flutter/foundation.dart';
import '../brain/llm_provider.dart';
import '../brain/gemini_provider.dart';
import '../brain/conversation_manager.dart';
import '../voice/tts_provider.dart';
import '../voice/sapi_tts_provider.dart';
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

  LLMProvider? get llmProvider => _llmProvider;
  TTSProvider? get ttsProvider => _ttsProvider;
  ConversationManager get conversation => _conversation;
  bool get llmEnabled => _llmEnabled;

  Future<void> initialize({
    String? geminiApiKey,
    String? geminiModel,
  }) async {
    if (_initialized) return;

    // Initialize TTS (always available)
    _ttsProvider = SapiTTSProvider();
    await (_ttsProvider as SapiTTSProvider).initialize();

    // Initialize LLM if API key provided
    if (geminiApiKey != null && geminiApiKey.isNotEmpty) {
      try {
        _llmProvider = GeminiProvider(
          apiKey: geminiApiKey,
          model: geminiModel ?? 'gemini-2.0-flash',
        );

        final available = await _llmProvider!.isAvailable();
        if (available) {
          _llmEnabled = true;
          debugPrint('[VoiceManager] LLM enabled: ${_llmProvider!.name}');
        } else {
          debugPrint('[VoiceManager] LLM not available, using local commands only');
          _llmProvider = null;
        }
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

    // Status command
    if (lower == 'status' || lower == 'system status') {
      return const VoiceResponse(
        text: 'All systems operational.',
        type: ResponseType.commandConfirmation,
      );
    }

    // Hello
    if (lower.startsWith('hello') || lower.startsWith('hi prime') || lower.startsWith('hey prime')) {
      return const VoiceResponse(
        text: 'Hello! How can I help you?',
        type: ResponseType.conversation,
      );
    }

    // What can you do
    if (lower.contains('what can you do') || lower.contains('capabilities')) {
      return const VoiceResponse(
        text: 'I can answer questions, help with tasks, and manage your system. Just speak naturally.',
        type: ResponseType.conversation,
      );
    }

    // Shutdown
    if (lower == 'shutdown' || lower == 'shut down') {
      return const VoiceResponse(
        text: 'Shutting down. Goodbye.',
        type: ResponseType.commandConfirmation,
      );
    }

    return null; // Not a local command, send to LLM
  }

  Future<VoiceResponse> _processWithLLM(String input) async {
    try {
      _conversation.addUserMessage(input);

      final response = await _llmProvider!.generate(
        userMessage: input,
        context: _conversation.getContext(),
      );

      _conversation.addAssistantMessage(response.text);

      return VoiceResponse(
        text: response.text,
        type: response.type,
        shouldSpeak: response.shouldSpeak,
      );
    } catch (e) {
      debugPrint('[VoiceManager] LLM error: $e');
      return const VoiceResponse(
        text: 'I had trouble processing that. Could you try again?',
        type: ResponseType.error,
      );
    }
  }

  /// Speak text using the TTS provider
  Future<void> speak(String text) async {
    if (text.isEmpty || _ttsProvider == null) return;

    AudioService.instance.playReply();
    await _ttsProvider!.speak(text);
  }

  /// Stop speaking
  Future<void> stopSpeaking() async {
    await _ttsProvider?.stop();
  }

  /// Check if PRIME is speaking
  bool get isSpeaking => _ttsProvider?.isSpeaking ?? false;
}

/// Response from the voice manager
class VoiceResponse {
  final String text;
  final ResponseType type;
  final bool shouldSpeak;

  const VoiceResponse({
    required this.text,
    this.type = ResponseType.conversation,
    this.shouldSpeak = true,
  });
}
