class MarketData {
  final String symbol;
  final String name;
  final double price;
  final double change;
  final double changePercent;
  final double high;
  final double low;
  final int volume;
  final DateTime timestamp;

  MarketData({
    required this.symbol,
    required this.name,
    required this.price,
    required this.change,
    required this.changePercent,
    required this.high,
    required this.low,
    required this.volume,
    required this.timestamp,
  });

  factory MarketData.fromJson(Map<String, dynamic> json) {
    return MarketData(
      symbol: json['symbol'] ?? '',
      name: json['name'] ?? '',
      price: (json['price'] ?? 0).toDouble(),
      change: (json['change'] ?? 0).toDouble(),
      changePercent: (json['change_percent'] ?? 0).toDouble(),
      high: (json['high'] ?? 0).toDouble(),
      low: (json['low'] ?? 0).toDouble(),
      volume: json['volume'] ?? 0,
      timestamp: json['timestamp'] != null
          ? DateTime.parse(json['timestamp'])
          : DateTime.now(),
    );
  }
}


class MarketHistory {
  final String symbol;
  final List<HistoryPoint> data;

  MarketHistory({required this.symbol, required this.data});

  factory MarketHistory.fromJson(Map<String, dynamic> json) {
    return MarketHistory(
      symbol: json['symbol'] ?? '',
      data: (json['data'] as List<dynamic>?)
              ?.map((e) => HistoryPoint.fromJson(e))
              .toList() ??
          [],
    );
  }
}

class HistoryPoint {
  final DateTime date;
  final double open;
  final double high;
  final double low;
  final double close;
  final int volume;

  HistoryPoint({
    required this.date,
    required this.open,
    required this.high,
    required this.low,
    required this.close,
    required this.volume,
  });

  factory HistoryPoint.fromJson(Map<String, dynamic> json) {
    return HistoryPoint(
      date: DateTime.parse(json['date']),
      open: (json['open'] ?? 0).toDouble(),
      high: (json['high'] ?? 0).toDouble(),
      low: (json['low'] ?? 0).toDouble(),
      close: (json['close'] ?? 0).toDouble(),
      volume: json['volume'] ?? 0,
    );
  }
}