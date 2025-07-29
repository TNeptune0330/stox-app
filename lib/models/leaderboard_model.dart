class LeaderboardEntry {
  final String id;
  final String username;
  final String? avatarUrl;
  final double netWorth;
  final double totalPnL;
  final double totalPnLPercentage;
  final int totalTrades;
  final int rank;
  final DateTime lastUpdated;

  LeaderboardEntry({
    required this.id,
    required this.username,
    this.avatarUrl,
    required this.netWorth,
    required this.totalPnL,
    required this.totalPnLPercentage,
    required this.totalTrades,
    required this.rank,
    required this.lastUpdated,
  });

  factory LeaderboardEntry.fromJson(Map<String, dynamic> json) {
    return LeaderboardEntry(
      id: json['id'],
      username: json['username'] ?? 'Anonymous Trader',
      avatarUrl: json['avatar_url'],
      netWorth: (json['net_worth'] as num).toDouble(),
      totalPnL: (json['total_pnl'] as num).toDouble(),
      totalPnLPercentage: (json['total_pnl_percentage'] as num).toDouble(),
      totalTrades: json['total_trades'] ?? 0,
      rank: json['rank'] ?? 0,
      lastUpdated: DateTime.parse(json['last_updated']),
    );
  }

  // Create mock leaderboard data
  static List<LeaderboardEntry> getMockLeaderboard() {
    final mockData = [
      {'name': 'Wolf of Wall St', 'worth': 25000, 'pnl': 15000, 'trades': 150},
      {'name': 'Crypto King', 'worth': 22500, 'pnl': 12500, 'trades': 120},
      {'name': 'Stock Ninja', 'worth': 20000, 'pnl': 10000, 'trades': 89},
      {'name': 'Bull Runner', 'worth': 18750, 'pnl': 8750, 'trades': 95},
      {'name': 'Market Maverick', 'worth': 17500, 'pnl': 7500, 'trades': 67},
      {'name': 'Trading Titan', 'worth': 16250, 'pnl': 6250, 'trades': 78},
      {'name': 'Profit Prophet', 'worth': 15000, 'pnl': 5000, 'trades': 56},
      {'name': 'Gold Getter', 'worth': 13750, 'pnl': 3750, 'trades': 45},
      {'name': 'Diamond Hands', 'worth': 12500, 'pnl': 2500, 'trades': 34},
      {'name': 'Rocket Rider', 'worth': 11250, 'pnl': 1250, 'trades': 23},
    ];

    return mockData.asMap().entries.map((entry) {
      final index = entry.key;
      final data = entry.value;
      
      return LeaderboardEntry(
        id: 'mock_${index + 1}',
        username: data['name'] as String,
        avatarUrl: null,
        netWorth: (data['worth'] as num).toDouble(),
        totalPnL: (data['pnl'] as num).toDouble(),
        totalPnLPercentage: ((data['pnl'] as num).toDouble() / 10000) * 100,
        totalTrades: data['trades'] as int,
        rank: index + 1,
        lastUpdated: DateTime.now(),
      );
    }).toList();
  }

  String get formattedNetWorth => '\$${netWorth.toStringAsFixed(2)}';
  String get formattedPnL => totalPnL >= 0 
      ? '+\$${totalPnL.toStringAsFixed(2)}'
      : '-\$${totalPnL.abs().toStringAsFixed(2)}';
  String get formattedPnLPercentage => totalPnLPercentage >= 0 
      ? '+${totalPnLPercentage.toStringAsFixed(1)}%'
      : '${totalPnLPercentage.toStringAsFixed(1)}%';
}