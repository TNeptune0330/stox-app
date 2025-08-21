class UserModel {
  final String id;
  final String email;
  final String? username;
  final String? displayName;
  final String? avatarUrl;
  final String colorTheme;
  final bool isAdmin;
  final double cashBalance;
  final double initialBalance;
  final double totalDeposited;
  final int totalTrades;
  final double totalProfitLoss;
  final double totalFeesPaid;
  final double maxPortfolioValue;
  final double maxSingleDayGain;
  final double maxSingleDayLoss;
  final int currentStreak;
  final int maxStreak;
  final double winRate;
  final int daysTraded;
  final int monthsActive;
  final List<String> sectorsTraded;
  final List<String> assetTypesTraded;
  final DateTime? firstTradeDate;
  final DateTime? lastTradeDate;
  final DateTime lastActiveDate;
  final int totalAppOpens;
  final int totalScreenTimeMinutes;
  final bool notificationsEnabled;
  final bool darkModeEnabled;
  final bool soundEffectsEnabled;
  final double dailyLossLimit;
  final double positionSizeLimit;
  final DateTime createdAt;
  final DateTime lastLogin;
  final DateTime updatedAt;

  UserModel({
    required this.id,
    required this.email,
    this.username,
    this.displayName,
    this.avatarUrl,
    required this.colorTheme,
    required this.isAdmin,
    required this.cashBalance,
    required this.initialBalance,
    required this.totalDeposited,
    required this.totalTrades,
    required this.totalProfitLoss,
    required this.totalFeesPaid,
    required this.maxPortfolioValue,
    required this.maxSingleDayGain,
    required this.maxSingleDayLoss,
    required this.currentStreak,
    required this.maxStreak,
    required this.winRate,
    required this.daysTraded,
    required this.monthsActive,
    required this.sectorsTraded,
    required this.assetTypesTraded,
    this.firstTradeDate,
    this.lastTradeDate,
    required this.lastActiveDate,
    required this.totalAppOpens,
    required this.totalScreenTimeMinutes,
    required this.notificationsEnabled,
    required this.darkModeEnabled,
    required this.soundEffectsEnabled,
    required this.dailyLossLimit,
    required this.positionSizeLimit,
    required this.createdAt,
    required this.lastLogin,
    required this.updatedAt,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'],
      email: json['email'],
      username: json['username'],
      displayName: json['display_name'],
      avatarUrl: json['avatar_url'],
      colorTheme: json['color_theme'] ?? 'neon_navy',
      isAdmin: json['is_admin'] ?? false,
      cashBalance: (json['cash_balance'] as num?)?.toDouble() ?? 10000.0,
      initialBalance: (json['initial_balance'] as num?)?.toDouble() ?? 10000.0,
      totalDeposited: (json['total_deposited'] as num?)?.toDouble() ?? 10000.0,
      totalTrades: json['total_trades'] ?? 0,
      totalProfitLoss: (json['total_profit_loss'] as num?)?.toDouble() ?? 0.0,
      totalFeesPaid: (json['total_fees_paid'] as num?)?.toDouble() ?? 0.0,
      maxPortfolioValue: (json['max_portfolio_value'] as num?)?.toDouble() ?? 10000.0,
      maxSingleDayGain: (json['max_single_day_gain'] as num?)?.toDouble() ?? 0.0,
      maxSingleDayLoss: (json['max_single_day_loss'] as num?)?.toDouble() ?? 0.0,
      currentStreak: json['current_streak'] ?? 0,
      maxStreak: json['max_streak'] ?? 0,
      winRate: (json['win_rate'] as num?)?.toDouble() ?? 0.0,
      daysTraded: json['days_traded'] ?? 0,
      monthsActive: json['months_active'] ?? 0,
      sectorsTraded: (json['sectors_traded'] as List<dynamic>?)?.cast<String>() ?? [],
      assetTypesTraded: (json['asset_types_traded'] as List<dynamic>?)?.cast<String>() ?? [],
      firstTradeDate: json['first_trade_date'] != null ? DateTime.parse(json['first_trade_date']) : null,
      lastTradeDate: json['last_trade_date'] != null ? DateTime.parse(json['last_trade_date']) : null,
      lastActiveDate: json['last_active_date'] != null 
          ? DateTime.parse(json['last_active_date']) 
          : DateTime.now(),
      totalAppOpens: json['total_app_opens'] ?? 0,
      totalScreenTimeMinutes: json['total_screen_time_minutes'] ?? 0,
      notificationsEnabled: json['notifications_enabled'] ?? true,
      darkModeEnabled: json['dark_mode_enabled'] ?? true,
      soundEffectsEnabled: json['sound_effects_enabled'] ?? true,
      dailyLossLimit: (json['daily_loss_limit'] as num?)?.toDouble() ?? 1000.0,
      positionSizeLimit: (json['position_size_limit'] as num?)?.toDouble() ?? 5000.0,
      createdAt: DateTime.parse(json['created_at']),
      lastLogin: json['last_login'] != null 
          ? DateTime.parse(json['last_login']) 
          : DateTime.now(),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'username': username,
      'display_name': displayName,
      'avatar_url': avatarUrl,
      'color_theme': colorTheme,
      'is_admin': isAdmin,
      'cash_balance': cashBalance,
      'initial_balance': initialBalance,
      'total_deposited': totalDeposited,
      'total_trades': totalTrades,
      'total_profit_loss': totalProfitLoss,
      'total_fees_paid': totalFeesPaid,
      'max_portfolio_value': maxPortfolioValue,
      'max_single_day_gain': maxSingleDayGain,
      'max_single_day_loss': maxSingleDayLoss,
      'current_streak': currentStreak,
      'max_streak': maxStreak,
      'win_rate': winRate,
      'days_traded': daysTraded,
      'months_active': monthsActive,
      'sectors_traded': sectorsTraded,
      'asset_types_traded': assetTypesTraded,
      'first_trade_date': firstTradeDate?.toIso8601String(),
      'last_trade_date': lastTradeDate?.toIso8601String(),
      'last_active_date': lastActiveDate.toIso8601String(),
      'total_app_opens': totalAppOpens,
      'total_screen_time_minutes': totalScreenTimeMinutes,
      'notifications_enabled': notificationsEnabled,
      'dark_mode_enabled': darkModeEnabled,
      'sound_effects_enabled': soundEffectsEnabled,
      'daily_loss_limit': dailyLossLimit,
      'position_size_limit': positionSizeLimit,
      'created_at': createdAt.toIso8601String(),
      'last_login': lastLogin.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  UserModel copyWith({
    String? id,
    String? email,
    String? username,
    String? displayName,
    String? avatarUrl,
    String? colorTheme,
    bool? isAdmin,
    double? cashBalance,
    double? initialBalance,
    double? totalDeposited,
    int? totalTrades,
    double? totalProfitLoss,
    double? totalFeesPaid,
    double? maxPortfolioValue,
    double? maxSingleDayGain,
    double? maxSingleDayLoss,
    int? currentStreak,
    int? maxStreak,
    double? winRate,
    int? daysTraded,
    int? monthsActive,
    List<String>? sectorsTraded,
    List<String>? assetTypesTraded,
    DateTime? firstTradeDate,
    DateTime? lastTradeDate,
    DateTime? lastActiveDate,
    int? totalAppOpens,
    int? totalScreenTimeMinutes,
    bool? notificationsEnabled,
    bool? darkModeEnabled,
    bool? soundEffectsEnabled,
    double? dailyLossLimit,
    double? positionSizeLimit,
    DateTime? createdAt,
    DateTime? lastLogin,
    DateTime? updatedAt,
  }) {
    return UserModel(
      id: id ?? this.id,
      email: email ?? this.email,
      username: username ?? this.username,
      displayName: displayName ?? this.displayName,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      colorTheme: colorTheme ?? this.colorTheme,
      isAdmin: isAdmin ?? this.isAdmin,
      cashBalance: cashBalance ?? this.cashBalance,
      initialBalance: initialBalance ?? this.initialBalance,
      totalDeposited: totalDeposited ?? this.totalDeposited,
      totalTrades: totalTrades ?? this.totalTrades,
      totalProfitLoss: totalProfitLoss ?? this.totalProfitLoss,
      totalFeesPaid: totalFeesPaid ?? this.totalFeesPaid,
      maxPortfolioValue: maxPortfolioValue ?? this.maxPortfolioValue,
      maxSingleDayGain: maxSingleDayGain ?? this.maxSingleDayGain,
      maxSingleDayLoss: maxSingleDayLoss ?? this.maxSingleDayLoss,
      currentStreak: currentStreak ?? this.currentStreak,
      maxStreak: maxStreak ?? this.maxStreak,
      winRate: winRate ?? this.winRate,
      daysTraded: daysTraded ?? this.daysTraded,
      monthsActive: monthsActive ?? this.monthsActive,
      sectorsTraded: sectorsTraded ?? this.sectorsTraded,
      assetTypesTraded: assetTypesTraded ?? this.assetTypesTraded,
      firstTradeDate: firstTradeDate ?? this.firstTradeDate,
      lastTradeDate: lastTradeDate ?? this.lastTradeDate,
      lastActiveDate: lastActiveDate ?? this.lastActiveDate,
      totalAppOpens: totalAppOpens ?? this.totalAppOpens,
      totalScreenTimeMinutes: totalScreenTimeMinutes ?? this.totalScreenTimeMinutes,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      darkModeEnabled: darkModeEnabled ?? this.darkModeEnabled,
      soundEffectsEnabled: soundEffectsEnabled ?? this.soundEffectsEnabled,
      dailyLossLimit: dailyLossLimit ?? this.dailyLossLimit,
      positionSizeLimit: positionSizeLimit ?? this.positionSizeLimit,
      createdAt: createdAt ?? this.createdAt,
      lastLogin: lastLogin ?? this.lastLogin,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() {
    return 'UserModel(id: $id, email: $email, username: $username, cashBalance: $cashBalance)';
  }
}