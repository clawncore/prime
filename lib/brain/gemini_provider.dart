import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../config/prime_identity.dart';
import 'llm_provider.dart';

/// PRIME Brain - Gemini LLM Provider
///
/// Uses Google Gemini API for conversational intelligence.
/// Supports both streaming and non-streaming generation.

class GeminiProvider implements LLMProvider {
  final String apiKey;
  final String model;
  final String _baseUrl = 'https://generativelanguage.googleapis.com/v1';

  /// HTTP client with connection pooling
  final http.Client _client = http.Client();

  GeminiProvider({
    required this.apiKey,
    this.model = 'gemini-3.6-flash',
  });

  @override
  String get name => 'Gemini ($model)';

  @override
  bool get supportsStreaming => true;

  /// Non-streaming generation with timeout and performance tracking
  @override
  Future<LLMResponse> generate({
    required String userMessage,
    required List<ConversationTurn> context,
    String? systemPrompt,
  }) async {
    final reqId = _shortId();
    final sw = Stopwatch()..start();

    try {
      final messages = _buildMessages(userMessage, context, systemPrompt);

      debugPrint('[Gemini][$reqId] REQUEST START — '
          'model=$model, messages=${messages.length}');

      final response = await _client
          .post(
            Uri.parse('$_baseUrl/models/$model:generateContent?key=$apiKey'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'contents': messages,
              'generationConfig': {
                'temperature': 0.7,
                'maxOutputTokens': 4096,
                'topP': 0.9,
              },
            }),
          )
          .timeout(const Duration(seconds: 60));

      sw.stop();
      debugPrint('[Gemini][$reqId] RESPONSE — '
          'status=${response.statusCode}, '
          'time=${sw.elapsedMilliseconds}ms, '
          'body=${response.body.length} bytes');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final candidates = data['candidates'] as List?;
        if (candidates != null && candidates.isNotEmpty) {
          final content = candidates[0]['content'];
          final parts = content['parts'] as List;
          if (parts.isNotEmpty) {
            final text = parts[0]['text'] as String;
            final cleaned = _cleanResponse(text);
            debugPrint('[Gemini][$reqId] GENERATED — '
                'chars=${cleaned.length}, '
                'words=${cleaned.split(' ').length}');
            return LLMResponse(
              text: cleaned,
              type: ResponseType.conversation,
            );
          }
        }
      }

      debugPrint('[Gemini][$reqId] API ERROR — status=${response.statusCode}, '
          'body=${response.body.substring(0, response.body.length > 500 ? 500 : response.body.length)}');
      return LLMResponse(
        text: 'API error (${response.statusCode}): ${response.body.substring(0, response.body.length > 200 ? 200 : response.body.length)}',
        type: ResponseType.error,
      );
    } on TimeoutException {
      sw.stop();
      debugPrint('[Gemini][$reqId] TIMEOUT after ${sw.elapsedMilliseconds}ms');
      return const LLMResponse(
        text: 'The request timed out. Please try again.',
        type: ResponseType.error,
      );
    } catch (e) {
      sw.stop();
      debugPrint('[Gemini][$reqId] FAILED after ${sw.elapsedMilliseconds}ms: $e');
      return const LLMResponse(
        text: 'I am having trouble connecting to my brain. Please try again.',
        type: ResponseType.error,
      );
    }
  }

  /// Streaming generation — yields tokens as they arrive
  @override
  Stream<LLMStreamChunk> streamGenerate({
    required String userMessage,
    required List<ConversationTurn> context,
    String? systemPrompt,
  }) async* {
    final reqId = _shortId();
    final sw = Stopwatch()..start();
    final messages = _buildMessages(userMessage, context, systemPrompt);

    debugPrint('[Gemini][$reqId] STREAM START — '
        'model=$model, messages=${messages.length}');

    try {
      final request = http.Request(
        'POST',
        Uri.parse('$_baseUrl/models/$model:streamGenerateContent?alt=sse&key=$apiKey'),
      );
      request.headers['Content-Type'] = 'application/json';
      request.body = jsonEncode({
        'contents': messages,
        'generationConfig': {
          'temperature': 0.7,
          'maxOutputTokens': 4096,
          'topP': 0.9,
        },
      });

      final streamedResponse = await _client.send(request).timeout(
        const Duration(seconds: 60),
      );

      if (streamedResponse.statusCode != 200) {
        sw.stop();
        debugPrint('[Gemini][$reqId] STREAM ERROR — status=${streamedResponse.statusCode}');
        yield const LLMStreamChunk(
          text: 'Error: Unable to connect to Gemini',
          isComplete: true,
          type: ResponseType.error,
        );
        return;
      }

      debugPrint('[Gemini][$reqId] STREAM CONNECTED — ${sw.elapsedMilliseconds}ms');

      String buffer = '';
      int chunkCount = 0;
      int totalChars = 0;
      bool firstToken = false;

      await for (final chunk in streamedResponse.stream.transform(utf8.decoder)) {
        buffer += chunk;

        final lines = buffer.split('\n');
        buffer = lines.removeLast();

        for (final line in lines) {
          if (line.startsWith('data: ')) {
            final jsonStr = line.substring(6).trim();
            if (jsonStr.isEmpty) continue;

            try {
              final data = jsonDecode(jsonStr);
              final candidates = data['candidates'] as List?;
              if (candidates != null && candidates.isNotEmpty) {
                final content = candidates[0]['content'];
                if (content != null) {
                  final parts = content['parts'] as List;
                  if (parts.isNotEmpty) {
                    final text = parts[0]['text'] as String;
                    final cleaned = _cleanResponse(text);

                    if (!firstToken) {
                      firstToken = true;
                      debugPrint('[Gemini][$reqId] FIRST TOKEN — '
                          '${sw.elapsedMilliseconds}ms');
                    }

                    chunkCount++;
                    totalChars += cleaned.length;

                    yield LLMStreamChunk(
                      text: cleaned,
                      isComplete: false,
                    );
                  }
                }
              }

              final finishReason = candidates?[0]['finishReason'];
              if (finishReason == 'STOP') {
                sw.stop();
                debugPrint('[Gemini][$reqId] STREAM COMPLETE — '
                    'chunks=$chunkCount, chars=$totalChars, '
                    'time=${sw.elapsedMilliseconds}ms');
                yield const LLMStreamChunk(
                  text: '',
                  isComplete: true,
                );
                return;
              }
            } catch (e) {
              // Skip malformed JSON
            }
          }
        }
      }

      sw.stop();
      debugPrint('[Gemini][$reqId] STREAM END — '
          'chunks=$chunkCount, chars=$totalChars, '
          'time=${sw.elapsedMilliseconds}ms');
      yield const LLMStreamChunk(
        text: '',
        isComplete: true,
      );
    } on TimeoutException {
      sw.stop();
      debugPrint('[Gemini][$reqId] STREAM TIMEOUT — ${sw.elapsedMilliseconds}ms');
      yield LLMStreamChunk(
        text: '',
        isComplete: true,
        type: ResponseType.error,
      );
    } catch (e) {
      sw.stop();
      debugPrint('[Gemini][$reqId] STREAM ERROR — ${sw.elapsedMilliseconds}ms: $e');
      yield LLMStreamChunk(
        text: 'Error: $e',
        isComplete: true,
        type: ResponseType.error,
      );
    }
  }

  @override
  Future<bool> isAvailable() async {
    if (apiKey.isEmpty) return false;
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/models?key=$apiKey'),
      ).timeout(const Duration(seconds: 10));
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  List<Map<String, dynamic>> _buildMessages(
    String userMessage,
    List<ConversationTurn> context,
    String? systemPrompt,
  ) {
    final messages = <Map<String, dynamic>>[];

    // System prompt (compact — single user/model pair)
    final prompt = systemPrompt ?? PrimeIdentity.systemPrompt;
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
    return text
        .replaceAll(RegExp(r'\*+'), '')
        .replaceAll(RegExp(r'#+\s*'), '')
        .replaceAll('```', '')
        .trim();
  }

  /// Short correlation ID for log tracing
  String _shortId() {
    final now = DateTime.now().millisecondsSinceEpoch;
    return now.toRadixString(36).toUpperCase().substring(
      now.toRadixString(36).length - 5,
    );
  }

  @override
  Future<void> dispose() async {
    _client.close();
  }
}
