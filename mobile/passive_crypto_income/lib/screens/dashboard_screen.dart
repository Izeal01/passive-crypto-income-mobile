import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import '../providers/api_keys_provider.dart';
import '../services/api_service.dart';
import '../services/websocket_service.dart';

class DashboardScreen extends StatefulWidget {
  final String userEmail;
  const DashboardScreen({super.key, required this.userEmail});

  @override
  DashboardScreenState createState() => DashboardScreenState();
}

class DashboardScreenState extends State<DashboardScreen> {
  Map<String, dynamic> _arbitrageData = {};
  Map<String, dynamic> _balances = {};
  bool _autoTradeEnabled = false;
  double _tradeThreshold = 0.0001;
  double _tradeAmount = 100.0;
  bool _isLoading = true;
  bool _wsLoading = true;
  Timer? _timer;
  StreamSubscription<Map<String, dynamic>>? _wsSubscription;

  @override
  void initState() {
    super.initState();
    _fetchData();
    // 8-second polling – safe for free CEX.IO & Kraken tiers
    _timer = Timer.periodic(const Duration(seconds: 8), (_) => _fetchData());
    _getAutoTradeStatus();
    _connectWebSocket();

    Provider.of<ApiKeysProvider>(context, listen: false).addListener(_onKeysChanged);
  }

  void _onKeysChanged() {
    if (mounted) _fetchData();
  }

  void _connectWebSocket() {
    WebSocketService().connect(onData: (wsData) {
      if (mounted) {
        setState(() {
          _arbitrageData = wsData;
          _wsLoading = false;
        });
      }
    });
    _wsSubscription = WebSocketService().stream.listen((wsData) {
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
    WebSocketService().disconnect();
    Provider.of<ApiKeysProvider>(context, listen: false).removeListener(_onKeysChanged);
    super.dispose();
  }

  Future<void> _fetchData() async {
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
      debugPrint('Fetch Error: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _getAutoTradeStatus() async {
    // Placeholder – implement if you have real endpoint
    if (mounted) setState(() => _autoTradeEnabled = false);
  }

  Future<void> _toggleAutoTrade(bool enabled) async {
    try {
      await ApiService.toggleAutoTrade(enabled, widget.userEmail);
      if (mounted) {
        setState(() => _autoTradeEnabled = enabled);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Auto-Trade ${enabled ? "Enabled" : "Disabled"}'),
            backgroundColor: enabled ? Colors.green : Colors.orange,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Toggle failed: $e'), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _setThreshold(double value) async {
    try {
      await ApiService.setTradeThreshold(value, widget.userEmail);
      setState(() => _tradeThreshold = value);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Threshold set to ${(value * 100).toStringAsFixed(4)}%'), backgroundColor: Colors.green),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed: $e'), backgroundColor: Colors.red));
    }
  }

  Future<void> _setAmount() async {
    try {
      await ApiService.setAmount(_tradeAmount, widget.userEmail);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Trade amount set to \$${_tradeAmount.toStringAsFixed(2)}'), backgroundColor: Colors.green),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed: $e'), backgroundColor: Colors.red));
    }
  }

  // FINAL: Beautiful arbitrage subtitle with ROI displayed
  Widget _buildArbitrageSubtitle() {
    if (_arbitrageData['error'] != null) {
      return Text(
        _arbitrageData['error'] ?? 'Waiting for data...',
        style: const TextStyle(color: Colors.orange, fontWeight: FontWeight.bold),
      );
    }

    final cex = _arbitrageData['cex']?.toStringAsFixed(6) ?? '—';
    final kraken = _arbitrageData['kraken']?.toStringAsFixed(6) ?? '—';
    final spread = (_arbitrageData['spread_pct'] ?? 0).toStringAsFixed(4);
    final roi = _arbitrageData['roi_usdt'];
    final pnlPct = _arbitrageData['pnl_pct'];
    final isProfitable = (pnlPct ?? 0) > 0 || (roi ?? -999) > 0;

    if (roi != null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("CEX.IO: $cex USDT  •  Kraken: $kraken USD"),
          const SizedBox(height: 6),
          Text(
            "Spread: $spread%  •  Potential Profit: \$${roi.toStringAsFixed(2)}",
            style: TextStyle(
              color: isProfitable ? Colors.green : Colors.red,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ],
      );
    }

    // Fallback when ROI not available (partial data)
    return Text(
      "CEX.IO: $cex USDT  •  Kraken: $kraken USD  •  Spread: $spread%",
      style: const TextStyle(fontSize: 14),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ApiKeysProvider>(
      builder: (context, provider, child) {
        return Scaffold(
          appBar: AppBar(title: const Text('Dashboard'), backgroundColor: Colors.green),
          body: provider.isLoading || _isLoading
              ? const Center(child: CircularProgressIndicator())
              : RefreshIndicator(
                  onRefresh: _fetchData,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Arbitrage Opportunity Card
                        Card(
                          elevation: 4,
                          child: ListTile(
                            leading: _wsLoading
                                ? const CircularProgressIndicator()
                                : const Icon(Icons.swap_horiz, color: Colors.purple, size: 40),
                            title: const Text('Live Arbitrage Opportunity', style: TextStyle(fontWeight: FontWeight.bold)),
                            subtitle: _buildArbitrageSubtitle(),
                          ),
                        ),

                        const SizedBox(height: 10),

                        // Auto Trading Switch
                        Card(
                          child: SwitchListTile(
                            title: const Text('Auto Trading'),
                            subtitle: const Text('Execute profitable trades automatically'),
                            value: _autoTradeEnabled,
                            onChanged: _toggleAutoTrade,
                            secondary: const Icon(Icons.autorenew, color: Colors.blue),
                          ),
                        ),

                        // Trade Threshold
                        Card(
                          child: Column(
                            children: [
                              const ListTile(title: Text('Minimum Profit Threshold (%)')),
                              Slider(
                                value: _tradeThreshold,
                                min: 0.0,
                                max: 0.01,
                                divisions: 100,
                                label: '${(_tradeThreshold * 100).toStringAsFixed(4)}%',
                                onChanged: _setThreshold,
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 16),
                                child: Text('Current: ${(_tradeThreshold * 100).toStringAsFixed(4)}%'),
                              ),
                            ],
                          ),
                        ),

                        // USD Balances
                        Card(
                          color: Colors.blue.shade50,
                          child: _balances['error'] != null
                              ? ListTile(
                                  title: const Text('USD Balances'),
                                  subtitle: Text(_balances['error'], style: const TextStyle(color: Colors.red)),
                                )
                              : ListTile(
                                  title: const Text('Available USD Balances'),
                                  subtitle: Text(
                                    'CEX.IO (USDT): \$${(_balances['cex_usd'] ?? 0).toStringAsFixed(2)}\nKraken (USD): \$${(_balances['kraken_usd'] ?? 0).toStringAsFixed(2)}',
                                    style: const TextStyle(fontSize: 16),
                                  ),
                                ),
                        ),

                        // Set Trade Amount
                        Card(
                          child: Column(
                            children: [
                              const ListTile(title: Text('Trade Amount per Opportunity (USD)')),
                              Padding(
                                padding: const EdgeInsets.all(16),
                                child: TextFormField(
                                  initialValue: _tradeAmount.toStringAsFixed(2),
                                  keyboardType: TextInputType.numberWithOptions(decimal: true),
                                  decoration: const InputDecoration(
                                    prefixText: r'$ ',
                                    labelText: 'Amount',
                                    border: OutlineInputBorder(),
                                  ),
                                  onChanged: (v) => _tradeAmount = double.tryParse(v) ?? _tradeAmount,
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 16),
                                child: SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton(
                                    onPressed: _setAmount,
                                    child: const Text('Update Amount'),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 10),
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
