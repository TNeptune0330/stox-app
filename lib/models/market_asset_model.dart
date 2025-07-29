class MarketAssetModel {
  final String symbol;
  final String name;
  final double price;
  final double change;
  final double changePercent;
  final String type; // 'stock', 'crypto', 'etf'
  final DateTime lastUpdated;

  MarketAssetModel({
    required this.symbol,
    required this.name,
    required this.price,
    required this.change,
    required this.changePercent,
    required this.type,
    required this.lastUpdated,
  });

  factory MarketAssetModel.fromJson(Map<String, dynamic> json) {
    return MarketAssetModel(
      symbol: json['symbol'] as String,
      name: json['name'] as String,
      price: (json['price'] as num).toDouble(),
      change: (json['change'] as num).toDouble(),
      changePercent: (json['change_percent'] as num).toDouble(),
      type: json['type'] as String,
      lastUpdated: DateTime.parse(json['last_updated'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'symbol': symbol,
      'name': name,
      'price': price,
      'change': change,
      'change_percent': changePercent,
      'type': type,
      'last_updated': lastUpdated.toIso8601String(),
    };
  }

  MarketAssetModel copyWith({
    String? symbol,
    String? name,
    double? price,
    double? change,
    double? changePercent,
    String? type,
    DateTime? lastUpdated,
  }) {
    return MarketAssetModel(
      symbol: symbol ?? this.symbol,
      name: name ?? this.name,
      price: price ?? this.price,
      change: change ?? this.change,
      changePercent: changePercent ?? this.changePercent,
      type: type ?? this.type,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }

  bool get isGainer => changePercent > 0;
  bool get isLoser => changePercent < 0;
  bool get isUnchanged => changePercent == 0;

  String get formattedPrice {
    if (price < 1) {
      return '\$${price.toStringAsFixed(4)}';
    } else if (price < 10) {
      return '\$${price.toStringAsFixed(3)}';
    } else {
      return '\$${price.toStringAsFixed(2)}';
    }
  }

  String get formattedChange {
    final sign = change >= 0 ? '+' : '';
    if (change.abs() < 1) {
      return '$sign${change.toStringAsFixed(4)}';
    } else {
      return '$sign${change.toStringAsFixed(2)}';
    }
  }

  String get formattedChangePercent {
    final sign = changePercent >= 0 ? '+' : '';
    return '$sign${changePercent.toStringAsFixed(2)}%';
  }

  @override
  String toString() {
    return 'MarketAssetModel(symbol: $symbol, name: $name, price: $price, change: $change, changePercent: $changePercent, type: $type, lastUpdated: $lastUpdated)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is MarketAssetModel &&
        other.symbol == symbol &&
        other.name == name &&
        other.price == price &&
        other.change == change &&
        other.changePercent == changePercent &&
        other.type == type &&
        other.lastUpdated == lastUpdated;
  }

  @override
  int get hashCode {
    return symbol.hashCode ^
        name.hashCode ^
        price.hashCode ^
        change.hashCode ^
        changePercent.hashCode ^
        type.hashCode ^
        lastUpdated.hashCode;
  }
}