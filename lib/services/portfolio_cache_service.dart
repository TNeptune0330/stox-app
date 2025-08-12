import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/portfolio_model.dart';
import '../models/transaction_model.dart';

/// Advanced caching service for portfolio data to minimize database calls
class PortfolioCacheService {
  static const String _logPrefix = '[PortfolioCache]';
  
  // Cache keys
  static const String _portfolioKey = 'portfolio_cache';
  static const String _transactionsKey = 'transactions_cache';
  static const String _summaryKey = 'summary_cache';
  static const String _statsKey = 'stats_cache';
  static const String _lastUpdateKey = 'portfolio_last_update';
  
  // Cache duration (5 minutes for portfolio data)
  static const Duration _cacheValidDuration = Duration(minutes: 5);
  
  /// Check if cache is still valid
  static Future<bool> isCacheValid() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lastUpdateStr = prefs.getString(_lastUpdateKey);
      
      if (lastUpdateStr == null) {
        print('$_logPrefix No cache timestamp found');
        return false;
      }
      
      final lastUpdate = DateTime.parse(lastUpdateStr);
      final now = DateTime.now();
      final isValid = now.difference(lastUpdate) < _cacheValidDuration;
      
      print('$_logPrefix Cache valid: $isValid (age: ${now.difference(lastUpdate).inMinutes}m)');
      return isValid;
    } catch (e) {
      print('$_logPrefix Error checking cache validity: $e');
      return false;
    }
  }
  
  /// Cache portfolio data
  static Future<void> cachePortfolioData({
    required List<PortfolioModel> portfolio,
    required List<TransactionModel> transactions,
    required Map<String, dynamic> summary,
    required Map<String, dynamic> stats,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Cache portfolio holdings
      final portfolioJson = portfolio.map((p) => p.toJson()).toList();
      await prefs.setString(_portfolioKey, jsonEncode(portfolioJson));
      
      // Cache transactions
      final transactionsJson = transactions.map((t) => t.toJson()).toList();
      await prefs.setString(_transactionsKey, jsonEncode(transactionsJson));
      
      // Cache summary and stats
      await prefs.setString(_summaryKey, jsonEncode(summary));
      await prefs.setString(_statsKey, jsonEncode(stats));
      
      // Update cache timestamp
      await prefs.setString(_lastUpdateKey, DateTime.now().toIso8601String());
      
      print('$_logPrefix ✅ Cached portfolio data: ${portfolio.length} holdings, ${transactions.length} transactions');
    } catch (e) {
      print('$_logPrefix ❌ Error caching portfolio data: $e');
    }
  }
  
  /// Get cached portfolio data
  static Future<Map<String, dynamic>?> getCachedPortfolioData() async {
    try {
      if (!await isCacheValid()) {
        print('$_logPrefix Cache expired or invalid');
        return null;
      }
      
      final prefs = await SharedPreferences.getInstance();
      
      final portfolioStr = prefs.getString(_portfolioKey);
      final transactionsStr = prefs.getString(_transactionsKey);
      final summaryStr = prefs.getString(_summaryKey);
      final statsStr = prefs.getString(_statsKey);
      
      if (portfolioStr == null || transactionsStr == null || 
          summaryStr == null || statsStr == null) {
        print('$_logPrefix Incomplete cache data');
        return null;
      }
      
      // Parse cached data
      final portfolioJson = jsonDecode(portfolioStr) as List;
      final transactionsJson = jsonDecode(transactionsStr) as List;
      final summary = jsonDecode(summaryStr) as Map<String, dynamic>;
      final stats = jsonDecode(statsStr) as Map<String, dynamic>;
      
      final portfolio = portfolioJson.map((json) => PortfolioModel.fromJson(json)).toList();
      final transactions = transactionsJson.map((json) => TransactionModel.fromJson(json)).toList();
      
      print('$_logPrefix ✅ Retrieved cached data: ${portfolio.length} holdings, ${transactions.length} transactions');
      
      return {
        'portfolio': portfolio,
        'transactions': transactions,
        'summary': summary,
        'stats': stats,
      };
    } catch (e) {
      print('$_logPrefix ❌ Error retrieving cached data: $e');
      return null;
    }
  }
  
  /// Clear all portfolio cache
  static Future<void> clearCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_portfolioKey);
      await prefs.remove(_transactionsKey);
      await prefs.remove(_summaryKey);
      await prefs.remove(_statsKey);
      await prefs.remove(_lastUpdateKey);
      
      print('$_logPrefix 🗑️ Portfolio cache cleared');
    } catch (e) {
      print('$_logPrefix ❌ Error clearing cache: $e');
    }
  }
  
  /// Cache specific portfolio summary (for quick access)
  static Future<void> cacheSummaryOnly(Map<String, dynamic> summary) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_summaryKey, jsonEncode(summary));
      print('$_logPrefix ✅ Summary cached');
    } catch (e) {
      print('$_logPrefix ❌ Error caching summary: $e');
    }
  }
  
  /// Get cached summary only (for portfolio card display)
  static Future<Map<String, dynamic>?> getCachedSummary() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final summaryStr = prefs.getString(_summaryKey);
      
      if (summaryStr == null) {
        return null;
      }
      
      return jsonDecode(summaryStr) as Map<String, dynamic>;
    } catch (e) {
      print('$_logPrefix ❌ Error retrieving cached summary: $e');
      return null;
    }
  }
  
  /// Force refresh cache (invalidate current cache)
  static Future<void> invalidateCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_lastUpdateKey);
      print('$_logPrefix ♻️ Cache invalidated - will refresh on next load');
    } catch (e) {
      print('$_logPrefix ❌ Error invalidating cache: $e');
    }
  }
  
  /// Get cache statistics
  static Future<Map<String, dynamic>> getCacheStats() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lastUpdateStr = prefs.getString(_lastUpdateKey);
      final portfolioStr = prefs.getString(_portfolioKey);
      final transactionsStr = prefs.getString(_transactionsKey);
      
      final hasCache = lastUpdateStr != null && portfolioStr != null && transactionsStr != null;
      final isValid = hasCache ? await isCacheValid() : false;
      
      DateTime? lastUpdate;
      if (lastUpdateStr != null) {
        lastUpdate = DateTime.parse(lastUpdateStr);
      }
      
      return {
        'hasCache': hasCache,
        'isValid': isValid,
        'lastUpdate': lastUpdate,
        'cacheAge': lastUpdate != null ? DateTime.now().difference(lastUpdate) : null,
        'portfolioSize': portfolioStr?.length ?? 0,
        'transactionsSize': transactionsStr?.length ?? 0,
      };
    } catch (e) {
      print('$_logPrefix ❌ Error getting cache stats: $e');
      return {
        'hasCache': false,
        'isValid': false,
        'error': e.toString(),
      };
    }
  }
}