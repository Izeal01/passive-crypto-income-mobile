import 'dart:convert';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  static String _baseUrl = 'https://passive-crypto-backend.onrender.com/';
  static String? _authToken;

  static String get baseUrl => _baseUrl;

  static Future<void> loadBaseUrl() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString('api_base_url');
    if (saved == null || !saved.contains('render.com')) {
      await prefs.setString('api_base_url', _baseUrl);
    } else {
      _baseUrl = saved.endsWith('/') ? saved : '$saved/';
    }
    await loadAuthToken();
  }

  static Future<void> setAuthToken(String? token) async {
    _authToken = token;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('auth_token', token ?? '');
  }

  static Future<void> loadAuthToken() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    if (token != null && token.isNotEmpty) _authToken = token;
  }

  static Map<String, String> _getHeaders({bool includeAuth = true}) {
    final headers = {'Content-Type': 'application/json'};
    if (includeAuth && _authToken != null) {
      headers['Authorization'] = 'Bearer $_authToken';
    }
    return headers;
  }

  static Future<Map<String, dynamic>> postWithRetry(String endpoint, Map<String, dynamic> data, {int retries = 3}) async {
    final url = Uri.parse('$_baseUrl${endpoint.startsWith('/') ? endpoint.substring(1) : endpoint}');
    final body = json.encode(data);

    for (int i = 0; i < retries; i++) {
      try {
        final response = await http.post(url, headers: _getHeaders(), body: body).timeout(const Duration(seconds: 20));
        if (response.statusCode == 200) {
          final decoded = json.decode(response.body);
          if (decoded is Map<String, dynamic>) {
            if (decoded['token'] != null) await setAuthToken(decoded['token']);
            return decoded;
          }
        }
        throw Exception('HTTP ${response.statusCode}');
      } catch (e) {
        if (i == retries - 1) rethrow;
        await Future.delayed(Duration(seconds: i + 1));
      }
    }
    throw Exception('Network error');
  }

  static Future<Map<String, dynamic>> login(Map<String, String> user) => postWithRetry('/login', user);
  static Future<Map<String, dynamic>> signup(Map<String, String> user) => postWithRetry('/signup', user);

  static Future<Map<String, dynamic>> saveKeys(Map<String, String> keys, String email) =>
      postWithRetry('/save_keys', {'email': email, ...keys});

  static Future<Map<String, dynamic>> clearKeys(String email) => postWithRetry('/clear_keys', {'email': email});

  static Future<Map<String, dynamic>> getKeys(String email) async {
    final url = Uri.parse('$_baseUrl/get_keys?email=${Uri.encodeComponent(email)}');
    final response = await http.get(url, headers: _getHeaders()).timeout(const Duration(seconds: 20));
    if (response.statusCode == 200) return json.decode(response.body) as Map<String, dynamic>;
    throw Exception('Failed to load keys');
  }

  static Future<Map<String, dynamic>> setAmount(double amount, String email) =>
      postWithRetry('/set_amount', {'amount': amount, 'email': email});

  static Future<Map<String, dynamic>> toggleAutoTrade(bool enabled, String email) =>
      postWithRetry('/toggle_auto_trade', {'enabled': enabled, 'email': email});

  static Future<Map<String, dynamic>> setTradeThreshold(double threshold, String email) =>
      postWithRetry('/set_threshold', {'threshold': threshold, 'email': email});

  static Future<Map<String, dynamic>> fetchBalances(String email) async {
    final url = Uri.parse('$_baseUrl/balances?email=${Uri.encodeComponent(email)}');
    final response = await http.get(url, headers: _getHeaders()).timeout(const Duration(seconds: 20));
    if (response.statusCode == 200) {
      final data = json.decode(response.body) as Map<String, dynamic>;
      return {
        'cex_usdc': data['cex_usdc'] ?? data['cex_usd'] ?? 0.0,
        'kraken_usdc': data['kraken_usdc'] ?? data['kraken_usd'] ?? 0.0,
        if (data.containsKey('error')) 'error': data['error'],
      };
    }
    throw Exception('Failed to fetch balances');
  }

  static Future<Map<String, dynamic>> fetchArbitrage(String email) async {
    final url = Uri.parse('$_baseUrl/arbitrage?email=${Uri.encodeComponent(email)}');
    final response = await http.get(url, headers: _getHeaders()).timeout(const Duration(seconds: 20));
    if (response.statusCode == 200) return json.decode(response.body) as Map<String, dynamic>;
    throw Exception('Failed to fetch arbitrage');
  }
}
