import 'package:flutter/foundation.dart';
import '../models/achievement_model.dart';
import '../services/local_database_service.dart';

class AchievementProvider with ChangeNotifier {
  List<Achievement> _achievements = [];
  Map<String, int> _userProgress = {};
  Set<String> _unlockedAchievements = {};

  List<Achievement> get achievements => _achievements;
  Map<String, int> get userProgress => _userProgress;
  Set<String> get unlockedAchievements => _unlockedAchievements;

  Future<void> initialize() async {
    try {
      _achievements = Achievement.getAchievements();
      _unlockedAchievements = LocalDatabaseService.getSetting<Set<String>>('unlocked_achievements') ?? {};
      _userProgress = LocalDatabaseService.getSetting<Map<String, int>>('user_progress') ?? {};
      
      // Update achievement states based on progress
      _updateAchievementStates();
      notifyListeners();
    } catch (e) {
      print('Error initializing achievements: $e');
      // Use default values if database fails
      _achievements = Achievement.getAchievements();
      _unlockedAchievements = {};
      _userProgress = {};
      _updateAchievementStates();
      notifyListeners();
    }
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
      await LocalDatabaseService.saveSetting('user_progress', _userProgress);
      
      // Check if achievement should be unlocked
      final achievement = _achievements.firstWhere((a) => a.id == achievementId);
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
        await LocalDatabaseService.saveSetting('unlocked_achievements', _unlockedAchievements);
        
        // Show achievement notification
        _showAchievementNotification(achievementId);
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
}