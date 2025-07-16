import 'dart:convert';
import 'dart:math';
import 'package:http/http.dart' as http;
import '../config/api_keys.dart';
import '../models/market_asset_model.dart';
import '../services/local_database_service.dart';

class EnhancedMarketDataService {
  static const String _logPrefix = '[MarketData]';
  
  // API endpoints
  static const String _finnhubBaseUrl = 'https://finnhub.io/api/v1';
  static const String _coinGeckoBaseUrl = 'https://api.coingecko.com/api/v3';
  static const String _alphaVantageBaseUrl = 'https://www.alphavantage.co/query';
  
  // Rate limiting
  static DateTime _lastApiCall = DateTime.now().subtract(Duration(seconds: 2));
  static const Duration _apiCallDelay = Duration(milliseconds: 1200);
  
  // Essential assets for the trading game
  static const List<String> _essentialStocks = [
    'AAPL', 'GOOGL', 'MSFT', 'AMZN', 'TSLA', 'META', 'NVDA', 'JPM', 'V', 'WMT',
    'SPY', 'QQQ', 'VOO', 'IWM', 'DIA', 'BRK.B', 'JNJ', 'PG', 'KO', 'HD'
  ];
  
  static const List<String> _essentialCryptos = [
    'bitcoin', 'ethereum', 'binancecoin', 'ripple', 'cardano', 'solana',
    'polkadot', 'dogecoin', 'avalanche-2', 'shiba-inu', 'chainlink', 'polygon'
  ];
  
  // Company names for stocks
  static const Map<String, String> _stockNames = {
    'AAPL': 'Apple Inc.',
    'GOOGL': 'Alphabet Inc.',
    'MSFT': 'Microsoft Corporation',
    'AMZN': 'Amazon.com Inc.',
    'TSLA': 'Tesla Inc.',
    'META': 'Meta Platforms Inc.',
    'NVDA': 'NVIDIA Corporation',
    'JPM': 'JPMorgan Chase & Co.',
    'V': 'Visa Inc.',
    'WMT': 'Walmart Inc.',
    'SPY': 'SPDR S&P 500 ETF',
    'QQQ': 'Invesco QQQ Trust',
    'VOO': 'Vanguard S&P 500 ETF',
    'IWM': 'iShares Russell 2000 ETF',
    'DIA': 'SPDR Dow Jones Industrial Average ETF',
    'BRK.B': 'Berkshire Hathaway Inc.',
    'JNJ': 'Johnson & Johnson',
    'PG': 'Procter & Gamble Company',
    'KO': 'The Coca-Cola Company',
    'HD': 'The Home Depot Inc.'
  };
  
  static const Map<String, String> _cryptoNames = {
    'bitcoin': 'Bitcoin',
    'ethereum': 'Ethereum',
    'binancecoin': 'Binance Coin',
    'ripple': 'XRP',
    'cardano': 'Cardano',
    'solana': 'Solana',
    'polkadot': 'Polkadot',
    'dogecoin': 'Dogecoin',
    'avalanche-2': 'Avalanche',
    'shiba-inu': 'Shiba Inu',
    'chainlink': 'Chainlink',
    'polygon': 'Polygon'
  };
  
  // Initialize market data
  static Future<void> initializeMarketData() async {
    try {
      print('$_logPrefix Initializing market data...');
      
      // Check if we have recent data
      final existingAssets = LocalDatabaseService.getMarketAssets();
      final hasRecentData = existingAssets.isNotEmpty && 
          existingAssets.any((asset) => 
            DateTime.now().difference(asset.lastUpdated).inMinutes < 30);
      
      if (hasRecentData) {
        print('$_logPrefix Using cached market data (less than 30 minutes old)');
        return;
      }
      
      // Update market data from APIs
      await updateAllMarketData();
      
    } catch (e) {
      print('$_logPrefix ❌ Error initializing market data: $e');
      // Create mock data if all else fails
      await _createMockMarketData();
    }
  }
  
  static Future<void> updateAllMarketData() async {
    try {
      print('$_logPrefix 🔄 Updating all market data...');
      
      // Update stocks and cryptos in parallel
      final futures = <Future>[
        _updateStockData(),
        _updateCryptoData(),
      ];
      
      await Future.wait(futures);
      
      print('$_logPrefix ✅ Market data update completed');
    } catch (e) {
      print('$_logPrefix ❌ Error updating market data: $e');
    }
  }
  
  static Future<void> _updateStockData() async {
    try {
      print('$_logPrefix 📈 Updating stock data...');
      
      for (final symbol in _essentialStocks) {
        try {
          await _waitForRateLimit();
          
          // Try Finnhub first
          if (await _updateStockFromFinnhub(symbol)) {
            continue;
          }
          
          // Try Alpha Vantage as backup
          if (await _updateStockFromAlphaVantage(symbol)) {
            continue;
          }
          
          // Create mock data as last resort
          await _createMockStockData(symbol);
          
        } catch (e) {
          print('$_logPrefix ❌ Error updating $symbol: $e');
          await _createMockStockData(symbol);
        }
      }
      
      print('$_logPrefix ✅ Stock data updated');
    } catch (e) {
      print('$_logPrefix ❌ Error updating stock data: $e');
    }
  }
  
  static Future<bool> _updateStockFromFinnhub(String symbol) async {
    try {
      final url = '$_finnhubBaseUrl/quote?symbol=$symbol&token=${ApiKeys.finnhubApiKey}';
      final response = await http.get(Uri.parse(url));
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        if (data['c'] != null && data['c'] > 0) {
          final price = (data['c'] as num).toDouble();
          final previousClose = (data['pc'] as num).toDouble();
          final change = price - previousClose;
          final changePercent = (change / previousClose) * 100;
          
          final asset = MarketAssetModel(
            symbol: symbol,
            name: _stockNames[symbol] ?? symbol,
            price: price,
            change: change,
            changePercent: changePercent,
            type: _getStockType(symbol),
            lastUpdated: DateTime.now(),
          );
          
          await LocalDatabaseService.saveMarketAsset(asset);
          print('$_logPrefix ✅ [Finnhub] Updated $symbol: \$${price.toStringAsFixed(2)} (${changePercent.toStringAsFixed(2)}%)');
          return true;
        }
      }
      
      return false;
    } catch (e) {
      print('$_logPrefix ❌ Finnhub error for $symbol: $e');
      return false;
    }
  }
  
  static Future<bool> _updateStockFromAlphaVantage(String symbol) async {
    try {
      final url = '$_alphaVantageBaseUrl?function=GLOBAL_QUOTE&symbol=$symbol&apikey=${ApiKeys.alphaVantageApiKey}';
      final response = await http.get(Uri.parse(url));
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final quote = data['Global Quote'];
        
        if (quote != null && quote['05. price'] != null) {
          final price = double.parse(quote['05. price']);
          final change = double.parse(quote['09. change']);
          final changePercent = double.parse(quote['10. change percent'].replaceAll('%', ''));
          
          final asset = MarketAssetModel(
            symbol: symbol,
            name: _stockNames[symbol] ?? symbol,
            price: price,
            change: change,
            changePercent: changePercent,
            type: _getStockType(symbol),
            lastUpdated: DateTime.now(),
          );
          
          await LocalDatabaseService.saveMarketAsset(asset);
          print('$_logPrefix ✅ [Alpha Vantage] Updated $symbol: \$${price.toStringAsFixed(2)} (${changePercent.toStringAsFixed(2)}%)');
          return true;
        }
      }
      
      return false;
    } catch (e) {
      print('$_logPrefix ❌ Alpha Vantage error for $symbol: $e');
      return false;
    }
  }
  
  static Future<void> _updateCryptoData() async {
    try {
      print('$_logPrefix 🪙 Updating crypto data...');
      
      // Get all crypto data in one API call
      final ids = _essentialCryptos.join(',');
      final url = '$_coinGeckoBaseUrl/simple/price?ids=$ids&vs_currencies=usd&include_24hr_change=true';
      
      await _waitForRateLimit();
      final response = await http.get(Uri.parse(url));
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        for (final cryptoId in _essentialCryptos) {
          final cryptoData = data[cryptoId];
          if (cryptoData != null) {
            final price = (cryptoData['usd'] as num).toDouble();
            final changePercent = (cryptoData['usd_24h_change'] as num?)?.toDouble() ?? 0.0;
            final change = price * (changePercent / 100);
            
            final asset = MarketAssetModel(
              symbol: _getCryptoSymbol(cryptoId),
              name: _cryptoNames[cryptoId] ?? cryptoId,
              price: price,
              change: change,
              changePercent: changePercent,
              type: 'crypto',
              lastUpdated: DateTime.now(),
            );
            
            await LocalDatabaseService.saveMarketAsset(asset);
            print('$_logPrefix ✅ [CoinGecko] Updated ${asset.symbol}: \$${price.toStringAsFixed(2)} (${changePercent.toStringAsFixed(2)}%)');
          }
        }
      } else {
        print('$_logPrefix ❌ CoinGecko API error: ${response.statusCode}');
        await _createMockCryptoData();
      }
      
    } catch (e) {
      print('$_logPrefix ❌ Error updating crypto data: $e');
      await _createMockCryptoData();
    }
  }
  
  static Future<void> _createMockMarketData() async {
    print('$_logPrefix 📊 Creating mock market data...');
    
    // Create mock stock data
    for (final symbol in _essentialStocks) {
      await _createMockStockData(symbol);
    }
    
    // Create mock crypto data
    await _createMockCryptoData();
    
    print('$_logPrefix ✅ Mock market data created');
  }
  
  static Future<void> _createMockStockData(String symbol) async {
    final random = Random();
    final basePrice = _getBasePriceForStock(symbol);
    final price = basePrice + (random.nextDouble() * 20 - 10);
    final changePercent = (random.nextDouble() * 10 - 5);
    final change = price * (changePercent / 100);
    
    final asset = MarketAssetModel(
      symbol: symbol,
      name: _stockNames[symbol] ?? symbol,
      price: price,
      change: change,
      changePercent: changePercent,
      type: _getStockType(symbol),
      lastUpdated: DateTime.now(),
    );
    
    await LocalDatabaseService.saveMarketAsset(asset);
    print('$_logPrefix 📊 [Mock] Created $symbol: \$${price.toStringAsFixed(2)} (${changePercent.toStringAsFixed(2)}%)');
  }
  
  static Future<void> _createMockCryptoData() async {
    final random = Random();
    final basePrices = {
      'bitcoin': 65000.0,
      'ethereum': 3500.0,
      'binancecoin': 600.0,
      'ripple': 0.60,
      'cardano': 0.45,
      'solana': 160.0,
      'polkadot': 6.50,
      'dogecoin': 0.15,
      'avalanche-2': 37.0,
      'shiba-inu': 0.000024,
      'chainlink': 15.0,
      'polygon': 0.85,
    };
    
    for (final cryptoId in _essentialCryptos) {
      final basePrice = basePrices[cryptoId] ?? 1.0;
      final price = basePrice + (random.nextDouble() * basePrice * 0.2 - basePrice * 0.1);
      final changePercent = (random.nextDouble() * 20 - 10);
      final change = price * (changePercent / 100);
      
      final asset = MarketAssetModel(
        symbol: _getCryptoSymbol(cryptoId),
        name: _cryptoNames[cryptoId] ?? cryptoId,
        price: price,
        change: change,
        changePercent: changePercent,
        type: 'crypto',
        lastUpdated: DateTime.now(),
      );
      
      await LocalDatabaseService.saveMarketAsset(asset);
      print('$_logPrefix 📊 [Mock] Created ${asset.symbol}: \$${price.toStringAsFixed(2)} (${changePercent.toStringAsFixed(2)}%)');
    }
  }
  
  static String _getCryptoSymbol(String cryptoId) {
    const symbolMap = {
      'bitcoin': 'BTC',
      'ethereum': 'ETH',
      'binancecoin': 'BNB',
      'ripple': 'XRP',
      'cardano': 'ADA',
      'solana': 'SOL',
      'polkadot': 'DOT',
      'dogecoin': 'DOGE',
      'avalanche-2': 'AVAX',
      'shiba-inu': 'SHIB',
      'chainlink': 'LINK',
      'polygon': 'MATIC',
    };
    
    return symbolMap[cryptoId] ?? cryptoId.toUpperCase();
  }
  
  static String _getStockType(String symbol) {
    const etfSymbols = {'SPY', 'QQQ', 'VOO', 'IWM', 'DIA'};
    return etfSymbols.contains(symbol) ? 'etf' : 'stock';
  }
  
  static double _getBasePriceForStock(String symbol) {
    const basePrices = {
      'AAPL': 210.0,
      'GOOGL': 184.0,
      'MSFT': 505.0,
      'AMZN': 225.0,
      'TSLA': 320.0,
      'META': 705.0,
      'NVDA': 170.0,
      'JPM': 286.0,
      'V': 349.0,
      'WMT': 95.0,
      'SPY': 623.0,
      'QQQ': 556.0,
      'VOO': 572.0,
      'IWM': 220.0,
      'DIA': 441.0,
      'BRK.B': 465.0,
      'JNJ': 155.0,
      'PG': 165.0,
      'KO': 62.0,
      'HD': 410.0,
    };
    
    return basePrices[symbol] ?? 100.0;
  }
  
  static Future<void> _waitForRateLimit() async {
    final now = DateTime.now();
    final timeSinceLastCall = now.difference(_lastApiCall);
    
    if (timeSinceLastCall < _apiCallDelay) {
      final waitTime = _apiCallDelay - timeSinceLastCall;
      await Future.delayed(waitTime);
    }
    
    _lastApiCall = DateTime.now();
  }
  
  // Public API methods
  static Future<List<MarketAssetModel>> getAllAssets() async {
    return LocalDatabaseService.getMarketAssets();
  }
  
  static Future<List<MarketAssetModel>> getAssetsByType(String type) async {
    return LocalDatabaseService.getMarketAssetsByType(type);
  }
  
  static Future<MarketAssetModel?> getAsset(String symbol) async {
    return LocalDatabaseService.getMarketAsset(symbol);
  }
  
  static Future<List<MarketAssetModel>> searchAssets(String query) async {
    final assets = await getAllAssets();
    final lowercaseQuery = query.toLowerCase();
    
    return assets.where((asset) =>
        asset.symbol.toLowerCase().contains(lowercaseQuery) ||
        asset.name.toLowerCase().contains(lowercaseQuery)
    ).toList();
  }
  
  static Future<void> startPeriodicUpdates() async {
    print('$_logPrefix Starting periodic market data updates...');
    
    // Update immediately
    await updateAllMarketData();
    
    // Schedule periodic updates every 5 minutes
    Stream.periodic(const Duration(minutes: 5)).listen((_) async {
      try {
        await updateAllMarketData();
      } catch (e) {
        print('$_logPrefix ❌ Periodic update failed: $e');
      }
    });
  }
  
  static Future<Map<String, dynamic>> getMarketStats() async {
    final assets = await getAllAssets();
    
    if (assets.isEmpty) {
      return {
        'total_assets': 0,
        'gainers': 0,
        'losers': 0,
        'avg_change': 0.0,
        'last_updated': null,
      };
    }
    
    final gainers = assets.where((asset) => asset.changePercent > 0).length;
    final losers = assets.where((asset) => asset.changePercent < 0).length;
    final avgChange = assets.map((asset) => asset.changePercent).reduce((a, b) => a + b) / assets.length;
    final lastUpdated = assets.map((asset) => asset.lastUpdated).reduce((a, b) => a.isAfter(b) ? a : b);
    
    return {
      'total_assets': assets.length,
      'gainers': gainers,
      'losers': losers,
      'avg_change': avgChange,
      'last_updated': lastUpdated,
    };
  }
}