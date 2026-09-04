import 'dart:async';
import 'package:flutter/foundation.dart';
import 'tts_provider.dart';
import 'voice_director.dart';

/// PRIME Voice - Audio Queue
///
/// Manages sequential TTS playback with proper queuing,
/// cancellation, and amplitude monitoring for UI reactivity.

enum AudioQueueState {
  idle,
  playing,
  paused,
  clearing,
}

class AudioQueue {
  TTSProvider? _ttsProvider;
  final List<SpeechChunk> _queue = [];
  final StreamController<AudioQueueState> _stateController =
      StreamController<AudioQueueState>.broadcast();
  final StreamController<double> _amplitudeController =
      StreamController<double>.broadcast();

  AudioQueueState _state = AudioQueueState.idle;
  bool _isProcessing = false;
  bool _isPaused = false;

  AudioQueue();

  AudioQueueState get state => _state;
  bool get isPlaying => _state == AudioQueueState.playing;
  bool get isIdle => _state == AudioQueueState.idle;
  int get queueLength => _queue.length;

  Stream<AudioQueueState> get stateStream => _stateController.stream;
  Stream<double> get amplitudeStream => _amplitudeController.stream;

  /// Set or change the TTS provider
  set ttsProvider(TTSProvider? provider) {
    _ttsProvider = provider;
  }

  /// Add a chunk to the queue
  Future<void> enqueue(SpeechChunk chunk) async {
    _queue.add(chunk);
    debugPrint('[AudioQueue] Enqueued chunk ${chunk.index}: "${chunk.text.substring(0, chunk.text.length.clamp(0, 30))}..."');

    if (!_isProcessing && !_isPaused) {
      _processQueue();
    }
  }

  /// Add multiple chunks at once
  Future<void> enqueueAll(List<SpeechChunk> chunks) async {
    for (final chunk in chunks) {
      _queue.add(chunk);
    }
    debugPrint('[AudioQueue] Enqueued ${chunks.length} chunks');

    if (!_isProcessing && !_isPaused) {
      _processQueue();
    }
  }

  /// Process the queue sequentially
  Future<void> _processQueue() async {
    if (_isProcessing) return;

    _isProcessing = true;
    _setState(AudioQueueState.playing);

    while (_queue.isNotEmpty && !_isPaused) {
      final chunk = _queue.removeAt(0);

      if (_ttsProvider == null) {
        debugPrint('[AudioQueue] No TTS provider, skipping');
        continue;
      }

      try {
        // Emit amplitude for UI (pulsing while speaking)
        _emitSpeakingAmplitude();

        // Synthesize and play
        await _ttsProvider!.speak(chunk.text);

        // Wait for the pause after this chunk
        if (chunk.pauseAfter.inMilliseconds > 0) {
          await Future.delayed(chunk.pauseAfter);
        }
      } catch (e) {
        debugPrint('[AudioQueue] Error playing chunk: $e');
      }
    }

    _isProcessing = false;
    _setState(_isPaused ? AudioQueueState.paused : AudioQueueState.idle);
  }

  void _emitSpeakingAmplitude() async {
    // Emit a pulsing amplitude while speaking
    while (_isProcessing && !_isPaused) {
      await Future.delayed(const Duration(milliseconds: 50));
      if (_isProcessing && !_isPaused) {
        // Simulated speaking amplitude (can be replaced with real output amplitude)
        _amplitudeController.add(0.3 + (DateTime.now().millisecond % 100) / 200);
      }
    }
  }

  /// Pause queue processing
  void pause() {
    if (_state == AudioQueueState.playing) {
      _isPaused = true;
      _setState(AudioQueueState.paused);
      debugPrint('[AudioQueue] Paused');
    }
  }

  /// Resume queue processing
  void resume() {
    if (_state == AudioQueueState.paused) {
      _isPaused = false;
      _setState(AudioQueueState.idle);
      _processQueue();
      debugPrint('[AudioQueue] Resumed');
    }
  }

  /// Clear the queue and stop current playback
  Future<void> clear() async {
    _queue.clear();
    _isPaused = false;
    _setState(AudioQueueState.clearing);

    try {
      await _ttsProvider?.stop();
    } catch (e) {
      debugPrint('[AudioQueue] Error stopping TTS: $e');
    }

    _isProcessing = false;
    _setState(AudioQueueState.idle);
    debugPrint('[AudioQueue] Cleared');
  }

  /// Skip to next chunk in queue
  Future<void> skip() async {
    if (_queue.isNotEmpty) {
      _queue.removeAt(0);
      debugPrint('[AudioQueue] Skipped to next');
    }
  }

  void _setState(AudioQueueState newState) {
    if (_state != newState) {
      _state = newState;
      _stateController.add(newState);
    }
  }

  /// Dispose resources
  Future<void> dispose() async {
    await clear();
    await _stateController.close();
    await _amplitudeController.close();
  }
}
