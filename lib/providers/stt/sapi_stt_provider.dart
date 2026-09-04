import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'stt_provider.dart';

/// PRIME Voice - Windows SAPI Speech-to-Text Provider
///
/// Uses Windows System.Speech.Recognition for speech recognition.
/// This is the native Windows implementation.

class SapiSTTProvider implements STTProvider {
  Process? _currentProcess;
  String? _scriptDir;
  bool _initialized = false;
  bool _isListening = false;
  String _currentLanguage = 'en-US';

  final StreamController<STTResult> _resultController =
      StreamController<STTResult>.broadcast();
  final StreamController<double> _amplitudeController =
      StreamController<double>.broadcast();

  SapiSTTProvider();

  @override
  String get name => 'Windows SAPI STT';

  @override
  bool get isListening => _isListening;

  @override
  Stream<STTResult> get resultStream => _resultController.stream;

  @override
  Stream<double> get amplitudeStream => _amplitudeController.stream;

  Future<void> initialize() async {
    if (_initialized) return;

    if (!Platform.isWindows) {
      debugPrint('[SapiSTT] Not available on ${Platform.operatingSystem}');
      return;
    }

    try {
      final tempDir = await getTemporaryDirectory();
      _scriptDir = '${tempDir.path}${Platform.pathSeparator}prime_stt';
      await Directory(_scriptDir!).create(recursive: true);
      _initialized = true;
      debugPrint('[SapiSTT] Initialized');
    } catch (e) {
      debugPrint('[SapiSTT] Init failed: $e');
    }
  }

  @override
  Future<bool> isAvailable() async {
    if (!Platform.isWindows) return false;
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
  Future<void> startListening({String language = 'en-US'}) async {
    if (!_initialized || _isListening) return;

    _currentLanguage = language;
    _isListening = true;

    debugPrint('[SapiSTT] Starting listening...');

    // Simulate amplitude while listening
    _simulateAmplitude();

    try {
      // Write PowerShell script for speech recognition
      final script = '''
Add-Type -AssemblyName System.Speech
\$recognizer = New-Object System.Speech.Recognition.SpeechRecognizer
\$grammar = New-Object System.Speech.Recognition.DictationGrammar
\$recognizer.LoadGrammar(\$grammar)
\$recognizer.BabbleTimeout = [TimeSpan]::FromSeconds(3)
\$recognizer.InitialSilenceTimeout = [TimeSpan]::FromSeconds(8)
\$recognizer.EndSilenceTimeout = [TimeSpan]::FromSeconds(1.5)
\$result = \$recognizer.Recognize([TimeSpan]::FromSeconds(15))
if (\$result -ne \$null) {
    Write-Output \$result.Text
}
''';

      final scriptPath = '${_scriptDir}${Platform.pathSeparator}listen.ps1';
      await File(scriptPath).writeAsString(script);

      _currentProcess = await Process.start('powershell.exe', [
        '-NoProfile',
        '-ExecutionPolicy', 'Bypass',
        '-File', scriptPath,
      ]);

      // Read output as it comes
      final output = StringBuffer();
      _currentProcess!.stdout.transform(SystemEncoding().decoder).listen(
        (data) {
          output.write(data);
        },
      );

      // Wait for completion
      final exitCode = await _currentProcess!.exitCode;
      _currentProcess = null;

      final recognized = output.toString().trim();
      if (recognized.isNotEmpty) {
        _resultController.add(STTResult(
          text: recognized,
          isFinal: true,
          confidence: 0.9,
        ));
      }

      _isListening = false;
      debugPrint('[SapiSTT] Listening ended');

      // Cleanup
      try {
        await File(scriptPath).delete();
      } catch (e) {}
    } catch (e) {
      debugPrint('[SapiSTT] Listen error: $e');
      _isListening = false;
      _resultController.addError(e);
    }
  }

  void _simulateAmplitude() async {
    // Simulate subtle amplitude while listening
    while (_isListening) {
      await Future.delayed(const Duration(milliseconds: 50));
      if (_isListening) {
        _amplitudeController.add(0.1 + (DateTime.now().millisecond % 100) / 500);
      }
    }
  }

  @override
  Future<void> stopListening() async {
    if (!_isListening) return;

    _isListening = false;

    if (_currentProcess != null) {
      try {
        _currentProcess!.kill();
      } catch (e) {
        // Ignore
      }
      _currentProcess = null;
    }

    debugPrint('[SapiSTT] Stopped listening');
  }

  @override
  Future<List<String>> getAvailableLanguages() async {
    return ['en-US', 'en-GB', 'de-DE', 'fr-FR', 'es-ES'];
  }

  @override
  Future<void> dispose() async {
    await stopListening();
    await _resultController.close();
    await _amplitudeController.close();
  }
}
