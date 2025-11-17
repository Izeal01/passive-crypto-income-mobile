import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';

class ApiKeysProvider extends ChangeNotifier {
  String? _cexKey;
  String? _cexSecret;
  String? _krakenKey;
  String? _krakenSecret;
  bool _isLoading = false;
  String _errorMessage = '';

  String get cexKey => _cexKey ?? '';
  set cexKey(String value) => _cexKey = value;  // Setter for onChanged
  String get cexSecret => _cexSecret ?? '';
  set cexSecret(String value) => _cexSecret = value;
  String get krakenKey => _krakenKey ?? '';
  set krakenKey(String value) => _krakenKey = value;
  String get krakenSecret => _krakenSecret ?? '';
  set krakenSecret(String value) => _krakenSecret = value;
  bool get isLoading => _isLoading;
  String get errorMessage => _errorMessage;

  // Load saved keys from backend + local fallback
  Future<void> loadKeys() async {
    _isLoading = true;
    _errorMessage = '';
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      final email = prefs.getString('user_email');
      if (email == null || email.isEmpty) {
        throw Exception('No user email found. Please log in first.');
      }

      // Fetch from backend first (overrides local)
      final keysData = await ApiService.getKeys(email);
      if (keysData.isNotEmpty) {
        cexKey = keysData['cex_key'] ?? '';  // FIXED: Removed 'this.'
        cexSecret = keysData['cex_secret'] ?? '';
        krakenKey = keysData['kraken_key'] ?? '';
        krakenSecret = keysData['kraken_secret'] ?? '';

        // Sync to local prefs
        await prefs.setString('cex_key', cexKey);
        await prefs.setString('cex_secret', cexSecret);
        await prefs.setString('kraken_key', krakenKey);
        await prefs.setString('kraken_secret', krakenSecret);
      } else {
        // Fallback to local if backend empty
        cexKey = prefs.getString('cex_key') ?? '';
        cexSecret = prefs.getString('cex_secret') ?? '';
        krakenKey = prefs.getString('kraken_key') ?? '';
        krakenSecret = prefs.getString('kraken_secret') ?? '';
      }
    } catch (e) {
      _errorMessage = 'Failed to load keys: $e';
      // Fallback to local on error
      final prefs = await SharedPreferences.getInstance();
      cexKey = prefs.getString('cex_key') ?? '';
      cexSecret = prefs.getString('cex_secret') ?? '';
      krakenKey = prefs.getString('kraken_key') ?? '';
      krakenSecret = prefs.getString('kraken_secret') ?? '';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Save keys (local + backend)
  Future<bool> saveKeys(String cexKey, String cexSecret, String krakenKey, String krakenSecret) async {
    _isLoading = true;
    _errorMessage = '';
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      final email = prefs.getString('user_email');
      if (email == null || email.isEmpty) {
        throw Exception('No user email found. Please log in first.');
      }

      // Save to backend first
      final keysMap = <String, String>{
        'cex_key': cexKey,
        'cex_secret': cexSecret,
        'kraken_key': krakenKey,
        'kraken_secret': krakenSecret,
      };
      await ApiService.saveKeys(keysMap, email);

      // Backend success: Update local + state
      await prefs.setString('cex_key', cexKey);
      await prefs.setString('cex_secret', cexSecret);
      await prefs.setString('kraken_key', krakenKey);
      await prefs.setString('kraken_secret', krakenSecret);
      cexKey = cexKey;  // FIXED: Removed 'this.' (assign param to setter)
      cexSecret = cexSecret;
      krakenKey = krakenKey;
      krakenSecret = krakenSecret;
      return true;
    } catch (e) {
      _errorMessage = 'Save error: $e';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Clear keys (backend + local)
  Future<bool> clearKeys() async {
    _isLoading = true;
    _errorMessage = '';
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      final email = prefs.getString('user_email');
      if (email == null || email.isEmpty) {
        throw Exception('No user email found. Please log in first.');
      }

      // Clear backend first
      await ApiService.clearKeys(email);

      // Backend success: Clear local + state
      await prefs.remove('cex_key');
      await prefs.remove('cex_secret');
      await prefs.remove('kraken_key');
      await prefs.remove('kraken_secret');
      cexKey = '';  // FIXED: Already without 'this.'
      cexSecret = '';
      krakenKey = '';
      krakenSecret = '';
      return true;
    } catch (e) {
      _errorMessage = 'Clear error: $e';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
