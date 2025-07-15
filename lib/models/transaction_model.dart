class TransactionModel {
  final String id;
  final String userId;
  final String symbol;
  final String type;
  final int quantity;
  final double price;
  final double totalAmount;
  final DateTime timestamp;

  TransactionModel({
    required this.id,
    required this.userId,
    required this.symbol,
    required this.type,
    required this.quantity,
    required this.price,
    required this.totalAmount,
    required this.timestamp,
  });

  factory TransactionModel.fromJson(Map<String, dynamic> json) {
    return TransactionModel(
      id: json['id'],
      userId: json['user_id'],
      symbol: json['symbol'],
      type: json['type'],
      quantity: json['quantity'],
      price: (json['price'] as num).toDouble(),
      totalAmount: (json['total_amount'] as num).toDouble(),
      timestamp: DateTime.parse(json['timestamp']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'symbol': symbol,
      'type': type,
      'quantity': quantity,
      'price': price,
      'total_amount': totalAmount,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  bool get isBuy => type == 'buy';
  bool get isSell => type == 'sell';
  
  String get formattedPrice => '\$${price.toStringAsFixed(2)}';
  String get formattedTotal => '\$${totalAmount.toStringAsFixed(2)}';
}