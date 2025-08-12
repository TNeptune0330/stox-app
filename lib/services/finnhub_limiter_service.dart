import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_keys.dart';
import '../models/market_asset_model.dart';
import '../services/local_database_service.dart';

/// Service for unlimited Finnhub API calls - use to maximum capacity
class FinnhubLimiterService {
  static const String _logPrefix = '[Finnhub-MAX]';
  static const String _finnhubBaseUrl = 'https://finnhub.io/api/v1';
  
  // Track API calls for monitoring only (no limits)
  static int _callsToday = 0;
  static DateTime _lastResetDate = DateTime.now();
  
  /// Always returns true - no artificial limits
  static bool canMakeCall() {
    _resetCounterIfNewDay();
    return true; // UNLIMITED - use to maximum API capacity
  }
  
  /// Get current usage stats (monitoring only)
  static Map<String, dynamic> getUsageStats() {
    _resetCounterIfNewDay();
    return {
      'callsUsed': _callsToday,
      'maxCalls': 'UNLIMITED',
      'remaining': 'UNLIMITED',
      'resetDate': _lastResetDate,
    };
  }
  
  /// Reset counter if it's a new day (monitoring only)
  static void _resetCounterIfNewDay() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final lastResetDay = DateTime(_lastResetDate.year, _lastResetDate.month, _lastResetDate.day);
    
    if (today.isAfter(lastResetDay)) {
      print('$_logPrefix 🔄 New day detected, resetting call counter (monitoring only)');
      _callsToday = 0;
      _lastResetDate = now;
    }
  }
  
  /// Make unlimited Finnhub API call for stock quote
  static Future<MarketAssetModel?> getStockQuote(String symbol) async {
    try {
      final url = '$_finnhubBaseUrl/quote?symbol=$symbol&token=${ApiKeys.finnhubApiKey}';
      print('$_logPrefix 🌐 [Call #$_callsToday] Fetching $symbol from Finnhub (UNLIMITED)');
      
      final response = await http.get(Uri.parse(url));
      _callsToday++; // Increment counter for monitoring only
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        if (data['c'] != null && data['c'] > 0) {
          final price = (data['c'] as num).toDouble();
          final previousClose = (data['pc'] as num).toDouble();
          final change = price - previousClose;
          final changePercent = (change / previousClose) * 100;
          
          final asset = MarketAssetModel(
            symbol: symbol,
            name: symbol, // We'll need to get name from elsewhere
            price: price,
            change: change,
            changePercent: changePercent,
            type: 'stock',
            lastUpdated: DateTime.now(),
          );
          
          // Cache the result for future use
          await LocalDatabaseService.saveMarketAsset(asset);
          
          print('$_logPrefix ✅ [Call #$_callsToday] $symbol: \$${price.toStringAsFixed(2)} (${changePercent >= 0 ? '+' : ''}${changePercent.toStringAsFixed(2)}%)');
          return asset;
        } else {
          print('$_logPrefix ⚠️ Invalid price data for $symbol');
          return null;
        }
      } else if (response.statusCode == 429) {
        print('$_logPrefix ⚠️ Rate limited by Finnhub API (natural limit reached) for $symbol');
        return null;
      } else {
        print('$_logPrefix ❌ HTTP ${response.statusCode} error for $symbol');
        return null;
      }
    } catch (e) {
      print('$_logPrefix ❌ Exception fetching $symbol: $e');
      return null;
    }
  }
  
  /// All stocks are now priority - use Finnhub for everything
  static List<String> getPriorityStocks() {
    return []; // No longer needed - all stocks use Finnhub
  }
  
  /// All stocks should use Finnhub (unlimited usage)
  static bool isPriorityStock(String symbol) {
    return true; // ALL stocks are priority - use Finnhub for maximum accuracy
  }
}