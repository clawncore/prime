import 'dart:async';

/// PRIME Voice - Voice Activity Detection Interface
///
/// Detects when speech starts and ends in an audio stream.
/// Used for automatic listening control and interruption detection.

abstract class VADProvider {
  /// Check if VAD is available
  Future<bool> isAvailable();

  /// Get provider name
  String get name;

  /// Start processing audio stream for voice activity
  /// [audioStream] should provide raw audio samples (PCM 16-bit, mono)
  Future<void> start(Stream<List<int>> audioStream);

  /// Stop processing
  Future<void> stop();

  /// Stream of VAD events
  Stream<VADEvent> get eventStream;

  /// Current speech amplitude (0.0 to 1.0)
  double get currentAmplitude;

  /// Configuration
  set speechThreshold(double threshold); // 0.0 to 1.0
  set silenceDuration(Duration duration);
  set minimumSpeechDuration(Duration duration);

  /// Clean up resources
  Future<void> dispose();
}

/// Voice activity events
enum VADEvent {
  /// Speech started above threshold
  speechStart,

  /// Speech ended (silence detected)
  speechEnd,

  /// Continuous silence
  silence,

  /// Audio stream started
  streamStart,

  /// Audio stream ended
  streamEnd,
}

/// Configuration for VAD
class VADConfig {
  final double speechThreshold;
  final Duration silenceDuration;
  final Duration minimumSpeechDuration;

  const VADConfig({
    this.speechThreshold = 0.1,
    this.silenceDuration = const Duration(milliseconds: 1500),
    this.minimumSpeechDuration = const Duration(milliseconds: 300),
  });

  static const defaultConfig = VADConfig();
}
