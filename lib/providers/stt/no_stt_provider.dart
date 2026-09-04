import 'dart:async';
import 'package:flutter/foundation.dart';
import 'stt_provider.dart';

/// PRIME Voice - No-op STT Provider
///
/// Used when no speech recognition is available.
/// Always returns not available, allows text input to continue.

class NoSTTProvider implements STTProvider {
  final StreamController<STTResult> _resultController =
      StreamController<STTResult>.broadcast();
  final StreamController<double> _amplitudeController =
      StreamController<double>.broadcast();

  NoSTTProvider();

  @override
  String get name => 'No STT Available';

  @override
  bool get isListening => false;

  @override
  Stream<STTResult> get resultStream => _resultController.stream;

  @override
  Stream<double> get amplitudeStream => _amplitudeController.stream;

  @override
  Future<bool> isAvailable() async => false;

  @override
  Future<void> startListening({String language = 'en-US'}) async {
    debugPrint('[NoSTT] Speech recognition not available');
    _resultController.addError(
      StateError('Speech recognition not available on this platform'),
    );
  }

  @override
  Future<void> stopListening() async {}

  @override
  Future<List<String>> getAvailableLanguages() async => [];

  @override
  Future<void> dispose() async {
    await _resultController.close();
    await _amplitudeController.close();
  }
}
