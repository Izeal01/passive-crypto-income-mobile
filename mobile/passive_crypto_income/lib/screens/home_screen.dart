import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';  // For clearing auth token and fetching balances
import 'dashboard_screen.dart';  // FIXED: Navigate to dedicated Dashboard for consistency (or merge if duplicate)
import 'api_keys_screen.dart';
import 'login_screen.dart';

class HomeScreen extends StatefulWidget {
  final String userEmail;
  const HomeScreen({super.key, required this.userEmail});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _loading = true;
  Map<String, dynamic> _balances = {};  // Added: For displaying balances

  @override
  void initState() {
    super.initState();
    // FIXED: Quick status fetch on entry; full dashboard handles polling/WS
    _fetchBalances();  // Added: Fetch balances on init
    _loading = false;  // FIXED: No async init needed
  }

  // Added: Fetch balances similar to Dashboard
  Future<void> _fetchBalances() async {
    try {
      final bal = await ApiService.fetchBalances(widget.userEmail);
      if (mounted) {
        setState(() {
          _balances = bal;
        });
      }
    } catch (e) {
      debugPrint('Balances fetch error: $e');
      if (mounted) {
        setState(() {
          _balances = {'error': 'Failed to load balances. Ensure API keys are set.'};
        });
      }
    }
  }

  Future<void> _logout() async {
    try {
      // Clear local auth state
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('user_email');
      await prefs.remove('auth_token');
      await ApiService.setAuthToken(null);  // Clear static token

      // Optional: Clear API keys if desired (uncomment if logout should wipe them)
      // await prefs.remove('binance_key');
      // await prefs.remove('binance_secret');
      // await prefs.remove('kraken_key');
      // await prefs.remove('kraken_secret');

      // Navigate to login (pushReplacement to prevent back navigation)
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const LoginScreen()),
        );
      }
    } catch (e) {
      // Handle any clear errors (e.g., show snackbar)
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Logout failed: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Home'),
        actions: [
          // Removed: API Keys icon (moved to body below welcome)
          IconButton(
            icon: const Icon(Icons.dashboard),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => DashboardScreen(userEmail: widget.userEmail)),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _logout,
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(  // Added: Scrollable for added content
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.trending_up, size: 100, color: Colors.green),
                  const SizedBox(height: 16),
                  const Text('Welcome to Passive Crypto Income', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  const Text('Tap Dashboard to get started with arbitrage opportunities', style: TextStyle(fontSize: 16, color: Colors.grey)),
                  const SizedBox(height: 24),  // Spacing below welcome
                  // Added: API Settings button below welcome
                  Card(
                    child: ListTile(
                      leading: const Icon(Icons.key, color: Colors.blue),
                      title: const Text('Manage API Keys'),
                      subtitle: const Text('Set up your CEX.IO and Kraken API credentials'),
                      trailing: const Icon(Icons.arrow_forward_ios),
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => ApiKeysScreen(userEmail: widget.userEmail)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),  // Spacing before balances
                  // Added: Balances Card (similar to Dashboard)
                  Card(
                    color: Colors.blue.shade50,
                    child: _balances['error'] != null
                        ? ListTile(
                            title: const Text('Account Balances'),
                            subtitle: Text(_balances['error'] ?? 'Loading...', style: const TextStyle(color: Colors.red)),
                          )
                        : ListTile(
                            title: const Text('Account Balances'),
                            subtitle: Text(
                              'CEX.IO: \$${_balances['cex_usd']?.toStringAsFixed(2) ?? '0.00'}\nKraken: \$${_balances['kraken_usd']?.toStringAsFixed(2) ?? '0.00'}',
                            ),
                            trailing: IconButton(
                              icon: const Icon(Icons.refresh),
                              onPressed: _fetchBalances,  // Refresh button
                            ),
                          ),
                  ),
                ],
              ),
            ),
    );
  }

  @override
  void dispose() {
    super.dispose();
  }
}
