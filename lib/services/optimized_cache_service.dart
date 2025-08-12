import 'dart:convert';
import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/market_asset_model.dart';

/// High-performance caching service with intelligent cache management
class OptimizedCacheService {
  static const String _logPrefix = '[OptimizedCache]';
  
  // Cache categories with different TTLs
  static const String _marketDataPrefix = 'market_';
  static const String _userDataPrefix = 'user_';
  static const String _portfolioPrefix = 'portfolio_';
  static const String _newsPrefix = 'news_';
  
  // Cache TTL (Time To Live) in minutes
  static const Map<String, int> _cacheTTL = {
    'market_data': 2,        // Market data: 2 minutes
    'user_portfolio': 5,     // Portfolio: 5 minutes
    'user_settings': 30,     // Settings: 30 minutes
    'news_data': 15,         // News: 15 minutes
    'static_data': 1440,     // Static data: 24 hours
  };
  
  // In-memory cache for frequently accessed data
  static final Map<String, _CacheEntry> _memoryCache = {};
  static const int _maxMemoryCacheSize = 200;
  
  // Cache hit/miss statistics
  static int _cacheHits = 0;
  static int _cacheMisses = 0;
  static int _cacheEvictions = 0;
  
  /// Get cached data with automatic TTL checking
  static Future<T?> get<T>(String key, {String category = 'market_data'}) async {
    try {
      // Check memory cache first (fastest)
      final memoryEntry = _memoryCache[key];
      if (memoryEntry != null && !memoryEntry.isExpired) {
        _cacheHits++;
        print('$_logPrefix 🚀 Memory hit: $key');
        return memoryEntry.data as T?;
      }
      
      // Check persistent cache
      final prefs = await SharedPreferences.getInstance();
      final cachedDataJson = prefs.getString(key);
      
      if (cachedDataJson != null) {
        final cachedData = jsonDecode(cachedDataJson);
        final timestamp = DateTime.parse(cachedData['timestamp']);
        final ttlMinutes = _cacheTTL[category] ?? 5;
        
        if (DateTime.now().difference(timestamp).inMinutes < ttlMinutes) {
          _cacheHits++;
          
          // Add to memory cache for next time
          _addToMemoryCache(key, cachedData['data'], ttlMinutes);
          
          print('$_logPrefix 💾 Persistent hit: $key (age: ${DateTime.now().difference(timestamp).inMinutes}min)');
          return cachedData['data'] as T?;
        } else {
          // Expired cache, remove it
          await prefs.remove(key);
          print('$_logPrefix ⏰ Expired and removed: $key');
        }
      }
      
      _cacheMisses++;
      print('$_logPrefix ❌ Cache miss: $key');
      return null;
    } catch (e) {
      print('$_logPrefix ❌ Error getting cache for $key: $e');
      return null;
    }
  }
  
  /// Store data in cache with category-based TTL
  static Future<void> set<T>(String key, T data, {String category = 'market_data'}) async {
    try {
      final ttlMinutes = _cacheTTL[category] ?? 5;
      
      // Store in memory cache
      _addToMemoryCache(key, data, ttlMinutes);
      
      // Store in persistent cache
      final prefs = await SharedPreferences.getInstance();
      final cacheData = {
        'data': data,
        'timestamp': DateTime.now().toIso8601String(),
        'category': category,
        'ttl_minutes': ttlMinutes,
      };
      
      await prefs.setString(key, jsonEncode(cacheData));
      print('$_logPrefix 💾 Cached: $key (TTL: ${ttlMinutes}min)');
    } catch (e) {
      print('$_logPrefix ❌ Error caching $key: $e');
    }
  }
  
  /// Add to memory cache with size management
  static void _addToMemoryCache<T>(String key, T data, int ttlMinutes) {
    // Evict oldest entries if cache is full
    if (_memoryCache.length >= _maxMemoryCacheSize) {
      final oldestKey = _memoryCache.keys.first;
      _memoryCache.remove(oldestKey);
      _cacheEvictions++;
    }
    
    final expiry = DateTime.now().add(Duration(minutes: ttlMinutes));
    _memoryCache[key] = _CacheEntry(data, expiry);
  }
  
  /// Batch get multiple keys (optimized for bulk operations)
  static Future<Map<String, T?>> getBatch<T>(List<String> keys, {String category = 'market_data'}) async {
    final results = <String, T?>{};
    final futures = keys.map((key) => get<T>(key, category: category));
    final values = await Future.wait(futures);
    
    for (int i = 0; i < keys.length; i++) {
      results[keys[i]] = values[i];
    }
    
    return results;
  }
  
  /// Batch set multiple keys (optimized for bulk operations)
  static Future<void> setBatch<T>(Map<String, T> data, {String category = 'market_data'}) async {
    final futures = data.entries.map((entry) => 
      set(entry.key, entry.value, category: category)
    );
    await Future.wait(futures);
  }
  
  /// Get market asset with optimized caching
  static Future<MarketAssetModel?> getMarketAsset(String symbol) async {
    final key = '${_marketDataPrefix}asset_$symbol';
    final cached = await get<Map<String, dynamic>>(key, category: 'market_data');
    
    if (cached != null) {
      return MarketAssetModel.fromJson(cached);
    }
    return null;
  }
  
  /// Cache market asset
  static Future<void> setMarketAsset(MarketAssetModel asset) async {
    final key = '${_marketDataPrefix}asset_${asset.symbol}';
    await set(key, asset.toJson(), category: 'market_data');
  }
  
  /// Cache multiple market assets efficiently
  static Future<void> setMarketAssets(List<MarketAssetModel> assets) async {
    final dataMap = <String, Map<String, dynamic>>{};
    for (final asset in assets) {
      final key = '${_marketDataPrefix}asset_${asset.symbol}';
      dataMap[key] = asset.toJson();
    }
    await setBatch(dataMap, category: 'market_data');
  }
  
  /// Get portfolio data with caching
  static Future<List<Map<String, dynamic>>?> getPortfolioData(String userId) async {
    final key = '${_portfolioPrefix}holdings_$userId';
    return await get<List<Map<String, dynamic>>>(key, category: 'user_portfolio');
  }
  
  /// Cache portfolio data
  static Future<void> setPortfolioData(String userId, List<Map<String, dynamic>> portfolio) async {
    final key = '${_portfolioPrefix}holdings_$userId';
    await set(key, portfolio, category: 'user_portfolio');
  }
  
  /// Clean expired cache entries
  static Future<void> cleanExpiredCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys().where((key) => 
        key.startsWith(_marketDataPrefix) || 
        key.startsWith(_userDataPrefix) ||
        key.startsWith(_portfolioPrefix) ||
        key.startsWith(_newsPrefix)
      ).toList();
      
      int removedCount = 0;
      for (final key in keys) {
        final cachedDataJson = prefs.getString(key);
        if (cachedDataJson != null) {
          try {
            final cachedData = jsonDecode(cachedDataJson);
            final timestamp = DateTime.parse(cachedData['timestamp']);
            final category = cachedData['category'] ?? 'market_data';
            final ttlMinutes = _cacheTTL[category] ?? 5;
            
            if (DateTime.now().difference(timestamp).inMinutes >= ttlMinutes) {
              await prefs.remove(key);
              removedCount++;
            }
          } catch (e) {
            // Invalid cache entry, remove it
            await prefs.remove(key);
            removedCount++;
          }
        }
      }
      
      // Clean memory cache
      final now = DateTime.now();
      final expiredKeys = _memoryCache.entries
          .where((entry) => entry.value.isExpired)
          .map((entry) => entry.key)
          .toList();
      
      for (final key in expiredKeys) {
        _memoryCache.remove(key);
      }
      
      print('$_logPrefix 🧹 Cleaned $removedCount expired persistent entries, ${expiredKeys.length} memory entries');
    } catch (e) {
      print('$_logPrefix ❌ Error cleaning cache: $e');
    }
  }
  
  /// Get cache statistics
  static Map<String, dynamic> getStats() {
    final hitRate = _cacheHits + _cacheMisses > 0 
        ? (_cacheHits / (_cacheHits + _cacheMisses) * 100).toStringAsFixed(1)
        : '0.0';
    
    return {
      'cache_hits': _cacheHits,
      'cache_misses': _cacheMisses,
      'cache_evictions': _cacheEvictions,
      'hit_rate_percent': hitRate,
      'memory_cache_size': _memoryCache.length,
      'memory_cache_max': _maxMemoryCacheSize,
    };
  }
  
  /// Clear all cache
  static Future<void> clearAll() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys().where((key) => 
        key.startsWith(_marketDataPrefix) || 
        key.startsWith(_userDataPrefix) ||
        key.startsWith(_portfolioPrefix) ||
        key.startsWith(_newsPrefix)
      ).toList();
      
      for (final key in keys) {
        await prefs.remove(key);
      }
      
      _memoryCache.clear();
      
      // Reset stats
      _cacheHits = 0;
      _cacheMisses = 0;
      _cacheEvictions = 0;
      
      print('$_logPrefix 🗑️ All cache cleared');
    } catch (e) {
      print('$_logPrefix ❌ Error clearing cache: $e');
    }
  }
  
  /// Initialize cache service (call at app startup)
  static Future<void> initialize() async {
    print('$_logPrefix 🚀 Initializing optimized cache service...');
    
    // Clean expired entries on startup
    await cleanExpiredCache();
    
    // Schedule periodic cleanup every 30 minutes
    Timer.periodic(const Duration(minutes: 30), (timer) {
      cleanExpiredCache();
    });
    
    print('$_logPrefix ✅ Cache service initialized');
  }
}

/// Cache entry for memory cache
class _CacheEntry {
  final dynamic data;
  final DateTime expiry;
  
  _CacheEntry(this.data, this.expiry);
  
  bool get isExpired => DateTime.now().isAfter(expiry);
}