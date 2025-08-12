import 'dart:math';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/local_database_service.dart';

class RealisticPriceSimulator {
  static final SupabaseClient _supabase = Supabase.instance.client;
  static final Random _random = Random();
  
  // Base volatility for different asset types
  static const Map<String, double> _baseVolatility = {
    'stock': 0.02,      // 2% daily volatility
    'etf': 0.015,       // 1.5% daily volatility
    'crypto': 0.05,     // 5% daily volatility
  };
  
  // Market trend factors
  static double _marketTrend = 0.0; // -1 to 1 (bearish to bullish)
  static DateTime _lastTrendUpdate = DateTime.now();
  
  /// Update market trend periodically (every 30 minutes)
  static void _updateMarketTrend() {
    final now = DateTime.now();
    if (now.difference(_lastTrendUpdate).inMinutes >= 30) {
      // Gradual trend changes
      _marketTrend += (_random.nextDouble() - 0.5) * 0.3;
      _marketTrend = _marketTrend.clamp(-1.0, 1.0);
      _lastTrendUpdate = now;
      print('📈 Market trend updated to: ${(_marketTrend * 100).toStringAsFixed(1)}%');
    }
  }

  /// Generate realistic price change for an asset
  static double _generatePriceChange(String symbol, String type, double currentPrice) {
    _updateMarketTrend();
    
    // Base volatility for asset type
    final baseVol = _baseVolatility[type] ?? 0.02;
    
    // Symbol-specific volatility adjustments
    double symbolVol = 1.0;
    if (symbol == 'TSLA' || symbol == 'NVDA' || symbol == 'ARKK') {
      symbolVol = 2.0; // High volatility stocks
    } else if (symbol == 'KO' || symbol == 'PG' || symbol == 'JNJ') {
      symbolVol = 0.5; // Low volatility stocks
    }
    
    // Generate random price movement
    final randomFactor = (_random.nextDouble() - 0.5) * 2; // -1 to 1
    final volatility = baseVol * symbolVol;
    
    // Combine trend and random movement
    final trendWeight = 0.3;
    final randomWeight = 0.7;
    
    final priceChangePercent = (
      (_marketTrend * trendWeight) + 
      (randomFactor * randomWeight)
    ) * volatility;
    
    return currentPrice * priceChangePercent;
  }

  /// Simulate realistic price updates for all assets
  static Future<void> simulateRealisticPriceUpdates() async {
    try {
      print('🎯 Starting realistic price simulation...');
      
      // Get all assets from database
      List<Map<String, dynamic>> assets = [];
      
      try {
        final response = await _supabase
            .from('market_prices')
            .select('symbol, name, price, type, sector');
        assets = List<Map<String, dynamic>>.from(response);
      } catch (e) {
        print('❌ Supabase error, using local data: $e');
        // Fallback to local data or default assets
        assets = await _getDefaultAssets();
      }
      
      if (assets.isEmpty) {
        print('❌ No assets found for price simulation');
        return;
      }
      
      print('📊 Simulating prices for ${assets.length} assets');
      
      for (final asset in assets) {
        final symbol = asset['symbol'] as String;
        final type = asset['type'] as String;
        final currentPrice = (asset['price'] as num).toDouble();
        
        // Generate realistic price change
        final priceChange = _generatePriceChange(symbol, type, currentPrice);
        final newPrice = currentPrice + priceChange;
        final changePercent = (priceChange / currentPrice) * 100;
        
        // Update in database
        final updatedAsset = {
          'symbol': symbol,
          'name': asset['name'],
          'price': newPrice,
          'change_24h': priceChange,
          'change_percent_24h': changePercent,
          'type': type,
          'sector': asset['sector'],
          'last_updated': DateTime.now().toIso8601String(),
        };
        
        try {
          await _supabase.from('market_prices').upsert(updatedAsset);
        } catch (e) {
          // Fallback to local storage
          await LocalDatabaseService.saveSetting('market_price_$symbol', updatedAsset);
        }
        
        // Log significant price changes
        if (changePercent.abs() > 1.0) {
          final direction = changePercent > 0 ? '📈' : '📉';
          print('$direction $symbol: \$${newPrice.toStringAsFixed(2)} (${changePercent.toStringAsFixed(2)}%)');
        }
      }
      
      print('✅ Price simulation completed successfully');
      
    } catch (e) {
      print('❌ Error during price simulation: $e');
    }
  }

  /// Get default assets if database is empty
  static Future<List<Map<String, dynamic>>> _getDefaultAssets() async {
    return [
      {'symbol': 'AAPL', 'name': 'Apple Inc.', 'price': 175.0, 'type': 'stock', 'sector': 'Technology'},
      {'symbol': 'GOOGL', 'name': 'Alphabet Inc.', 'price': 140.0, 'type': 'stock', 'sector': 'Technology'},
      {'symbol': 'MSFT', 'name': 'Microsoft Corporation', 'price': 380.0, 'type': 'stock', 'sector': 'Technology'},
      {'symbol': 'AMZN', 'name': 'Amazon.com Inc.', 'price': 150.0, 'type': 'stock', 'sector': 'Technology'},
      {'symbol': 'TSLA', 'name': 'Tesla Inc.', 'price': 250.0, 'type': 'stock', 'sector': 'Technology'},
      {'symbol': 'META', 'name': 'Meta Platforms Inc.', 'price': 300.0, 'type': 'stock', 'sector': 'Technology'},
      {'symbol': 'NVDA', 'name': 'NVIDIA Corporation', 'price': 880.0, 'type': 'stock', 'sector': 'Technology'},
      {'symbol': 'JPM', 'name': 'JPMorgan Chase & Co.', 'price': 145.0, 'type': 'stock', 'sector': 'Financial'},
      {'symbol': 'V', 'name': 'Visa Inc.', 'price': 235.0, 'type': 'stock', 'sector': 'Financial'},
      {'symbol': 'WMT', 'name': 'Walmart Inc.', 'price': 157.0, 'type': 'stock', 'sector': 'Consumer'},
      {'symbol': 'SPY', 'name': 'SPDR S&P 500 ETF Trust', 'price': 440.0, 'type': 'etf', 'sector': 'Broad Market'},
      {'symbol': 'QQQ', 'name': 'Invesco QQQ Trust', 'price': 380.0, 'type': 'etf', 'sector': 'Technology'},
      {'symbol': 'BTC', 'name': 'Bitcoin', 'price': 67000.0, 'type': 'crypto', 'sector': 'Cryptocurrency'},
      {'symbol': 'ETH', 'name': 'Ethereum', 'price': 3400.0, 'type': 'crypto', 'sector': 'Cryptocurrency'},
    ];
  }

  /// Create market events (news-driven price movements)
  static Future<void> simulateMarketEvent() async {
    try {
      print('📰 Simulating market event...');
      
      // Random market events
      final events = [
        {'type': 'earnings', 'impact': 0.08, 'sector': 'Technology'},
        {'type': 'fed_announcement', 'impact': 0.05, 'sector': 'all'},
        {'type': 'sector_news', 'impact': 0.06, 'sector': 'Healthcare'},
        {'type': 'crypto_news', 'impact': 0.12, 'sector': 'Cryptocurrency'},
      ];
      
      final event = events[_random.nextInt(events.length)];
      final impactMultiplier = (_random.nextDouble() - 0.5) * 2 * (event['impact'] as double);
      
      // Apply event to relevant assets
      final response = await _supabase
          .from('market_prices')
          .select('symbol, name, price, type, sector')
          .eq('sector', event['sector'] as String);
      
      for (final asset in response) {
        final symbol = asset['symbol'] as String;
        final currentPrice = (asset['price'] as num).toDouble();
        
        // Apply event impact
        final eventChange = currentPrice * impactMultiplier;
        final newPrice = currentPrice + eventChange;
        final changePercent = (eventChange / currentPrice) * 100;
        
        await _supabase.from('market_prices').update({
          'price': newPrice,
          'change_24h': eventChange,
          'change_percent_24h': changePercent,
          'last_updated': DateTime.now().toIso8601String(),
        }).eq('symbol', symbol);
        
        final direction = changePercent > 0 ? '📈' : '📉';
        print('$direction ${event['type']} impact on $symbol: ${changePercent.toStringAsFixed(2)}%');
      }
      
    } catch (e) {
      print('❌ Error simulating market event: $e');
    }
  }

  /// Generate intraday price movements (more frequent, smaller changes)
  static Future<void> simulateIntradayMovements() async {
    try {
      // Get active trading assets
      final response = await _supabase
          .from('market_prices')
          .select('symbol, name, price, type')
          .limit(20); // Focus on top 20 assets for performance
      
      for (final asset in response) {
        final symbol = asset['symbol'] as String;
        final type = asset['type'] as String;
        final currentPrice = (asset['price'] as num).toDouble();
        
        // Smaller intraday movements (0.1% to 0.5%)
        final maxChange = _baseVolatility[type]! * 0.25; // 25% of daily volatility
        final changePercent = (_random.nextDouble() - 0.5) * 2 * maxChange;
        final priceChange = currentPrice * changePercent;
        final newPrice = currentPrice + priceChange;
        
        await _supabase.from('market_prices').update({
          'price': newPrice,
          'change_24h': priceChange,
          'change_percent_24h': changePercent * 100,
          'last_updated': DateTime.now().toIso8601String(),
        }).eq('symbol', symbol);
      }
      
    } catch (e) {
      print('❌ Error simulating intraday movements: $e');
    }
  }

  /// Get current market summary
  static Future<Map<String, dynamic>> getMarketSummary() async {
    try {
      final response = await _supabase
          .from('market_prices')
          .select('change_percent_24h, type');
      
      double totalChange = 0;
      int stockCount = 0;
      int gainers = 0;
      int losers = 0;
      
      for (final asset in response) {
        final change = (asset['change_percent_24h'] as num?)?.toDouble() ?? 0.0;
        if (asset['type'] == 'stock') {
          totalChange += change;
          stockCount++;
          if (change > 0) gainers++;
          if (change < 0) losers++;
        }
      }
      
      return {
        'market_trend': _marketTrend,
        'average_change': stockCount > 0 ? totalChange / stockCount : 0.0,
        'gainers': gainers,
        'losers': losers,
        'last_updated': DateTime.now().toIso8601String(),
      };
      
    } catch (e) {
      print('❌ Error getting market summary: $e');
      return {'market_trend': 0.0, 'average_change': 0.0, 'gainers': 0, 'losers': 0};
    }
  }
}