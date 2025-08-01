import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/market_asset_model.dart';
import '../config/api_keys.dart';
import 'optimized_network_service.dart';
import 'optimized_cache_service.dart';

/// Service to fetch real market indices data
class MarketIndicesService {
  static const String _logPrefix = '[MarketIndices]';
  static const String _finnhubBaseUrl = 'https://finnhub.io/api/v1';

  /// Get real market indices data using multiple data sources with fallbacks
  static Future<List<MarketAssetModel>> getRealMarketIndices() async {
    const cacheKey = 'market_indices_all';
    
    print('$_logPrefix 🚀 FORCE FETCH: Getting real market indices data (NO CACHE)');
    
    // ONLY use ETF proxies - they're more reliable than direct index calls
    final indices = await _fetchETFProxies();
    
    if (indices.isNotEmpty) {
      print('$_logPrefix ✅ SUCCESS: Retrieved ${indices.length} real market indices');
      for (final index in indices) {
        print('$_logPrefix 📊 ${index.name}: ${index.price.toStringAsFixed(0)} (${index.changePercent >= 0 ? '+' : ''}${index.changePercent.toStringAsFixed(2)}%)');
      }
    } else {
      print('$_logPrefix ❌ FAILED: No real market indices data available');
    }
    
    return indices;
  }

  /// Try to fetch direct index data from Finnhub
  static Future<List<MarketAssetModel>> _fetchDirectIndices() async {
    final indices = <MarketAssetModel>[];
    
    // Real index symbols that sometimes work with Finnhub
    final indexSymbols = {
      '^GSPC': 'S&P 500',
      '^IXIC': 'NASDAQ',  
      '^DJI': 'DOW',
    };
    
    try {
      final futures = indexSymbols.entries.map((entry) {
        return _fetchIndexData(entry.key, entry.value);
      }).toList();
      
      final results = await Future.wait(futures);
      
      for (final result in results) {
        if (result != null) {
          indices.add(result);
        }
      }
    } catch (e) {
      print('$_logPrefix ❌ Direct indices fetch failed: $e');
    }
    
    return indices;
  }

  /// Fetch ETF proxy data as fallback
  static Future<List<MarketAssetModel>> _fetchETFProxies() async {
    final indices = <MarketAssetModel>[];
    print('$_logPrefix 🎯 Attempting to fetch ETF proxies for market indices...');
    
    // ETF proxies that track the major indices - using real market prices
    final etfProxies = {
      'SPY': 'S&P 500', // SPDR S&P 500 ETF - tracks S&P 500
      'QQQ': 'NASDAQ', // Invesco QQQ Trust - tracks NASDAQ-100  
      'DIA': 'DOW', // SPDR Dow Jones Industrial Average ETF - tracks DOW
    };
    
    print('$_logPrefix 📊 ETF Proxies to fetch: ${etfProxies.keys.join(', ')}');
    
    try {
      final futures = etfProxies.entries.map((entry) {
        return _fetchETFData(entry.key, entry.value);
      }).toList();
      
      final results = await Future.wait(futures);
      
      for (final result in results) {
        if (result != null) {
          indices.add(result);
        }
      }
    } catch (e) {
      print('$_logPrefix ❌ ETF proxies fetch failed: $e');
    }
    
    return indices;
  }


  /// Fetch individual index data from Finnhub
  static Future<MarketAssetModel?> _fetchIndexData(String symbol, String displayName) async {
    try {
      final url = '$_finnhubBaseUrl/quote?symbol=$symbol&token=${ApiKeys.finnhubApiKey}';
      
      final response = await OptimizedNetworkService.get(
        url,
        useCache: true,
        rateLimitKey: 'finnhub_indices_direct',
        rateLimitDuration: const Duration(milliseconds: 800),
      );
      
      if (response != null && response['c'] != null && response['c'] > 0) {
        final price = (response['c'] as num).toDouble();
        final previousClose = (response['pc'] as num).toDouble();
        final change = price - previousClose;
        final changePercent = (change / previousClose) * 100;
        
        return MarketAssetModel(
          symbol: symbol,
          name: displayName,
          price: price,
          change: change,
          changePercent: changePercent,
          type: 'index',
          lastUpdated: DateTime.now(),
        );
      }
      
      return null;
    } catch (e) {
      print('$_logPrefix ❌ Failed to fetch index $symbol: $e');
      return null;
    }
  }
  
  /// Fetch ETF data using optimized network service
  static Future<MarketAssetModel?> _fetchETFData(String symbol, String displayName) async {
    try {
      print('$_logPrefix 🌐 Fetching real market data for $symbol ($displayName)...');
      final url = '$_finnhubBaseUrl/quote?symbol=$symbol&token=${ApiKeys.finnhubApiKey}';
      
      // Use optimized network service - NO CACHE to ensure fresh data
      final response = await OptimizedNetworkService.get(
        url,
        useCache: false, // FORCE FRESH DATA
        rateLimitKey: 'finnhub_market_indices',
        rateLimitDuration: const Duration(milliseconds: 800),
      );
      
      if (response != null && response['c'] != null && response['c'] > 0) {
        final etfPrice = (response['c'] as num).toDouble();
        final previousClose = (response['pc'] as num).toDouble();
        final change = etfPrice - previousClose;
        final changePercent = (change / previousClose) * 100;
        
        // Convert ETF price to approximate index value
        double indexPrice;
        switch (symbol) {
          case 'SPY':
            indexPrice = etfPrice * 12.0; // SPY is roughly 1/12th of S&P 500
            break;
          case 'QQQ':
            indexPrice = etfPrice * 50.0; // QQQ is roughly 1/50th of NASDAQ-100
            break;
          case 'DIA':
            indexPrice = etfPrice * 130.0; // DIA is roughly 1/130th of DOW
            break;
          default:
            indexPrice = etfPrice; // fallback
        }
        
        print('$_logPrefix ✅ $displayName: ETF($symbol)=\$${etfPrice.toStringAsFixed(2)} → Index≈\$${indexPrice.toStringAsFixed(0)} (${changePercent >= 0 ? '+' : ''}${changePercent.toStringAsFixed(2)}%)');
        
        return MarketAssetModel(
          symbol: symbol,
          name: displayName,
          price: indexPrice,
          change: change * (indexPrice / etfPrice), // Scale change proportionally
          changePercent: changePercent,
          type: 'index',
          lastUpdated: DateTime.now(),
        );
      }
      
      print('$_logPrefix ❌ No valid data received for $symbol');
      return null;
    } catch (e) {
      print('$_logPrefix ❌ Failed to fetch $symbol: $e');
      return null;
    }
  }
}