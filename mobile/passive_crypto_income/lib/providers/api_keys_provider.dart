import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';

class ApiKeysProvider extends ChangeNotifier {
  String _cexKey = '';
  String _cexSecret = '';
  String _krakenKey = '';
  String _krakenSecret = '';
  bool _isLoading = false;
  String _errorMessage = '';

  String get cexKey => _cexKey;  // FIXED: Replaced binanceKey with cexKey
  String get cexSecret => _cexSecret;  // FIXED: Replaced binanceSecret with cexSecret
  String get krakenKey => _krakenKey;
  String get krakenSecret => _krakenSecret;
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
        _cexKey = keysData['cex_key'] ?? '';  // FIXED: Updated for cex_key
        _cexSecret = keysData['cex_secret'] ?? '';  // FIXED: Updated for cex_secret
        _krakenKey = keysData['kraken_key'] ?? '';
        _krakenSecret = keysData['kraken_secret'] ?? '';

        // Sync to local prefs
        await prefs.setString('cex_key', _cexKey);  // FIXED: Updated for cex_key
        await prefs.setString('cex_secret', _cexSecret);  // FIXED: Updated for cex_secret
        await prefs.setString('kraken_key', _krakenKey);
        await prefs.setString('kraken_secret', _krakenSecret);
      } else {
        // Fallback to local if backend empty
        _cexKey = prefs.getString('cex_key') ?? '';  // FIXED: Updated for cex_key
        _cexSecret = prefs.getString('cex_secret') ?? '';  // FIXED: Updated for cex_secret
        _krakenKey = prefs.getString('kraken_key') ?? '';
        _krakenSecret = prefs.getString('kraken_secret') ?? '';
      }
    } catch (e) {
      _errorMessage = 'Failed to load keys: $e';
      // Fallback to local on error
      final prefs = await SharedPreferences.getInstance();
      _cexKey = prefs.getString('cex_key') ?? '';  // FIXED: Updated for cex_key
      _cexSecret = prefs.getString('cex_secret') ?? '';  // FIXED: Updated for cex_secret
      _krakenKey = prefs.getString('kraken_key') ?? '';
      _krakenSecret = prefs.getString('kraken_secret') ?? '';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Save keys (local + backend)
  Future<bool> saveKeys(String cexKey, String cexSecret, String krakenKey, String krakenSecret) async {  // FIXED: Replaced binance params with cex
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
        'cex_key': cexKey,  // FIXED: Updated for cex_key
        'cex_secret': cexSecret,  // FIXED: Updated for cex_secret
        'kraken_key': krakenKey,
        'kraken_secret': krakenSecret,
      };
      await ApiService.saveKeys(keysMap, email);

      // Backend success: Update local + state
      await prefs.setString('cex_key', cexKey);  // FIXED: Updated for cex_key
      await prefs.setString('cex_secret', cexSecret);  // FIXED: Updated for cex_secret
      await prefs.setString('kraken_key', krakenKey);
      await prefs.setString('kraken_secret', krakenSecret);
      _cexKey = cexKey;
      _cexSecret = cexSecret;
      _krakenKey = krakenKey;
      _krakenSecret = krakenSecret;
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
      await prefs.remove('cex_key');  // FIXED: Updated for cex_key
      await prefs.remove('cex_secret');  // FIXED: Updated for cex_secret
      await prefs.remove('kraken_key');
      await prefs.remove('kraken_secret');
      _cexKey = '';
      _cexSecret = '';
      _krakenKey = '';
      _krakenSecret = '';
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
