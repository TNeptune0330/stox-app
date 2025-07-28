class UserModel {
  final String id;
  final String email;
  final String? username;
  final String? avatarUrl;
  final String colorTheme;
  final bool isAdmin;
  final double cashBalance;
  final DateTime createdAt;
  final DateTime updatedAt;

  UserModel({
    required this.id,
    required this.email,
    this.username,
    this.avatarUrl,
    required this.colorTheme,
    required this.isAdmin,
    required this.cashBalance,
    required this.createdAt,
    required this.updatedAt,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'],
      email: json['email'],
      username: json['username'],
      avatarUrl: json['avatar_url'],
      colorTheme: json['color_theme'] ?? 'default',
      isAdmin: json['is_admin'] ?? false,
      cashBalance: (json['cash_balance'] as num).toDouble(),
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'username': username,
      'avatar_url': avatarUrl,
      'color_theme': colorTheme,
      'is_admin': isAdmin,
      'cash_balance': cashBalance,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  UserModel copyWith({
    String? id,
    String? email,
    String? username,
    String? avatarUrl,
    String? colorTheme,
    bool? isAdmin,
    double? cashBalance,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserModel(
      id: id ?? this.id,
      email: email ?? this.email,
      username: username ?? this.username,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      colorTheme: colorTheme ?? this.colorTheme,
      isAdmin: isAdmin ?? this.isAdmin,
      cashBalance: cashBalance ?? this.cashBalance,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}