/// PRIME Brain - LLM Provider Interface
/// 
/// The brain layer decides what PRIME should say.
/// It must NOT directly control audio, visuals, or system commands.

abstract class LLMProvider {
  /// Generate a response from the LLM
  Future<LLMResponse> generate({
    required String userMessage,
    required List<ConversationTurn> context,
    String? systemPrompt,
  });

  /// Check if the provider is available
  Future<bool> isAvailable();

  /// Get provider name for diagnostics
  String get name;
}

/// A single turn in the conversation
class ConversationTurn {
  final String role; // 'user' or 'assistant'
  final String content;
  final DateTime timestamp;

  const ConversationTurn({
    required this.role,
    required this.content,
    required this.timestamp,
  });

  Map<String, dynamic> toMap() => {
    'role': role,
    'content': content,
  };
}

/// Response from the LLM
class LLMResponse {
  final String text;
  final ResponseType type;
  final bool shouldSpeak;

  const LLMResponse({
    required this.text,
    this.type = ResponseType.conversation,
    this.shouldSpeak = true,
  });
}

/// Classification of response type for the audio engine
enum ResponseType {
  conversation,
  commandConfirmation,
  error,
  clarification,
}
