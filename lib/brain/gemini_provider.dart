import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'llm_provider.dart';

/// PRIME Brain - Gemini LLM Provider
/// 
/// Uses Google Gemini API for conversational intelligence.
/// This is the first real brain implementation.

class GeminiProvider implements LLMProvider {
  final String apiKey;
  final String model;
  final String _baseUrl = 'https://generativelanguage.googleapis.com/v1';

  GeminiProvider({
    required this.apiKey,
    this.model = 'gemini-3.6-flash',
  });

  @override
  String get name => 'Gemini ($model)';

  @override
  Future<bool> isAvailable() async {
    if (apiKey.isEmpty) return false;
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/models?key=$apiKey'),
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  @override
  Future<LLMResponse> generate({
    required String userMessage,
    required List<ConversationTurn> context,
    String? systemPrompt,
  }) async {
    try {
      final messages = _buildMessages(userMessage, context, systemPrompt);

      final response = await http.post(
        Uri.parse('$_baseUrl/models/$model:generateContent?key=$apiKey'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'contents': messages,
          'generationConfig': {
            'temperature': 0.7,
            'maxOutputTokens': 256,
            'topP': 0.9,
          },
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final candidates = data['candidates'] as List?;
        if (candidates != null && candidates.isNotEmpty) {
          final content = candidates[0]['content'];
          final parts = content['parts'] as List;
          if (parts.isNotEmpty) {
            final text = parts[0]['text'] as String;
            return LLMResponse(
              text: _cleanResponse(text),
              type: ResponseType.conversation,
            );
          }
        }
      }

      debugPrint('[Gemini] API error: ${response.statusCode}');
      return const LLMResponse(
        text: 'I encountered an error processing your request.',
        type: ResponseType.error,
      );
    } catch (e) {
      debugPrint('[Gemini] Request failed: $e');
      return const LLMResponse(
        text: 'I am having trouble connecting to my brain. Please try again.',
        type: ResponseType.error,
      );
    }
  }

  List<Map<String, dynamic>> _buildMessages(
    String userMessage,
    List<ConversationTurn> context,
    String? systemPrompt,
  ) {
    final messages = <Map<String, dynamic>>[];

    // System prompt
    final prompt = systemPrompt ?? _defaultSystemPrompt;
    messages.add({
      'role': 'user',
      'parts': [{'text': prompt}],
    });
    messages.add({
      'role': 'model',
      'parts': [{'text': 'Understood. I am PRIME.'}],
    });

    // Conversation context (last 10 turns)
    final recentContext = context.length > 10
        ? context.sublist(context.length - 10)
        : context;

    for (final turn in recentContext) {
      messages.add({
        'role': turn.role == 'user' ? 'user' : 'model',
        'parts': [{'text': turn.content}],
      });
    }

    // Current user message
    messages.add({
      'role': 'user',
      'parts': [{'text': userMessage}],
    });

    return messages;
  }

  String _cleanResponse(String text) {
    // Remove markdown formatting that doesn't work in speech
    return text
        .replaceAll(RegExp(r'\*+'), '')
        .replaceAll(RegExp(r'#+\s*'), '')
        .replaceAll('```', '')
        .trim();
  }

  static const String _defaultSystemPrompt = '''
You are PRIME, the user's personal AI computer assistant.

Speak naturally and conversationally.

Be calm, intelligent, confident, concise, and technically capable.

Do not sound like a customer-service bot.

Do not begin every response with "Certainly", "Absolutely",
"Of course", or similar filler.

Do not unnecessarily repeat the user's question.

Adapt response length to the situation.

For simple questions, answer briefly.

For complex questions, provide enough explanation to be useful.

Maintain current conversational context.

If the user changes direction, follow naturally.

If the user interrupts you, stop and listen.

If clarification is genuinely necessary, ask briefly.

Never claim an action was completed unless PRIME actually
performed it successfully.

Never fabricate files, system state, tool results, permissions,
or external information.

Do not expose hidden chain-of-thought.

You are PRIME, not a narrator describing your internal reasoning.
''';
}
