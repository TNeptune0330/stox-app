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
        category: 'portfolio',
      ),
      Achievement(
        id: 'diversified',
        title: 'Diversified',
        description: 'Hold 10 different assets',
        icon: Icons.scatter_plot,
        color: const Color(0xFF16a085),
        requiredValue: 10,
        category: 'portfolio',
      ),
      Achievement(
        id: 'crypto_king',
        title: 'Crypto King',
        description: 'Make \$10,000 profit from crypto',
        icon: Icons.currency_bitcoin,
        color: const Color(0xFFf39c12),
        requiredValue: 10000,
        category: 'portfolio',
      ),
      Achievement(
        id: 'paper_hands',
        title: 'Paper Hands',
        description: 'Sell a position within 1 hour',
        icon: Icons.flash_on,
        color: const Color(0xFFe74c3c),
        requiredValue: 1,
        category: 'portfolio',
      ),
      Achievement(
        id: 'early_bird',
        title: 'Early Bird',
        description: 'Make a trade before 9:00 AM',
        icon: Icons.wb_sunny,
        color: const Color(0xFFf39c12),
        requiredValue: 1,
        category: 'portfolio',
      ),
      Achievement(
        id: 'night_owl',
        title: 'Night Owl',
        description: 'Make a trade after 10:00 PM',
        icon: Icons.nightlight,
        color: const Color(0xFF6b46c1),
        requiredValue: 1,
        category: 'portfolio',
      ),
      Achievement(
        id: 'weekend_warrior',
        title: 'Weekend Warrior',
        description: 'Make 5 trades on weekends',
        icon: Icons.weekend,
        color: const Color(0xFF059669),
        requiredValue: 5,
        category: 'portfolio',
      ),
      Achievement(
        id: 'high_roller',
        title: 'High Roller',
        description: 'Make a single trade worth \$50,000',
        icon: Icons.casino,
        color: const Color(0xFFdc2626),
        requiredValue: 50000,
        category: 'portfolio',
      ),
      Achievement(
        id: 'penny_pincher',
        title: 'Penny Pincher',
        description: 'Buy 1,000 shares of a stock under \$5',
        icon: Icons.savings,
        color: const Color(0xFF059669),
        requiredValue: 1000,
        category: 'portfolio',
      ),
      Achievement(
        id: 'tech_giant',
        title: 'Tech Giant',
        description: 'Hold positions in 5 different tech stocks',
        icon: Icons.computer,
        color: const Color(0xFF3b82f6),
        requiredValue: 5,
        category: 'sectors',
      ),
      Achievement(
        id: 'energy_investor',
        title: 'Energy Investor',
        description: 'Hold positions in 3 different energy stocks',
        icon: Icons.bolt,
        color: const Color(0xFFf59e0b),
        requiredValue: 3,
        category: 'portfolio',
      ),
      Achievement(
        id: 'healthcare_hero',
        title: 'Healthcare Hero',
        description: 'Hold positions in 3 different healthcare stocks',
        icon: Icons.health_and_safety,
        color: const Color(0xFF10b981),
        requiredValue: 3,
        category: 'portfolio',
      ),
      Achievement(
        id: 'financial_wizard',
        title: 'Financial Wizard',
        description: 'Hold positions in 3 different financial stocks',
        icon: Icons.account_balance,
        color: const Color(0xFF8b5cf6),
        requiredValue: 3,
        category: 'portfolio',
      ),
      Achievement(
        id: 'dividend_hunter',
        title: 'Dividend Hunter',
        description: 'Hold 5 dividend-paying stocks',
        icon: Icons.monetization_on,
        color: const Color(0xFF059669),
        requiredValue: 5,
        category: 'portfolio',
      ),
      Achievement(
        id: 'value_investor',
        title: 'Value Investor',
        description: 'Hold a position for 90 days',
        icon: Icons.trending_up,
        color: const Color(0xFF6366f1),
        requiredValue: 90,
        category: 'portfolio',
      ),
      Achievement(
        id: 'momentum_trader',
        title: 'Momentum Trader',
        description: 'Make 20 trades in a single day',
        icon: Icons.speed,
        color: const Color(0xFFf59e0b),
        requiredValue: 20,
        category: 'portfolio',
      ),
      Achievement(
        id: 'swing_trader',
        title: 'Swing Trader',
        description: 'Complete 50 trades within 7 days',
        icon: Icons.swap_horiz,
        color: const Color(0xFF8b5cf6),
        requiredValue: 50,
        category: 'portfolio',
      ),
      Achievement(
        id: 'market_timer',
        title: 'Market Timer',
        description: 'Buy low and sell high on the same stock in one day',
        icon: Icons.schedule,
        color: const Color(0xFF10b981),
        requiredValue: 1,
        category: 'portfolio',
      ),
      Achievement(
        id: 'risk_taker',
        title: 'Risk Taker',
        description: 'Put 50% of portfolio in a single stock',
        icon: Icons.warning,
        color: const Color(0xFFdc2626),
        requiredValue: 50,
        category: 'portfolio',
      ),
      Achievement(
        id: 'conservative',
        title: 'Conservative',
        description: 'Keep 30% of portfolio in cash',
        icon: Icons.shield,
        color: const Color(0xFF6b7280),
        requiredValue: 30,
        category: 'portfolio',
      ),
      Achievement(
        id: 'comeback_kid',
        title: 'Comeback Kid',
        description: 'Recover from a 50% portfolio loss',
        icon: Icons.arrow_upward,
        color: const Color(0xFF059669),
        requiredValue: 50,
        category: 'portfolio',
      ),
      Achievement(
        id: 'loss_leader',
        title: 'Expensive Lesson',
        description: 'Lose \$10,000 in a single trade',
        icon: Icons.trending_down,
        color: const Color(0xFFdc2626),
        requiredValue: 10000,
        category: 'portfolio',
      ),
      Achievement(
        id: 'day_trader',
        title: 'Day Trader',
        description: 'Complete 100 same-day buy/sell trades',
        icon: Icons.today,
        color: const Color(0xFFf59e0b),
        requiredValue: 100,
        category: 'portfolio',
      ),
      Achievement(
        id: 'blue_chip',
        title: 'Blue Chip Collector',
        description: 'Hold positions in 10 S&P 500 stocks',
        icon: Icons.star,
        color: const Color(0xFF3b82f6),
        requiredValue: 10,
        category: 'portfolio',
      ),
      Achievement(
        id: 'small_cap',
        title: 'Small Cap Explorer',
        description: 'Hold positions in 5 small-cap stocks',
        icon: Icons.explore,
        color: const Color(0xFF8b5cf6),
        requiredValue: 5,
        category: 'portfolio',
      ),
      Achievement(
        id: 'international',
        title: 'Global Investor',
        description: 'Hold positions in 3 international stocks',
        icon: Icons.public,
        color: const Color(0xFF06b6d4),
        requiredValue: 3,
        category: 'portfolio',
      ),
      Achievement(
        id: 'meme_lord',
        title: 'Meme Lord',
        description: 'Hold positions in 3 meme stocks',
        icon: Icons.sentiment_very_satisfied,
        color: const Color(0xFFf59e0b),
        requiredValue: 3,
        category: 'portfolio',
      ),
      Achievement(
        id: 'etf_fan',
        title: 'ETF Enthusiast',
        description: 'Hold positions in 5 different ETFs',
        icon: Icons.account_tree,
        color: const Color(0xFF10b981),
        requiredValue: 5,
        category: 'portfolio',
      ),
      Achievement(
        id: 'options_trader',
        title: 'Options Trader',
        description: 'Complete 10 options trades',
        icon: Icons.tune,
        color: const Color(0xFF8b5cf6),
        requiredValue: 10,
        category: 'portfolio',
      ),
      Achievement(
        id: 'volatility_surfer',
        title: 'Volatility Surfer',
        description: 'Trade during high volatility periods',
        icon: Icons.waves,
        color: const Color(0xFF06b6d4),
        requiredValue: 1,
        category: 'portfolio',
      ),
      Achievement(
        id: 'earnings_player',
        title: 'Earnings Player',
        description: 'Trade around 5 earnings announcements',
        icon: Icons.announcement,
        color: const Color(0xFFf59e0b),
        requiredValue: 5,
        category: 'portfolio',
      ),
      Achievement(
        id: 'sector_rotator',
        title: 'Sector Rotator',
        description: 'Hold positions in 8 different sectors',
        icon: Icons.rotate_right,
        color: const Color(0xFF8b5cf6),
        requiredValue: 8,
        category: 'portfolio',
      ),
      Achievement(
        id: 'market_maker',
        title: 'Market Maker',
        description: 'Place 1,000 limit orders',
        icon: Icons.settings,
        color: const Color(0xFF6b7280),
        requiredValue: 1000,
        category: 'portfolio',
      ),
      Achievement(
        id: 'iron_stomach',
        title: 'Iron Stomach',
        description: 'Hold through a 30% market crash',
        icon: Icons.fitness_center,
        color: const Color(0xFF374151),
        requiredValue: 30,
        category: 'portfolio',
      ),
      Achievement(
        id: 'bull_market',
        title: 'Bull Market Rider',
        description: 'Achieve 100% portfolio gain',
        icon: Icons.trending_up,
        color: const Color(0xFF059669),
        requiredValue: 100,
        category: 'portfolio',
      ),
      Achievement(
        id: 'bear_market',
        title: 'Bear Market Survivor',
        description: 'Maintain positive returns during market downturn',
        icon: Icons.trending_down,
        color: const Color(0xFF6b7280),
        requiredValue: 1,
        category: 'portfolio',
      ),
      Achievement(
        id: 'contrarian',
        title: 'Contrarian',
        description: 'Buy when everyone else is selling',
        icon: Icons.arrow_back,
        color: const Color(0xFF8b5cf6),
        requiredValue: 1,
        category: 'portfolio',
      ),
      Achievement(
        id: 'social_trader',
        title: 'Social Trader',
        description: 'Follow 10 other traders',
        icon: Icons.group,
        color: const Color(0xFF06b6d4),
        requiredValue: 10,
        category: 'portfolio',
      ),
      Achievement(
        id: 'research_master',
        title: 'Research Master',
        description: 'Read 100 company reports',
        icon: Icons.library_books,
        color: const Color(0xFF6366f1),
        requiredValue: 100,
        category: 'portfolio',
      ),
      Achievement(
        id: 'news_junkie',
        title: 'News Junkie',
        description: 'Read 500 market news articles',
        icon: Icons.newspaper,
        color: const Color(0xFF374151),
        requiredValue: 500,
        category: 'portfolio',
      ),
      Achievement(
        id: 'chart_master',
        title: 'Chart Master',
        description: 'Analyze 1,000 stock charts',
        icon: Icons.analytics,
        color: const Color(0xFF10b981),
        requiredValue: 1000,
        category: 'portfolio',
      ),
      Achievement(
        id: 'algorithm_beater',
        title: 'Algorithm Beater',
        description: 'Outperform the market by 20%',
        icon: Icons.smart_toy,
        color: const Color(0xFFf59e0b),
        requiredValue: 20,
        category: 'portfolio',
      ),
      Achievement(
        id: 'multi_millionaire',
        title: 'Multi-Millionaire',
        description: 'Reach \$10,000,000 net worth',
        icon: Icons.diamond,
        color: const Color(0xFFf59e0b),
        requiredValue: 10000000,
        category: 'profit',
      ),
      Achievement(
        id: 'billionaire',
        title: 'Billionaire',
        description: 'Reach \$1,000,000,000 net worth',
        icon: Icons.star,
        color: const Color(0xFFf59e0b),
        requiredValue: 1000000000,
        category: 'profit',
      ),
      Achievement(
        id: 'perfectionist',
        title: 'Perfectionist',
        description: 'Complete 100 profitable trades in a row',
        icon: Icons.emoji_events,
        color: const Color(0xFFf59e0b),
        requiredValue: 100,
        category: 'streak',
      ),
      Achievement(
        id: 'legendary_trader',
        title: 'Legendary Trader',
        description: 'Complete 10,000 trades',
        icon: Icons.auto_awesome,
        color: const Color(0xFFf59e0b),
        requiredValue: 10000,
        category: 'trading',
      ),
      Achievement(
        id: 'master_of_all',
        title: 'Master of All',
        description: 'Unlock all other achievements',
        icon: Icons.emoji_events,
        color: const Color(0xFFf59e0b),
        requiredValue: 1,
        category: 'portfolio',
      ),
    ];
  }

  static List<String> getTechStocks() {
    return ['AAPL', 'MSFT', 'GOOGL', 'AMZN', 'META', 'TSLA', 'NVDA', 'NFLX', 'ADBE', 'CRM', 'INTC', 'CSCO', 'ORCL', 'AMD', 'IBM'];
  }

  static List<String> getEnergyStocks() {
    return ['XOM', 'CVX', 'COP', 'EOG', 'SLB', 'KMI', 'VLO', 'PSX', 'MPC', 'OXY'];
  }

  static List<String> getHealthcareStocks() {
    return ['JNJ', 'UNH', 'PFE', 'ABT', 'TMO', 'LLY', 'ABBV', 'MDT', 'BMY', 'GILD'];
  }

  static List<String> getFinancialStocks() {
    return ['JPM', 'BAC', 'WFC', 'GS', 'MS', 'V', 'MA', 'AXP', 'C', 'BLK'];
  }

  static List<String> getMemeStocks() {
    return ['GME', 'AMC', 'BB', 'NOK', 'SNDL', 'PLTR', 'NIO', 'WISH'];
  }

  static List<String> getSP500Stocks() {
    return ['AAPL', 'MSFT', 'AMZN', 'GOOGL', 'TSLA', 'META', 'NVDA', 'JPM', 'V', 'WMT', 'JNJ', 'UNH', 'HD', 'PG', 'MA', 'NFLX', 'ADBE', 'CRM'];
  }

  static List<String> getConsumerStocks() {
    return ['WMT', 'HD', 'PG', 'KO', 'PEP', 'COST', 'NKE', 'SBUX', 'MCD', 'LOW'];
  }

  static List<String> getCryptoSymbols() {
    return ['BTC', 'ETH', 'BNB', 'ADA', 'SOL', 'DOT', 'AVAX', 'LINK', 'UNI', 'MATIC'];
  }

  static List<String> getETFSymbols() {
    return ['SPY', 'QQQ', 'IWM', 'VTI', 'EFA', 'VEA', 'VWO', 'GLD', 'SLV', 'TLT'];
  }

  static List<String> getDividendStocks() {
    return ['JNJ', 'KO', 'PG', 'PEP', 'WMT', 'V', 'MA', 'JPM', 'UNH', 'HD'];
  }

  static List<String> getSmallCapStocks() {
    // These would typically be smaller companies - using some examples
    return ['IWM']; // Small cap ETF as proxy
  }

  static List<String> getInternationalStocks() {
    return ['EFA', 'VEA', 'VWO']; // International ETFs as proxy
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