import 'package:flutter/foundation.dart';
import '../models/achievement_model.dart';
import '../services/local_database_service.dart';
import '../services/achievement_service.dart';
import '../services/connection_manager.dart';

class AchievementProvider with ChangeNotifier {
  final AchievementService _achievementService = AchievementService();
  final ConnectionManager _connectionManager = ConnectionManager();
  List<Achievement> _achievements = [];
  Map<String, int> _userProgress = {};
  Set<String> _unlockedAchievements = {};
  Map<String, DateTime> _unlockedTimestamps = {};
  String? _currentUserId;

  List<Achievement> get achievements => _achievements;
  Map<String, int> get userProgress => _userProgress;
  Set<String> get unlockedAchievements => _unlockedAchievements;

  Future<void> initialize([String? userId]) async {
    try {
      _currentUserId = userId;
      _achievements = Achievement.getAchievements();
      
      print('🏆 AchievementProvider: Initializing ${_achievements.length} achievements for user: ${userId ?? 'anonymous'}');
      
      if (userId != null) {
        // Load from Supabase with local fallback
        final data = await _achievementService.loadUserAchievements(userId);
        _unlockedAchievements = Set<String>.from(data['unlocked_achievements'] ?? []);
        
        // Handle the user_progress type conversion more safely
        final rawProgress = data['user_progress'];
        _userProgress = {};
        
        if (rawProgress is Map<String, int>) {
          _userProgress = rawProgress;
        } else if (rawProgress is Map) {
          // Safely convert each entry
          for (final entry in rawProgress.entries) {
            try {
              final key = entry.key.toString();
              final value = entry.value;
              if (value is num) {
                _userProgress[key] = value.toInt();
              } else if (value is String) {
                _userProgress[key] = int.tryParse(value) ?? 0;
              }
            } catch (e) {
              print('🏆 Error converting achievement progress from Supabase: $e');
              // Skip this entry and continue
            }
          }
        }
        
        // New users start with clean slate - no automatic demo achievements
        
        // Sync any pending local achievements to Supabase
        await _achievementService.syncAchievementsToSupabase(userId);
        
        // Process any pending unlocks that were delayed due to network issues
        await processPendingUnlocks();
      } else {
        // Fallback to local storage only
        _unlockedAchievements = LocalDatabaseService.getSetting<Set<String>>('unlocked_achievements') ?? <String>{};
        _userProgress = LocalDatabaseService.getSetting<Map<String, int>>('user_progress') ?? <String, int>{};
        
        // Load unlock timestamps
        final timestampData = LocalDatabaseService.getSetting<Map<String, String>>('unlock_timestamps') ?? <String, String>{};
        _unlockedTimestamps = {};
        for (final entry in timestampData.entries) {
          try {
            _unlockedTimestamps[entry.key] = DateTime.parse(entry.value);
          } catch (e) {
            print('Error parsing timestamp for ${entry.key}: $e');
          }
        }
        
        // Anonymous users also start with no achievements
      }
      
      // Update achievement states based on progress
      _updateAchievementStates();
      
      print('🏆 AchievementProvider: Initialized with ${_unlockedAchievements.length} unlocked, ${_userProgress.length} in progress');
      notifyListeners();
    } catch (e) {
      print('🏆 Error initializing achievements: $e');
      // Use default values if everything fails
      _achievements = Achievement.getAchievements();
      _unlockedAchievements = {};
      _userProgress = {};
      
      // On error, users start with clean slate - no free achievements
      _updateAchievementStates();
      notifyListeners();
    }
  }

  /// Create demo achievements for testing
  Future<void> _createDemoAchievements(String userId) async {
    try {
      // Give some demo achievements to show the difference between locked/unlocked
      _unlockedAchievements.add('first_trade');
      _unlockedAchievements.add('early_bird');
      _unlockedAchievements.add('paper_hands');
      
      // Set some progress on other achievements
      _userProgress['first_trade'] = 1;
      _userProgress['ten_trades'] = 5; // Progress towards 10 trades
      _userProgress['hundred_trades'] = 5; // Progress towards 100 trades
      _userProgress['first_profit'] = 500; // Progress towards $1000 profit
      _userProgress['early_bird'] = 1;
      _userProgress['paper_hands'] = 1;
      
      print('🏆 Created demo achievements for testing');
    } catch (e) {
      print('🏆 Failed to create demo achievements: $e');
    }
  }

  /// Create starter achievements for new users
  Future<void> _createStarterAchievements(String userId) async {
    try {
      // Give some progress on early achievements
      _userProgress['first_trade'] = 1; // Complete first trade
      _userProgress['portfolio_watcher'] = 3; // Some portfolio views
      _userProgress['market_explorer'] = 5; // Some market browsing
      
      // Unlock the first trade achievement
      _unlockedAchievements.add('first_trade');
      
      // Update in Supabase
      await _achievementService.updateAchievementProgress(
        userId: userId,
        achievementId: 'first_trade',
        progress: 1,
        target: 1,
      );
      
      await _achievementService.unlockAchievement(
        userId: userId,
        achievement: _achievements.firstWhere((a) => a.id == 'first_trade'),
      );
      
      print('🏆 Created starter achievements for user');
    } catch (e) {
      print('🏆 Failed to create starter achievements: $e');
    }
  }

  /// Create starter achievements locally
  Future<void> _createStarterAchievementsLocal() async {
    _userProgress['first_trade'] = 1;
    _userProgress['portfolio_watcher'] = 2; 
    _userProgress['market_explorer'] = 3;
    _unlockedAchievements.add('first_trade');
    
    // Save locally
    await LocalDatabaseService.saveSetting('unlocked_achievements', _unlockedAchievements);
    await LocalDatabaseService.saveSetting('user_progress', _userProgress);
  }

  /// Create basic progress even on error
  Future<void> _createBasicProgress() async {
    _userProgress['portfolio_watcher'] = 1;
    _userProgress['market_explorer'] = 2;
  }

  void _updateAchievementStates() {
    for (int i = 0; i < _achievements.length; i++) {
      final achievement = _achievements[i];
      final progress = _userProgress[achievement.id] ?? 0;
      final isUnlocked = _unlockedAchievements.contains(achievement.id);
      
      _achievements[i] = Achievement(
        id: achievement.id,
        title: achievement.title,
        description: achievement.description,
        icon: achievement.icon,
        color: achievement.color,
        requiredValue: achievement.requiredValue,
        category: achievement.category,
        isUnlocked: isUnlocked,
        unlockedAt: isUnlocked ? _unlockedTimestamps[achievement.id] : null,
        currentProgress: progress,
      );
    }
  }

  Future<void> updateProgress(String achievementId, int progress) async {
    try {
      _userProgress[achievementId] = progress;
      
      // Find the achievement definition
      final achievement = _achievements.firstWhere((a) => a.id == achievementId);
      
      // Update in Supabase if user is signed in
      if (_currentUserId != null) {
        await _achievementService.updateAchievementProgress(
          userId: _currentUserId!,
          achievementId: achievementId,
          progress: progress,
          target: achievement.requiredValue,
        );
      } else {
        // Fallback to local storage
        await LocalDatabaseService.saveSetting('user_progress', _userProgress);
      }
      
      // DO NOT auto-unlock achievements - they should only be unlocked manually by the user
      // This prevents achievements from unlocking by themselves during network failures or data syncing
      
      // Just save progress - achievement unlocking must be triggered explicitly by user actions
      
      _updateAchievementStates();
      notifyListeners();
    } catch (e) {
      print('Error updating progress: $e');
    }
  }

  /// Manually check and unlock achievements that meet their requirements
  /// This should be called explicitly after user actions, not automatically
  Future<void> checkAndUnlockEligibleAchievements() async {
    if (_currentUserId == null && !_connectionManager.isOnline) {
      print('🏆 Skipping achievement check - offline and no user');
      return;
    }
    
    try {
      final eligibleAchievements = <String>[];
      
      for (final achievement in _achievements) {
        final progress = _userProgress[achievement.id] ?? 0;
        
        // Check if achievement is eligible for unlock
        if (progress >= achievement.requiredValue && !_unlockedAchievements.contains(achievement.id)) {
          eligibleAchievements.add(achievement.id);
        }
      }
      
      // Only unlock if we're online or if this is a local-only user
      if (_connectionManager.isOnline || _currentUserId == null) {
        for (final achievementId in eligibleAchievements) {
          await unlockAchievement(achievementId);
          print('🏆 Manually unlocked eligible achievement: $achievementId');
        }
      } else {
        // Save achievements as pending for when connection is restored
        for (final achievementId in eligibleAchievements) {
          await LocalDatabaseService.saveSetting('pending_unlock_$achievementId', true);
          print('⚠️ Achievement $achievementId queued for unlock when online');
        }
      }
      
      if (eligibleAchievements.isNotEmpty) {
        _updateAchievementStates();
        notifyListeners();
      }
    } catch (e) {
      print('❌ Error checking eligible achievements: $e');
    }
  }

  Future<void> unlockAchievement(String achievementId) async {
    try {
      if (!_unlockedAchievements.contains(achievementId)) {
        _unlockedAchievements.add(achievementId);
        _unlockedTimestamps[achievementId] = DateTime.now();
        
        // Find the achievement definition
        final achievement = _achievements.firstWhere((a) => a.id == achievementId);
        
        // Unlock in Supabase if user is signed in
        if (_currentUserId != null) {
          await _achievementService.unlockAchievement(
            userId: _currentUserId!,
            achievement: achievement,
          );
        } else {
          // Fallback to local storage
          await LocalDatabaseService.saveSetting('unlocked_achievements', _unlockedAchievements);
        }
        
        // Save timestamps to local storage
        final timestampData = <String, String>{};
        for (final entry in _unlockedTimestamps.entries) {
          timestampData[entry.key] = entry.value.toIso8601String();
        }
        await LocalDatabaseService.saveSetting('unlock_timestamps', timestampData);
        
        // Show achievement notification
        _showAchievementNotification(achievementId);
        
        // Check if all achievements are unlocked (except "Master of All")
        await _checkMasterOfAllAchievement();
      }
    } catch (e) {
      print('Error unlocking achievement: $e');
    }
  }

  void _showAchievementNotification(String achievementId) {
    final achievement = _achievements.firstWhere((a) => a.id == achievementId);
    // This would show a notification popup
    debugPrint('Achievement Unlocked: ${achievement.title}');
  }

  // Methods to track various user actions
  Future<void> recordTrade() async {
    // Sync trade-based achievements with database trade count
    await syncTradeAchievements();
  }
  
  /// Sync trade achievements with the database total_trades count
  Future<void> syncTradeAchievements() async {
    if (_currentUserId == null) return;
    
    try {
      // Get trade count from database using our SQL function
      final response = await _achievementService.getUserTradeCount(_currentUserId!);
      final tradeCount = response ?? 0;
      
      // Update all trade-based achievement progress
      await updateProgress('first_trade', tradeCount >= 1 ? 1 : 0);
      await updateProgress('ten_trades', tradeCount);
      await updateProgress('hundred_trades', tradeCount);
      await updateProgress('thousand_trades', tradeCount);
      await updateProgress('legendary_trader', tradeCount);
      
      print('🏆 Synced trade achievements: $tradeCount total trades');
    } catch (e) {
      print('❌ Error syncing trade achievements: $e');
    }
  }

  Future<void> recordProfit(double profit) async {
    final currentProfit = _userProgress['first_profit'] ?? 0;
    await updateProgress('first_profit', (currentProfit + profit).toInt());
  }

  Future<void> recordNetWorth(double netWorth) async {
    await updateProgress('big_profit', netWorth.toInt());
    await updateProgress('millionaire', netWorth.toInt());
  }

  Future<void> recordWinningStreak(int streak) async {
    await updateProgress('winning_streak', streak);
  }

  Future<void> recordConsecutiveDays(int days) async {
    await updateProgress('marathon_trader', days);
  }

  Future<void> recordHoldingPeriod(int days) async {
    await updateProgress('diamond_hands', days);
  }

  Future<void> recordDiversification(int uniqueAssets) async {
    await updateProgress('diversified', uniqueAssets);
  }

  // Crypto profit tracking removed - no longer needed

  Future<void> _checkMasterOfAllAchievement() async {
    // Don't check if Master of All is already unlocked
    if (_unlockedAchievements.contains('master_of_all')) return;
    
    // Get all achievements except "Master of All"
    final allAchievements = _achievements.where((a) => a.id != 'master_of_all').toList();
    
    // Check if all other achievements are unlocked
    final allUnlocked = allAchievements.every((achievement) => 
        _unlockedAchievements.contains(achievement.id));
    
    if (allUnlocked) {
      await unlockAchievement('master_of_all');
    }
  }

  // All sector-based achievement tracking methods removed
  // Achievements now focus on trading behavior, not specific sectors

  Future<void> recordHighValueTrade(double tradeValue) async {
    if (tradeValue >= 50000) {
      await updateProgress('high_roller', tradeValue.toInt());
    }
  }

  Future<void> recordLowPriceHighVolume(double price, int quantity) async {
    if (price < 5.0 && quantity >= 1000) {
      await updateProgress('penny_pincher', quantity);
    }
  }

  Future<void> recordTimeBasedTrade(DateTime tradeTime) async {
    final hour = tradeTime.hour;
    
    // Early bird (before 9 AM)
    if (hour < 9) {
      await updateProgress('early_bird', 1);
    }
    
    // Night owl (after 10 PM)
    if (hour >= 22) {
      await updateProgress('night_owl', 1);
    }
    
    // Weekend warrior (Saturday or Sunday)
    if (tradeTime.weekday == DateTime.saturday || tradeTime.weekday == DateTime.sunday) {
      final currentWeekendTrades = _userProgress['weekend_warrior'] ?? 0;
      await updateProgress('weekend_warrior', currentWeekendTrades + 1);
    }
  }

  Future<void> recordDailyTrades(int tradesInDay) async {
    if (tradesInDay >= 20) {
      await updateProgress('momentum_trader', tradesInDay);
    }
  }

  Future<void> recordPortfolioConcentration(double concentrationPercentage) async {
    if (concentrationPercentage >= 50) {
      await updateProgress('risk_taker', concentrationPercentage.toInt());
    }
  }

  Future<void> recordCashPercentage(double cashPercentage) async {
    if (cashPercentage >= 30) {
      await updateProgress('conservative', cashPercentage.toInt());
    }
  }

  Future<void> recordPortfolioRecovery(double recoveryPercentage) async {
    if (recoveryPercentage >= 50) {
      await updateProgress('comeback_kid', recoveryPercentage.toInt());
    }
  }

  Future<void> recordLargeLoss(double lossAmount) async {
    if (lossAmount >= 10000) {
      await updateProgress('loss_leader', lossAmount.toInt());
    }
  }

  Future<void> recordBullMarketGain(double gainPercentage) async {
    if (gainPercentage >= 100) {
      await updateProgress('bull_market', gainPercentage.toInt());
    }
  }

  Future<void> recordMarketOutperformance(double outperformancePercentage) async {
    if (outperformancePercentage >= 20) {
      await updateProgress('algorithm_beater', outperformancePercentage.toInt());
    }
  }

  int getUnlockedCount() {
    return _unlockedAchievements.length;
  }

  int getTotalCount() {
    return _achievements.length;
  }

  List<Achievement> getRecentlyUnlocked() {
    return _achievements
        .where((a) => a.isUnlocked)
        .toList()
        .take(3)
        .toList();
  }

  // Get Supabase achievement stats
  Future<Map<String, dynamic>> getAchievementStats() async {
    if (_currentUserId != null) {
      return await _achievementService.getAchievementStats(_currentUserId!);
    }
    return {
      'total_unlocked': _unlockedAchievements.length,
      'total_available': _achievements.length,
      'category_breakdown': <String, int>{},
    };
  }

  // Set current user ID for Supabase sync
  void setUserId(String? userId) {
    _currentUserId = userId;
    if (userId != null) {
      // Re-initialize with user data
      initialize(userId);
    }
  }

  // Get achievements by category
  List<Achievement> getAchievementsByCategory(String category) {
    return _achievements.where((a) => a.category == category).toList();
  }

  // Get completion percentage
  double getCompletionPercentage() {
    if (_achievements.isEmpty) return 0.0;
    return (_unlockedAchievements.length / _achievements.length) * 100;
  }

  // Get next achievement to unlock
  Achievement? getNextAchievement() {
    final locked = _achievements.where((a) => !a.isUnlocked).toList();
    if (locked.isEmpty) return null;
    
    // Sort by progress and return the one closest to completion
    locked.sort((a, b) => b.currentProgress.compareTo(a.currentProgress));
    return locked.first;
  }

  // Sector-based tracking methods removed as requested
  // All achievements now focus on trading behavior rather than specific sectors

  // Additional missing tracking methods
  Future<void> recordLongHold(int days) async {
    await updateProgress('value_investor', days);
  }

  Future<void> recordProfitableStreak(int streak) async {
    await updateProgress('perfectionist', streak);
  }

  Future<void> recordSameDayBuySell() async {
    final currentDayTrades = _userProgress['day_trader'] ?? 0;
    await updateProgress('day_trader', currentDayTrades + 1);
  }

  Future<void> recordSwingTrade() async {
    final currentSwingTrades = _userProgress['swing_trader'] ?? 0;
    await updateProgress('swing_trader', currentSwingTrades + 1);
  }

  Future<void> recordQuickSale() async {
    await updateProgress('paper_hands', 1);
  }

  Future<void> recordMultiMillionaire(double netWorth) async {
    if (netWorth >= 10000000) {
      await updateProgress('multi_millionaire', netWorth.toInt());
    }
    if (netWorth >= 1000000000) {
      await updateProgress('billionaire', netWorth.toInt());
    }
  }

  // Sector diversification removed - no longer tracking sector-specific achievements

  Future<void> recordLimitOrder() async {
    final currentLimitOrders = _userProgress['market_maker'] ?? 0;
    await updateProgress('market_maker', currentLimitOrders + 1);
  }

  Future<void> recordMarketCrashHolding(double crashPercentage) async {
    if (crashPercentage >= 30) {
      await updateProgress('iron_stomach', crashPercentage.toInt());
    }
  }

  Future<void> recordContrarian() async {
    await updateProgress('contrarian', 1);
  }

  Future<void> recordVolatilityTrade() async {
    await updateProgress('volatility_surfer', 1);
  }

  Future<void> recordEarningsPlay() async {
    final currentEarningsPlays = _userProgress['earnings_player'] ?? 0;
    await updateProgress('earnings_player', currentEarningsPlays + 1);
  }

  Future<void> recordOptionsTrade() async {
    final currentOptionstrades = _userProgress['options_trader'] ?? 0;
    await updateProgress('options_trader', currentOptionstrades + 1);
  }

  Future<void> recordBearMarketSurvival() async {
    await updateProgress('bear_market', 1);
  }

  Future<void> recordSocialFollowing(int followCount) async {
    await updateProgress('social_trader', followCount);
  }

  Future<void> recordResearch() async {
    final currentResearch = _userProgress['research_master'] ?? 0;
    await updateProgress('research_master', currentResearch + 1);
  }

  Future<void> recordNewsRead() async {
    final currentNews = _userProgress['news_junkie'] ?? 0;
    await updateProgress('news_junkie', currentNews + 1);
  }

  Future<void> recordChartAnalysis() async {
    final currentCharts = _userProgress['chart_master'] ?? 0;
    await updateProgress('chart_master', currentCharts + 1);
  }

  Future<void> recordMarketTimingSuccess() async {
    await updateProgress('market_timer', 1);
  }

  /// Process achievements that were pending unlock due to network issues
  Future<void> processPendingUnlocks() async {
    if (_currentUserId == null || !_connectionManager.isOnline) return;

    try {
      print('🔄 Processing pending achievement unlocks...');
      final allAchievements = Achievement.getAchievements();
      
      for (final achievement in allAchievements) {
        final pendingKey = 'pending_unlock_${achievement.id}';
        final isPending = LocalDatabaseService.getSetting<bool>(pendingKey) ?? false;
        
        if (isPending && !_unlockedAchievements.contains(achievement.id)) {
          // Check if the progress still meets the requirement
          final currentProgress = _userProgress[achievement.id] ?? 0;
          if (currentProgress >= achievement.requiredValue) {
            await unlockAchievement(achievement.id);
            // Remove the pending flag
            await LocalDatabaseService.deleteSetting(pendingKey);
            print('✅ Processed pending unlock: ${achievement.title}');
          }
        }
      }
      
      print('✅ Finished processing pending unlocks');
    } catch (e) {
      print('❌ Failed to process pending unlocks: $e');
    }
  }
}