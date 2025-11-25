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
      debugPrint('No saved keys found');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _saveKeys() async {
    if (_cexKeyController.text.trim().isEmpty ||
        _krakenKeyController.text.trim().isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all required fields')),
      );
      return;
    }

    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      await ApiService.saveKeys({
        'cex_key': _cexKeyController.text.trim(),
        'cex_secret': _cexSecretController.text.trim(),
        'kraken_key': _krakenKeyController.text.trim(),
        'kraken_secret': _krakenSecretController.text.trim(),
      }, widget.userEmail);

      Provider.of<ApiKeysProvider>(context, listen: false).setKeysSaved(true);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_hasKeys ? 'API Keys Updated!' : 'API Keys Saved!'),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
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
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(
                        _hasKeys
                            ? 'Update your exchange API keys below.'
                            : 'Enter your CEX.IO and Kraken API keys to start arbitrage.',
                        style: const TextStyle(fontSize: 15),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text('CEX.IO', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _cexKeyController,
                    decoration: const InputDecoration(
                      labelText: 'API Key',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _cexSecretController,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: 'API Secret',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text('Kraken', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _krakenKeyController,
                    decoration: const InputDecoration(
                      labelText: 'API Key',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _krakenSecretController,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: 'API Secret',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 30),
                  ElevatedButton(
                    onPressed: _isLoading ? null : _saveKeys,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : Text(_hasKeys ? 'Update Keys' : 'Save Keys'),
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
