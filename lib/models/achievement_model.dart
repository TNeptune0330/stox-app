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
      // TRADING ACHIEVEMENTS - Based on number of trades
      Achievement(
        id: 'first_trade',
        title: 'First Steps',
        description: 'Complete your first trade',
        icon: Icons.trending_up,
        color: const Color(0xFF27ae60),
        requiredValue: 1,
        category: 'trading',
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
      Achievement(
        id: 'legendary_trader',
        title: 'Legendary Trader',
        description: 'Complete 10,000 trades',
        icon: Icons.military_tech,
        color: const Color(0xFF8e44ad),
        requiredValue: 10000,
        category: 'trading',
      ),

      // MILESTONE ACHIEVEMENTS - Portfolio milestones and major accomplishments
      Achievement(
        id: 'diversified',
        title: 'Diversified',
        description: 'Hold 10 different assets',
        icon: Icons.scatter_plot,
        color: const Color(0xFF16a085),
        requiredValue: 10,
        category: 'milestone',
      ),
      Achievement(
        id: 'portfolio_watcher',
        title: 'Portfolio Watcher',
        description: 'Check your portfolio 10 times',
        icon: Icons.visibility,
        color: const Color(0xFF3498db),
        requiredValue: 10,
        category: 'milestone',
      ),
      Achievement(
        id: 'market_explorer',
        title: 'Market Explorer',
        description: 'Browse the market 25 times',
        icon: Icons.explore,
        color: const Color(0xFF9b59b6),
        requiredValue: 25,
        category: 'milestone',
      ),
      Achievement(
        id: 'master_of_all',
        title: 'Master of All',
        description: 'Unlock all other achievements',
        icon: Icons.emoji_events,
        color: const Color(0xFFf39c12),
        requiredValue: 1,
        category: 'milestone',
      ),

      // PROFIT ACHIEVEMENTS - Money-based achievements
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
      Achievement(
        id: 'multi_millionaire',
        title: 'Multi-Millionaire',
        description: 'Reach \$10,000,000 net worth',
        icon: Icons.star,
        color: const Color(0xFF8e44ad),
        requiredValue: 10000000,
        category: 'profit',
      ),
      Achievement(
        id: 'billionaire',
        title: 'Billionaire',
        description: 'Reach \$1,000,000,000 net worth',
        icon: Icons.auto_awesome,
        color: const Color(0xFFe74c3c),
        requiredValue: 1000000000,
        category: 'profit',
      ),

      // STREAK ACHIEVEMENTS - Consecutive actions and winning streaks
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
      Achievement(
        id: 'perfectionist',
        title: 'Perfectionist',
        description: '10 profitable trades in a row',
        icon: Icons.star_rate,
        color: const Color(0xFFf39c12),
        requiredValue: 10,
        category: 'streak',
      ),

      // SPECIAL ACHIEVEMENTS - Unique behaviors and special actions
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
        id: 'paper_hands',
        title: 'Paper Hands',
        description: 'Sell a position within 1 hour',
        icon: Icons.flash_on,
        color: const Color(0xFFe67e22),
        requiredValue: 1,
        category: 'special',
      ),
      Achievement(
        id: 'early_bird',
        title: 'Early Bird',
        description: 'Make a trade before 9 AM',
        icon: Icons.wb_sunny,
        color: const Color(0xFFf39c12),
        requiredValue: 1,
        category: 'special',
      ),
      Achievement(
        id: 'night_owl',
        title: 'Night Owl',
        description: 'Make a trade after 10 PM',
        icon: Icons.nightlight_round,
        color: const Color(0xFF9b59b6),
        requiredValue: 1,
        category: 'special',
      ),
      Achievement(
        id: 'weekend_warrior',
        title: 'Weekend Warrior',
        description: 'Make 5 trades on weekends',
        icon: Icons.weekend,
        color: const Color(0xFF059669),
        requiredValue: 5,
        category: 'special',
      ),
      Achievement(
        id: 'high_roller',
        title: 'High Roller',
        description: 'Make a single trade worth \$50,000',
        icon: Icons.casino,
        color: const Color(0xFFdc2626),
        requiredValue: 50000,
        category: 'special',
      ),
      Achievement(
        id: 'penny_pincher',
        title: 'Penny Pincher',
        description: 'Buy 1,000 shares of a stock under \$5',
        icon: Icons.savings,
        color: const Color(0xFF059669),
        requiredValue: 1000,
        category: 'special',
      ),
      Achievement(
        id: 'day_trader',
        title: 'Day Trader',
        description: 'Buy and sell the same stock on the same day',
        icon: Icons.flash_auto,
        color: const Color(0xFFf39c12),
        requiredValue: 1,
        category: 'special',
      ),
      Achievement(
        id: 'swing_trader',
        title: 'Swing Trader',
        description: 'Hold positions for 2-10 days',
        icon: Icons.trending_neutral,
        color: const Color(0xFF3498db),
        requiredValue: 5,
        category: 'special',
      ),
      Achievement(
        id: 'value_investor',
        title: 'Value Investor',
        description: 'Hold a position for 90+ days',
        icon: Icons.schedule,
        color: const Color(0xFF27ae60),
        requiredValue: 90,
        category: 'special',
      ),
    ];
  }

  // Helper methods for achievement tracking
  static List<String> getTechStocks() => [];
  static List<String> getEnergyStocks() => [];
  static List<String> getHealthcareStocks() => [];
  static List<String> getFinancialStocks() => [];
  static List<String> getMemeStocks() => [];
  static List<String> getSP500Stocks() => [];
  static List<String> getETFSymbols() => [];
  static List<String> getDividendStocks() => [];
  static List<String> getSmallCapStocks() => [];
  static List<String> getInternationalStocks() => [];
  static List<String> getConsumerStocks() => [];
}