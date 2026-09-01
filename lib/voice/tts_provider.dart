/// PRIME Voice - TTS Provider Interface
/// 
/// The voice layer decides how PRIME sounds.
/// The brain must NOT know which provider generated the audio.

abstract class TTSProvider {
  /// Convert text to speech
  Future<void> speak(String text);

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
}
