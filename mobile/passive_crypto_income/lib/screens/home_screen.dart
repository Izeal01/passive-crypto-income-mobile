// lib/screens/home_screen.dart — FINAL & COMPLETE — 15-second updates
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dashboard_screen.dart';
import 'api_keys_screen.dart';
import '../services/api_service.dart';
import 'login_screen.dart';

class HomeScreen extends StatefulWidget {
  final String userEmail;
  const HomeScreen({super.key, required this.userEmail});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  Map<String, dynamic> _arbitrageData = {};
  Map<String, dynamic> _balances = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchData();
    Timer.periodic(const Duration(seconds: 15), (_) {
      if (mounted) _fetchData();
    });
  }

  Future<void> _fetchData() async {
    if (!mounted) return;
    try {
      final arb = await ApiService.fetchArbitrage(widget.userEmail);
      final bal = await ApiService.fetchBalances(widget.userEmail);
      if (mounted) {
        setState(() {
          _arbitrageData = arb;
          _balances = bal;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('user_email');
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final avgPrice = ((_arbitrageData['binanceus'] ?? 0.0) + (_arbitrageData['kraken'] ?? 0.0)) / 2;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Passive Crypto Income'),
        backgroundColor: Colors.green.shade700,
        foregroundColor: Colors.white,
        actions: [
          IconButton(icon: const Icon(Icons.logout, color: Colors.white), onPressed: _logout, tooltip: 'Logout'),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Welcome back!', style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold, color: Colors.grey.shade800)),
              const SizedBox(height: 6),
              Text(widget.userEmail, style: TextStyle(fontSize: 18, color: Colors.grey.shade600)),
              const SizedBox(height: 30),

              Card(
                elevation: 8,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text("XRP/USD Live Price", style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 16),
                      _isLoading
                          ? const Center(child: CircularProgressIndicator())
                          : Column(
                              children: [
                                Text("\$${avgPrice.toStringAsFixed(6)}", style: const TextStyle(fontSize: 36, fontWeight: FontWeight.bold, color: Colors.green)),
                                const SizedBox(height: 12),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                                  children: [
                                    _priceBox("Binance.US", (_arbitrageData['binanceus'] ?? 0.0).toStringAsFixed(6), Colors.blue),
                                    _priceBox("Kraken", (_arbitrageData['kraken'] ?? 0.0).toStringAsFixed(6), Colors.purple),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                Container(
                                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
                                  decoration: BoxDecoration(color: Colors.green.shade50, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.green.shade200)),
                                  child: const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                                    Icon(Icons.autorenew, color: Colors.green, size: 18),
                                    SizedBox(width: 8),
                                    Text("Live • Updated every 15s", style: TextStyle(fontWeight: FontWeight.w600, color: Colors.green)),
                                  ]),
                                ),
                              ],
                            ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 30),

              Card(
                elevation: 6,
                color: Colors.blue.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('USD Balances', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 16),
                      _isLoading
                          ? const Center(child: CircularProgressIndicator())
                          : Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Binance.US: \$${_balances['binanceus_usd']?.toStringAsFixed(2) ?? '0.00'}', style: const TextStyle(fontSize: 18)),
                                Text('Kraken: \$${_balances['kraken_usd']?.toStringAsFixed(2) ?? '0.00'}', style: const TextStyle(fontSize: 18)),
                                const Divider(height: 20),
                                Text('Total: \$${_balances['binanceus_usd'] != null && _balances['kraken_usd'] != null ? (_balances['binanceus_usd'] + _balances['kraken_usd']).toStringAsFixed(2) : '0.00'}', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.green)),
                              ],
                            ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 30),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => DashboardScreen(userEmail: widget.userEmail))),
                  icon: const Icon(Icons.dashboard, size: 28),
                  label: const Text('Open Live Dashboard', style: TextStyle(fontSize: 18)),
                  style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 18), backgroundColor: Colors.green.shade600),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ApiKeysScreen(userEmail: widget.userEmail))),
                  icon: const Icon(Icons.vpn_key),
                  label: const Text('Manage API Keys', style: TextStyle(fontSize: 18)),
                  style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 18), side: BorderSide(color: Colors.green.shade600, width: 2)),
                ),
              ),

              const SizedBox(height: 40),
              const Center(
                child: Text(
                  'Auto-trading runs 24/7 in background\nEven when you log out or close the app',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontStyle: FontStyle.italic, fontSize: 15),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _priceBox(String exchange, String price, Color color) {
    return Column(
      children: [
        Text(exchange, style: const TextStyle(fontSize: 13, color: Colors.grey)),
        const SizedBox(height: 6),
        Text("\$$price", style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: color)),
      ],
    );
  }
}
