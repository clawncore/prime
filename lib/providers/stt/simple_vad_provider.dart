import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'vad_provider.dart';

/// PRIME Voice - Simple Voice Activity Detection
///
/// Basic amplitude-based VAD for detecting speech activity.
/// Good enough for initial implementation; can be replaced with
/// a more sophisticated provider later.

class SimpleVADProvider implements VADProvider {
  Stream<List<int>>? _audioStream;
  StreamSubscription? _audioSubscription;

  final StreamController<VADEvent> _eventController =
      StreamController<VADEvent>.broadcast();

  double _speechThreshold = 0.1;
  Duration _silenceDuration = const Duration(milliseconds: 1500);
  Duration _minimumSpeechDuration = const Duration(milliseconds: 300);

  bool _isSpeaking = false;
  bool _isProcessing = false;
  double _currentAmplitude = 0.0;
  DateTime? _speechStartTime;
  DateTime? _silenceStartTime;

  SimpleVADProvider();

  @override
  String get name => 'Simple Amplitude VAD';

  @override
  double get currentAmplitude => _currentAmplitude;

  @override
  Stream<VADEvent> get eventStream => _eventController.stream;

  @override
  set speechThreshold(double threshold) {
    _speechThreshold = threshold.clamp(0.0, 1.0);
  }

  @override
  set silenceDuration(Duration duration) {
    _silenceDuration = duration;
  }

  @override
  set minimumSpeechDuration(Duration duration) {
    _minimumSpeechDuration = duration;
  }

  @override
  Future<bool> isAvailable() async => true;

  @override
  Future<void> start(Stream<List<int>> audioStream) async {
    if (_isProcessing) return;

    _audioStream = audioStream;
    _isProcessing = true;

    _audioSubscription = audioStream.listen(
      (data) {
        _processAudioData(data);
      },
      onError: (error) {
        debugPrint('[VAD] Audio stream error: $error');
      },
      onDone: () {
        _isProcessing = false;
        _eventController.add(VADEvent.streamEnd);
      },
    );

    _eventController.add(VADEvent.streamStart);
    debugPrint('[VAD] Started processing');
  }

  void _processAudioData(List<int> data) {
    // Calculate RMS amplitude from PCM 16-bit samples
    if (data.isEmpty) return;

    double sumSquares = 0;
    final sampleCount = data.length ~/ 2; // 16-bit = 2 bytes per sample

    for (int i = 0; i < data.length - 1; i += 2) {
      // Convert to 16-bit signed integer
      final sample = (data[i] | (data[i + 1] << 8));
      final normalized = sample / 32768.0;
      sumSquares += normalized * normalized;
    }

    final rms = math.sqrt(sumSquares / sampleCount);
    _currentAmplitude = rms.clamp(0.0, 1.0);

    final now = DateTime.now();

    if (!_isSpeaking) {
      // Check for speech start
      if (_currentAmplitude > _speechThreshold) {
        _speechStartTime ??= now;
        final speechDuration = now.difference(_speechStartTime!);

        if (speechDuration >= _minimumSpeechDuration) {
          _isSpeaking = true;
          _silenceStartTime = null;
          _eventController.add(VADEvent.speechStart);
          debugPrint('[VAD] Speech started (amplitude: ${_currentAmplitude.toStringAsFixed(3)})');
        }
      } else {
        _speechStartTime = null;
      }
    } else {
      // Check for speech end
      if (_currentAmplitude < _speechThreshold) {
        _silenceStartTime ??= now;
        final silenceDuration = now.difference(_silenceStartTime!);

        if (silenceDuration >= _silenceDuration) {
          _isSpeaking = false;
          _speechStartTime = null;
          _silenceStartTime = null;
          _eventController.add(VADEvent.speechEnd);
          debugPrint('[VAD] Speech ended');
        }
      } else {
        _silenceStartTime = null;
      }
    }
  }

  @override
  Future<void> stop() async {
    _isProcessing = false;
    await _audioSubscription?.cancel();
    _audioSubscription = null;
    _isSpeaking = false;
    _speechStartTime = null;
    _silenceStartTime = null;
    _eventController.add(VADEvent.streamEnd);
    debugPrint('[VAD] Stopped');
  }

  @override
  Future<void> dispose() async {
    await stop();
    await _eventController.close();
  }
}
