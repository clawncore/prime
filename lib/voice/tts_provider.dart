/// PRIME Voice - TTS Provider Interface
///
/// The voice layer decides how PRIME sounds.
/// The brain must NOT know which provider generated the audio.

abstract class TTSProvider {
  /// Convert text to speech and play immediately
  Future<void> speak(String text);

  /// Convert text to audio bytes (for queueing)
  /// Returns null if not supported
  Future<List<int>?> synthesizeToBytes(String text) async => null;

  /// Play audio bytes directly
  Future<void> playBytes(List<int> audioBytes) async {}

  /// Stop current speech
  Future<void> stop();

  /// Check if provider is available
  Future<bool> isAvailable();

  /// Get provider name for diagnostics
  String get name;

  /// Voice properties (provider-dependent)
  Future<List<String>> getAvailableVoices();
  Future<void> setVoice(String voiceName);
  Future<void> setRate(double rate); // 0.0 to 2.0
  Future<void> setVolume(double volume); // 0.0 to 1.0

  /// Current state
  bool get isSpeaking;

  /// Stream of amplitude levels (0.0 to 1.0) for UI reactivity
  Stream<double> get amplitudeStream async* {
    // Default: no amplitude data available
    yield 0.0;
  }

  /// Clean up resources
  Future<void> dispose() async {}
}
