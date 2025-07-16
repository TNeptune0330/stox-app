import 'package:flutter/material.dart';

class Achievement {
  final String id;
  final String title;
  final String description;
  final IconData icon;
  final Color color;
  final int requiredValue;
  final String category;
  final bool isUnlocked;
  final DateTime? unlockedAt;
  final int currentProgress;

  Achievement({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
    required this.requiredValue,
    required this.category,
    this.isUnlocked = false,
    this.unlockedAt,
    this.currentProgress = 0,
  });

  static List<Achievement> getAchievements() {
    return [
      // Trading Volume Achievements
      Achievement(
        id: 'first_trade',
        title: 'First Steps',
        description: 'Complete your first trade',
        icon: Icons.trending_up,
        color: const Color(0xFF27ae60),
        requiredValue: 1,
        category: 'trading',
        isUnlocked: true,
      ),
      Achievement(
        id: 'ten_trades',
        title: 'Getting Started',
        description: 'Complete 10 trades',
        icon: Icons.show_chart,
        color: const Color(0xFF3498db),
        requiredValue: 10,
        category: 'trading',
      ),
      Achievement(
        id: 'hundred_trades',
        title: 'Active Trader',
        description: 'Complete 100 trades',
        icon: Icons.timeline,
        color: const Color(0xFF9b59b6),
        requiredValue: 100,
        category: 'trading',
      ),
      Achievement(
        id: 'thousand_trades',
        title: 'Trading Master',
        description: 'Complete 1,000 trades',
        icon: Icons.auto_graph,
        color: const Color(0xFFf39c12),
        requiredValue: 1000,
        category: 'trading',
      ),

      // Profit Achievements
      Achievement(
        id: 'first_profit',
        title: 'In the Green',
        description: 'Make your first \$1,000 profit',
        icon: Icons.attach_money,
        color: const Color(0xFF27ae60),
        requiredValue: 1000,
        category: 'profit',
      ),
      Achievement(
        id: 'big_profit',
        title: 'Big Winner',
        description: 'Reach \$25,000 net worth',
        icon: Icons.diamond,
        color: const Color(0xFFe74c3c),
        requiredValue: 25000,
        category: 'profit',
      ),
      Achievement(
        id: 'millionaire',
        title: 'Millionaire',
        description: 'Reach \$1,000,000 net worth',
        icon: Icons.military_tech,
        color: const Color(0xFFf39c12),
        requiredValue: 1000000,
        category: 'profit',
      ),

      // Streak Achievements
      Achievement(
        id: 'winning_streak',
        title: 'Hot Streak',
        description: '5 profitable trades in a row',
        icon: Icons.local_fire_department,
        color: const Color(0xFFe74c3c),
        requiredValue: 5,
        category: 'streak',
      ),
      Achievement(
        id: 'marathon_trader',
        title: 'Marathon Trader',
        description: 'Trade for 7 consecutive days',
        icon: Icons.run_circle,
        color: const Color(0xFF9b59b6),
        requiredValue: 7,
        category: 'streak',
      ),

      // Special Achievements
      Achievement(
        id: 'diamond_hands',
        title: 'Diamond Hands',
        description: 'Hold a position for 30 days',
        icon: Icons.diamond_outlined,
        color: const Color(0xFF3498db),
        requiredValue: 30,
        category: 'special',
      ),
      Achievement(
        id: 'diversified',
        title: 'Diversified',
        description: 'Hold 10 different assets',
        icon: Icons.scatter_plot,
        color: const Color(0xFF16a085),
        requiredValue: 10,
        category: 'special',
      ),
      Achievement(
        id: 'crypto_king',
        title: 'Crypto King',
        description: 'Make \$10,000 profit from crypto',
        icon: Icons.currency_bitcoin,
        color: const Color(0xFFf39c12),
        requiredValue: 10000,
        category: 'special',
      ),
    ];
  }

  String get progressText {
    if (isUnlocked) {
      return 'Unlocked!';
    }
    return '$currentProgress / $requiredValue';
  }

  double get progress {
    if (isUnlocked) return 1.0;
    return (currentProgress / requiredValue).clamp(0.0, 1.0);
  }
}