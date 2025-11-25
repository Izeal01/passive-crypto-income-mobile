// lib/screens/home_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/api_keys_provider.dart';
import '../services/api_service.dart';
import 'api_keys_screen.dart';
import 'dashboard_screen.dart';

class HomeScreen extends StatefulWidget {
  final String userEmail;
  const HomeScreen({super.key, required this.userEmail});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _hasKeys = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _checkApiKeys();
  }

  Future<void> _checkApiKeys() async {
    if (!mounted) return;

    setState(() => _isLoading = true);

    try {
      final keys = await ApiService.getKeys(widget.userEmail);
      final hasKeys = keys['cex_key'] != null && keys['kraken_key'] != null;

      if (!mounted) return;
      setState(() {
        _hasKeys = hasKeys;
        _isLoading = false;
      });

      // Update provider so dashboard knows keys are saved
      Provider.of<ApiKeysProvider>(context, listen: false).setKeysSaved(hasKeys);
    } catch (e) {
      debugPrint('Error checking API keys: $e');
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  Future<void> _openApiKeysScreen() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ApiKeysScreen(userEmail: widget.userEmail),
      ),
    );

    // Prevent context usage after async gap
    if (!mounted) return;
    if (result == true) {
      _checkApiKeys(); // Refresh key status after update
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Passive Crypto Income'),
        backgroundColor: Colors.green,
        elevation: 4,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: _hasKeys
              ? Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.check_circle, color: Colors.green, size: 100),
                    const SizedBox(height: 24),
                    const Text(
                      'API Keys Connected',
                      style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'You\'re ready to monitor arbitrage opportunities!',
                      style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 40),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              builder: (_) => DashboardScreen(userEmail: widget.userEmail),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          backgroundColor: Colors.green,
                        ),
                        child: const Text('Go to Dashboard', style: TextStyle(fontSize: 18)),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextButton(
                      onPressed: _openApiKeysScreen,
                      child: const Text('Replace API Keys'),
                    ),
                  ],
                )
              : Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.vpn_key_off, size: 100, color: Colors.grey),
                    const SizedBox(height: 24),
                    const Text(
                      'No API Keys Found',
                      style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Connect your CEX.IO and Kraken accounts to start earning passive income.',
                      style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 40),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _openApiKeysScreen,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          backgroundColor: Colors.green,
                        ),
                        child: const Text('Connect Exchanges', style: TextStyle(fontSize: 18)),
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}
