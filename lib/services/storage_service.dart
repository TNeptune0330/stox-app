import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/asset_model.dart';
import '../models/user_model.dart';
import '../utils/uuid_utils.dart';

class StorageService {
  static const String _themeKey = 'selected_theme';
  static const String _userKey = 'cached_user';
  static const String _assetsBoxName = 'assets_cache';
  static const String _pricesBoxName = 'prices_cache';
  static const String _unlockedAchievementsKey = 'unlocked_achievements';
  static const String _userProgressKey = 'user_progress';

  static SharedPreferences? _prefs;
  static Box<Map>? _assetsBox;
  static Box<Map>? _pricesBox;

  static Future<void> initialize() async {
    // Initialize Hive first
    await Hive.initFlutter();
    
    _prefs = await SharedPreferences.getInstance();
    _assetsBox = await Hive.openBox<Map>(_assetsBoxName);
    _pricesBox = await Hive.openBox<Map>(_pricesBoxName);
  }

  static Future<void> saveTheme(String theme) async {
    await _prefs?.setString(_themeKey, theme);
  }

  static String getTheme() {
    return _prefs?.getString(_themeKey) ?? 'dark';
  }

  static Future<void> cacheUser(UserModel user) async {
    try {
      final userJson = jsonEncode(user.toJson());
      await _prefs?.setString(_userKey, userJson);
      print('✅ User cached successfully with ID: ${user.id}');
    } catch (e) {
      // If caching fails, log but don't crash
      print('Failed to cache user: $e');
    }
  }

  static UserModel? getCachedUser() {
    final userString = _prefs?.getString(_userKey);
    if (userString != null) {
      try {
        final userJson = jsonDecode(userString) as Map<String, dynamic>;
        final user = UserModel.fromJson(userJson);
        
        // Check if the user ID is in the old Google ID format and needs migration
        if (_needsUuidMigration(user.id)) {
          print('🔄 Migrating user ID from Google ID format to UUID format');
          print('  Original ID: ${user.id}');
          final convertedId = UuidUtils.ensureUuidFormat(user.id);
          print('  Converted ID: $convertedId');
          final migratedUser = user.copyWith(id: convertedId);
          
          // Cache the migrated user synchronously
          _cacheMigratedUser(migratedUser);
          
          return migratedUser;
        }
        
        return user;
      } catch (e) {
        // If deserialization fails, return null
        print('Failed to deserialize cached user: $e');
        return null;
      }
    }
    return null;
  }
  
  static void _cacheMigratedUser(UserModel user) {
    try {
      final userJson = jsonEncode(user.toJson());
      _prefs?.setString(_userKey, userJson);
      print('✅ Migrated user cached successfully with ID: ${user.id}');
    } catch (e) {
      print('❌ Failed to cache migrated user: $e');
    }
  }
  
  static bool _needsUuidMigration(String id) {
    // Check if ID is in raw Google ID format (all digits)
    return RegExp(r'^\d+$').hasMatch(id);
  }

  static Future<void> cacheAssets(List<AssetModel> assets) async {
    final assetsMap = <String, Map<String, dynamic>>{};
    for (final asset in assets) {
      assetsMap[asset.symbol] = asset.toJson();
    }
    await _assetsBox?.clear();
    await _assetsBox?.putAll(assetsMap);
  }

  static List<AssetModel> getCachedAssets() {
    final cachedData = _assetsBox?.values.toList() ?? [];
    return cachedData
        .map((data) => AssetModel.fromJson(Map<String, dynamic>.from(data)))
        .toList();
  }

  static Future<void> cachePrice(String symbol, double price) async {
    await _pricesBox?.put(symbol, {
      'price': price,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    });
  }

  static double? getCachedPrice(String symbol) {
    final priceData = _pricesBox?.get(symbol);
    if (priceData != null) {
      final timestamp = priceData['timestamp'] as int;
      final now = DateTime.now().millisecondsSinceEpoch;
      
      // Cache is valid for 5 minutes
      if (now - timestamp < 5 * 60 * 1000) {
        return (priceData['price'] as num).toDouble();
      }
    }
    return null;
  }

  static Future<void> clearCache() async {
    await _assetsBox?.clear();
    await _pricesBox?.clear();
    await _prefs?.clear();
  }

  static Future<void> clearUserData() async {
    await _prefs?.remove(_userKey);
  }

  static bool isDataStale(DateTime lastUpdated) {
    final now = DateTime.now();
    final difference = now.difference(lastUpdated);
    return difference.inMinutes > 5; // Consider data stale after 5 minutes
  }

  // Achievement methods
  static Future<void> saveUnlockedAchievements(Set<String> achievements) async {
    await _prefs?.setStringList(_unlockedAchievementsKey, achievements.toList());
  }

  static Set<String> getUnlockedAchievements() {
    final achievements = _prefs?.getStringList(_unlockedAchievementsKey) ?? [];
    return achievements.toSet();
  }

  static Future<void> saveUserProgress(Map<String, int> progress) async {
    final progressList = progress.entries.map((e) => '${e.key}:${e.value}').toList();
    await _prefs?.setStringList(_userProgressKey, progressList);
  }

  static Map<String, int> getUserProgress() {
    final progressList = _prefs?.getStringList(_userProgressKey) ?? [];
    final progress = <String, int>{};
    for (final entry in progressList) {
      final parts = entry.split(':');
      if (parts.length == 2) {
        progress[parts[0]] = int.tryParse(parts[1]) ?? 0;
      }
    }
    return progress;
  }
}