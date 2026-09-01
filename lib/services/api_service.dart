import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class ApiService {
  ApiService._();
  static final ApiService instance = ApiService._();

  final String _baseUrl = 'http://localhost:4000';
  http.Client? _client;

  http.Client get _httpClient {
    _client ??= http.Client();
    return _client!;
  }

  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };

  Future<Map<String, dynamic>?> getState() async {
    try {
      final response = await _httpClient
          .get(Uri.parse('$_baseUrl/api/state'), headers: _headers)
          .timeout(const Duration(seconds: 5));
      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      }
      debugPrint('[ApiService] getState failed: ${response.statusCode}');
    } catch (e) {
      debugPrint('[ApiService] getState error: $e');
    }
    return null;
  }

  Future<Map<String, dynamic>?> executeTask(String task,
      {String? agentId}) async {
    try {
      final body = <String, dynamic>{
        'task': task,
      };
      if (agentId != null) body['agent_id'] = agentId;

      final response = await _httpClient
          .post(
            Uri.parse('$_baseUrl/api/tasks'),
            headers: _headers,
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 30));
      if (response.statusCode == 200 || response.statusCode == 201) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      }
      debugPrint('[ApiService] executeTask failed: ${response.statusCode}');
    } catch (e) {
      debugPrint('[ApiService] executeTask error: $e');
    }
    return null;
  }

  Future<Map<String, dynamic>?> sendMessage(String message,
      {String? conversationId}) async {
    try {
      final body = <String, dynamic>{
        'message': message,
      };
      if (conversationId != null) body['conversation_id'] = conversationId;

      final response = await _httpClient
          .post(
            Uri.parse('$_baseUrl/api/chat'),
            headers: _headers,
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 30));
      if (response.statusCode == 200 || response.statusCode == 201) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      }
      debugPrint('[ApiService] sendMessage failed: ${response.statusCode}');
    } catch (e) {
      debugPrint('[ApiService] sendMessage error: $e');
    }
    return null;
  }

  Future<List<Map<String, dynamic>>?> getAgents() async {
    try {
      final response = await _httpClient
          .get(Uri.parse('$_baseUrl/api/agents'), headers: _headers)
          .timeout(const Duration(seconds: 5));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data is List) {
          return data.cast<Map<String, dynamic>>();
        }
      }
    } catch (e) {
      debugPrint('[ApiService] getAgents error: $e');
    }
    return null;
  }

  Future<Map<String, dynamic>?> getTelemetry() async {
    try {
      final response = await _httpClient
          .get(Uri.parse('$_baseUrl/api/telemetry'), headers: _headers)
          .timeout(const Duration(seconds: 5));
      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      }
    } catch (e) {
      debugPrint('[ApiService] getTelemetry error: $e');
    }
    return null;
  }

  Future<void> sendCommand(String command,
      {Map<String, dynamic>? payload}) async {
    try {
      final body = <String, dynamic>{
        'command': command,
      };
      if (payload != null) body['payload'] = payload;

      await _httpClient
          .post(
            Uri.parse('$_baseUrl/api/command'),
            headers: _headers,
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 10));
    } catch (e) {
      debugPrint('[ApiService] sendCommand error: $e');
    }
  }

  Future<bool> healthCheck() async {
    try {
      final response = await _httpClient
          .get(Uri.parse('$_baseUrl/health'), headers: _headers)
          .timeout(const Duration(seconds: 3));
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  void dispose() {
    _client?.close();
    _client = null;
  }
}
