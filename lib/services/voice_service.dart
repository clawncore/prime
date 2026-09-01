import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'audio_service.dart';

enum VoiceState {
  idle,
  listening,
  processing,
  speaking,
  error,
}

class VoiceService {
  VoiceService._();
  static final VoiceService instance = VoiceService._();

  VoiceState _state = VoiceState.idle;
  bool _initialized = false;
  bool _enabled = true;
  String _lastRecognized = '';
  double _confidence = 0.0;
  bool _ttsAvailable = false;
  Process? _ttsProcess;
  String? _scriptDir;

  VoiceState get state => _state;
  bool get isListening => _state == VoiceState.listening;
  bool get isSpeaking => _state == VoiceState.speaking;
  bool get isEnabled => _enabled;
  String get lastRecognized => _lastRecognized;
  double get confidence => _confidence;
  bool get ttsAvailable => _ttsAvailable;

  final StreamController<VoiceState> _stateController =
      StreamController<VoiceState>.broadcast();
  final StreamController<String> _textController =
      StreamController<String>.broadcast();

  Stream<VoiceState> get stateStream => _stateController.stream;
  Stream<String> get recognizedText => _textController.stream;

  Future<void> initialize() async {
    if (_initialized) return;

    try {
      debugPrint('[VoiceService] Initializing Windows SAPI voice system...');

      final tempDir = await getTemporaryDirectory();
      _scriptDir = '${tempDir.path}\\prime_voice';
      await Directory(_scriptDir!).create(recursive: true);

      _ttsAvailable = await _testSapi();
      debugPrint('[VoiceService] TTS available: $_ttsAvailable');

      _initialized = true;
      debugPrint('[VoiceService] Initialized successfully');
    } catch (e) {
      debugPrint('[VoiceService] Init failed: $e');
      _ttsAvailable = false;
    }
  }

  Future<bool> _testSapi() async {
    try {
      final script = '''
Add-Type -AssemblyName System.Speech
\$synth = New-Object System.Speech.Synthesis.SpeechSynthesizer
\$voices = \$synth.GetInstalledVoices()
Write-Output \$voices.Count
\$synth.Dispose()
''';
      final scriptPath = '$_scriptDir\\test.ps1';
      await File(scriptPath).writeAsString(script);

      final result = await Process.run('powershell.exe', [
        '-NoProfile',
        '-ExecutionPolicy', 'Bypass',
        '-File', scriptPath,
      ]);

      return result.exitCode == 0;
    } catch (e) {
      debugPrint('[VoiceService] SAPI test failed: $e');
      return false;
    }
  }

  void _updateState(VoiceState newState) {
    if (_state == newState) return;
    _state = newState;
    _stateController.add(newState);
    debugPrint('[VoiceService] State: $newState');
  }

  Future<void> speak(String text) async {
    if (!_initialized || !_ttsAvailable || text.trim().isEmpty) return;

    await stopSpeaking();
    AudioService.instance.playReply();

    try {
      _updateState(VoiceState.speaking);

      // Escape single quotes for PowerShell
      final escapedText = text.replaceAll("'", "''");

      // Write speak script
      final script = '''
Add-Type -AssemblyName System.Speech
\$synth = New-Object System.Speech.Synthesis.SpeechSynthesizer
\$synth.SelectVoice('Microsoft Zira Desktop')
\$synth.Rate = 1
\$synth.Volume = 100
\$synth.Speak('$escapedText')
\$synth.Dispose()
''';
      final scriptPath = '$_scriptDir\\speak.ps1';
      await File(scriptPath).writeAsString(script);

      // Run PowerShell
      _ttsProcess = await Process.start('powershell.exe', [
        '-NoProfile',
        '-ExecutionPolicy', 'Bypass',
        '-File', scriptPath,
      ]);

      // Wait for completion
      await _ttsProcess!.exitCode;
      _ttsProcess = null;
      _updateState(VoiceState.idle);
    } catch (e) {
      debugPrint('[VoiceService] Speak error: $e');
      _updateState(VoiceState.error);
      Future.delayed(const Duration(seconds: 2), () {
        if (_state == VoiceState.error) _updateState(VoiceState.idle);
      });
    }
  }

  Future<void> stopSpeaking() async {
    if (_ttsProcess != null) {
      try {
        _ttsProcess!.kill();
      } catch (e) {
        // Ignore
      }
      _ttsProcess = null;
    }
    _updateState(VoiceState.idle);
  }

  void toggle() {
    _enabled = !_enabled;
    if (!_enabled) {
      stopSpeaking();
    }
    debugPrint('[VoiceService] Toggled: $_enabled');
  }

  void toggleListening() async {
    if (_state == VoiceState.listening) {
      _updateState(VoiceState.idle);
    } else {
      await stopSpeaking();
      _updateState(VoiceState.listening);

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

        final scriptPath = '$_scriptDir\\listen.ps1';
        await File(scriptPath).writeAsString(script);

        final result = await Process.run('powershell.exe', [
          '-NoProfile',
          '-ExecutionPolicy', 'Bypass',
          '-File', scriptPath,
        ]);

        final recognized = result.stdout.toString().trim();
        if (recognized.isNotEmpty) {
          _lastRecognized = recognized;
          _textController.add(recognized);
          _updateState(VoiceState.processing);

          // Wait briefly for command processing
          await Future.delayed(const Duration(milliseconds: 500));
          if (_state == VoiceState.processing) {
            _updateState(VoiceState.idle);
          }
        } else {
          _updateState(VoiceState.idle);
        }

        await File(scriptPath).delete();
      } catch (e) {
        debugPrint('[VoiceService] Listen error: $e');
        _updateState(VoiceState.error);
        Future.delayed(const Duration(seconds: 2), () {
          if (_state == VoiceState.error) _updateState(VoiceState.idle);
        });
      }
    }
  }

  @override
  void dispose() {
    stopSpeaking();
    _stateController.close();
    _textController.close();
  }
}
