import 'package:shared_preferences/shared_preferences.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/asset_model.dart';
import '../models/user_model.dart';

class StorageService {
  static const String _themeKey = 'selected_theme';
  static const String _userKey = 'cached_user';
  static const String _assetsBoxName = 'assets_cache';
  static const String _pricesBoxName = 'prices_cache';

  static SharedPreferences? _prefs;
  static Box<Map>? _assetsBox;
  static Box<Map>? _pricesBox;

  static Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();
    _assetsBox = await Hive.openBox<Map>(_assetsBoxName);
    _pricesBox = await Hive.openBox<Map>(_pricesBoxName);
  }

  static Future<void> saveTheme(String theme) async {
    await _prefs?.setString(_themeKey, theme);
  }

  static String getTheme() {
    return _prefs?.getString(_themeKey) ?? 'light';
  }

  static Future<void> cacheUser(UserModel user) async {
    await _prefs?.setString(_userKey, user.toJson().toString());
  }

  static UserModel? getCachedUser() {
    final userString = _prefs?.getString(_userKey);
    if (userString != null) {
      try {
        // Note: This is a simplified approach. In production, use proper JSON serialization
        return null; // Implement proper deserialization
      } catch (e) {
        return null;
      }
    }
    return null;
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
}