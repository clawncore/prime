import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

class WebSocketService {
  WebSocketService._();
  static final WebSocketService instance = WebSocketService._();

  WebSocketChannel? _channel;
  Timer? _reconnectTimer;
  Timer? _pingTimer;

  final String _url = 'ws://localhost:4000';
  bool _connected = false;
  bool _intentionalClose = false;
  int _reconnectAttempts = 0;
  static const int _maxReconnectAttempts = 10;

  final StreamController<Map<String, dynamic>> _eventController =
      StreamController<Map<String, dynamic>>.broadcast();
  final StreamController<bool> _connectionController =
      StreamController<bool>.broadcast();

  Stream<Map<String, dynamic>> get events => _eventController.stream;
  Stream<bool> get connectionStatus => _connectionController.stream;
  bool get isConnected => _connected;

  Future<void> connect() async {
    if (_connected) return;
    _intentionalClose = false;

    try {
      debugPrint('[WebSocketService] Connecting to $_url ...');
      _channel = WebSocketChannel.connect(Uri.parse(_url));

      _channel!.stream.listen(
        (data) {
          _connected = true;
          _reconnectAttempts = 0;
          _connectionController.add(true);

          try {
            final decoded = jsonDecode(data as String) as Map<String, dynamic>;
            _eventController.add(decoded);
            debugPrint('[WebSocketService] Received: ${decoded['type']}');
          } catch (e) {
            debugPrint('[WebSocketService] Parse error: $e');
          }
        },
        onDone: () {
          debugPrint('[WebSocketService] Connection closed');
          _connected = false;
          _connectionController.add(false);
          _startReconnect();
        },
        onError: (error) {
          debugPrint('[WebSocketService] Error: $error');
          _connected = false;
          _connectionController.add(false);
          _startReconnect();
        },
      );

      _startPing();
      _connected = true;
      _connectionController.add(true);
      debugPrint('[WebSocketService] Connected');
    } catch (e) {
      debugPrint('[WebSocketService] Connection failed: $e');
      _connected = false;
      _connectionController.add(false);
      _startReconnect();
    }
  }

  void _startReconnect() {
    if (_intentionalClose) return;
    if (_reconnectAttempts >= _maxReconnectAttempts) {
      debugPrint('[WebSocketService] Max reconnect attempts reached');
      return;
    }

    _reconnectTimer?.cancel();
    final delay = Duration(seconds: (2 * (_reconnectAttempts + 1)).clamp(2, 30));
    _reconnectAttempts++;

    debugPrint(
        '[WebSocketService] Reconnecting in ${delay.inSeconds}s (attempt $_reconnectAttempts)');
    _reconnectTimer = Timer(delay, () => connect());
  }

  void _startPing() {
    _pingTimer?.cancel();
    _pingTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      send({'type': 'ping'});
    });
  }

  void send(Map<String, dynamic> data) {
    if (!_connected || _channel == null) {
      debugPrint('[WebSocketService] Not connected, cannot send');
      return;
    }
    try {
      _channel!.sink.add(jsonEncode(data));
    } catch (e) {
      debugPrint('[WebSocketService] Send error: $e');
    }
  }

  void sendChatMessage(String message) {
    send({
      'type': 'chat_message',
      'content': message,
      'timestamp': DateTime.now().toIso8601String(),
    });
  }

  void sendCommand(String command, {Map<String, dynamic>? payload}) {
    send({
      'type': 'command',
      'command': command,
      'payload': payload,
      'timestamp': DateTime.now().toIso8601String(),
    });
  }

  void requestState() {
    send({'type': 'get_state'});
  }

  void requestTelemetry() {
    send({'type': 'get_telemetry'});
  }

  void disconnect() {
    _intentionalClose = true;
    _reconnectTimer?.cancel();
    _pingTimer?.cancel();
    _connected = false;
    _channel?.sink.close();
    _channel = null;
    _connectionController.add(false);
    debugPrint('[WebSocketService] Disconnected');
  }

  void dispose() {
    disconnect();
    _eventController.close();
    _connectionController.close();
  }
}
