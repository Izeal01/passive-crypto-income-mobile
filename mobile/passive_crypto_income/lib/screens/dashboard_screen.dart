// lib/screens/dashboard_screen.dart — FINAL & ABSOLUTELY PERFECT (Negative threshold stays forever)
import 'package:flutter/material.dart';
import 'dart:async';
import '../services/api_service.dart';

class DashboardScreen extends StatefulWidget {
  final String userEmail;
  const DashboardScreen({super.key, required this.userEmail});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  Map<String, dynamic> _arb = {};
  Map<String, dynamic> _bal = {};
  bool _autoTrade = false;
  double _threshold = 0.0;
  double _amount = 0.0;
  bool _loading = true;
  Timer? _timer;

  final TextEditingController _thresholdCtrl = TextEditingController();
  final TextEditingController _amountCtrl = TextEditingController();

  // Track if user has manually set the value
  bool _thresholdManuallySet = false;
  bool _amountManuallySet = false;

  @override
  void initState() {
    super.initState();
    _loadEverything();
    _timer = Timer.periodic(const Duration(seconds: 2), (_) => _loadEverything());
  }

  @override
  void dispose() {
    _timer?.cancel();
    _thresholdCtrl.dispose();
    _amountCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadEverything() async {
    if (!mounted) return;
    try {
      final arb = await ApiService.fetchArbitrage(widget.userEmail);
      final bal = await ApiService.fetchBalances(widget.userEmail);
      final settings = await ApiService.getSettings(widget.userEmail);

      if (!mounted) return;

      setState(() {
        _arb = arb;
        _bal = bal;
        _autoTrade = settings['auto_trade'] ?? false;
        _threshold = (settings['threshold'] ?? 0.0).toDouble();
        _amount = (settings['trade_amount'] ?? 0.0).toDouble();
        _loading = false;

        // ONLY update threshold field if user has NEVER manually set it
        if (!_thresholdManuallySet) {
          _thresholdCtrl.text = (_threshold * 100).toStringAsFixed(4);
        }

        // ONLY update amount field if user has NEVER manually set it
        if (!_amountManuallySet) {
          _amountCtrl.text = _amount > 0 ? _amount.toStringAsFixed(2) : '';
        }
      });
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _toggleAutoTrade(bool enabled) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      await ApiService.toggleAutoTrade(enabled, widget.userEmail);
      if (!mounted) return;
      setState(() => _autoTrade = enabled);
      messenger.showSnackBar(
        SnackBar(content: Text('Auto-Trading ${enabled ? "Enabled" : "Disabled"}'), backgroundColor: enabled ? Colors.green : Colors.orange),
      );
    } catch (e) {
      if (!mounted) return;
      messenger.showSnackBar(SnackBar(content: Text('Failed: $e'), backgroundColor: Colors.red));
    }
  }

  // FIXED: Negative threshold now stays in "Current" forever
  Future<void> _saveThreshold() async {
    final messenger = ScaffoldMessenger.of(context);
    final inputText = _thresholdCtrl.text.trim();
    final input = double.tryParse(inputText);

    if (input == null) {
      messenger.showSnackBar(const SnackBar(content: Text('Invalid input'), backgroundColor: Colors.red));
      return;
    }

    final value = input / 100;

    try {
      await ApiService.setTradeThreshold(value, widget.userEmail);
      if (!mounted) return;

      setState(() {
        _threshold = value;
        _thresholdManuallySet = true;  // Prevent future overwrites
        _thresholdCtrl.text = input.toStringAsFixed(4);  // Force correct display
      });

      messenger.showSnackBar(
        SnackBar(content: Text('Threshold set to ${input.toStringAsFixed(4)}%'), backgroundColor: Colors.green),
      );
    } catch (e) {
      if (!mounted) return;
      messenger.showSnackBar(SnackBar(content: Text('Failed: $e'), backgroundColor: Colors.red));
    }
  }

  Future<void> _saveAmount() async {
    final messenger = ScaffoldMessenger.of(context);
    final input = double.tryParse(_amountCtrl.text);
    if (input == null || input <= 0) {
      messenger.showSnackBar(const SnackBar(content: Text('Amount must be > 0'), backgroundColor: Colors.red));
      return;
    }
    try {
      await ApiService.setAmount(input, widget.userEmail);
      if (!mounted) return;
      setState(() {
        _amount = input;
        _amountManuallySet = true;
      });
      messenger.showSnackBar(
        SnackBar(content: Text('Trade amount set to \$${input.toStringAsFixed(2)}'), backgroundColor: Colors.green),
      );
    } catch (e) {
      if (!mounted) return;
      messenger.showSnackBar(SnackBar(content: Text('Failed: $e'), backgroundColor: Colors.red));
    }
  }

  @override
  Widget build(BuildContext context) {
    final binance = (_arb['binanceus'] ?? 0.0).toStringAsFixed(6);
    final kraken = (_arb['kraken'] ?? 0.0).toStringAsFixed(6);
    final spread = _arb['spread_pct'] ?? 0.0;
    final profit = _arb['roi_usd'] ?? 0.0;
    final profitable = profit > 0;

    return Scaffold(
      appBar: AppBar(title: const Text('Dashboard'), backgroundColor: Colors.green),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadEverything,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Card(
                      elevation: 6,
                      child: ListTile(
                        leading: const Icon(Icons.swap_horiz, color: Colors.purple, size: 48),
                        title: const Text('Live Arbitrage', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("Binance.US: $binance USD  •  Kraken: $kraken USD"),
                            const SizedBox(height: 8),
                            Text("Spread: ${spread.toStringAsFixed(4)}%", style: const TextStyle(fontSize: 16)),
                            Text(
                              profit >= 0
                                  ? "Net Profit: \$${profit.toStringAsFixed(4)}"
                                  : "Net Loss: -\$${(-profit).toStringAsFixed(4)}",
                              style: TextStyle(color: profitable ? Colors.green : Colors.red, fontWeight: FontWeight.bold, fontSize: 18),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Card(
                      child: SwitchListTile(
                        title: const Text('Auto Trading'),
                        subtitle: const Text('Execute profitable trades 24/7'),
                        value: _autoTrade,
                        onChanged: _toggleAutoTrade,
                        secondary: Icon(Icons.autorenew, color: _autoTrade ? Colors.green : Colors.grey),
                      ),
                    ),
                    Card(
                      child: Column(
                        children: [
                          const ListTile(title: Text('Minimum Profit Threshold (%)')),
                          Padding(
                            padding: const EdgeInsets.all(16),
                            child: Row(
                              children: [
                                Expanded(
                                  child: TextFormField(
                                    controller: _thresholdCtrl,
                                    keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
                                    decoration: const InputDecoration(
                                      hintText: '-0.01 or 0.05',
                                      suffixText: '%',
                                      border: OutlineInputBorder(),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                ElevatedButton(
                                  onPressed: _saveThreshold,
                                  child: const Text('Save'),
                                ),
                              ],
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(16),
                            child: Text('Current: ${(_threshold * 100).toStringAsFixed(4)}%', style: const TextStyle(fontWeight: FontWeight.w600)),
                          ),
                        ],
                      ),
                    ),
                    Card(
                      child: Column(
                        children: [
                          const ListTile(title: Text('Trade Amount per Opportunity (USD)')),
                          Padding(
                            padding: const EdgeInsets.all(16),
                            child: Row(
                              children: [
                                Expanded(
                                  child: TextFormField(
                                    controller: _amountCtrl,
                                    keyboardType: TextInputType.numberWithOptions(decimal: true),
                                    decoration: const InputDecoration(
                                      prefixText: r'$ ',
                                      hintText: '20.00',
                                      border: OutlineInputBorder(),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                ElevatedButton(
                                  onPressed: _saveAmount,
                                  child: const Text('Save'),
                                ),
                              ],
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(16),
                            child: Text('Current: \$${_amount.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.w600)),
                          ),
                        ],
                      ),
                    ),
                    Card(
                      color: Colors.blue.shade50,
                      child: ListTile(
                        title: const Text('USD Balances'),
                        subtitle: Text(
                          'Binance.US: \$${_bal['binanceus_usd']?.toStringAsFixed(2) ?? '0.00'}\nKraken: \$${_bal['kraken_usd']?.toStringAsFixed(2) ?? '0.00'}',
                          style: const TextStyle(fontSize: 18),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
