import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'tts_provider.dart';

/// PRIME Voice - Linux TTS Provider (espeak-ng)
///
/// Uses espeak-ng for text-to-speech on Linux.
/// This is the cross-platform fallback for non-Windows systems.

class LinuxTTSProvider implements TTSProvider {
  Process? _currentProcess;
  bool _initialized = false;
  bool _isSpeaking = false;
  String _currentVoice = 'default';
  double _rate = 1.0;
  double _volume = 1.0;
  final StreamController<double> _amplitudeController =
      StreamController<double>.broadcast();

  LinuxTTSProvider();

  @override
  String get name => 'Linux espeak-ng';

  @override
  bool get isSpeaking => _isSpeaking;

  @override
  Stream<double> get amplitudeStream => _amplitudeController.stream;

  Future<void> initialize() async {
    if (_initialized) return;

    try {
      // Check if espeak-ng is available
      final result = await Process.run('which', ['espeak-ng']);
      if (result.exitCode != 0) {
        debugPrint('[LinuxTTS] espeak-ng not found in PATH');
        return;
      }
      _initialized = true;
      debugPrint('[LinuxTTS] Initialized with espeak-ng');
    } catch (e) {
      debugPrint('[LinuxTTS] Init failed: $e');
    }
  }

  @override
  Future<void> speak(String text) async {
    if (!_initialized || text.trim().isEmpty) return;

    await stop();

    try {
      _isSpeaking = true;

      final args = <String>[
        '-v', _currentVoice,
        '-s', '${(_rate * 175).round()}',
        '-a', '${(_volume * 200).round()}',
        text,
      ];

      _currentProcess = await Process.start('espeak-ng', args);
      await _currentProcess!.exitCode;
      _currentProcess = null;
      _isSpeaking = false;
    } catch (e) {
      debugPrint('[LinuxTTS] Speak error: $e');
      _isSpeaking = false;
    }
  }

  @override
  Future<void> stop() async {
    if (_currentProcess != null) {
      try {
        _currentProcess!.kill();
      } catch (e) {
        // Ignore
      }
      _currentProcess = null;
    }
    _isSpeaking = false;
  }

  @override
  Future<List<int>?> synthesizeToBytes(String text) async {
    // espeak-ng can output to stdout as WAV
    try {
      final result = await Process.run('espeak-ng', [
        '-v', _currentVoice,
        '-s', '${(_rate * 175).round()}',
        '-w', '-', // Output WAV to stdout
        text,
      ]);
      if (result.exitCode == 0) {
        return result.stdout as List<int>;
      }
    } catch (e) {
      debugPrint('[LinuxTTS] synthesizeToBytes error: $e');
    }
    return null;
  }

  @override
  Future<void> playBytes(List<int> audioBytes) async {
    // Write bytes to temp file and play with paplay
    try {
      final tempDir = Directory.systemTemp;
      final tempFile = File('${tempDir.path}/prime_tts_${DateTime.now().millisecondsSinceEpoch}.wav');
      await tempFile.writeAsBytes(audioBytes);
      await Process.run('paplay', [tempFile.path]);
      await tempFile.delete();
    } catch (e) {
      debugPrint('[LinuxTTS] playBytes error: $e');
    }
  }

  @override
  Future<bool> isAvailable() async {
    try {
      final result = await Process.run('which', ['espeak-ng']);
      return result.exitCode == 0;
    } catch (e) {
      return false;
    }
  }

  @override
  Future<List<String>> getAvailableVoices() async {
    try {
      final result = await Process.run('espeak-ng', ['--voices']);
      if (result.exitCode == 0) {
        final lines = result.stdout.toString().split('\n');
        final voices = <String>['default'];
        for (final line in lines) {
          if (line.trim().isEmpty || line.startsWith('Pty') || line.startsWith('Language')) continue;
          final parts = line.trim().split(RegExp(r'\s+'));
          if (parts.length >= 2) {
            voices.add(parts[1]);
          }
        }
        return voices;
      }
    } catch (e) {
      debugPrint('[LinuxTTS] GetVoices error: $e');
    }
    return ['default'];
  }

  @override
  Future<void> setVoice(String voiceName) async {
    _currentVoice = voiceName;
    debugPrint('[LinuxTTS] Voice set to: $voiceName');
  }

  @override
  Future<void> setRate(double rate) async {
    _rate = rate.clamp(0.0, 2.0);
    debugPrint('[LinuxTTS] Rate set to: $_rate');
  }

  @override
  Future<void> setVolume(double volume) async {
    _volume = volume.clamp(0.0, 1.0);
    debugPrint('[LinuxTTS] Volume set to: $_volume');
  }

  @override
  Future<void> dispose() async {
    await stop();
    await _amplitudeController.close();
  }
}
