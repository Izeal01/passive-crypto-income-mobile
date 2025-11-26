// lib/screens/api_keys_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/api_service.dart';
import '../providers/api_keys_provider.dart';

class ApiKeysScreen extends StatefulWidget {
  final String userEmail;
  const ApiKeysScreen({super.key, required this.userEmail});

  @override
  State<ApiKeysScreen> createState() => _ApiKeysScreenState();
}

class _ApiKeysScreenState extends State<ApiKeysScreen> {
  final _cexKeyController = TextEditingController();
  final _cexSecretController = TextEditingController();
  final _krakenKeyController = TextEditingController();
  final _krakenSecretController = TextEditingController();

  bool _isLoading = false;
  bool _hasKeys = false;

  @override
  void initState() {
    super.initState();
    _loadExistingKeys();
  }

  Future<void> _loadExistingKeys() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      final keys = await ApiService.getKeys(widget.userEmail);
      if (keys['cex_key'] != null && keys['kraken_key'] != null) {
        _cexKeyController.text = keys['cex_key'];
        _cexSecretController.text = keys['cex_secret'] ?? '';
        _krakenKeyController.text = keys['kraken_key'];
        _krakenSecretController.text = keys['kraken_secret'] ?? '';
        setState(() => _hasKeys = true);
      }
    } catch (e) {
      debugPrint('No existing keys found: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _saveKeys() async {
    final cexKey = _cexKeyController.text.trim();
    final krakenKey = _krakenKeyController.text.trim();

    if (cexKey.isEmpty || krakenKey.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill in all required fields'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      await ApiService.saveKeys({
        'cex_key': cexKey,
        'cex_secret': _cexSecretController.text.trim(),
        'kraken_key': krakenKey,
        'kraken_secret': _krakenSecretController.text.trim(),
      }, widget.userEmail);

      Provider.of<ApiKeysProvider>(context, listen: false).setKeysSaved(true);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_hasKeys ? 'API Keys Updated Successfully!' : 'API Keys Saved Successfully!'),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 3),
        ),
      );

      Navigator.pop(context, true); // Signal success to HomeScreen
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_hasKeys ? 'Replace API Keys' : 'Connect Exchanges'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        elevation: 4,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Card(
                    elevation: 3,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(
                        _hasKeys
                            ? 'You can update or replace your existing API keys below.'
                            : 'Enter your CEX.IO and Kraken API keys to enable real-time arbitrage monitoring and auto-trading.',
                        style: const TextStyle(fontSize: 15),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),

                  // CEX.IO Section
                  const Text('CEX.IO', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _cexKeyController,
                    decoration: const InputDecoration(
                      labelText: 'API Key *',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.vpn_key),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _cexSecretController,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: 'API Secret',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.lock),
                    ),
                  ),
                  const SizedBox(height: 30),

                  // Kraken Section
                  const Text('Kraken', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _krakenKeyController,
                    decoration: const InputDecoration(
                      labelText: 'API Key *',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.vpn_key),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _krakenSecretController,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: 'API Secret',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.lock),
                    ),
                  ),
                  const SizedBox(height: 40),

                  // Save Button
                  ElevatedButton(
                    onPressed: _isLoading ? null : _saveKeys,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      elevation: 5,
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            height: 24,
                            width: 24,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                          )
                        : Text(
                            _hasKeys ? 'Update API Keys' : 'Save API Keys',
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                  ),

                  const SizedBox(height: 16),

                  // Cancel button (only if updating)
                  if (_hasKeys)
                    OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancel'),
                    ),
                ],
              ),
            ),
    );
  }

  @override
  void dispose() {
    _cexKeyController.dispose();
    _cexSecretController.dispose();
    _krakenKeyController.dispose();
    _krakenSecretController.dispose();
    super.dispose();
  }
}
