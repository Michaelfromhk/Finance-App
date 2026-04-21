import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../models/market.dart';
import 'package:fl_chart/fl_chart.dart';

class MarketScreen extends StatefulWidget {
  const MarketScreen({super.key});

  @override
  State<MarketScreen> createState() => _MarketScreenState();
}

class _MarketScreenState extends State<MarketScreen> {
  final ApiService _apiService = ApiService();
  final TextEditingController _symbolController = TextEditingController();
  
  String? _selectedSymbol;
  MarketData? _marketData;
  MarketHistory? _marketHistory;
  bool _isLoading = false;
  String _selectedPeriod = '1mo';
  final List<String> _defaultSymbols = ['AAPL', 'MSFT', 'GOOGL', 'AMZN', 'SPY', 'BTC-USD', 'EUR/USD', 'GC=F'];

  Future<void> _searchSymbol() async {
    if (_symbolController.text.isEmpty) return;
    
    setState(() {
      _selectedSymbol = _symbolController.text.toUpperCase();
      _isLoading = true;
    });

    try {
      final data = await _apiService.getMarketData(_selectedSymbol!);
      final history = await _apiService.getMarketHistory(_selectedSymbol!, period: _selectedPeriod);
      setState(() {
        _marketData = data;
        _marketHistory = history;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  Future<void> _selectFromDefaults(String symbol) async {
    setState(() {
      _selectedSymbol = symbol;
      _symbolController.text = symbol;
      _isLoading = true;
    });

    try {
      final data = await _apiService.getMarketData(symbol);
      final history = await _apiService.getMarketHistory(symbol, period: _selectedPeriod);
      setState(() {
        _marketData = data;
        _marketHistory = history;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  Future<void> _changePeriod(String period) async {
    if (_selectedSymbol == null) return;
    
    setState(() {
      _selectedPeriod = period;
      _isLoading = true;
    });

    try {
      final history = await _apiService.getMarketHistory(_selectedSymbol!, period: period);
      setState(() {
        _marketHistory = history;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Market Data'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _symbolController,
              decoration: InputDecoration(
                hintText: 'Enter symbol (e.g., AAPL)',
                border: const OutlineInputBorder(),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.search),
                  onPressed: _searchSymbol,
                ),
              ),
              onSubmitted: (_) => _searchSymbol(),
            ),
            const SizedBox(height: 16),
            const Text('Popular Symbols', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: _defaultSymbols.map((symbol) => 
                ActionChip(
                  label: Text(symbol),
                  onPressed: () => _selectFromDefaults(symbol),
                ),
              ).toList(),
            ),
            const SizedBox(height: 24),
            if (_marketData != null) ...[
              _buildPriceCard(),
              const SizedBox(height: 16),
              if (_marketHistory != null) _buildChart(),
            ],
            if (_isLoading) const Center(child: CircularProgressIndicator()),
          ],
        ),
      ),
    );
  }

  Widget _buildPriceCard() {
    final data = _marketData!;
    final isPositive = data.change >= 0;
    final color = isPositive ? Colors.green : Colors.red;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(data.name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    Text(data.symbol, style: TextStyle(color: Colors.grey[600])),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('\$${data.price.toStringAsFixed(2)}', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                    Text(
                      '${isPositive ? '+' : ''}${data.change.toStringAsFixed(2)} (${isPositive ? '+' : ''}${data.changePercent.toStringAsFixed(2)}%)',
                      style: TextStyle(color: color, fontSize: 14),
                    ),
                  ],
                ),
              ],
            ),
            const Divider(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildStat('High', '\$${data.high.toStringAsFixed(2)}'),
                _buildStat('Low', '\$${data.low.toStringAsFixed(2)}'),
                _buildStat('Volume', _formatVolume(data.volume)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStat(String label, String value) {
    return Column(
      children: [
        Text(label, style: TextStyle(color: Colors.grey[600], fontSize: 12)),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildChart() {
    final history = _marketHistory!;
    if (history.data.isEmpty) return const SizedBox();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SegmentedButton<String>(
          segments: const [
            ButtonSegment(value: '1d', label: Text('1D')),
            ButtonSegment(value: '1mo', label: Text('1M')),
            ButtonSegment(value: '3mo', label: Text('3M')),
            ButtonSegment(value: '1y', label: Text('1Y')),
          ],
          selected: {_selectedPeriod},
          onSelectionChanged: (value) => _changePeriod(value.first),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 200,
          child: LineChart(
            LineChartData(
              gridData: const FlGridData(show: false),
              titlesData: const FlTitlesData(show: false),
              borderData: FlBorderData(show: false),
              lineBarsData: [
                LineChartBarData(
                  spots: history.data.asMap().entries.map((e) => 
                    FlSpot(e.key.toDouble(), e.value.close)
                  ).toList(),
                  isCurved: true,
                  color: Colors.blue,
                  barWidth: 2,
                  dotData: const FlDotData(show: false),
                  belowBarData: BarAreaData(
                    show: true,
                    color: Colors.blue.withOpacity(0.1),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  String _formatVolume(int volume) {
    if (volume >= 1000000000) {
      return '${(volume / 1000000000).toStringAsFixed(1)}B';
    } else if (volume >= 1000000) {
      return '${(volume / 1000000).toStringAsFixed(1)}M';
    } else if (volume >= 1000) {
      return '${(volume / 1000).toStringAsFixed(1)}K';
    }
    return volume.toString();
  }

  @override
  void dispose() {
    _symbolController.dispose();
    super.dispose();
  }
}