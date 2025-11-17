import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import '../providers/api_keys_provider.dart';  // For auto-refresh listener
import '../services/api_service.dart';
import '../services/websocket_service.dart';  // For real-time WS updates
// Removed unused import 'api_keys_screen.dart'

class DashboardScreen extends StatefulWidget {
  final String userEmail;  // From login
  const DashboardScreen({super.key, required this.userEmail});

  @override
  DashboardScreenState createState() => DashboardScreenState();
}

class DashboardScreenState extends State<DashboardScreen> {  // Public class name
  Map<String, dynamic> _arbitrageData = {};
  Map<String, dynamic> _balances = {};
  bool _autoTradeEnabled = false;
  double _tradeThreshold = 0.0001;  // Default 0.0001 = 0.01%
  double _tradeAmount = 100.0;
  bool _isLoading = true;
  bool _wsLoading = true;  // Separate loading for WS connection
  Timer? _timer;
  StreamSubscription<Map<String, dynamic>>? _wsSubscription;  // For WS stream listener

  @override
  void initState() {
    super.initState();
    _fetchData();
    _timer = Timer.periodic(const Duration(seconds: 10), (_) => _fetchData());  // Less frequent poll (10s) with WS handling real-time
    _getAutoTradeStatus();
    _connectWebSocket();

    // Listen to provider for key changes (auto-refresh data)
    Provider.of<ApiKeysProvider>(context, listen: false).addListener(_onKeysChanged);
  }

  // Auto-refresh on key changes
  void _onKeysChanged() {
    if (mounted) {
      _fetchData();
    }
  }

  void _connectWebSocket() {
    WebSocketService().connect(onData: (wsData) {  // Now defined in service
      debugPrint('WS Update: $wsData');
      if (mounted) {
        setState(() {
          _arbitrageData = wsData;  // Update arbitrage in real-time (e.g., {'opportunity': true, 'spread': 0.005})
          _wsLoading = false;
        });
      }
    });
    _wsSubscription = WebSocketService().stream.listen((wsData) {
      // Fallback listener if connect callback not used; consolidate as needed
      debugPrint('Stream Update: $wsData');
      if (mounted) {
        setState(() {
          _arbitrageData = wsData;
          _wsLoading = false;
        });
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _wsSubscription?.cancel();
    WebSocketService().disconnect();  // Clean disconnect
    // Remove listener
    Provider.of<ApiKeysProvider>(context, listen: false).removeListener(_onKeysChanged);
    super.dispose();
  }

  Future<void> _fetchData() async {
    try {
      final arb = await ApiService.fetchArbitrage(widget.userEmail);  // Pass email, use fetchArbitrage for clarity
      final bal = await ApiService.fetchBalances(widget.userEmail);  // Pass email, use fetchBalances for clarity
      if (mounted) {
        setState(() {
          _arbitrageData = arb;
          _balances = bal;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Fetch Error: $e');  // Non-blocking log
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _getAutoTradeStatus() async {
    // Call /auto_trade_status if needed
    if (mounted) {
      setState(() => _autoTradeEnabled = false);  // Default off
    }
  }

  Future<void> _toggleAutoTrade(bool enabled) async {
    try {
      await ApiService.toggleAutoTrade(enabled, widget.userEmail);
      if (mounted) {
        setState(() => _autoTradeEnabled = enabled);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Auto-Trade ${enabled ? "Enabled" : "Disabled"}'), backgroundColor: enabled ? Colors.green : Colors.orange),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Toggle failed: $e'), backgroundColor: Colors.red));
      }
    }
  }

  Future<void> _setThreshold(double value) async {
    try {
      await ApiService.setTradeThreshold(value, widget.userEmail);  // Use setTradeThreshold for clarity (alias handles old name too)
      if (mounted) {
        setState(() => _tradeThreshold = value);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Threshold set to ${value * 100}%'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Set failed: $e'), backgroundColor: Colors.red));
      }
    }
  }

  Future<void> _setAmount() async {
    final value = _tradeAmount;  // Use current value
    try {
      await ApiService.setAmount(value, widget.userEmail);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Amount set to \$${value.toStringAsFixed(2)}'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Set failed: $e'), backgroundColor: Colors.red));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ApiKeysProvider>(  // Reactive to provider loading
      builder: (context, provider, child) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('Dashboard'),
            backgroundColor: Colors.green,
            // API Keys icon removed (moved to Home screen)
            actions: [
              // No actions needed now
            ],
          ),
          body: provider.isLoading
              ? const Center(child: CircularProgressIndicator())
              : _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : RefreshIndicator(
                      onRefresh: _fetchData,
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Card(
                              child: ListTile(
                                leading: _wsLoading ? const CircularProgressIndicator() : null,  // Conditional spinner for WS
                                title: const Text('Arbitrage'),
                                subtitle: _arbitrageData['error'] != null
                                    ? Text(_arbitrageData['error'], style: const TextStyle(color: Colors.red))
                                    : _arbitrageData['opportunity'] == true
                                        ? Text('Opportunity detected! Spread: ${(_arbitrageData['spread'] ?? 0) * 100}%', style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold))
                                        : Text('No opportunity (Save API keys first?)', style: const TextStyle(color: Colors.orange)),
                              ),
                            ),
                            Card(
                              child: SwitchListTile(
                                title: const Text('Auto Trading'),
                                subtitle: const Text('Toggle to enable profitable trades'),
                                value: _autoTradeEnabled,
                                onChanged: _toggleAutoTrade,
                                secondary: const Icon(Icons.autorenew),
                              ),
                            ),
                            Card(
                              child: Column(
                                children: [
                                  const ListTile(title: Text('Trade Threshold (%)')),
                                  Slider(
                                    value: _tradeThreshold,
                                    min: 0.0,
                                    max: 0.01,  // Up to 1%
                                    divisions: 100,  // Fine steps
                                    onChanged: _setThreshold,
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 16),
                                    child: Text('Current: ${(_tradeThreshold * 100).toStringAsFixed(4)}%'),
                                  ),
                                ],
                              ),
                            ),
                            Card(
                              color: Colors.blue.shade50,
                              child: _balances['error'] != null
                                  ? ListTile(
                                      title: const Text('USD Balances'),  // FIXED: Changed from 'USDT' to 'USD'
                                      subtitle: Text(_balances['error'] ?? 'Loading... (Save API keys first?)', style: const TextStyle(color: Colors.red)),
                                    )
                                  : ListTile(
                                      title: const Text('USD Balances'),  // FIXED: Changed from 'USDT' to 'USD'
                                      subtitle: Text('CEX.IO: \$${_balances['cex_usd']?.toStringAsFixed(2) ?? '0'}\nKraken: \$${_balances['kraken_usd']?.toStringAsFixed(2) ?? '0'}'),
                                    ),
                            ),
                            Card(
                              child: Column(
                                children: [
                                  const ListTile(title: Text('Set Trade Amount (USD)')),  // FIXED: Changed from 'USDT' to 'USD'
                                  Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 16),
                                    child: TextFormField(
                                      decoration: const InputDecoration(
                                        labelText: 'Trade Amount',
                                        prefixText: r'$',  // Raw string r'$' for literal $
                                        prefixIcon: Icon(Icons.account_balance_wallet),
                                        hintText: 'Enter amount (no limit)',
                                      ),
                                      keyboardType: TextInputType.numberWithOptions(decimal: true),
                                      validator: (value) {
                                        if (value == null || value.isEmpty) {
                                          return 'Please enter an amount';
                                        }
                                        final amount = double.tryParse(value);
                                        if (amount == null || amount <= 0) {
                                          return 'Please enter a valid positive amount';
                                        }
                                        return null;  // No upper limit
                                      },
                                      onChanged: (value) {
                                        final amount = double.tryParse(value);
                                        if (amount != null) {
                                          _tradeAmount = amount;
                                        }
                                      },
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  ElevatedButton(
                                    onPressed: _isLoading ? null : _setAmount,
                                    child: _isLoading
                                        ? const CircularProgressIndicator()
                                        : const Text('Set Amount'),
                                  ),
                                ],
                              ),
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
