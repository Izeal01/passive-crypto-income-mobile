import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart'; // Assuming you're using this for storage; add to pubspec.yaml if not.

class ApiKeysScreen extends StatefulWidget {
  final String userEmail; // Added: Required userEmail parameter

  const ApiKeysScreen({
    super.key,
    required this.userEmail, // FIXED: Added named parameter 'userEmail'
  });

  @override
  State<ApiKeysScreen> createState() => _ApiKeysScreenState();
}

class _ApiKeysScreenState extends State<ApiKeysScreen> {
  // Controllers for API keys (private with _ prefix)
  late TextEditingController _cexKey;
  late TextEditingController _cexSecret;
  late TextEditingController _krakenKey;
  late TextEditingController _krakenSecret;

  // Form key for validation
  final _formKey = GlobalKey<FormState>();

  // Loading state
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    // Initialize controllers
    _cexKey = TextEditingController();
    _cexSecret = TextEditingController();
    _krakenKey = TextEditingController();
    _krakenSecret = TextEditingController();

    // Optional: Load saved values
    _loadSavedKeys();
  }

  // Load saved API keys from SharedPreferences (prefixed by userEmail for multi-user support)
  Future<void> _loadSavedKeys() async {
    final prefs = await SharedPreferences.getInstance();
    final email = widget.userEmail; // Use passed userEmail
    _cexKey.text = prefs.getString('${email}_cex_key') ?? '';
    _cexSecret.text = prefs.getString('${email}_cex_secret') ?? '';
    _krakenKey.text = prefs.getString('${email}_kraken_key') ?? '';
    _krakenSecret.text = prefs.getString('${email}_kraken_secret') ?? '';
    setState(() {}); // Trigger rebuild if needed
  }

  // Save API keys (prefixed by userEmail)
  Future<void> _saveKeys() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);
    final prefs = await SharedPreferences.getInstance();
    final email = widget.userEmail; // Use passed userEmail
    await prefs.setString('${email}_cex_key', _cexKey.text);
    await prefs.setString('${email}_cex_secret', _cexSecret.text);
    await prefs.setString('${email}_kraken_key', _krakenKey.text);
    await prefs.setString('${email}_kraken_secret', _krakenSecret.text);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('API keys saved successfully!')),
      );
      setState(() => _isSaving = false);
    }
  }

  @override
  void dispose() {
    // Dispose controllers (now matching private names)
    _cexKey.dispose();
    _cexSecret.dispose();
    _krakenKey.dispose();
    _krakenSecret.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('API Keys for ${widget.userEmail}'), // Optional: Display email in title
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: SingleChildScrollView(  // Scrollable to handle keyboard
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(  // Fixed: Ensured proper children list with no extra commas/parentheses
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Enter your exchange API keys below for ${widget.userEmail}.', // Updated: Include email
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              // CEX.IO Section (removed Binance reference)
              ExpansionTile(
                title: const Text('CEX.IO'),
                children: [
                  TextFormField(
                    controller: _cexKey,
                    decoration: const InputDecoration(
                      labelText: 'API Key',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) => value?.isEmpty == true ? 'API Key is required' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _cexSecret,
                    decoration: const InputDecoration(
                      labelText: 'API Secret',
                      border: OutlineInputBorder(),
                    ),
                    obscureText: true,
                    validator: (value) => value?.isEmpty == true ? 'API Secret is required' : null,
                  ),
                ],
              ),
              const SizedBox(height: 20),
              // Kraken Section
              ExpansionTile(
                title: const Text('Kraken'),
                children: [
                  TextFormField(
                    controller: _krakenKey,
                    decoration: const InputDecoration(
                      labelText: 'API Key',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) => value?.isEmpty == true ? 'API Key is required' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _krakenSecret,
                    decoration: const InputDecoration(
                      labelText: 'API Secret',
                      border: OutlineInputBorder(),
                    ),
                    obscureText: true,
                    validator: (value) => value?.isEmpty == true ? 'API Secret is required' : null,
                  ),
                ],
              ),
              const SizedBox(height: 30),
              // Save Button
              ElevatedButton(
                onPressed: _isSaving ? null : _saveKeys,
                child: _isSaving
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Save API Keys'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
