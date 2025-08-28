import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/achievement_model.dart';
import '../services/connection_manager.dart';
import '../services/local_database_service.dart';
import '../utils/uuid_utils.dart';

class AchievementService {
  final SupabaseClient _supabase = Supabase.instance.client;
  final ConnectionManager _connectionManager = ConnectionManager();

  // Sync achievement progress to Supabase
  Future<bool> updateAchievementProgress({
    required String userId,
    required String achievementId,
    required int progress,
    required int target,
    Map<String, dynamic>? progressData,
  }) async {
    return await _connectionManager.executeWithFallback<bool>(
      () async {
        final response = await _supabase.rpc('update_achievement_progress', params: {
          'user_id_param': UuidUtils.ensureUuidFormat(userId),
          'achievement_id_param': achievementId,
          'progress_param': progress,
          'target_param': target,
          'progress_data_param': progressData ?? {},
        });

        _connectionManager.recordSuccess();
        print('✅ Achievement progress synced to Supabase: $achievementId ($progress/$target)');
        
        // Also save locally as backup
        await LocalDatabaseService.saveSetting('progress_$achievementId', progress);
        
        return response['success'] == true;
      },
      () async {
        // During network failure, save progress locally but don't trigger immediate unlocks
        await LocalDatabaseService.saveSetting('progress_$achievementId', progress);
        print('📱 Achievement progress saved locally (will sync when online): $achievementId ($progress/$target)');
        // Return true for progress tracking, but unlock logic will be controlled separately
        return true;
      },
    ) ?? false;
  }

  // Unlock achievement in Supabase
  Future<bool> unlockAchievement({
    required String userId,
    required Achievement achievement,
  }) async {
    return await _connectionManager.executeWithFallback<bool>(
      () async {
        final response = await _supabase.rpc('unlock_achievement', params: {
          'user_id_param': UuidUtils.ensureUuidFormat(userId),
          'achievement_id_param': achievement.id,
          'title_param': achievement.title,
          'description_param': achievement.description,
          'category_param': achievement.category,
          'icon_param': achievement.icon.codePoint.toString(),
          'color_param': '#${achievement.color.value.toRadixString(16).substring(2)}',
        });

        _connectionManager.recordSuccess();
        print('🏆 Achievement unlocked in Supabase: ${achievement.title}');
        
        // Also save locally
        final unlockedAchievements = LocalDatabaseService.getSetting<Set<String>>('unlocked_achievements') ?? <String>{};
        unlockedAchievements.add(achievement.id);
        await LocalDatabaseService.saveSetting('unlocked_achievements', unlockedAchievements);
        
        return response['success'] == true;
      },
      () async {
        // During network failures, don't automatically unlock achievements
        // Only save locally without triggering unlock notifications
        print('⚠️ Network failure: Achievement ${achievement.title} will be synced when connection is restored');
        return false; // Don't trigger unlock UI during network failures
      },
    ) ?? false;
  }

  // Get user's current trade count from database
  Future<int> getUserTradeCount(String userId) async {
    return await _connectionManager.executeWithFallback<int>(
      () async {
        final response = await _supabase.rpc('get_user_trade_count', params: {
          'user_id_param': UuidUtils.ensureUuidFormat(userId),
        });
        
        _connectionManager.recordSuccess();
        print('✅ Retrieved trade count from database: $response');
        return (response as int?) ?? 0;
      },
      () async {
        print('📱 Network failure: Cannot retrieve trade count');
        return 0;
      },
    ) ?? 0;
  }

  // Sync trade achievements with database
  Future<Map<String, dynamic>?> syncTradeAchievements(String userId) async {
    return await _connectionManager.executeWithFallback<Map<String, dynamic>>(
      () async {
        final response = await _supabase.rpc('sync_trade_achievements', params: {
          'user_id_param': UuidUtils.ensureUuidFormat(userId),
        });
        
        _connectionManager.recordSuccess();
        print('✅ Synced trade achievements from database');
        return response;
      },
      () async {
        print('📱 Network failure: Cannot sync trade achievements');
        return null;
      },
    );
  }

  // Load user achievements from Supabase
  Future<Map<String, dynamic>> loadUserAchievements(String userId) async {
    print('🏆 AchievementService: Loading achievements for user $userId');
    
    return await _connectionManager.executeWithFallback<Map<String, dynamic>>(
      () async {
        try {
          print('🏆 AchievementService: Querying Supabase for achievements...');
          
          // Get unlocked achievements
          final unlockedResponse = await _supabase
              .from('user_achievements')
              .select('achievement_id, unlocked_at')
              .eq('user_id', UuidUtils.ensureUuidFormat(userId));

          print('🏆 AchievementService: Found ${unlockedResponse.length} unlocked achievements');

          // Get achievement progress
          final progressResponse = await _supabase
              .from('achievement_progress')
              .select('achievement_id, current_progress, is_completed')
              .eq('user_id', UuidUtils.ensureUuidFormat(userId));

          print('🏆 AchievementService: Found ${progressResponse.length} progress records');

          _connectionManager.recordSuccess();

          final Set<String> unlockedAchievements = {};
          final Map<String, int> userProgress = {};

          for (final row in unlockedResponse) {
            unlockedAchievements.add(row['achievement_id'] as String);
          }

          for (final row in progressResponse) {
            final achievementId = row['achievement_id'] as String;
            final progress = row['current_progress'] as int;
            userProgress[achievementId] = progress;
          }

          print('✅ Loaded achievements from Supabase: ${unlockedAchievements.length} unlocked, ${userProgress.length} in progress');

          // Cache locally
          await LocalDatabaseService.saveSetting('unlocked_achievements', unlockedAchievements);
          await LocalDatabaseService.saveSetting('user_progress', userProgress);

          return {
            'unlocked_achievements': unlockedAchievements,
            'user_progress': userProgress,
          };
        } catch (e) {
          print('❌ AchievementService: Supabase query failed: $e');
          rethrow;
        }
      },
      () async {
        // Fallback to local storage
        final unlockedAchievements = LocalDatabaseService.getSetting<Set<String>>('unlocked_achievements') ?? <String>{};
        final userProgress = LocalDatabaseService.getSetting<Map<String, int>>('user_progress') ?? <String, int>{};
        
        print('📱 Loaded achievements from local storage: ${unlockedAchievements.length} unlocked, ${userProgress.length} in progress');

        return {
          'unlocked_achievements': unlockedAchievements,
          'user_progress': userProgress,
        };
      },
    ) ?? {
      'unlocked_achievements': <String>{},
      'user_progress': <String, int>{},
    };
  }

  // Sync all local achievements to Supabase (for when coming back online)
  Future<void> syncAchievementsToSupabase(String userId) async {
    if (!_connectionManager.shouldRetry) return;

    try {
      print('🔄 Syncing local achievements to Supabase...');

      final localUnlocked = LocalDatabaseService.getSetting<Set<String>>('unlocked_achievements') ?? <String>{};
      final localProgress = LocalDatabaseService.getSetting<Map<String, int>>('user_progress') ?? <String, int>{};

      // Get all achievement definitions
      final allAchievements = Achievement.getAchievements();
      final achievementMap = {for (var a in allAchievements) a.id: a};

      // Sync unlocked achievements
      for (final achievementId in localUnlocked) {
        final achievement = achievementMap[achievementId];
        if (achievement != null) {
          await unlockAchievement(userId: userId, achievement: achievement);
        }
      }

      // Sync progress
      for (final entry in localProgress.entries) {
        final achievement = achievementMap[entry.key];
        if (achievement != null) {
          await updateAchievementProgress(
            userId: userId,
            achievementId: entry.key,
            progress: entry.value,
            target: achievement.requiredValue,
          );
        }
      }

      print('✅ All achievements synced to Supabase');
    } catch (e) {
      print('❌ Failed to sync achievements to Supabase: $e');
    }
  }

  // Get achievement statistics
  Future<Map<String, dynamic>> getAchievementStats(String userId) async {
    return await _connectionManager.executeWithFallback<Map<String, dynamic>>(
      () async {
        final response = await _supabase
            .from('user_achievements')
            .select('achievement_category, unlocked_at')
            .eq('user_id', UuidUtils.ensureUuidFormat(userId));

        final Map<String, int> categoryCount = {};
        int totalUnlocked = response.length;
        DateTime? firstAchievement;
        DateTime? latestAchievement;

        for (final row in response) {
          final category = row['achievement_category'] as String;
          categoryCount[category] = (categoryCount[category] ?? 0) + 1;

          final unlockedAt = DateTime.parse(row['unlocked_at'] as String);
          if (firstAchievement == null || unlockedAt.isBefore(firstAchievement)) {
            firstAchievement = unlockedAt;
          }
          if (latestAchievement == null || unlockedAt.isAfter(latestAchievement)) {
            latestAchievement = unlockedAt;
          }
        }

        return {
          'total_unlocked': totalUnlocked,
          'total_available': Achievement.getAchievements().length,
          'category_breakdown': categoryCount,
          'first_achievement': firstAchievement?.toIso8601String(),
          'latest_achievement': latestAchievement?.toIso8601String(),
        };
      },
      () async {
        // Fallback to local calculation
        final unlockedAchievements = LocalDatabaseService.getSetting<Set<String>>('unlocked_achievements') ?? <String>{};
        return {
          'total_unlocked': unlockedAchievements.length,
          'total_available': Achievement.getAchievements().length,
          'category_breakdown': <String, int>{},
          'first_achievement': null,
          'latest_achievement': null,
        };
      },
    ) ?? {
      'total_unlocked': 0,
      'total_available': Achievement.getAchievements().length,
      'category_breakdown': <String, int>{},
      'first_achievement': null,
      'latest_achievement': null,
    };
  }

  // Check if user has specific achievement
  Future<bool> hasAchievement(String userId, String achievementId) async {
    return await _connectionManager.executeWithFallback<bool>(
      () async {
        final response = await _supabase
            .from('user_achievements')
            .select('id')
            .eq('user_id', UuidUtils.ensureUuidFormat(userId))
            .eq('achievement_id', achievementId)
            .maybeSingle();

        return response != null;
      },
      () async {
        final unlockedAchievements = LocalDatabaseService.getSetting<Set<String>>('unlocked_achievements') ?? <String>{};
        return unlockedAchievements.contains(achievementId);
      },
    ) ?? false;
  }

  // Get recent achievements for display
  Future<List<Map<String, dynamic>>> getRecentAchievements(String userId, {int limit = 5}) async {
    return await _connectionManager.executeWithFallback<List<Map<String, dynamic>>>(
      () async {
        final response = await _supabase
            .from('user_achievements')
            .select('achievement_id, achievement_title, achievement_description, icon_name, color_hex, unlocked_at')
            .eq('user_id', UuidUtils.ensureUuidFormat(userId))
            .order('unlocked_at', ascending: false)
            .limit(limit);

        return response.cast<Map<String, dynamic>>();
      },
      () async {
        // Fallback to local data (limited info available)
        final unlockedAchievements = LocalDatabaseService.getSetting<Set<String>>('unlocked_achievements') ?? <String>{};
        final allAchievements = Achievement.getAchievements();
        
        final recent = allAchievements
            .where((a) => unlockedAchievements.contains(a.id))
            .take(limit)
            .map((a) => {
              'achievement_id': a.id,
              'achievement_title': a.title,
              'achievement_description': a.description,
              'icon_name': a.icon.codePoint.toString(),
              'color_hex': '#${a.color.value.toRadixString(16).substring(2)}',
              'unlocked_at': DateTime.now().toIso8601String(),
            })
            .toList();

        return recent;
      },
    ) ?? [];
  }
}