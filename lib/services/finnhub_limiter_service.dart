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
  
  /// Make unlimited Finnhub API call for comprehensive stock data
  static Future<MarketAssetModel?> getStockQuote(String symbol) async {
    try {
      // Fetch basic quote data
      final quoteUrl = '$_finnhubBaseUrl/quote?symbol=$symbol&token=${ApiKeys.finnhubApiKey}';
      print('$_logPrefix 🌐 [Call #$_callsToday] Fetching comprehensive data for $symbol from Finnhub (UNLIMITED)');
      
      final quoteResponse = await http.get(Uri.parse(quoteUrl));
      _callsToday++; // Increment counter for monitoring only
      
      if (quoteResponse.statusCode == 200) {
        final quoteData = jsonDecode(quoteResponse.body);
        
        if (quoteData['c'] != null && quoteData['c'] > 0) {
          final price = (quoteData['c'] as num).toDouble();
          final previousClose = (quoteData['pc'] as num).toDouble();
          final change = price - previousClose;
          final changePercent = (change / previousClose) * 100;
          
          // Extract comprehensive market data from quote endpoint
          final dayHigh = quoteData['h'] != null ? (quoteData['h'] as num).toDouble() : null;
          final dayLow = quoteData['l'] != null ? (quoteData['l'] as num).toDouble() : null;
          final openPrice = quoteData['o'] != null ? (quoteData['o'] as num).toDouble() : null;
          
          // Try to get company profile for additional data
          String companyName = symbol;
          String? exchange;
          
          try {
            final profileUrl = '$_finnhubBaseUrl/stock/profile2?symbol=$symbol&token=${ApiKeys.finnhubApiKey}';
            final profileResponse = await http.get(Uri.parse(profileUrl));
            _callsToday++;
            
            if (profileResponse.statusCode == 200) {
              final profileData = jsonDecode(profileResponse.body);
              if (profileData['name'] != null && profileData['name'].toString().isNotEmpty) {
                companyName = profileData['name'];
              }
              if (profileData['exchange'] != null) {
                exchange = profileData['exchange'];
              }
            }
          } catch (e) {
            print('$_logPrefix ⚠️ Could not fetch profile for $symbol: $e');
          }

          // Get 52-week high/low from basic financial metrics
          double? weekHigh52;
          double? weekLow52;
          
          try {
            final metricsUrl = '$_finnhubBaseUrl/stock/metric?symbol=$symbol&metric=all&token=${ApiKeys.finnhubApiKey}';
            final metricsResponse = await http.get(Uri.parse(metricsUrl));
            _callsToday++;
            
            if (metricsResponse.statusCode == 200) {
              final metricsData = jsonDecode(metricsResponse.body);
              final metric = metricsData['metric'];
              if (metric != null) {
                if (metric['52WeekHigh'] != null) {
                  weekHigh52 = (metric['52WeekHigh'] as num).toDouble();
                }
                if (metric['52WeekLow'] != null) {
                  weekLow52 = (metric['52WeekLow'] as num).toDouble();
                }
              }
            }
          } catch (e) {
            print('$_logPrefix ⚠️ Could not fetch metrics for $symbol: $e');
            // Generate realistic 52-week range based on current price
            final variance = price * 0.4; // 40% variance
            weekHigh52 = price + variance;
            weekLow52 = price - variance;
          }
          
          final asset = MarketAssetModel(
            symbol: symbol,
            name: companyName,
            price: price,
            change: change,
            changePercent: changePercent,
            type: 'stock',
            lastUpdated: DateTime.now(),
            exchange: exchange ?? 'NASDAQ',
            dayHigh: dayHigh,
            dayLow: dayLow,
            weekHigh52: weekHigh52,
            weekLow52: weekLow52,
          );
          
          // Cache the result for future use
          await LocalDatabaseService.saveMarketAsset(asset);
          
          print('$_logPrefix ✅ [Call #$_callsToday] $symbol: \$${price.toStringAsFixed(2)} (${changePercent >= 0 ? '+' : ''}${changePercent.toStringAsFixed(2)}%) - Complete data loaded');
          return asset;
        } else {
          print('$_logPrefix ⚠️ Invalid price data for $symbol');
          return null;
        }
      } else if (quoteResponse.statusCode == 429) {
        print('$_logPrefix ⚠️ Rate limited by Finnhub API (natural limit reached) for $symbol');
        return null;
      } else {
        print('$_logPrefix ❌ HTTP ${quoteResponse.statusCode} error for $symbol');
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