import 'dart:math';
import 'package:flutter/foundation.dart';
import 'llm_provider.dart';

/// PRIME Brain - Conversation Manager
/// 
/// Manages conversation context, memory, and token usage.
/// Prevents sending entire conversation history to the LLM.

class ConversationManager {
  final List<ConversationTurn> _turns = [];
  final int _maxRecentTurns;
  String _summary = '';
  int _totalTokensEstimate = 0;

  ConversationManager({
    int maxRecentTurns = 10,
  }) : _maxRecentTurns = maxRecentTurns;

  /// Add a user message
  void addUserMessage(String message) {
    _turns.add(ConversationTurn(
      role: 'user',
      content: message,
      timestamp: DateTime.now(),
    ));
    _estimateTokens(message);
    _trimOldTurns();
  }

  /// Add an assistant response
  void addAssistantMessage(String message) {
    _turns.add(ConversationTurn(
      role: 'assistant',
      content: message,
      timestamp: DateTime.now(),
    ));
    _estimateTokens(message);
    _trimOldTurns();
  }

  /// Get context for the LLM (recent turns only)
  List<ConversationTurn> getContext() {
    if (_turns.length <= _maxRecentTurns) {
      return List.from(_turns);
    }
    return _turns.sublist(_turns.length - _maxRecentTurns);
  }

  /// Get full context including summary
  Map<String, dynamic> getFullContext() {
    return {
      'summary': _summary,
      'recentTurns': getContext(),
      'totalTurns': _turns.length,
      'estimatedTokens': _totalTokensEstimate,
    };
  }

  /// Generate a compact summary of older conversation
  Future<void> generateSummary(String Function(List<ConversationTurn>) summarizer) {
    if (_turns.length > _maxRecentTurns * 2) {
      final oldTurns = _turns.sublist(0, _turns.length - _maxRecentTurns);
      _summary = summarizer(oldTurns);
    }
    return Future.value();
  }

  /// Clear conversation
  void clear() {
    _turns.clear();
    _summary = '';
    _totalTokensEstimate = 0;
  }

  /// Get turn count
  int get turnCount => _turns.length;

  /// Get estimated token usage
  int get estimatedTokens => _totalTokensEstimate;

  void _trimOldTurns() {
    // Keep more turns in memory, but only send recent to LLM
    if (_turns.length > _maxRecentTurns * 3) {
      final removed = _turns.sublist(0, _turns.length - _maxRecentTurns * 2);
      // Update summary with removed turns
      if (_summary.isEmpty) {
        _summary = removed.map((t) => '${t.role}: ${t.content}').join('\n');
      }
      _turns.removeRange(0, removed.length);
    }
  }

  void _estimateTokens(String text) {
    // Rough estimate: 1 token per 4 characters
    _totalTokensEstimate += (text.length / 4).ceil();
  }
}
