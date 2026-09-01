import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

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

  final AudioPlayer _bgPlayer = AudioPlayer();
  final AudioPlayer _sfxPlayer = AudioPlayer();
  final Map<PrimeSound, String> _soundPaths = {};

  bool _initialized = false;
  bool _muted = false;
  double _volume = 0.7;

  bool get isMuted => _muted;
  double get volume => _volume;

  Future<void> initialize() async {
    if (_initialized) return;

    _soundPaths[PrimeSound.startup] = 'audio/prime/startup/start.mp3';
    _soundPaths[PrimeSound.wakeNotification] =
        'audio/prime/wake/wake_notification.wav';
    _soundPaths[PrimeSound.wakeFromSleep] =
        'audio/prime/wake/wake_from_sleep.wav';
    _soundPaths[PrimeSound.sleepNotification] =
        'audio/prime/power/sleep_notification.wav';
    _soundPaths[PrimeSound.analysing] = 'audio/prime/processing/analysing.wav';
    _soundPaths[PrimeSound.reply] = 'audio/prime/response/reply.wav';
    _soundPaths[PrimeSound.affirmation] =
        'audio/prime/response/affirmation.wav';
    _soundPaths[PrimeSound.positiveResult] =
        'audio/prime/alerts/positive_result.wav';
    _soundPaths[PrimeSound.negativeResult] =
        'audio/prime/alerts/negative_result.wav';
    _soundPaths[PrimeSound.warning] = 'audio/prime/alerts/warning.wav';
    _soundPaths[PrimeSound.malfunction] = 'audio/prime/alerts/malfunction.wav';
    _soundPaths[PrimeSound.notification] = 'audio/prime/notification.wav';
    _soundPaths[PrimeSound.click] = 'audio/prime/ui/click.wav';
    _soundPaths[PrimeSound.clickSecondary] =
        'audio/prime/ui/click_secondary.wav';
    _soundPaths[PrimeSound.zoomIn] = 'audio/prime/ui/zoom_in.wav';
    _soundPaths[PrimeSound.zoomOut] = 'audio/prime/ui/zoom_out.wav';

    _sfxPlayer.setVolume(_volume);
    _initialized = true;
    debugPrint('[AudioService] Initialized with ${_soundPaths.length} sounds');
  }

  Future<void> play(PrimeSound sound) async {
    if (_muted || !_initialized) return;
    final path = _soundPaths[sound];
    if (path == null) {
      debugPrint('[AudioService] Unknown sound: $sound');
      return;
    }
    try {
      await _sfxPlayer.stop();
      await _sfxPlayer.play(AssetSource(path), volume: _volume);
    } catch (e) {
      debugPrint('[AudioService] Error playing $sound: $e');
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
      _sfxPlayer.stop();
    }
    debugPrint('[AudioService] Muted: $_muted');
  }

  void setVolume(double vol) {
    _volume = vol.clamp(0.0, 1.0);
    _sfxPlayer.setVolume(_volume);
  }

  void dispose() {
    _bgPlayer.dispose();
    _sfxPlayer.dispose();
  }
}
