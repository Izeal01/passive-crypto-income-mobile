import 'dart:convert';
import 'dart:async';
import 'package:flutter/foundation.dart';  // For debugPrint
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/status.dart' as status;
import 'api_service.dart';  // FIXED: Corrected relative import (same directory)

class WebSocketService {
  static final WebSocketService _instance = WebSocketService._internal();
  factory WebSocketService() => _instance;
  WebSocketService._internal();

  WebSocketChannel? _channel;
  bool _isConnected = false;  // FIXED: Local flag for connection state (replaces undefined readyState)
  final _controller = StreamController<Map<String, dynamic>>.broadcast();
  Timer? _reconnectTimer;
  static const int _maxReconnectAttempts = 5;
  int _reconnectAttempts = 0;
  Function(Map<String, dynamic>)? _onDataCallback;  // FIXED: Added callback support for direct onData

  Stream<Map<String, dynamic>> get stream => _controller.stream;

  Future<void> connect({bool forceReconnect = false, Function(Map<String, dynamic>)? onData}) async {  // FIXED: Added optional onData param
    _onDataCallback = onData ?? _onDataCallback;  // FIXED: Set or retain callback

    // Ensure baseUrl is loaded
    await ApiService.loadBaseUrl();

    if (_isConnected && !forceReconnect) {  // FIXED: Use _isConnected flag instead of undefined readyState
      debugPrint('DEBUG: WebSocket already connected');
      return;
    }

    _disconnect();

    final wsUriStr = ApiService.baseUrl.replaceAll('http://', 'ws://').replaceAll('https://', 'wss://');
    final wsUri = Uri.parse(wsUriStr);
    final uri = Uri(
      scheme: wsUri.scheme,
      host: wsUri.host,
      port: wsUri.port,
      path: '/ws',
    );

    try {
      _channel = WebSocketChannel.connect(uri);
      _isConnected = true;  // FIXED: Set flag on successful connect
      _channel!.stream.listen(
        (data) {
          try {
            final wsData = json.decode(data);
            _controller.add(wsData);  // Emit updates (e.g., {'opportunity': true, 'pnl': 1.2})
            _onDataCallback?.call(wsData);  // FIXED: Call callback if set
            _reconnectAttempts = 0;
          } catch (e) {
            debugPrint('WS Parse Error: $e');
          }
        },
        onError: (error) {
          debugPrint('WS Error: $error');
          _isConnected = false;  // FIXED: Update flag on error
          _controller.addError(error);
          _attemptReconnect();
        },
        onDone: () {
          debugPrint('WS Closed');
          _isConnected = false;  // FIXED: Update flag on close
          _attemptReconnect();
        },
      );
      debugPrint('DEBUG: WebSocket connected to $uri');
    } catch (e) {
      debugPrint('WS Connect Failed: $e');
      _isConnected = false;  // FIXED: Update flag on connect fail
      _attemptReconnect();
    }
  }

  void _attemptReconnect() {
    if (_reconnectAttempts >= _maxReconnectAttempts) {
      debugPrint('Max WS reconnect attempts reached');
      return;
    }
    _reconnectAttempts++;
    final delay = Duration(seconds: _reconnectAttempts * 2);
    debugPrint('Reconnecting WS in $delay (attempt $_reconnectAttempts/$_maxReconnectAttempts)');
    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(delay, () => connect());  // FIXED: Retain callback on reconnect
  }

  void sendMessage(Map<String, dynamic> message) {
    if (_isConnected) {  // FIXED: Use _isConnected flag instead of undefined readyState
      _channel!.sink.add(json.encode(message));
    } else {
      debugPrint('WARN: Cannot send message - WS not open');
    }
  }

  void disconnect() {
    _disconnect();
    _reconnectAttempts = 0;
  }

  void _disconnect() {
    _isConnected = false;  // FIXED: Update flag on disconnect
    _channel?.sink.close(status.goingAway);
    _channel = null;
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
  }

  void dispose() {
    _controller.close();
    disconnect();
  }
}
