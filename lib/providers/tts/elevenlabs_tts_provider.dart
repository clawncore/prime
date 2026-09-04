import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import '../../voice/tts_provider.dart';

/// PRIME Providers - ElevenLabs TTS
///
/// Cloud TTS using ElevenLabs API for high-quality voices.
/// Requires API key in .env: ELEVENLABS_API_KEY

class ElevenLabsTTSProvider implements TTSProvider {
  final String apiKey;
  String _voiceId = '21m00Tcm4TlvDq8ikWAM'; // Rachel (default)
  double _stability = 0.5;
  double _similarityBoost = 0.75;

  bool _initialized = false;
  bool _isSpeaking = false;
  Process? _currentProcess;

  final StreamController<bool> _speakingController =
      StreamController<bool>.broadcast();
  final StreamController<double> _amplitudeController =
      StreamController<double>.broadcast();

  ElevenLabsTTSProvider({required this.apiKey});

  @override
  String get name => 'ElevenLabs TTS';

  @override
  bool get isSpeaking => _isSpeaking;

  @override
  Stream<double> get amplitudeStream => _amplitudeController.stream;

  @override
  Future<List<String>> getAvailableVoices() async {
    // Common ElevenLabs voices
    return [
      'Rachel (21m00Tcm4TlvDq8ikWAM)',
      'Domi (AZnzlk1XvdvUeBnXmlld)',
      'Bella (EXAVITQu4vr4xnSDxMaL)',
      'Antoni (ErXwobaYiN019PkySvjV)',
      ' Elli (MF3mGyEYCl7XYWbV9V6O)',
    ];
  }

  @override
  Future<void> setVoice(String voiceName) async {
    // Extract voice ID from format "Name (ID)"
    final match = RegExp(r'\(([^)]+)\)').firstMatch(voiceName);
    if (match != null) {
      _voiceId = match.group(1)!;
      debugPrint('[ElevenLabs] Voice set to: $_voiceId');
    }
  }

  void setVoiceId(String voiceId) => _voiceId = voiceId;
  void setStability(double stability) => _stability = stability.clamp(0.0, 1.0);
  void setSimilarity(double similarity) => _similarityBoost = similarity.clamp(0.0, 1.0);

  @override
  Future<void> setRate(double rate) async {
    // ElevenLabs doesn't have a rate parameter
    debugPrint('[ElevenLabs] Rate setting ignored (not supported by API)');
  }

  @override
  Future<void> setVolume(double volume) async {
    // Volume handled at playback level
    debugPrint('[ElevenLabs] Volume setting noted');
  }

  Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;
    debugPrint('[ElevenLabs] Initialized');
  }

  @override
  Future<bool> isAvailable() async {
    return apiKey.isNotEmpty;
  }

  @override
  Future<void> speak(String text) async {
    if (text.isEmpty || !_initialized) return;
    if (!await isAvailable()) {
      debugPrint('[ElevenLabs] Not available - no API key');
      return;
    }

    _setSpeaking(true);

    try {
      // Call ElevenLabs API
      final url = Uri.parse(
        'https://api.elevenlabs.io/v1/text-to-speech/$_voiceId',
      );

      final response = await http.post(
        url,
        headers: {
          'xi-api-key': apiKey,
          'Content-Type': 'application/json',
          'Accept': 'audio/mpeg',
        },
        body: jsonEncode({
          'text': text,
          'model_id': 'eleven_monolingual_v1',
          'voice_settings': {
            'stability': _stability,
            'similarity_boost': _similarityBoost,
          },
        }),
      );

      if (response.statusCode == 200) {
        // Save audio to temp file and play
        final tempDir = await getTemporaryDirectory();
        final audioFile = File('${tempDir.path}/prime_elevenlabs.mp3');
        await audioFile.writeAsBytes(response.bodyBytes);

        // Play with platform audio player
        await _playAudioFile(audioFile.path);
      } else {
        debugPrint('[ElevenLabs] API error: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('[ElevenLabs] Error: $e');
    } finally {
      _setSpeaking(false);
    }
  }

  @override
  Future<void> stop() async {
    if (_currentProcess != null) {
      try {
        _currentProcess!.kill();
      } catch (_) {}
      _currentProcess = null;
    }
    _setSpeaking(false);
  }

  @override
  Future<List<int>?> synthesizeToBytes(String text) async {
    if (text.isEmpty || !await isAvailable()) return null;

    try {
      final url = Uri.parse(
        'https://api.elevenlabs.io/v1/text-to-speech/$_voiceId/stream',
      );

      final response = await http.post(
        url,
        headers: {
          'xi-api-key': apiKey,
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'text': text,
          'model_id': 'eleven_monolingual_v1',
          'voice_settings': {
            'stability': _stability,
            'similarity_boost': _similarityBoost,
          },
        }),
      );

      if (response.statusCode == 200) {
        return response.bodyBytes;
      }
    } catch (e) {
      debugPrint('[ElevenLabs] Synthesize error: $e');
    }
    return null;
  }

  @override
  Future<void> playBytes(List<int> audioBytes) async {
    try {
      final tempDir = await getTemporaryDirectory();
      final audioFile = File('${tempDir.path}/prime_elevenlabs_stream.mp3');
      await audioFile.writeAsBytes(audioBytes);
      await _playAudioFile(audioFile.path);
    } catch (e) {
      debugPrint('[ElevenLabs] PlayBytes error: $e');
    }
  }

  Future<void> _playAudioFile(String path) async {
    try {
      if (Platform.isLinux) {
        _currentProcess = await Process.start('mpv', [
          '--no-video',
          '--really-quiet',
          path,
        ]);
        await _currentProcess!.exitCode;
      } else if (Platform.isWindows) {
        _currentProcess = await Process.start('powershell.exe', [
          '-NoProfile',
          '-Command',
          '(New-Object Media.SoundPlayer "$path").PlaySync()',
        ]);
        await _currentProcess!.exitCode;
      } else if (Platform.isMacOS) {
        _currentProcess = await Process.start('afplay', [path]);
        await _currentProcess!.exitCode;
      }
    } catch (e) {
      debugPrint('[ElevenLabs] Playback error: $e');
    } finally {
      _currentProcess = null;
    }
  }

  void _setSpeaking(bool speaking) {
    _isSpeaking = speaking;

    // Emit amplitude while speaking
    if (speaking) {
      _emitSpeakingAmplitude();
    }
  }

  void _emitSpeakingAmplitude() async {
    while (_isSpeaking) {
      await Future.delayed(const Duration(milliseconds: 50));
      if (_isSpeaking) {
        _amplitudeController.add(0.3 + (DateTime.now().millisecond % 100) / 200);
      }
    }
  }

  @override
  Future<void> dispose() async {
    await stop();
    await _speakingController.close();
    await _amplitudeController.close();
  }
}
