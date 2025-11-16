import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../providers/api_keys_provider.dart';  // Added: For backend sync

class ApiKeysScreen extends StatefulWidget {
  final String userEmail; // Required userEmail parameter

  const ApiKeysScreen({
    super.key,
    required this.userEmail,
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

    // Load saved values via provider (backend first, then local)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = Provider.of<ApiKeysProvider>(context, listen: false);
      provider.loadKeys();  // Triggers notifyListeners to populate controllers
      _loadLocalFallback();  // Immediate local load for UI
    });
  }

  // Load from local as fallback (while provider loads backend)
  Future<void> _loadLocalFallback() async {
    final prefs = await SharedPreferences.getInstance();
    final email = widget.userEmail;
    _cexKey.text = prefs.getString('${email}_cex_key') ?? '';
    _cexSecret.text = prefs.getString('${email}_cex_secret') ?? '';
    _krakenKey.text = prefs.getString('${email}_kraken_key') ?? '';
    _krakenSecret.text = prefs.getString('${email}_kraken_secret') ?? '';
    if (mounted) setState(() {});  // UI update
  }

  // Save via provider (backend + local sync)
  Future<void> _saveKeys() async {
    if (!_formKey.currentState!.validate()) return;

    // Check all fields filled (matches backend requirement)
    if (_cexKey.text.isEmpty || _cexSecret.text.isEmpty || _krakenKey.text.isEmpty || _krakenSecret.text.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please fill all API key fields to enable sync.'), backgroundColor: Colors.orange),
        );
      }
      return;
    }

    setState(() => _isSaving = true);
    final provider = Provider.of<ApiKeysProvider>(context, listen: false);
    final success = await provider.saveKeys(
      _cexKey.text,
      _cexSecret.text,
      _krakenKey.text,
      _krakenSecret.text,
    );

    if (mounted) {
      setState(() => _isSaving = false);
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('API keys saved and synced! Balances will update.'), backgroundColor: Colors.green),
        );
        // Optional: Pop back to Home and refresh balances (if navigated from there)
        // Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Save failed: ${provider.errorMessage}'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  void dispose() {
    // Dispose controllers
    _cexKey.dispose();
    _cexSecret.dispose();
    _krakenKey.dispose();
    _krakenSecret.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ApiKeysProvider>(  // Added: Listen to provider for loading/errors
      builder: (context, provider, child) {
        // Sync controllers to provider state (after load)
        if (provider.cexKey.isNotEmpty) {
          _cexKey.text = provider.cexKey;
          _cexSecret.text = provider.cexSecret;
          _krakenKey.text = provider.krakenKey;
          _krakenSecret.text = provider.krakenSecret;
        }

        return Scaffold(
          appBar: AppBar(
            title: Text('API Keys for ${widget.userEmail}'),
            backgroundColor: Theme.of(context).colorScheme.inversePrimary,
          ),
          body: provider.isLoading
              ? const Center(child: CircularProgressIndicator())
              : provider.errorMessage.isNotEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text('Load Error: ${provider.errorMessage}', style: const TextStyle(color: Colors.red)),
                          ElevatedButton(
                            onPressed: () => provider.loadKeys(),
                            child: const Text('Retry'),
                          ),
                        ],
                      ),
                    )
                  : SingleChildScrollView(
                      padding: const EdgeInsets.all(16.0),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              'Enter your exchange API keys below for ${widget.userEmail}.',
                              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 20),
                            // CEX.IO Section
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
                                  onChanged: (value) => provider.cexKey = value,  // Sync to provider
                                ),
                                const SizedBox(height: 12),
                                TextFormField(
                                  controller: _cexSecret,
                                  decoration: const InputDecoration(
                                    labelText: API Secret',
                                    border: OutlineInputBorder(),
                                  ),
                                  obscureText: true,
                                  validator: (value) => value?.isEmpty == true ? 'API Secret is required' : null,
                                  onChanged: (value) => provider.cexSecret = value,  // Sync to provider
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
                                  onChanged: (value) => provider.krakenKey = value,  // Sync to provider
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
                                  onChanged: (value) => provider.krakenSecret = value,  // Sync to provider
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
                                  : const Text('Save & Sync API Keys'),
                            ),
                          ],
                        ),
                      ),
                    ),
        );
      },
    );
  }
}
