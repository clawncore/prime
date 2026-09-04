import 'dart:async';

/// PRIME Voice - Voice Director
///
/// Segments streaming text into speakable chunks at sentence boundaries.
/// Adds prosody metadata for natural-sounding TTS.

class VoiceDirector {
  final StreamController<SpeechChunk> _chunkController =
      StreamController<SpeechChunk>.broadcast();

  String _buffer = '';
  int _chunkIndex = 0;

  // Abbreviations to skip when detecting sentence boundaries
  static const _abbreviations = {
    'mr', 'mrs', 'ms', 'dr', 'prof', 'sr', 'jr',
    'st', 'ave', 'blvd', 'etc', 'vs', 'inc', 'ltd',
    'corp', 'dept', 'est', 'approx',
  };

  Stream<SpeechChunk> get chunkStream => _chunkController.stream;

  /// Process a token from the LLM stream
  /// Returns a SpeechChunk if a sentence boundary is detected
  SpeechChunk? processToken(String token) {
    _buffer += token;

    // Check for sentence boundary
    final boundaryIndex = _findSentenceBoundary(_buffer);

    if (boundaryIndex != -1) {
      // Extract the complete sentence
      final sentence = _buffer.substring(0, boundaryIndex + 1).trim();
      _buffer = _buffer.substring(boundaryIndex + 1);

      if (sentence.isNotEmpty) {
        final chunk = _createChunk(sentence);
        _chunkController.add(chunk);
        return chunk;
      }
    }

    return null;
  }

  /// Flush remaining buffer (called when stream ends)
  SpeechChunk? flush() {
    if (_buffer.trim().isNotEmpty) {
      final chunk = _createChunk(_buffer.trim());
      _buffer = '';
      _chunkController.add(chunk);
      return chunk;
    }
    _buffer = '';
    return null;
  }

  /// Reset the director
  void reset() {
    _buffer = '';
    _chunkIndex = 0;
  }

  int _findSentenceBoundary(String text) {
    // Check from the end for sentence-ending punctuation
    for (int i = text.length - 1; i >= 0; i--) {
      final char = text[i];

      if (char == '.' || char == '!' || char == '?') {
        // Check if this is a real sentence boundary (not abbreviation or number)
        if (_isRealSentenceBoundary(text, i)) {
          return i;
        }
      }

      // Also break on newlines
      if (char == '\n') {
        return i;
      }
    }

    return -1;
  }

  bool _isRealSentenceBoundary(String text, int index) {
    // Check for abbreviations (word before the period)
    final before = text.substring(0, index);
    final lastSpace = before.lastIndexOf(' ');
    final lastWord = lastSpace >= 0
        ? before.substring(lastSpace + 1).toLowerCase()
        : before.toLowerCase();

    // Remove trailing non-alpha characters for comparison
    final cleanWord = lastWord.replaceAll(RegExp(r'[^a-z]'), '');

    if (_abbreviations.contains(cleanWord)) {
      return false;
    }

    // Check for decimal numbers (3.14)
    if (index > 0 && index < text.length - 1) {
      final beforeChar = text[index - 1];
      final afterChar = text[index + 1];
      if (RegExp(r'[0-9]').hasMatch(beforeChar) &&
          RegExp(r'[0-9]').hasMatch(afterChar)) {
        return false;
      }
    }

    // Check for "..." (ellipsis)
    if (index >= 2 && text[index - 1] == '.' && text[index - 2] == '.') {
      return false;
    }

    return true;
  }

  SpeechChunk _createChunk(String text) {
    _chunkIndex++;

    // Determine pause based on ending punctuation
    Duration pauseAfter;
    if (text.endsWith('!') || text.endsWith('?')) {
      pauseAfter = const Duration(milliseconds: 400);
    } else if (text.endsWith('...')) {
      pauseAfter = const Duration(milliseconds: 600);
    } else {
      pauseAfter = const Duration(milliseconds: 250);
    }

    // Determine energy based on content
    double energy = 0.5;
    if (text.contains('!')) energy = 0.7;
    if (text.toUpperCase() == text && text.length > 3) energy = 0.6;

    return SpeechChunk(
      text: text,
      index: _chunkIndex,
      pauseBefore: const Duration(milliseconds: 50),
      pauseAfter: pauseAfter,
      speed: 1.0,
      energy: energy,
    );
  }

  void dispose() {
    _chunkController.close();
  }
}

/// A chunk of speech to be synthesized
class SpeechChunk {
  final String text;
  final int index;
  final Duration pauseBefore;
  final Duration pauseAfter;
  final double speed;
  final double energy;

  const SpeechChunk({
    required this.text,
    required this.index,
    this.pauseBefore = Duration.zero,
    this.pauseAfter = const Duration(milliseconds: 250),
    this.speed = 1.0,
    this.energy = 0.5,
  });

  @override
  String toString() {
    final displayText = text.length > 30 ? '${text.substring(0, 30)}...' : text;
    return 'SpeechChunk(index: $index, text: "$displayText")';
  }
}
