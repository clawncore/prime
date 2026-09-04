import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// PRIME Settings Service
///
/// Manages provider configuration and user preferences.
/// Loads from .env file and SharedPreferences.

class SettingsService extends ChangeNotifier {
  static const String _prefix = 'prime_';

  // LLM Settings
  String _llmProvider = 'gemini';
  String _llmModel = 'gemini-3.6-flash';
  String _geminiApiKey = '';

  // TTS Settings
  String _ttsProvider = 'auto';
  String _ttsVoice = '';
  double _ttsRate = 1.0;
  double _ttsVolume = 1.0;

  // STT Settings
  String _sttProvider = 'auto';
  String _sttLanguage = 'en-US';

  // Audio Settings
  double _systemSoundVolume = 0.7;
  bool _autoListen = true;
  bool _bargeInEnabled = true;

  // API Keys (loaded from .env, never exposed)
  String _elevenLabsApiKey = '';

  // Getters
  String get llmProvider => _llmProvider;
  String get llmModel => _llmModel;
  String get geminiApiKey => _geminiApiKey;
  String get ttsProvider => _ttsProvider;
  String get ttsVoice => _ttsVoice;
  double get ttsRate => _ttsRate;
  double get ttsVolume => _ttsVolume;
  String get sttProvider => _sttProvider;
  String get sttLanguage => _sttLanguage;
  double get systemSoundVolume => _systemSoundVolume;
  bool get autoListen => _autoListen;
  bool get bargeInEnabled => _bargeInEnabled;
  String get elevenLabsApiKey => _elevenLabsApiKey;

  bool get hasGeminiKey => _geminiApiKey.isNotEmpty;
  bool get hasElevenLabsKey => _elevenLabsApiKey.isNotEmpty;

  /// Initialize settings from .env and SharedPreferences
  Future<void> initialize() async {
    await _loadFromEnv();
    await _loadFromPrefs();
    debugPrint('[SettingsService] Initialized');
    debugPrint('[SettingsService] LLM: $_llmProvider ($_llmModel)');
    debugPrint('[SettingsService] TTS: $_ttsProvider');
    debugPrint('[SettingsService] STT: $_sttProvider');
    debugPrint('[SettingsService] Gemini key: ${_geminiApiKey.isNotEmpty ? "set" : "not set"}');
  }

  /// Load API keys from .env file
  Future<void> _loadFromEnv() async {
    try {
      final exePath = Platform.resolvedExecutable;
      final exeDir = File(exePath).parent.path;
      final envFile = File('$exeDir${Platform.pathSeparator}.env');

      if (await envFile.exists()) {
        final content = await envFile.readAsString();
        for (final line in content.split('\n')) {
          final trimmed = line.trim();
          if (trimmed.isEmpty || trimmed.startsWith('#')) continue;

          final parts = trimmed.split('=');
          if (parts.length >= 2) {
            final key = parts[0].trim();
            final value = parts.sublist(1).join('=').trim();

            switch (key) {
              case 'GEMINI_API_KEY':
                _geminiApiKey = value;
                break;
              case 'GEMINI_MODEL':
                _llmModel = value;
                break;
              case 'ELEVENLABS_API_KEY':
                _elevenLabsApiKey = value;
                break;
              case 'TTS_PROVIDER':
                _ttsProvider = value;
                break;
              case 'STT_PROVIDER':
                _sttProvider = value;
                break;
              case 'STT_LANGUAGE':
                _sttLanguage = value;
                break;
            }
          }
        }
      }
    } catch (e) {
      debugPrint('[SettingsService] .env load error: $e');
    }
  }

  /// Load preferences from SharedPreferences
  Future<void> _loadFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    _llmProvider = prefs.getString('${_prefix}llm_provider') ?? _llmProvider;
    _llmModel = prefs.getString('${_prefix}llm_model') ?? _llmModel;
    _ttsProvider = prefs.getString('${_prefix}tts_provider') ?? _ttsProvider;
    _ttsVoice = prefs.getString('${_prefix}tts_voice') ?? _ttsVoice;
    _ttsRate = prefs.getDouble('${_prefix}tts_rate') ?? _ttsRate;
    _ttsVolume = prefs.getDouble('${_prefix}tts_volume') ?? _ttsVolume;
    _sttProvider = prefs.getString('${_prefix}stt_provider') ?? _sttProvider;
    _sttLanguage = prefs.getString('${_prefix}stt_language') ?? _sttLanguage;
    _systemSoundVolume = prefs.getDouble('${_prefix}sound_volume') ?? _systemSoundVolume;
    _autoListen = prefs.getBool('${_prefix}auto_listen') ?? _autoListen;
    _bargeInEnabled = prefs.getBool('${_prefix}barge_in') ?? _bargeInEnabled;
  }

  /// Save a setting
  Future<void> _save(String key, dynamic value) async {
    final prefs = await SharedPreferences.getInstance();
    final fullKey = '${_prefix}$key';

    if (value is String) {
      await prefs.setString(fullKey, value);
    } else if (value is double) {
      await prefs.setDouble(fullKey, value);
    } else if (value is bool) {
      await prefs.setBool(fullKey, value);
    }

    notifyListeners();
  }

  // Setters
  Future<void> setGeminiApiKey(String key) async {
    _geminiApiKey = key;
    await _save('gemini_api_key', key);
  }

  Future<void> setLLMProvider(String provider) async {
    _llmProvider = provider;
    await _save('llm_provider', provider);
  }

  Future<void> setLLMModel(String model) async {
    _llmModel = model;
    await _save('llm_model', model);
  }

  Future<void> setTTSProvider(String provider) async {
    _ttsProvider = provider;
    await _save('tts_provider', provider);
  }

  Future<void> setTTSVoice(String voice) async {
    _ttsVoice = voice;
    await _save('tts_voice', voice);
  }

  Future<void> setTTSRate(double rate) async {
    _ttsRate = rate.clamp(0.5, 2.0);
    await _save('tts_rate', _ttsRate);
  }

  Future<void> setTTSVolume(double volume) async {
    _ttsVolume = volume.clamp(0.0, 1.0);
    await _save('tts_volume', _ttsVolume);
  }

  Future<void> setSTTProvider(String provider) async {
    _sttProvider = provider;
    await _save('stt_provider', provider);
  }

  Future<void> setSTTLanguage(String language) async {
    _sttLanguage = language;
    await _save('stt_language', language);
  }

  Future<void> setSystemSoundVolume(double volume) async {
    _systemSoundVolume = volume.clamp(0.0, 1.0);
    await _save('sound_volume', _systemSoundVolume);
  }

  Future<void> setAutoListen(bool enabled) async {
    _autoListen = enabled;
    await _save('auto_listen', enabled);
  }

  Future<void> setBargeIn(bool enabled) async {
    _bargeInEnabled = enabled;
    await _save('barge_in', enabled);
  }
}
