import 'dart:convert';
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  // FIXED: Hard-coded to Render for production/release builds
  static String _baseUrl = 'https://passive-crypto-backend.onrender.com/';

  static String? _authToken;

  static String get baseUrl => _baseUrl;

  static Future<void> setBaseUrl(String newUrl) async {
    _baseUrl = newUrl.endsWith('/') ? newUrl : '$newUrl/';
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('api_base_url', _baseUrl);
  }

  // FIXED: Force Render URL on first launch or if old local URL cached
  static Future<void> loadBaseUrl() async {
    final prefs = await SharedPreferences.getInstance();
    final savedUrl = prefs.getString('api_base_url');
    if (savedUrl == null || !savedUrl.contains('render.com')) {
      await prefs.setString('api_base_url', _baseUrl);
    } else {
      _baseUrl = savedUrl.endsWith('/') ? savedUrl : '$savedUrl/';
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
    final savedToken = prefs.getString('auth_token');
    if (savedToken != null && savedToken.isNotEmpty) {
      _authToken = savedToken;
    }
  }

  static Map<String, String> _getHeaders({bool includeAuth = true}) {
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'User-Agent': 'PassiveCryptoIncome/1.0 (Flutter; Global)',
    };
    if (includeAuth && _authToken != null && _authToken!.isNotEmpty) {
      headers['Authorization'] = 'Bearer $_authToken';
    }
    return headers;
  }

  static Future<Map<String, dynamic>> postWithRetry(String endpoint, Map<String, dynamic> data, {int retries = 3}) async {
    final path = endpoint.startsWith('/') ? endpoint.substring(1) : endpoint;
    final fullUrl = Uri.parse('${baseUrl}$path');
    final bodyStr = json.encode(data);
    debugPrint('DEBUG: Posting to $fullUrl with body: $bodyStr');
    for (int i = 0; i < retries; i++) {
      try {
        final response = await http.post(
          fullUrl,
          headers: _getHeaders(includeAuth: endpoint != '/login' && endpoint != '/signup'),  // Exclude auth for login/signup
          body: bodyStr,  // Use pre-encoded bodyStr to avoid duplicate encoding
        ).timeout(const Duration(seconds: 20));
        final preview = response.body.length > 200
            ? '${response.body.substring(0, 200)}...'
            : response.body;
        debugPrint('DEBUG: Response status: $response.statusCode, body preview: $preview');
        if (response.statusCode == 200) {
          final decoded = json.decode(response.body);
          if (decoded is Map<String, dynamic>) {
            // Auto-save token if returned in response (assumes backend returns {'token': '...'} on success)
            if (decoded.containsKey('token') && (endpoint == '/login' || endpoint == '/signup')) {
              await setAuthToken(decoded['token']);
            }
            return decoded;
          } else {
            throw Exception('Invalid JSON response structure');
          }
        } else {
          throw Exception('HTTP $response.statusCode: $response.body');
        }
      } catch (e) {
        debugPrint('Attempt ${i+1}/$retries failed: $e');
        if (i == retries - 1) {
          rethrow;
        }
        await Future.delayed(Duration(seconds: (i + 1) * 2));
      }
    }
    throw Exception('Retries exhausted after $retries attempts');
  }

  static Future<Map<String, dynamic>> login(Map<String, String> user) async {
    final result = await postWithRetry('/login', user);
    // Caller can access result['token'] if needed, but auto-saved above
    return result;
  }

  static Future<Map<String, dynamic>> signup(Map<String, String> user) async {
    final result = await postWithRetry('/signup', user);
    // Caller can access result['token'] if needed, but auto-saved above
    return result;
  }

  static Future<Map<String, dynamic>> saveKeys(Map<String, String> keys, String email) async {
    final data = <String, dynamic>{'email': email, ...keys};
    debugPrint('Sending save keys: email: $email, keys: ${keys.keys.join(', ')}');
    return await postWithRetry('/save_keys', data);
  }

  static Future<Map<String, dynamic>> clearKeys(String email) async {
    debugPrint('Sending clear keys: email: $email');
    return await postWithRetry('/clear_keys', {'email': email});
  }

  static Future<Map<String, dynamic>> getKeys(String email) async {
    final fullUrl = Uri.parse('${baseUrl}get_keys?email=${Uri.encodeComponent(email)}');
    final response = await http.get(
      fullUrl,
      headers: _getHeaders(),  // Includes auth token
    ).timeout(const Duration(seconds: 20));
    if (response.statusCode == 200) {
      final decoded = json.decode(response.body);
      if (decoded is Map<String, dynamic>) return decoded;
      throw Exception('Invalid JSON response structure');
    }
    throw Exception('Get keys failed: $response.body');
  }

  static Future<Map<String, dynamic>> setAmount(double amount, String email) async {
    return await postWithRetry('/set_amount', {'amount': amount, 'email': email});
  }

  static Future<Map<String, dynamic>> toggleAutoTrade(bool enabled, String email) async {
    return await postWithRetry('/toggle_auto_trade', {'enabled': enabled, 'email': email});
  }

  static Future<Map<String, dynamic>> setTradeThreshold(double threshold, String email) async {
    return await postWithRetry('/set_threshold', {'threshold': threshold, 'email': email});
  }

  // Aliases for dashboard calls (getArbitrage -> fetchArbitrage, etc.; rename in dashboard later for cleanliness)
  static Future<Map<String, dynamic>> getArbitrage(String email) async => fetchArbitrage(email);
  static Future<Map<String, dynamic>> getBalances(String email) async => fetchBalances(email);
  static Future<Map<String, dynamic>> setThreshold(double threshold, String email) async => setTradeThreshold(threshold, email);

  static Future<Map<String, dynamic>> fetchArbitrage(String email) async {
    debugPrint('Fetching arbitrage for $email');  // FIXED: Added debug for call tracking
    final fullUrl = Uri.parse('${baseUrl}arbitrage?email=${Uri.encodeComponent(email)}');
    final response = await http.get(
      fullUrl,
      headers: _getHeaders(),  // Includes auth token
    ).timeout(const Duration(seconds: 20));
    if (response.statusCode == 200) {
      final decoded = json.decode(response.body);
      if (decoded is Map<String, dynamic>) return decoded;
      throw Exception('Invalid JSON response structure');
    }
    throw Exception('Arbitrage fetch failed: $response.body');
  }

  static Future<Map<String, dynamic>> fetchBalances(String email) async {
    debugPrint('Fetching balances for $email');  // FIXED: Added debug for call tracking
    final fullUrl = Uri.parse('${baseUrl}balances?email=${Uri.encodeComponent(email)}');
    final response = await http.get(
      fullUrl,
      headers: _getHeaders(),  // Includes auth token
    ).timeout(const Duration(seconds: 20));
    if (response.statusCode == 200) {
      final decoded = json.decode(response.body);
      if (decoded is Map<String, dynamic>) return decoded;
      throw Exception('Invalid JSON response structure');
    }
    throw Exception('Balances fetch failed: $response.body');
  }
}
