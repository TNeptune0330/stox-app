class PortfolioModel {
  final String id;
  final String userId;
  final String symbol;
  final int quantity;
  final double avgPrice;
  final DateTime createdAt;
  final DateTime updatedAt;

  PortfolioModel({
    required this.id,
    required this.userId,
    required this.symbol,
    required this.quantity,
    required this.avgPrice,
    required this.createdAt,
    required this.updatedAt,
  });

  factory PortfolioModel.fromJson(Map<String, dynamic> json) {
    return PortfolioModel(
      id: json['id'],
      userId: json['user_id'],
      symbol: json['symbol'],
      quantity: json['quantity'],
      avgPrice: (json['avg_price'] as num).toDouble(),
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'symbol': symbol,
      'quantity': quantity,
      'avg_price': avgPrice,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  double get totalValue => quantity * avgPrice;
  
  double calculatePnL(double currentPrice) {
    return (currentPrice - avgPrice) * quantity;
  }
  
  double calculatePnLPercentage(double currentPrice) {
    return ((currentPrice - avgPrice) / avgPrice) * 100;
  }
  
  PortfolioModel copyWith({
    String? id,
    String? userId,
    String? symbol,
    int? quantity,
    double? avgPrice,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return PortfolioModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      symbol: symbol ?? this.symbol,
      quantity: quantity ?? this.quantity,
      avgPrice: avgPrice ?? this.avgPrice,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}