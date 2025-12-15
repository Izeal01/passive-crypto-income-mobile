// lib/services/api_service.dart — FINAL & BULLETPROOF
import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  static const String _baseUrl = 'https://passive-crypto-backend.onrender.com';

  // REQUIRED BY main.dart
  static Future<void> loadBaseUrl() async {}

  // AUTH
  static Future<Map<String, dynamic>> login(Map<String, String> user) => _post('/login', user);
  static Future<Map<String, dynamic>> signup(Map<String, String> user) => _post('/signup', user);

  // KEYS
  static Future<Map<String, dynamic>> saveKeys(Map<String, String> keys, String email) =>
      _post('/save_keys', {'email': email, ...keys});
  static Future<Map<String, dynamic>> getKeys(String email) => _get('/get_keys', email);

  // CORE
  static Future<Map<String, dynamic>> fetchBalances(String email) => _get('/balances', email);
  static Future<Map<String, dynamic>> fetchArbitrage(String email) => _get('/arbitrage', email);

  // SETTINGS — NOW WITH REAL-TIME VALUES
  static Future<Map<String, dynamic>> getSettings(String email) => _get('/get_settings', email);
  static Future<Map<String, dynamic>> setAmount(double amount, String email) =>
      _post('/set_amount', {'email': email, 'amount': amount});
  static Future<Map<String, dynamic>> toggleAutoTrade(bool enabled, String email) =>
      _post('/toggle_auto_trade', {'email': email, 'enabled': enabled ? 1 : 0});
  static Future<Map<String, dynamic>> setTradeThreshold(double threshold, String email) =>
      _post('/set_threshold', {'email': email, 'threshold': threshold});

  // Helpers
  static Future<Map<String, dynamic>> _post(String endpoint, Map<String, dynamic> data) async {
    final response = await http.post(
      Uri.parse('$_baseUrl$endpoint'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode(data),
    );
    return json.decode(response.body);
  }

  static Future<Map<String, dynamic>> _get(String endpoint, String email) async {
    final response = await http.get(Uri.parse('$_baseUrl$endpoint?email=${Uri.encodeComponent(email)}'));
    return json.decode(response.body);
  }
}
