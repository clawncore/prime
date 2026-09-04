import 'dart:async';
import 'package:flutter/foundation.dart';
import 'audio_service.dart';

/// PRIME Services - Audio Mixer
///
/// Priority-based audio mixing with ducking support.
/// Ensures important sounds aren't masked by background audio.

enum AudioPriority {
  systemAlert(4),    // Highest - critical system alerts
  userVoice(3),      // User speaking (for interruption)
  primeSpeech(2),    // PRIME speaking
  uiSound(1);        // Lowest - UI feedback sounds

  final int value;
  const AudioPriority(this.value);
}

enum AudioDuckingState {
  none,
  ducked,     // Volume reduced
  muted,      // Volume at minimum
}

enum SoundEffect {
  click,
  reply,
  warning,
  error,
  success,
  activate,
  deactivate,
}

class AudioMixer {
  AudioDuckingState _duckingState = AudioDuckingState.none;
  AudioPriority? _currentPriority;
  Timer? _duckingTimer;

  final StreamController<AudioDuckingState> _duckingController =
      StreamController<AudioDuckingState>.broadcast();

  AudioDuckingState get duckingState => _duckingState;
  AudioPriority? get currentPriority => _currentPriority;

  Stream<AudioDuckingState> get duckingStream => _duckingController.stream;

  /// Play a sound with priority handling
  Future<void> playWithPriority(AudioPriority priority, SoundEffect sound) async {
    // Duck lower priority sounds
    _applyDucking(priority);

    // Play the sound
    final audio = AudioService.instance;
    switch (sound) {
      case SoundEffect.click:
        audio.playClick();
        break;
      case SoundEffect.reply:
        audio.playReply();
        break;
      case SoundEffect.warning:
        audio.playWarning();
        break;
      case SoundEffect.error:
        audio.playMalfunction();
        break;
      case SoundEffect.success:
        audio.playNotification();
        break;
      case SoundEffect.activate:
        audio.playPositive();
        break;
      case SoundEffect.deactivate:
        audio.playNegative();
        break;
    }

    // Release ducking after estimated duration
    _releaseDuckingAfterDelay();
  }

  /// Duck audio when higher priority sound plays
  void _applyDucking(AudioPriority newPriority) {
    if (_currentPriority != null && newPriority.value <= _currentPriority!.value) {
      return; // Already playing something equal or higher priority
    }

    _currentPriority = newPriority;

    if (newPriority == AudioPriority.systemAlert) {
      _setDuckingState(AudioDuckingState.muted);
    } else if (newPriority == AudioPriority.userVoice ||
        newPriority == AudioPriority.primeSpeech) {
      _setDuckingState(AudioDuckingState.ducked);
    }
  }

  /// Release ducking state
  void _releaseDucking() {
    _currentPriority = null;
    _setDuckingState(AudioDuckingState.none);
  }

  void _releaseDuckingAfterDelay() {
    _duckingTimer?.cancel();

    // Release ducking after a short delay
    _duckingTimer = Timer(const Duration(milliseconds: 500), () {
      _releaseDucking();
    });
  }

  void _setDuckingState(AudioDuckingState state) {
    if (_duckingState != state) {
      _duckingState = state;
      _duckingController.add(state);
      debugPrint('[AudioMixer] Ducking state: $state');
    }
  }

  /// Force release all ducking
  void forceRelease() {
    _duckingTimer?.cancel();
    _releaseDucking();
  }

  void dispose() {
    _duckingTimer?.cancel();
    _duckingController.close();
  }
}
