import 'dart:io';
import '../../brain/llm_provider.dart';
import '../../brain/gemini_provider.dart';
import '../../voice/tts_provider.dart';
import '../../voice/sapi_tts_provider.dart';
import '../../voice/linux_tts_provider.dart';
import '../stt/stt_provider.dart';
import '../stt/sapi_stt_provider.dart';
import '../stt/no_stt_provider.dart';
import '../tts/elevenlabs_tts_provider.dart';
import '../../services/settings_service.dart';
import '../../services/debug_service.dart';

/// PRIME Provider Factory
///
/// Creates and manages provider instances based on configuration.
/// Handles fallback chains when primary providers are unavailable.

class ProviderFactory {
  final SettingsService _settings;
  final DebugService _debug;

  LLMProvider? _currentLLM;
  TTSProvider? _currentTTS;
  STTProvider? _currentSTT;

  ProviderFactory(this._settings, this._debug);

  /// Get or create the LLM provider
  Future<LLMProvider?> getLLMProvider() async {
    if (_currentLLM != null) {
      final available = await _currentLLM!.isAvailable();
      if (available) return _currentLLM;
      _debug.warning('LLM', '${_currentLLM!.name} became unavailable');
    }

    // Try configured provider
    switch (_settings.llmProvider) {
      case 'gemini':
        if (_settings.hasGeminiKey) {
          _currentLLM = GeminiProvider(
            apiKey: _settings.geminiApiKey,
            model: _settings.llmModel,
          );
          final available = await _currentLLM!.isAvailable();
          if (available) {
            _debug.info('LLM', 'Gemini connected: ${_settings.llmModel}');
            return _currentLLM;
          }
          _debug.warning('LLM', 'Gemini unavailable');
        } else {
          _debug.warning('LLM', 'Gemini API key not configured');
        }
        break;

      default:
        _debug.warning('LLM', 'Unknown provider: ${_settings.llmProvider}');
    }

    _currentLLM = null;
    _debug.info('LLM', 'No LLM available - local commands only');
    return null;
  }

  /// Get or create the TTS provider with fallback
  Future<TTSProvider?> getTTSProvider() async {
    if (_currentTTS != null) {
      final available = await _currentTTS!.isAvailable();
      if (available) return _currentTTS;
      _debug.warning('TTS', '${_currentTTS!.name} became unavailable');
    }

    // Try configured provider first
    TTSProvider? provider = await _createTTSProvider(_settings.ttsProvider);
    if (provider != null) {
      final available = await provider.isAvailable();
      if (available) {
        _currentTTS = provider;
        _debug.info('TTS', 'Using ${provider.name}');
        return _currentTTS;
      }
    }

    // Fallback to platform default
    provider = await _createPlatformTTS();
    if (provider != null) {
      final available = await provider.isAvailable();
      if (available) {
        _currentTTS = provider;
        _debug.info('TTS', 'Fallback to ${provider.name}');
        return _currentTTS;
      }
    }

    _currentTTS = null;
    _debug.warning('TTS', 'No TTS available');
    return null;
  }

  /// Get or create the STT provider with fallback
  Future<STTProvider?> getSTTProvider() async {
    if (_currentSTT != null) {
      final available = await _currentSTT!.isAvailable();
      if (available) return _currentSTT;
      _debug.warning('STT', '${_currentSTT!.name} became unavailable');
    }

    // Try configured provider
    switch (_settings.sttProvider) {
      case 'sapi':
        if (Platform.isWindows) {
          final provider = SapiSTTProvider();
          await provider.initialize();
          final available = await provider.isAvailable();
          if (available) {
            _currentSTT = provider;
            _debug.info('STT', 'Using Windows SAPI');
            return _currentSTT;
          }
        }
        break;

      case 'vosk':
        // TODO: Implement Vosk STT
        _debug.info('STT', 'Vosk STT not yet implemented');
        break;

      default:
        // Auto-detect: try SAPI on Windows
        if (Platform.isWindows) {
          final provider = SapiSTTProvider();
          await provider.initialize();
          final available = await provider.isAvailable();
          if (available) {
            _currentSTT = provider;
            _debug.info('STT', 'Auto-detected Windows SAPI');
            return _currentSTT;
          }
        }
    }

    // Fallback: no STT available
    _currentSTT = NoSTTProvider();
    _debug.info('STT', 'No STT available - text input only');
    return _currentSTT;
  }

  Future<TTSProvider?> _createTTSProvider(String providerName) async {
    switch (providerName) {
      case 'sapi':
        if (Platform.isWindows) {
          final provider = SapiTTSProvider();
          await provider.initialize();
          return provider;
        }
        break;

      case 'linux':
        if (Platform.isLinux || Platform.isMacOS) {
          final provider = LinuxTTSProvider();
          await provider.initialize();
          return provider;
        }
        break;

      case 'elevenlabs':
        if (_settings.hasElevenLabsKey) {
          final provider = ElevenLabsTTSProvider(
            apiKey: _settings.elevenLabsApiKey,
          );
          await provider.initialize();
          return provider;
        }
        _debug.warning('TTS', 'ElevenLabs API key not configured');
        break;
    }
    return null;
  }

  Future<TTSProvider?> _createPlatformTTS() async {
    if (Platform.isWindows) {
      final provider = SapiTTSProvider();
      await provider.initialize();
      return provider;
    } else if (Platform.isLinux || Platform.isMacOS) {
      final provider = LinuxTTSProvider();
      await provider.initialize();
      return provider;
    }
    return null;
  }

  /// Dispose all providers
  Future<void> dispose() async {
    await _currentLLM?.dispose();
    await _currentTTS?.dispose();
    await _currentSTT?.dispose();
  }
}
