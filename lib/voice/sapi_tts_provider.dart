import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'tts_provider.dart';

/// PRIME Voice - Windows SAPI TTS Provider
/// 
/// Wraps the existing Windows System.Speech.Synthesis implementation.
/// This is the current default voice provider.
/// 
/// DO NOT REMOVE - this must continue working as the fallback.

class SapiTTSProvider implements TTSProvider {
  Process? _currentProcess;
  String? _scriptDir;
  bool _initialized = false;
  bool _isSpeaking = false;
  String _currentVoice = 'Microsoft Zira Desktop';
  double _rate = 1.0;
  double _volume = 1.0;
  final StreamController<double> _amplitudeController =
      StreamController<double>.broadcast();

  SapiTTSProvider();

  @override
  String get name => 'Windows SAPI';

  @override
  bool get isSpeaking => _isSpeaking;

  @override
  Stream<double> get amplitudeStream => _amplitudeController.stream;

  Future<void> initialize() async {
    if (_initialized) return;

    if (!Platform.isWindows) {
      debugPrint('[SapiTTS] Windows SAPI not available on ${Platform.operatingSystem}');
      return;
    }

    try {
      final tempDir = await getTemporaryDirectory();
      _scriptDir = '${tempDir.path}${Platform.pathSeparator}prime_voice';
      await Directory(_scriptDir!).create(recursive: true);
      _initialized = true;
      debugPrint('[SapiTTS] Initialized');
    } catch (e) {
      debugPrint('[SapiTTS] Init failed: $e');
    }
  }

  @override
  Future<void> speak(String text) async {
    if (!_initialized || text.trim().isEmpty) return;

    await stop();

    try {
      _isSpeaking = true;

      // Escape single quotes for PowerShell
      final escapedText = text.replaceAll("'", "''");

      // Write speak script
      final script = '''
Add-Type -AssemblyName System.Speech
\$synth = New-Object System.Speech.Synthesis.SpeechSynthesizer
\$synth.SelectVoice('$_currentVoice')
\$synth.Rate = ${_rate.toStringAsFixed(1)}
\$synth.Volume = ${(_volume * 100).round()}
\$synth.Speak('$escapedText')
\$synth.Dispose()
''';
      final scriptPath = '${_scriptDir}${Platform.pathSeparator}speak.ps1';
      await File(scriptPath).writeAsString(script);

      // Run PowerShell
      _currentProcess = await Process.start('powershell.exe', [
        '-NoProfile',
        '-ExecutionPolicy', 'Bypass',
        '-File', scriptPath,
      ]);

      // Wait for completion
      await _currentProcess!.exitCode;
      _currentProcess = null;
      _isSpeaking = false;
    } catch (e) {
      debugPrint('[SapiTTS] Speak error: $e');
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
    // SAPI doesn't easily support byte output via PowerShell
    // Return null to fall back to direct speak()
    return null;
  }

  @override
  Future<void> playBytes(List<int> audioBytes) async {
    // SAPI doesn't support byte playback
    // Fall back to speak() if needed
  }

  @override
  Future<bool> isAvailable() async {
    try {
      final result = await Process.run('powershell.exe', [
        '-NoProfile',
        '-Command',
        'Add-Type -AssemblyName System.Speech; Write-Output "OK"'
      ]);
      return result.exitCode == 0;
    } catch (e) {
      return false;
    }
  }

  @override
  Future<List<String>> getAvailableVoices() async {
    try {
      final script = '''
Add-Type -AssemblyName System.Speech
\$synth = New-Object System.Speech.Synthesis.SpeechSynthesizer
foreach (\$v in \$synth.GetInstalledVoices()) {
  Write-Output \$v.VoiceInfo.Name
}
\$synth.Dispose()
''';
      final scriptPath = '${_scriptDir}${Platform.pathSeparator}voices.ps1';
      await File(scriptPath).writeAsString(script);

      final result = await Process.run('powershell.exe', [
        '-NoProfile',
        '-ExecutionPolicy', 'Bypass',
        '-File', scriptPath,
      ]);

      if (result.exitCode == 0) {
        final output = result.stdout.toString().trim();
        return output.split('\n').where((v) => v.trim().isNotEmpty).toList();
      }
    } catch (e) {
      debugPrint('[SapiTTS] GetVoices error: $e');
    }
    return ['Microsoft Zira Desktop'];
  }

  @override
  Future<void> setVoice(String voiceName) async {
    _currentVoice = voiceName;
    debugPrint('[SapiTTS] Voice set to: $voiceName');
  }

  @override
  Future<void> setRate(double rate) async {
    _rate = rate.clamp(0.0, 2.0);
    debugPrint('[SapiTTS] Rate set to: $_rate');
  }

  @override
  Future<void> setVolume(double volume) async {
    _volume = volume.clamp(0.0, 1.0);
    debugPrint('[SapiTTS] Volume set to: $_volume');
  }

  @override
  Future<void> dispose() async {
    await stop();
    await _amplitudeController.close();
  }
}
