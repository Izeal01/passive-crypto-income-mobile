// lib/screens/api_keys_screen.dart — FINAL & 100% BINANCE.US + KRAKEN
import 'package:flutter/material.dart';
import '../services/api_service.dart';

class ApiKeysScreen extends StatefulWidget {
  final String userEmail;
  const ApiKeysScreen({super.key, required this.userEmail});

  @override
  State<ApiKeysScreen> createState() => _ApiKeysScreenState();
}

class _ApiKeysScreenState extends State<ApiKeysScreen> {
  late final TextEditingController _binanceusKey;
  late final TextEditingController _binanceusSecret;
  late final TextEditingController _krakenKey;
  late final TextEditingController _krakenSecret;

  final _formKey = GlobalKey<FormState>();
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _binanceusKey = TextEditingController();
    _binanceusSecret = TextEditingController();
    _krakenKey = TextEditingController();
    _krakenSecret = TextEditingController();
    _loadSavedKeys();
  }

  Future<void> _loadSavedKeys() async {
    try {
      final keys = await ApiService.getKeys(widget.userEmail);
      if (keys.isNotEmpty && mounted) {
        setState(() {
          _binanceusKey.text = keys['binanceus_key'] ?? '';
          _binanceusSecret.text = keys['binanceus_secret'] ?? '';
          _krakenKey.text = keys['kraken_key'] ?? '';
          _krakenSecret.text = keys['kraken_secret'] ?? '';
        });
      }
    } catch (e) {
      debugPrint("No saved keys: $e");
    }
  }

  Future<void> _saveKeys() async {
    if (!_formKey.currentState!.validate()) return;

    if (!mounted) return;
    setState(() => _isSaving = true);

    try {
      await ApiService.saveKeys({
        'binanceus_key': _binanceusKey.text.trim(),
        'binanceus_secret': _binanceusSecret.text.trim(),
        'kraken_key': _krakenKey.text.trim(),
        'kraken_secret': _krakenSecret.text.trim(),
      }, widget.userEmail);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('API keys saved! Arbitrage scanner started.'), backgroundColor: Colors.green),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _clearKeys() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Clear All API Keys?'),
        content: const Text('This will remove Binance.US and Kraken keys.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Clear', style: TextStyle(color: Colors.red))),
        ],
      ),
    );

    if (confirm != true || !mounted) return;

    setState(() => _isSaving = true);

    try {
      await ApiService.saveKeys({
        'binanceus_key': '',
        'binanceus_secret': '',
        'kraken_key': '',
        'kraken_secret': '',
      }, widget.userEmail);

      _binanceusKey.clear();
      _binanceusSecret.clear();
      _krakenKey.clear();
      _krakenSecret.clear();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('All API keys cleared'), backgroundColor: Colors.orange),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Exchange API Keys'),
        backgroundColor: Colors.green.shade700,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Connect your exchanges for live arbitrage',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),

              // BINANCE.US
              Card(
                child: ExpansionTile(
                  leading: Image.asset('assets/images/binanceus.png', width: 32), // Optional logo
                  title: const Text('Binance.US', style: TextStyle(fontWeight: FontWeight.bold)),
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        children: [
                          TextFormField(
                            controller: _binanceusKey,
                            decoration: const InputDecoration(
                              labelText: 'API Key',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.vpn_key),
                            ),
                            validator: (v) => v?.trim().isEmpty == true ? 'Required' : null,
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _binanceusSecret,
                            decoration: const InputDecoration(
                              labelText: 'API Secret',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.lock),
                            ),
                            obscureText: true,
                            validator: (v) => v?.trim().isEmpty == true ? 'Required' : null,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // KRAKEN
              Card(
                child: ExpansionTile(
                  leading: Image.asset('assets/images/kraken.png', width: 32), // Optional logo
                  title: const Text('Kraken', style: TextStyle(fontWeight: FontWeight.bold)),
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        children: [
                          TextFormField(
                            controller: _krakenKey,
                            decoration: const InputDecoration(
                              labelText: 'API Key',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.vpn_key),
                            ),
                            validator: (v) => v?.trim().isEmpty == true ? 'Required' : null,
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _krakenSecret,
                            decoration: const InputDecoration(
                              labelText: 'API Secret',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.lock),
                            ),
                            obscureText: true,
                            validator: (v) => v?.trim().isEmpty == true ? 'Required' : null,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              ElevatedButton(
                onPressed: _isSaving ? null : _saveKeys,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: Colors.green.shade600,
                ),
                child: _isSaving
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white))
                    : const Text('Save & Activate Arbitrage Scanner', style: TextStyle(fontSize: 16, color: Colors.white)),
              ),

              const SizedBox(height: 12),

              OutlinedButton(
                onPressed: _clearKeys,
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.red,
                  side: const BorderSide(color: Colors.red),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text('Disconnect & Clear All Keys'),
              ),

              const SizedBox(height: 20),
              const Text(
                'Your keys are encrypted in transit and never logged.\nAuto-trading starts immediately after saving.',
                style: TextStyle(fontSize: 12, color: Colors.grey),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _binanceusKey.dispose();
    _binanceusSecret.dispose();
    _krakenKey.dispose();
    _krakenSecret.dispose();
    super.dispose();
  }
}
