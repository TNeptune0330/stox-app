import 'package:flutter/foundation.dart';
import '../models/achievement_model.dart';
import '../services/local_database_service.dart';
import '../services/achievement_service.dart';

class AchievementProvider with ChangeNotifier {
  final AchievementService _achievementService = AchievementService();
  List<Achievement> _achievements = [];
  Map<String, int> _userProgress = {};
  Set<String> _unlockedAchievements = {};
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
        
        // Create some starter achievements for new users if none exist
        if (_unlockedAchievements.isEmpty && _userProgress.isEmpty) {
          print('🏆 New user detected - creating starter achievements');
          await _createStarterAchievements(userId);
        }
        
        // Sync any pending local achievements to Supabase
        await _achievementService.syncAchievementsToSupabase(userId);
      } else {
        // Fallback to local storage only
        _unlockedAchievements = LocalDatabaseService.getSetting<Set<String>>('unlocked_achievements') ?? <String>{};
        _userProgress = LocalDatabaseService.getSetting<Map<String, int>>('user_progress') ?? <String, int>{};
        
        // Create starter achievements for anonymous users too
        if (_unlockedAchievements.isEmpty && _userProgress.isEmpty) {
          print('🏆 Anonymous user - creating local starter achievements');
          await _createStarterAchievementsLocal();
        }
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
      
      // Even on error, create some basic progress for better UX
      await _createBasicProgress();
      _updateAchievementStates();
      notifyListeners();
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
        unlockedAt: isUnlocked ? DateTime.now() : null,
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
      
      // Check if achievement should be unlocked
      if (progress >= achievement.requiredValue && !_unlockedAchievements.contains(achievementId)) {
        await unlockAchievement(achievementId);
      }
      
      _updateAchievementStates();
      notifyListeners();
    } catch (e) {
      print('Error updating progress: $e');
    }
  }

  Future<void> unlockAchievement(String achievementId) async {
    try {
      if (!_unlockedAchievements.contains(achievementId)) {
        _unlockedAchievements.add(achievementId);
        
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
    await updateProgress('first_trade', 1);
    final currentTrades = _userProgress['ten_trades'] ?? 0;
    await updateProgress('ten_trades', currentTrades + 1);
    await updateProgress('hundred_trades', currentTrades + 1);
    await updateProgress('thousand_trades', currentTrades + 1);
    await updateProgress('legendary_trader', currentTrades + 1);
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

  Future<void> recordCryptoProfit(double profit) async {
    final currentCryptoProfit = _userProgress['crypto_king'] ?? 0;
    await updateProgress('crypto_king', (currentCryptoProfit + profit).toInt());
  }

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

  Future<void> recordTechStockPurchase(String symbol) async {
    if (Achievement.getTechStocks().contains(symbol)) {
      final currentTechStocks = _userProgress['tech_giant'] ?? 0;
      await updateProgress('tech_giant', currentTechStocks + 1);
    }
  }

  Future<void> recordEnergyStockPurchase(String symbol) async {
    if (Achievement.getEnergyStocks().contains(symbol)) {
      final currentEnergyStocks = _userProgress['energy_investor'] ?? 0;
      await updateProgress('energy_investor', currentEnergyStocks + 1);
    }
  }

  Future<void> recordHealthcareStockPurchase(String symbol) async {
    if (Achievement.getHealthcareStocks().contains(symbol)) {
      final currentHealthcareStocks = _userProgress['healthcare_hero'] ?? 0;
      await updateProgress('healthcare_hero', currentHealthcareStocks + 1);
    }
  }

  Future<void> recordFinancialStockPurchase(String symbol) async {
    if (Achievement.getFinancialStocks().contains(symbol)) {
      final currentFinancialStocks = _userProgress['financial_wizard'] ?? 0;
      await updateProgress('financial_wizard', currentFinancialStocks + 1);
    }
  }

  Future<void> recordMemeStockPurchase(String symbol) async {
    if (Achievement.getMemeStocks().contains(symbol)) {
      final currentMemeStocks = _userProgress['meme_lord'] ?? 0;
      await updateProgress('meme_lord', currentMemeStocks + 1);
    }
  }

  Future<void> recordSP500StockPurchase(String symbol) async {
    if (Achievement.getSP500Stocks().contains(symbol)) {
      final currentSP500Stocks = _userProgress['blue_chip'] ?? 0;
      await updateProgress('blue_chip', currentSP500Stocks + 1);
    }
  }

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
    locked.sort((a, b) => b.progress.compareTo(a.progress));
    return locked.first;
  }

  // Additional achievement tracking methods
  Future<void> recordETFPurchase(String symbol) async {
    if (Achievement.getETFSymbols().contains(symbol)) {
      final currentETFs = _userProgress['etf_fan'] ?? 0;
      await updateProgress('etf_fan', currentETFs + 1);
    }
  }

  Future<void> recordDividendStockPurchase(String symbol) async {
    if (Achievement.getDividendStocks().contains(symbol)) {
      final currentDividendStocks = _userProgress['dividend_hunter'] ?? 0;
      await updateProgress('dividend_hunter', currentDividendStocks + 1);
    }
  }

  Future<void> recordSmallCapPurchase(String symbol) async {
    if (Achievement.getSmallCapStocks().contains(symbol)) {
      final currentSmallCap = _userProgress['small_cap'] ?? 0;
      await updateProgress('small_cap', currentSmallCap + 1);
    }
  }

  Future<void> recordInternationalPurchase(String symbol) async {
    if (Achievement.getInternationalStocks().contains(symbol)) {
      final currentInternational = _userProgress['international'] ?? 0;
      await updateProgress('international', currentInternational + 1);
    }
  }

  Future<void> recordConsumerStockPurchase(String symbol) async {
    if (Achievement.getConsumerStocks().contains(symbol)) {
      final currentConsumer = _userProgress['consumer_staples'] ?? 0;
      await updateProgress('consumer_staples', currentConsumer + 1);
    }
  }
}