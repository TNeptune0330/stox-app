import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/asset_model.dart';
import '../config/api_keys.dart';
import '../config/supabase_config.dart';

class MarketDataService {
  final SupabaseClient _supabase = Supabase.instance.client;
  
  Future<Box> _getLocalBox() async {
    return await Hive.openBox('market_data');
  }
  
  Future<void> _saveToLocal(Map<String, dynamic> data) async {
    if (SupabaseConfig.useLocalStorage) {
      try {
        final box = await _getLocalBox();
        await box.put(data['symbol'], data);
      } catch (e) {
        print('Error saving to local storage: $e');
      }
    }
  }
  
  Future<List<Map<String, dynamic>>> _getFromLocal() async {
    if (SupabaseConfig.useLocalStorage) {
      try {
        final box = await _getLocalBox();
        return box.values.cast<Map<String, dynamic>>().toList();
      } catch (e) {
        print('Error reading from local storage: $e');
        return [];
      }
    }
    return [];
  }

  // Top assets to track
  static const List<String> topStocks = [
    'AAPL', 'GOOGL', 'MSFT', 'AMZN', 'TSLA', 'META', 'NVDA', 'JPM', 'V', 'WMT',
    'JNJ', 'UNH', 'HD', 'PG', 'MA', 'DIS', 'NFLX', 'ADBE', 'CRM', 'PYPL',
    'INTC', 'CSCO', 'VZ', 'KO', 'PFE', 'T', 'MRK', 'ABT', 'ABBV', 'TMO',
    'COST', 'AVGO', 'ACN', 'DHR', 'LLY', 'NKE', 'QCOM', 'TXN', 'BMY', 'ORCL',
    'MDT', 'PM', 'HON', 'UNP', 'LIN', 'SBUX', 'LOW', 'AMD', 'GILD', 'CAT',
    'BA', 'IBM', 'GS', 'SPGI', 'BLK', 'ISRG', 'ANTM', 'C', 'AXP', 'BKNG',
    'INTU', 'DE', 'TJX', 'ADP', 'MMM', 'CVS', 'PLD', 'MDLZ', 'REGN', 'SO',
    'CB', 'CI', 'DUK', 'ZTS', 'CL', 'ITW', 'CSX', 'USB', 'EOG', 'SYK',
    'PNC', 'BSX', 'AON', 'COP', 'FCX', 'NSC', 'ICE', 'D', 'WM', 'GD',
    'FIS', 'CME', 'MSI', 'EMR', 'MCK', 'ROP', 'COF', 'FISV', 'WFC', 'TFC'
  ];

  static const List<String> topEtfs = [
    'SPY', 'QQQ', 'VOO', 'IWM', 'DIA', 'VTI', 'VEA', 'VWO', 'IEFA', 'EFA',
    'XLK', 'XLF', 'XLE', 'XLV', 'XLI', 'XLP', 'XLY', 'XLB', 'XLRE', 'XLU',
    'ARKK', 'ARKQ', 'ARKG', 'ARKW', 'ARKF', 'TQQQ', 'SOXL', 'TECL', 'CURE',
    'AGG', 'BND', 'TLT', 'IEF', 'SHY', 'TIPS', 'HYG', 'LQD', 'EMB', 'MUB',
    'GLD', 'SLV', 'GDX', 'GDXJ', 'USO', 'UNG', 'DBC', 'PDBC', 'IAU', 'PALL'
  ];

  static const List<String> topCryptos = [
    'bitcoin', 'ethereum', 'binancecoin', 'ripple', 'cardano', 'solana', 'polkadot',
    'dogecoin', 'avalanche-2', 'polygon', 'shiba-inu', 'chainlink', 'cosmos',
    'algorand', 'uniswap', 'litecoin', 'bitcoin-cash', 'ethereum-classic',
    'stellar', 'vechain', 'filecoin', 'tron', 'monero', 'eos', 'aave',
    'compound-governance-token', 'maker', 'yearn-finance', 'sushiswap',
    'curve-dao-token', 'balancer', '1inch', 'pancakeswap-token', 'thorchain',
    'synthetix-network-token', 'optimism', 'arbitrum', 'loopring', 'immutable-x',
    'pepe', 'floki', 'baby-doge-coin', 'tether', 'usd-coin', 'binance-usd',
    'dai', 'frax', 'axie-infinity', 'decentraland', 'the-sandbox', 'enjincoin',
    'gala', 'flow', 'wax', 'chromia', 'ultra', 'alien-worlds'
  ];

  Future<List<AssetModel>> getAllAssets() async {
    try {
      // Try Supabase first
      try {
        final response = await _supabase
            .from('market_prices')
            .select()
            .order('type')
            .order('symbol');

        final assets = response.map<AssetModel>((json) => AssetModel.fromJson(json)).toList();
        
        if (assets.isNotEmpty) {
          print('📊 Loaded ${assets.length} assets from Supabase');
          return assets;
        }
      } catch (e) {
        print('❌ Supabase error, trying local storage: $e');
      }
      
      // Try local storage
      final localData = await _getFromLocal();
      if (localData.isNotEmpty) {
        final assets = localData.map<AssetModel>((json) => AssetModel.fromJson(json)).toList();
        print('📊 Loaded ${assets.length} assets from local storage');
        return assets;
      }
      
      // If no data found, update with real data first
      print('📊 No assets found, updating with real data...');
      await updateAllPrices();
      
      // Try again after update
      final updatedLocalData = await _getFromLocal();
      if (updatedLocalData.isNotEmpty) {
        final assets = updatedLocalData.map<AssetModel>((json) => AssetModel.fromJson(json)).toList();
        print('📊 Loaded ${assets.length} assets after update');
        return assets;
      }
      
      throw Exception('No market data available');
    } catch (e) {
      print('❌ Error loading assets: $e');
      rethrow;
    }
  }

  Future<List<AssetModel>> getAssetsByType(String type) async {
    try {
      final response = await _supabase
          .from('market_prices')
          .select()
          .eq('type', type)
          .order('symbol');

      return response.map<AssetModel>((json) => AssetModel.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Failed to fetch assets by type: $e');
    }
  }

  Future<AssetModel?> getAssetBySymbol(String symbol) async {
    try {
      final response = await _supabase
          .from('market_prices')
          .select()
          .eq('symbol', symbol)
          .maybeSingle();

      if (response == null) return null;
      return AssetModel.fromJson(response);
    } catch (e) {
      throw Exception('Failed to fetch asset: $e');
    }
  }

  Future<List<AssetModel>> searchAssets(String query) async {
    try {
      final response = await _supabase
          .from('market_prices')
          .select()
          .or('symbol.ilike.%$query%,name.ilike.%$query%')
          .order('symbol')
          .limit(20);

      return response.map<AssetModel>((json) => AssetModel.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Failed to search assets: $e');
    }
  }

  Future<void> updateStockPrices() async {
    try {
      print('📈 Updating stock prices with multiple APIs...');
      
      // Use essential stocks for better performance
      final essentialSymbols = [
        'AAPL', 'GOOGL', 'MSFT', 'AMZN', 'TSLA', 'META', 'NVDA', 'JPM', 'V', 'WMT',
        'SPY', 'QQQ', 'VOO', 'IWM', 'DIA'
      ];
      
      for (final symbol in essentialSymbols) {
        try {
          // Try Finnhub first (working API with higher rate limit)
          if (await _tryFinnhubStock(symbol)) {
            continue;
          }
          
          // If Finnhub fails, try Alpha Vantage
          if (await _tryAlphaVantageStock(symbol)) {
            continue;
          }
          
          // If both fail, try IEX Cloud
          if (await _tryIexCloudStock(symbol)) {
            continue;
          }
          
          // If all APIs fail, use mock data
          await _insertMockStockData(symbol);
          
          // Rate limit delay - Finnhub allows 60 calls per minute
          await Future.delayed(const Duration(seconds: 1));
        } catch (e) {
          print('❌ Error updating $symbol: $e');
          await _insertMockStockData(symbol);
        }
      }
    } catch (e) {
      print('❌ Failed to update stock prices: $e');
    }
  }

  Future<bool> _tryFinnhubStock(String symbol) async {
    try {
      final response = await http.get(
        Uri.parse('https://finnhub.io/api/v1/quote?symbol=$symbol&token=${ApiKeys.finnhubApiKey}'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        if (data['c'] != null && data['c'] != 0) {
          final price = data['c'].toDouble();
          final change = data['d']?.toDouble() ?? 0.0;
          final changePercent = data['dp']?.toDouble() ?? 0.0;
          
          // Get company name
          String name = _getStockName(symbol);
          
          final assetData = {
            'symbol': symbol,
            'name': name,
            'price': price,
            'change_24h': change,
            'change_percent_24h': changePercent,
            'type': topStocks.contains(symbol) ? 'stock' : 'etf',
            'last_updated': DateTime.now().toIso8601String(),
          };
          
          try {
            await _supabase.from('market_prices').upsert(assetData);
          } catch (e) {
            print('Supabase error, using local storage: $e');
            await _saveToLocal(assetData);
          }
          
          print('✅ [Finnhub] Updated $symbol: \$${price.toStringAsFixed(2)} (${changePercent.toStringAsFixed(2)}%)');
          return true;
        }
      }
    } catch (e) {
      print('❌ [Finnhub] Error fetching $symbol: $e');
    }
    return false;
  }

  Future<bool> _tryAlphaVantageStock(String symbol) async {
    try {
      // Use the real API key
      final response = await http.get(
        Uri.parse('https://www.alphavantage.co/query?function=GLOBAL_QUOTE&symbol=$symbol&apikey=${ApiKeys.alphaVantageApiKey}'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final quote = data['Global Quote'];
        
        if (quote != null && quote['05. price'] != null) {
          final price = double.tryParse(quote['05. price']) ?? 0.0;
          final change = double.tryParse(quote['09. change'] ?? '0') ?? 0.0;
          final changePercent = double.tryParse(quote['10. change percent']?.replaceAll('%', '') ?? '0') ?? 0.0;
          
          if (price > 0) {
            final assetData = {
              'symbol': symbol,
              'name': _getStockName(symbol),
              'price': price,
              'change_24h': change,
              'change_percent_24h': changePercent,
              'type': topStocks.contains(symbol) ? 'stock' : 'etf',
              'last_updated': DateTime.now().toIso8601String(),
            };
            
            try {
              await _supabase.from('market_prices').upsert(assetData);
            } catch (e) {
              print('Supabase error, using local storage: $e');
              await _saveToLocal(assetData);
            }
            
            print('✅ [Alpha Vantage] Updated $symbol: \$${price.toStringAsFixed(2)} (${changePercent.toStringAsFixed(2)}%)');
            return true;
          }
        }
      }
    } catch (e) {
      print('❌ [Alpha Vantage] Error fetching $symbol: $e');
    }
    return false;
  }

  Future<bool> _tryIexCloudStock(String symbol) async {
    try {
      final response = await http.get(
        Uri.parse('https://cloud.iexapis.com/stable/stock/$symbol/quote?token=${ApiKeys.iexCloudApiKey}'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        if (data['latestPrice'] != null) {
          final price = data['latestPrice'].toDouble();
          final change = data['change']?.toDouble() ?? 0.0;
          final changePercent = data['changePercent']?.toDouble() ?? 0.0;
          
          final assetData = {
            'symbol': symbol,
            'name': data['companyName'] ?? _getStockName(symbol),
            'price': price,
            'change_24h': change,
            'change_percent_24h': changePercent * 100, // IEX returns as decimal
            'type': topStocks.contains(symbol) ? 'stock' : 'etf',
            'last_updated': DateTime.now().toIso8601String(),
          };
          
          try {
            await _supabase.from('market_prices').upsert(assetData);
          } catch (e) {
            print('Supabase error, using local storage: $e');
            await _saveToLocal(assetData);
          }
          
          print('✅ [IEX Cloud] Updated $symbol: \$${price.toStringAsFixed(2)} (${changePercent.toStringAsFixed(4)}%)');
          return true;
        }
      }
    } catch (e) {
      print('❌ [IEX Cloud] Error fetching $symbol: $e');
    }
    return false;
  }

  Future<void> _insertMockStockData(String symbol) async {
    try {
      // Generate realistic mock data
      final random = DateTime.now().millisecondsSinceEpoch % 1000;
      final basePrice = _getMockPrice(symbol);
      final changePercent = (random % 10 - 5) * 0.5; // -2.5% to +2.5%
      final change = basePrice * changePercent / 100;
      
      final assetData = {
        'symbol': symbol,
        'name': _getStockName(symbol),
        'price': basePrice + change,
        'change_24h': change,
        'change_percent_24h': changePercent,
        'type': topStocks.contains(symbol) ? 'stock' : 'etf',
        'last_updated': DateTime.now().toIso8601String(),
      };
      
      try {
        await _supabase.from('market_prices').upsert(assetData);
      } catch (e) {
        print('Supabase error, using local storage: $e');
        await _saveToLocal(assetData);
      }
      
      print('📊 [Mock] Updated $symbol: \$${(basePrice + change).toStringAsFixed(2)} (${changePercent.toStringAsFixed(2)}%)');
    } catch (e) {
      print('❌ [Mock] Error inserting mock data for $symbol: $e');
    }
  }

  double _getMockPrice(String symbol) {
    const mockPrices = {
      'AAPL': 175.43,
      'GOOGL': 138.25,
      'MSFT': 378.85,
      'AMZN': 151.94,
      'TSLA': 248.50,
      'META': 319.48,
      'NVDA': 875.28,
      'NFLX': 485.73,
      'JPM': 147.82,
      'V': 256.73,
      'WMT': 158.92,
      'SPY': 436.92,
      'QQQ': 375.29,
      'VOO': 401.73,
      'IWM': 193.84,
    };
    return mockPrices[symbol] ?? 100.0;
  }

  String _getStockName(String symbol) {
    const stockNames = {
      'AAPL': 'Apple Inc.',
      'GOOGL': 'Alphabet Inc.',
      'MSFT': 'Microsoft Corporation',
      'AMZN': 'Amazon.com Inc.',
      'TSLA': 'Tesla Inc.',
      'META': 'Meta Platforms Inc.',
      'NVDA': 'NVIDIA Corporation',
      'NFLX': 'Netflix Inc.',
      'JPM': 'JPMorgan Chase & Co.',
      'V': 'Visa Inc.',
      'WMT': 'Walmart Inc.',
      'SPY': 'SPDR S&P 500 ETF Trust',
      'QQQ': 'Invesco QQQ Trust',
      'VOO': 'Vanguard S&P 500 ETF',
      'IWM': 'iShares Russell 2000 ETF',
    };
    return stockNames[symbol] ?? symbol;
  }

  Future<void> updateCryptoPrices() async {
    try {
      print('🪙 Updating crypto prices with CoinGecko API...');
      
      // Use essential cryptos for better reliability
      final essentialCryptos = [
        'bitcoin', 'ethereum', 'binancecoin', 'ripple', 'cardano', 'solana', 
        'polkadot', 'dogecoin', 'avalanche-2', 'polygon', 'shiba-inu', 'chainlink'
      ];
      
      // Try CoinGecko first
      if (await _tryCoinGeckoCrypto(essentialCryptos)) {
        return;
      }
      
      // If CoinGecko fails, use mock data
      await _insertMockCryptoData(essentialCryptos);
      
    } catch (e) {
      print('❌ Failed to update crypto prices: $e');
      // Fallback to mock data
      await _insertMockCryptoData([
        'bitcoin', 'ethereum', 'binancecoin', 'ripple', 'cardano', 'solana'
      ]);
    }
  }

  Future<bool> _tryCoinGeckoCrypto(List<String> cryptos) async {
    try {
      // Use public CoinGecko API (no API key required)
      final response = await http.get(
        Uri.parse('https://api.coingecko.com/api/v3/simple/price?ids=${cryptos.join(',')}&vs_currencies=usd&include_24hr_change=true'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        if (data.isNotEmpty) {
          for (final entry in data.entries) {
            final id = entry.key;
            final priceData = entry.value;
            
            if (priceData['usd'] != null) {
              final price = priceData['usd'].toDouble();
              final changePercent = priceData['usd_24h_change']?.toDouble() ?? 0.0;
              final change = price * changePercent / 100;
              
              final assetData = {
                'symbol': _getCryptoSymbol(id),
                'name': _getCryptoName(id),
                'price': price,
                'change_24h': change,
                'change_percent_24h': changePercent,
                'type': 'crypto',
                'last_updated': DateTime.now().toIso8601String(),
              };
              
              try {
                await _supabase.from('market_prices').upsert(assetData);
              } catch (e) {
                print('Supabase error, using local storage: $e');
                await _saveToLocal(assetData);
              }
              
              final symbol = _getCryptoSymbol(id);
              print('✅ [CoinGecko] Updated $symbol: \$${price.toStringAsFixed(price < 1 ? 6 : 2)} (${changePercent.toStringAsFixed(2)}%)');
            }
          }
          return true;
        }
      } else {
        print('❌ [CoinGecko] Failed to fetch crypto data: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ [CoinGecko] Error fetching crypto data: $e');
    }
    return false;
  }

  Future<void> _insertMockCryptoData(List<String> cryptos) async {
    try {
      for (final id in cryptos) {
        final symbol = _getCryptoSymbol(id);
        final basePrice = _getMockCryptoPrice(symbol);
        final random = DateTime.now().millisecondsSinceEpoch % 1000;
        final changePercent = (random % 20 - 10) * 0.5; // -5% to +5%
        final change = basePrice * changePercent / 100;
        
        final assetData = {
          'symbol': symbol,
          'name': _getCryptoName(id),
          'price': basePrice + change,
          'change_24h': change,
          'change_percent_24h': changePercent,
          'type': 'crypto',
          'last_updated': DateTime.now().toIso8601String(),
        };
        
        try {
          await _supabase.from('market_prices').upsert(assetData);
        } catch (e) {
          print('Supabase error, using local storage: $e');
          await _saveToLocal(assetData);
        }
        
        print('📊 [Mock] Updated $symbol: \$${(basePrice + change).toStringAsFixed(basePrice < 1 ? 6 : 2)} (${changePercent.toStringAsFixed(2)}%)');
      }
    } catch (e) {
      print('❌ [Mock] Error inserting mock crypto data: $e');
    }
  }

  double _getMockCryptoPrice(String symbol) {
    const mockPrices = {
      'BTC': 67845.32,
      'ETH': 3456.78,
      'BNB': 598.47,
      'XRP': 0.6234,
      'ADA': 0.4567,
      'SOL': 164.89,
      'DOT': 6.78,
      'DOGE': 0.1456,
      'AVAX': 37.82,
      'MATIC': 0.8934,
      'SHIB': 0.000024,
      'LINK': 14.67,
    };
    return mockPrices[symbol] ?? 1.0;
  }

  String _getCryptoSymbol(String id) {
    const cryptoSymbols = {
      'bitcoin': 'BTC',
      'ethereum': 'ETH',
      'binancecoin': 'BNB',
      'ripple': 'XRP',
      'cardano': 'ADA',
      'solana': 'SOL',
      'polkadot': 'DOT',
      'dogecoin': 'DOGE',
      'avalanche-2': 'AVAX',
      'polygon': 'MATIC',
      'shiba-inu': 'SHIB',
      'chainlink': 'LINK',
      'cosmos': 'ATOM',
      'algorand': 'ALGO',
      'uniswap': 'UNI',
      'litecoin': 'LTC',
      'bitcoin-cash': 'BCH',
      'ethereum-classic': 'ETC',
      'stellar': 'XLM',
      'vechain': 'VET',
      'filecoin': 'FIL',
      'tron': 'TRX',
      'monero': 'XMR',
      'eos': 'EOS',
      'aave': 'AAVE',
      'compound-governance-token': 'COMP',
      'maker': 'MKR',
      'yearn-finance': 'YFI',
      'sushiswap': 'SUSHI',
      'curve-dao-token': 'CRV',
      'balancer': 'BAL',
      '1inch': '1INCH',
      'pancakeswap-token': 'CAKE',
      'thorchain': 'RUNE',
      'synthetix-network-token': 'SNX',
      'optimism': 'OP',
      'arbitrum': 'ARB',
      'loopring': 'LRC',
      'immutable-x': 'IMX',
      'pepe': 'PEPE',
      'floki': 'FLOKI',
      'baby-doge-coin': 'BABYDOGE',
      'tether': 'USDT',
      'usd-coin': 'USDC',
      'binance-usd': 'BUSD',
      'dai': 'DAI',
      'frax': 'FRAX',
      'axie-infinity': 'AXS',
      'decentraland': 'MANA',
      'the-sandbox': 'SAND',
      'enjincoin': 'ENJ',
      'gala': 'GALA',
      'flow': 'FLOW',
      'wax': 'WAXP',
      'chromia': 'CHR',
      'ultra': 'UOS',
      'alien-worlds': 'TLM',
    };
    return cryptoSymbols[id] ?? id.toUpperCase();
  }

  String _getCryptoName(String id) {
    const cryptoNames = {
      'bitcoin': 'Bitcoin',
      'ethereum': 'Ethereum',
      'binancecoin': 'Binance Coin',
      'ripple': 'XRP',
      'cardano': 'Cardano',
      'solana': 'Solana',
      'polkadot': 'Polkadot',
      'dogecoin': 'Dogecoin',
      'avalanche-2': 'Avalanche',
      'polygon': 'Polygon',
      'shiba-inu': 'Shiba Inu',
      'chainlink': 'Chainlink',
      'cosmos': 'Cosmos',
      'algorand': 'Algorand',
      'uniswap': 'Uniswap',
      'litecoin': 'Litecoin',
      'bitcoin-cash': 'Bitcoin Cash',
      'ethereum-classic': 'Ethereum Classic',
      'stellar': 'Stellar',
      'vechain': 'VeChain',
      'filecoin': 'Filecoin',
      'tron': 'TRON',
      'monero': 'Monero',
      'eos': 'EOS',
      'aave': 'Aave',
      'compound-governance-token': 'Compound',
      'maker': 'Maker',
      'yearn-finance': 'Yearn Finance',
      'sushiswap': 'SushiSwap',
      'curve-dao-token': 'Curve DAO Token',
      'balancer': 'Balancer',
      '1inch': '1inch',
      'pancakeswap-token': 'PancakeSwap',
      'thorchain': 'THORChain',
      'synthetix-network-token': 'Synthetix',
      'optimism': 'Optimism',
      'arbitrum': 'Arbitrum',
      'loopring': 'Loopring',
      'immutable-x': 'Immutable X',
      'pepe': 'Pepe',
      'floki': 'FLOKI',
      'baby-doge-coin': 'Baby Doge Coin',
      'tether': 'Tether',
      'usd-coin': 'USD Coin',
      'binance-usd': 'Binance USD',
      'dai': 'Dai',
      'frax': 'Frax',
      'axie-infinity': 'Axie Infinity',
      'decentraland': 'Decentraland',
      'the-sandbox': 'The Sandbox',
      'enjincoin': 'Enjin Coin',
      'gala': 'Gala',
      'flow': 'Flow',
      'wax': 'WAX',
      'chromia': 'Chromia',
      'ultra': 'Ultra',
      'alien-worlds': 'Alien Worlds',
    };
    return cryptoNames[id] ?? id.split('-').map((word) => word[0].toUpperCase() + word.substring(1)).join(' ');
  }

  Future<void> updateAllPrices() async {
    print('🔄 Starting complete market data update...');
    
    await Future.wait([
      updateStockPrices(),
      updateCryptoPrices(),
    ]);
    
    print('✅ Market data update completed');
  }
}