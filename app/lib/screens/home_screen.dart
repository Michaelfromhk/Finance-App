import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../models/market.dart';
import '../models/prompt.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ApiService _apiService = ApiService();
  final TextEditingController _newsPromptController = TextEditingController();
  bool _isLoadingNews = false;
  String? _newsResult;
  String _selectedProvider = 'google';

  final List<String> _watchlist = ['AAPL', 'MSFT', 'GOOGL', 'AMZN', 'SPY', 'BTC-USD'];
  final Map<String, MarketData> _marketData = {};

  @override
  void initState() {
    super.initState();
    _loadWatchlist();
  }

  Future<void> _loadWatchlist() async {
    for (var symbol in _watchlist) {
      try {
        final data = await _apiService.getMarketData(symbol);
        setState(() {
          _marketData[symbol] = data;
        });
      } catch (e) {
        debugPrint('Error loading $symbol: $e');
      }
    }
  }

  Future<void> _generateNews() async {
    if (_newsPromptController.text.isEmpty) return;
    
    setState(() {
      _isLoadingNews = true;
      _newsResult = null;
    });

    try {
      final result = await _apiService.generateNews(
        _newsPromptController.text,
        _selectedProvider,
      );
      setState(() {
        _newsResult = result['content'] ?? 'No result';
      });
    } catch (e) {
      setState(() {
        _newsResult = 'Error: $e';
      });
    } finally {
      setState(() {
        _isLoadingNews = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Finance App'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: RefreshIndicator(
        onRefresh: _loadWatchlist,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Market Overview',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              _buildWatchlistGrid(),
              const SizedBox(height: 24),
              const Text(
                'Quick News Search',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              _buildNewsSearch(),
              if (_newsResult != null) ...[
                const SizedBox(height: 16),
                _buildNewsResult(),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWatchlistGrid() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 1.8,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: _watchlist.length,
      itemBuilder: (context, index) {
        final symbol = _watchlist[index];
        final data = _marketData[symbol];
        
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: data != null
                ? _buildMarketCard(data)
                : const Center(child: CircularProgressIndicator()),
          ),
        );
      },
    );
  }

  Widget _buildMarketCard(MarketData data) {
    final isPositive = data.change >= 0;
    final color = isPositive ? Colors.green : Colors.red;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          data.symbol,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        Text(
          '\$${data.price.toStringAsFixed(2)}',
          style: const TextStyle(fontSize: 16),
        ),
        Text(
          '${isPositive ? '+' : ''}${data.changePercent.toStringAsFixed(2)}%',
          style: TextStyle(color: color, fontSize: 12),
        ),
      ],
    );
  }

  Widget _buildNewsSearch() {
    return Column(
      children: [
        TextField(
          controller: _newsPromptController,
          decoration: const InputDecoration(
            hintText: 'Enter news topic...',
            border: OutlineInputBorder(),
          ),
          maxLines: 2,
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: SegmentedButton<String>(
                segments: const [
                  ButtonSegment(value: 'google', label: Text('Google')),
                  ButtonSegment(value: 'openai', label: Text('OpenAI')),
                ],
                selected: {_selectedProvider},
                onSelectionChanged: (Set<String> selection) {
                  setState(() {
                    _selectedProvider = selection.first;
                  });
                },
              ),
            ),
            const SizedBox(width: 8),
            ElevatedButton(
              onPressed: _isLoadingNews ? null : _generateNews,
              child: _isLoadingNews
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Search'),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildNewsResult() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Text(_newsResult!),
      ),
    );
  }

  @override
  void dispose() {
    _newsPromptController.dispose();
    super.dispose();
  }
}