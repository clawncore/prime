import 'dart:async';

/// PRIME Voice - Speech-to-Text Provider Interface
///
/// Abstracts speech recognition to allow multiple implementations.
/// Each platform can provide its own STT backend.

abstract class STTProvider {
  /// Check if the provider is available on this platform
  Future<bool> isAvailable();

  /// Get provider name for diagnostics
  String get name;

  /// Stream of transcription results
  /// Partial results have isFinal=false, final results have isFinal=true
  Stream<STTResult> get resultStream;

  /// Stream of amplitude levels (0.0 to 1.0) for UI reactivity
  Stream<double> get amplitudeStream;

  /// Start listening for speech
  Future<void> startListening({String language = 'en-US'});

  /// Stop listening
  Future<void> stopListening();

  /// Check if currently listening
  bool get isListening;

  /// Get available languages
  Future<List<String>> getAvailableLanguages();

  /// Clean up resources
  Future<void> dispose();
}

/// Result from speech recognition
class STTResult {
  final String text;
  final bool isFinal;
  final double confidence;
  final DateTime timestamp;

  STTResult({
    required this.text,
    required this.isFinal,
    this.confidence = 0.0,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  @override
  String toString() =>
      'STTResult(text: "$text", isFinal: $isFinal, confidence: $confidence)';
}
