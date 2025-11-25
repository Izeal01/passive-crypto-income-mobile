import 'package:flutter/material.dart';

class ApiKeysProvider extends ChangeNotifier {
  bool _keysSaved = false;
  bool _isLoading = false;

  bool get keysSaved => _keysSaved;
  bool get isLoading => _isLoading;

  void setKeysSaved(bool value) {
    _keysSaved = value;
    notifyListeners();
  }

  void setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}
