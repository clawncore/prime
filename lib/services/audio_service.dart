import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';

enum PrimeSound {
  startup,
  wakeNotification,
  wakeFromSleep,
  sleepNotification,
  analysing,
  reply,
  affirmation,
  positiveResult,
  negativeResult,
  warning,
  malfunction,
  notification,
  click,
  clickSecondary,
  zoomIn,
  zoomOut,
}

class AudioService {
  AudioService._();
  static final AudioService instance = AudioService._();

  final Map<PrimeSound, String> _soundPaths = {};
  bool _initialized = false;
  bool _muted = false;
  double _volume = 0.7;
  Process? _currentProcess;

  bool get isMuted => _muted;
  double get volume => _volume;

  Future<void> initialize() async {
    if (_initialized) return;

    _soundPaths[PrimeSound.startup] = 'assets/audio/prime/startup/start.mp3';
    _soundPaths[PrimeSound.wakeNotification] = 'assets/audio/prime/wake/wake_notification.wav';
    _soundPaths[PrimeSound.wakeFromSleep] = 'assets/audio/prime/wake/wake_from_sleep.wav';
    _soundPaths[PrimeSound.sleepNotification] = 'assets/audio/prime/power/sleep_notification.wav';
    _soundPaths[PrimeSound.analysing] = 'assets/audio/prime/processing/analysing.wav';
    _soundPaths[PrimeSound.reply] = 'assets/audio/prime/response/reply.wav';
    _soundPaths[PrimeSound.affirmation] = 'assets/audio/prime/response/affirmation.wav';
    _soundPaths[PrimeSound.positiveResult] = 'assets/audio/prime/alerts/positive_result.wav';
    _soundPaths[PrimeSound.negativeResult] = 'assets/audio/prime/alerts/negative_result.wav';
    _soundPaths[PrimeSound.warning] = 'assets/audio/prime/alerts/warning.wav';
    _soundPaths[PrimeSound.malfunction] = 'assets/audio/prime/alerts/malfunction.wav';
    _soundPaths[PrimeSound.notification] = 'assets/audio/prime/notification.wav';
    _soundPaths[PrimeSound.click] = 'assets/audio/prime/ui/click.wav';
    _soundPaths[PrimeSound.clickSecondary] = 'assets/audio/prime/ui/click_secondary.wav';
    _soundPaths[PrimeSound.zoomIn] = 'assets/audio/prime/ui/zoom_in.wav';
    _soundPaths[PrimeSound.zoomOut] = 'assets/audio/prime/ui/zoom_out.wav';

    _initialized = true;
    debugPrint('[AudioService] Initialized with ${_soundPaths.length} sounds');
  }

  Future<void> play(PrimeSound sound) async {
    if (_muted || !_initialized) return;
    final assetPath = _soundPaths[sound];
    if (assetPath == null) {
      debugPrint('[AudioService] Unknown sound: $sound');
      return;
    }

    try {
      await _stopCurrent();

      if (Platform.isLinux) {
        await _playLinux(assetPath);
      } else if (Platform.isWindows) {
        await _playWindows(assetPath);
      } else {
        await _playFallback(assetPath);
      }
    } catch (e) {
      debugPrint('[AudioService] Error playing $sound: $e');
    }
  }

  Future<void> _playLinux(String assetPath) async {
    final tempDir = await getTemporaryDirectory();
    final fileName = assetPath.split('/').last;
    final isMp3 = fileName.endsWith('.mp3');
    final baseName = fileName.replaceAll(RegExp(r'\.(mp3|wav)$'), '');
    final wavFile = File('${tempDir.path}${Platform.pathSeparator}${baseName}.wav');

    final data = await rootBundle.load(assetPath);
    final bytes = data.buffer.asUint8List();

    if (isMp3) {
      final mp3File = File('${tempDir.path}${Platform.pathSeparator}$fileName');
      await mp3File.writeAsBytes(bytes);
      await Process.run('ffmpeg', [
        '-i', mp3File.path,
        '-ar', '44100',
        '-ac', '2',
        '-y',
        wavFile.path,
      ]);
      try { await mp3File.delete(); } catch (e) {}
    } else {
      await wavFile.writeAsBytes(bytes);
    }

    _currentProcess = await Process.start('paplay', [wavFile.path]);
    _currentProcess?.exitCode.then((_) async {
      try { await wavFile.delete(); } catch (e) {}
    });
  }

  Future<void> _playWindows(String assetPath) async {
    final tempDir = await getTemporaryDirectory();
    final fileName = assetPath.split('/').last;
    final tempFile = File('${tempDir.path}${Platform.pathSeparator}$fileName');

    final data = await rootBundle.load(assetPath);
    final bytes = data.buffer.asUint8List();
    await tempFile.writeAsBytes(bytes);

    _currentProcess = await Process.start('powershell.exe', [
      '-NoProfile',
      '-Command',
      '(New-Object Media.SoundPlayer "${tempFile.path}").PlaySync()'
    ]);

    _currentProcess?.exitCode.then((_) async {
      try {
        await tempFile.delete();
      } catch (e) {}
    });
  }

  Future<void> _playFallback(String assetPath) async {
    final tempDir = await getTemporaryDirectory();
    final fileName = assetPath.split('/').last;
    final tempFile = File('${tempDir.path}${Platform.pathSeparator}$fileName');

    final data = await rootBundle.load(assetPath);
    final bytes = data.buffer.asUint8List();
    await tempFile.writeAsBytes(bytes);

    debugPrint('[AudioService] No audio player for ${Platform.operatingSystem}, saved to ${tempFile.path}');
  }

  Future<void> _stopCurrent() async {
    if (_currentProcess != null) {
      try {
        _currentProcess!.kill();
      } catch (e) {}
      _currentProcess = null;
    }
  }

  void playClick() => play(PrimeSound.click);
  void playClickSecondary() => play(PrimeSound.clickSecondary);
  void playStartup() => play(PrimeSound.startup);
  void playWake() => play(PrimeSound.wakeNotification);
  void playWakeFromSleep() => play(PrimeSound.wakeFromSleep);
  void playSleep() => play(PrimeSound.sleepNotification);
  void playAnalysing() => play(PrimeSound.analysing);
  void playReply() => play(PrimeSound.reply);
  void playAffirmation() => play(PrimeSound.affirmation);
  void playPositive() => play(PrimeSound.positiveResult);
  void playNegative() => play(PrimeSound.negativeResult);
  void playWarning() => play(PrimeSound.warning);
  void playMalfunction() => play(PrimeSound.malfunction);
  void playNotification() => play(PrimeSound.notification);
  void playZoomIn() => play(PrimeSound.zoomIn);
  void playZoomOut() => play(PrimeSound.zoomOut);

  void toggleMute() {
    _muted = !_muted;
    if (_muted) {
      _stopCurrent();
    }
    debugPrint('[AudioService] Muted: $_muted');
  }

  void setVolume(double vol) {
    _volume = vol.clamp(0.0, 1.0);
  }

  void dispose() {
    _stopCurrent();
  }
}
