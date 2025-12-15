// lib/services/websocket_service.dart — FINAL & SAFE VERSION
// This file is intentionally minimal — your backend has no /ws endpoint
// So we disable WebSocket to prevent 403 errors while keeping compatibility

class WebSocketService {
  // Singleton pattern
  static final WebSocketService _instance = WebSocketService._internal();
  factory WebSocketService() => _instance;
  WebSocketService._internal();

  // No active connection — prevents 403 Forbidden errors
  void connect({Function(Map<String, dynamic>)? onData}) {
    // WebSocket is disabled because backend doesn't support /ws
    // This avoids connection attempts and 403 errors
  }

  void disconnect() {
    // Nothing to close
  }

  // Keep stream for compatibility with DashboardScreen (won't emit anything)
  Stream<Map<String, dynamic>> get stream => Stream.empty();
}
