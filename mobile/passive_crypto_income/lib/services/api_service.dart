// lib/services/api_service.dart
import 'dart:convert';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  static const String _baseUrl = 'https://passive-crypto-backend.onrender.com';
  static String? _authToken;

  // Load base URL (required by main.dart and websocket_service.dart)
  static Future<void> loadBaseUrl() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString('api_base_url');
    if (saved == null || !saved.contains('render.com')) {
      await prefs.setString('api_base_url', _baseUrl);
    }
  }

  // Token management
  static Future<void> setAuthToken(String? token) async {
    _authToken = token;
    final prefs = await SharedPreferences.getInstance();
    if (token != null) {
      await prefs.setString('auth_token', token);
    } else {
      await prefs.remove('auth_token');
    }
  }

  static Future<void> loadAuthToken() async {
    final prefs = await SharedPreferences.getInstance();
    _authToken = prefs.getString('auth_token');
  }

  // Headers
  static Map<String, String> _headers() {
    final h = {'Content-Type': 'application/json'};
    if (_authToken != null) h['Authorization'] = 'Bearer $_authToken';
    return h;
  }

  // Generic POST with retry
  static Future<Map<String, dynamic>> postWithRetry(
    String endpoint,
    Map<String, dynamic> data,
  ) async {
    final url = Uri.parse('$_baseUrl$endpoint');
    for (int i = 0; i < 3; i++) {
      try {
        final response = await http
            .post(url, headers: _headers(), body: json.encode(data))
            .timeout(const Duration(seconds: 20));

        if (response.statusCode >= 200 && response.statusCode < 300) {
          final decoded = json.decode(response.body);
          if (decoded is Map<String, dynamic> && decoded['token'] != null) {
            await setAuthToken(decoded['token']);
          }
          return decoded;
        }
        throw Exception('HTTP ${response.statusCode}');
      } catch (e) {
        if (i == 2) rethrow;
        await Future.delayed(Duration(seconds: i + 1));
      }
    }
    throw Exception('Network error');
  }

  // Generic GET
  static Future<Map<String, dynamic>> get(String endpoint, String email) async {
    final url = Uri.parse('$_baseUrl$endpoint?email=${Uri.encodeComponent(email)}');
    final response = await http.get(url, headers: _headers()).timeout(const Duration(seconds: 20));
    if (response.statusCode == 200) {
      return json.decode(response.body) as Map<String, dynamic>;
    }
    throw Exception('HTTP ${response.statusCode}');
  }

  // Public methods
  static Future<Map<String, dynamic>> login(Map<String, String> user) =>
      postWithRetry('/login', user);

  static Future<Map<String, dynamic>> signup(Map<String, String> user) =>
      postWithRetry('/signup', user);

  static Future<Map<String, dynamic>> saveKeys(Map<String, String> keys, String email) =>
      postWithRetry('/save_keys', {'email': email, ...keys});

  static Future<Map<String, dynamic>> getKeys(String email) => get('/get_keys', email);

  static Future<Map<String, dynamic>> setAmount(double amount, String email) =>
      postWithRetry('/set_amount', {'amount': amount, 'email': email});

  static Future<Map<String, dynamic>> toggleAutoTrade(bool enabled, String email) =>
      postWithRetry('/toggle_auto_trade', {'enabled': enabled, 'email': email});

  static Future<Map<String, dynamic>> setTradeThreshold(double threshold, String email) =>
      postWithRetry('/set_threshold', {'threshold': threshold, 'email': email});

  static Future<Map<String, dynamic>> fetchBalances(String email) => get('/balances', email);
  static Future<Map<String, dynamic>> fetchArbitrage(String email) => get('/arbitrage', email);

  // For WebSocket
  static String get baseUrl => _baseUrl;
}
