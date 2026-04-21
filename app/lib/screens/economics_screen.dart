import 'package:flutter/material.dart';
import '../services/api_service.dart';

class EconomicsScreen extends StatefulWidget {
  const EconomicsScreen({super.key});

  @override
  State<EconomicsScreen> createState() => _EconomicsScreenState();
}

class _EconomicsScreenState extends State<EconomicsScreen> {
  final ApiService _apiService = ApiService();
  List<Map<String, dynamic>> _indicators = [];
  List<Map<String, dynamic>> _bonds = [];
  List<Map<String, dynamic>> _currencies = [];
  List<Map<String, dynamic>> _commodities = [];
  bool _isLoading = true;
  int _selectedTab = 0;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final indicators = await _apiService.getEconomicIndicators();
      final bonds = await _apiService.getBondYields();

      final currencies = await _apiService.getUserCurrencies();
      final commodityList = await _apiService.getUserCommodities();

      List<Map<String, dynamic>> loadedCurrencies = [];
      for (var c in currencies) {
        try {
          final data = await _apiService.getCurrency(c['symbol']);
          if (data['price'] != null) loadedCurrencies.add(data);
        } catch (_) {}
      }

      List<Map<String, dynamic>> loadedCommodities = [];
      for (var c in commodityList) {
        try {
          final data = await _apiService.getCommodity(c['symbol']);
          if (data['price'] != null) loadedCommodities.add(data);
        } catch (_) {}
      }

      setState(() {
        _indicators = indicators;
        _bonds = bonds;
        _currencies = loadedCurrencies;
        _commodities = loadedCommodities;
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

  void _showAddDialog(String type) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Add $type'),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(
            hintText: type == 'Currency' ? 'e.g., EURUSD' : 'e.g., GOLD',
            labelText: type == 'Currency' ? 'Currency Pair' : 'Commodity',
          ),
          textCapitalization: TextCapitalization.characters,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              final symbol = controller.text.toUpperCase().trim();
              if (symbol.isEmpty) return;
              try {
                if (type == 'Currency') {
                  await _apiService.addUserCurrency(symbol);
                } else {
                  await _apiService.addUserCommodity(symbol);
                }
                if (mounted) Navigator.pop(context);
                _loadData();
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error: $e')),
                  );
                }
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _removeItem(String symbol, String type) async {
    try {
      if (type == 'Currency') {
        await _apiService.removeUserCurrency(symbol);
      } else {
        await _apiService.removeUserCommodity(symbol);
      }
      _loadData();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Economics & FICC'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8),
            child: SegmentedButton<int>(
              segments: const [
                ButtonSegment(value: 0, label: Text('Indicators')),
                ButtonSegment(value: 1, label: Text('Bonds')),
                ButtonSegment(value: 2, label: Text('FX')),
                ButtonSegment(value: 3, label: Text('Commodities')),
              ],
              selected: {_selectedTab},
              onSelectionChanged: (value) {
                setState(() => _selectedTab = value.first);
              },
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : RefreshIndicator(
                    onRefresh: _loadData,
                    child: _buildTabContent(),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabContent() {
    switch (_selectedTab) {
      case 0:
        return _buildIndicatorsList();
      case 1:
        return _buildBondsList();
      case 2:
        return _buildCurrenciesList();
      case 3:
        return _buildCommoditiesList();
      default:
        return _buildIndicatorsList();
    }
  }

  Widget _buildIndicatorsList() {
    if (_indicators.isEmpty) {
      return const Center(child: Text('No indicators available'));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _indicators.length,
      itemBuilder: (context, index) {
        final item = _indicators[index];
        final value = item['value'];
        final unit = item['unit'] ?? '';

        return Card(
          child: ListTile(
            title: Text(item['name'] ?? ''),
            subtitle: Text(item['date'] ?? ''),
            trailing: Text(
              value != null ? '${value.toStringAsFixed(2)} $unit' : 'N/A',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        );
      },
    );
  }

  Widget _buildBondsList() {
    if (_bonds.isEmpty) {
      return const Center(child: Text('No bond data available'));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _bonds.length,
      itemBuilder: (context, index) {
        final bond = _bonds[index];
        final yieldVal = bond['yield']?.toDouble();

        return Card(
          child: ListTile(
            title: Text(bond['name'] ?? ''),
            subtitle: Text('Updated: ${bond['date'] ?? ''}'),
            trailing: Text(
              yieldVal != null ? '${yieldVal.toStringAsFixed(2)}%' : 'N/A',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
                color: _getYieldColor(yieldVal),
              ),
            ),
          ),
        );
      },
    );
  }

  Color _getYieldColor(double? yieldVal) {
    if (yieldVal == null) return Colors.grey;
    if (yieldVal < 2) return Colors.blue;
    if (yieldVal < 4) return Colors.green;
    if (yieldVal < 5) return Colors.orange;
    return Colors.red;
  }

  Widget _buildCurrenciesList() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(8),
          child: OutlinedButton.icon(
            onPressed: () => _showAddDialog('Currency'),
            icon: const Icon(Icons.add),
            label: const Text('Add Currency'),
          ),
        ),
        Expanded(
          child: _currencies.isEmpty
              ? const Center(child: Text('No currencies added'))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _currencies.length,
                  itemBuilder: (context, index) {
                    final currency = _currencies[index];
                    final price = currency['price'];
                    final change = (currency['change_percent'] ?? 0).toDouble();
                    final isPositive = change >= 0;
                    final symbol = currency['symbol'] ?? '';

                    return Card(
                      child: ListTile(
                        title: Text(symbol),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  price != null ? price.toStringAsFixed(5) : 'N/A',
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                ),
                                Text(
                                  '${isPositive ? '+' : ''}${change.toStringAsFixed(3)}%',
                                  style: TextStyle(
                                    color: isPositive ? Colors.green : Colors.red,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline, size: 20),
                              onPressed: () => _removeItem(symbol, 'Currency'),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildCommoditiesList() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(8),
          child: OutlinedButton.icon(
            onPressed: () => _showAddDialog('Commodity'),
            icon: const Icon(Icons.add),
            label: const Text('Add Commodity'),
          ),
        ),
        Expanded(
          child: _commodities.isEmpty
              ? const Center(child: Text('No commodities added'))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _commodities.length,
                  itemBuilder: (context, index) {
                    final commodity = _commodities[index];
                    final price = commodity['price'];
                    final change = (commodity['change_percent'] ?? 0).toDouble();
                    final isPositive = change >= 0;
                    final symbol = commodity['symbol'] ?? '';

                    return Card(
                      child: ListTile(
                        title: Text(symbol),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  price != null ? '\$${price.toStringAsFixed(2)}' : 'N/A',
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                ),
                                Text(
                                  '${isPositive ? '+' : ''}${change.toStringAsFixed(2)}%',
                                  style: TextStyle(
                                    color: isPositive ? Colors.green : Colors.red,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline, size: 20),
                              onPressed: () => _removeItem(symbol, 'Commodity'),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}