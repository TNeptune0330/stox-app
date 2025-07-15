class AssetModel {
  final String symbol;
  final String name;
  final String type;
  final double price;
  final double change24h;
  final double changePercent24h;
  final DateTime lastUpdated;

  AssetModel({
    required this.symbol,
    required this.name,
    required this.type,
    required this.price,
    required this.change24h,
    required this.changePercent24h,
    required this.lastUpdated,
  });

  factory AssetModel.fromJson(Map<String, dynamic> json) {
    return AssetModel(
      symbol: json['symbol'],
      name: json['name'],
      type: json['type'],
      price: (json['price'] as num).toDouble(),
      change24h: (json['change_24h'] as num?)?.toDouble() ?? 0.0,
      changePercent24h: (json['change_percent_24h'] as num?)?.toDouble() ?? 0.0,
      lastUpdated: DateTime.parse(json['last_updated']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'symbol': symbol,
      'name': name,
      'type': type,
      'price': price,
      'change_24h': change24h,
      'change_percent_24h': changePercent24h,
      'last_updated': lastUpdated.toIso8601String(),
    };
  }

  bool get isPositiveChange => changePercent24h >= 0;
  String get formattedPrice => '\$${price.toStringAsFixed(2)}';
  String get formattedChange => changePercent24h >= 0 
      ? '+${changePercent24h.toStringAsFixed(2)}%'
      : '${changePercent24h.toStringAsFixed(2)}%';
}