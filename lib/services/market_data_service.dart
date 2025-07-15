import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/asset_model.dart';
import '../config/api_keys.dart';

class MarketDataService {
  final SupabaseClient _supabase = Supabase.instance.client;

  static const List<String> topStocks = [
    'AAPL', 'GOOGL', 'MSFT', 'AMZN', 'TSLA', 'META', 'NVDA', 'JPM', 'V', 'WMT'
  ];

  static const List<String> topEtfs = [
    'SPY', 'QQQ', 'VOO', 'IWM', 'DIA'
  ];

  static const List<String> topCryptos = [
    'bitcoin', 'ethereum', 'binancecoin', 'cardano', 'solana'
  ];

  Future<List<AssetModel>> getAllAssets() async {
    try {
      final response = await _supabase
          .from('market_prices')
          .select()
          .order('type')
          .order('symbol');

      final assets = response.map<AssetModel>((json) => AssetModel.fromJson(json)).toList();
      
      // If no assets found, return mock data for development
      if (assets.isEmpty) {
        return _getMockAssets();
      }
      
      return assets;
    } catch (e) {
      // Return mock data if database not accessible
      return _getMockAssets();
    }
  }

  List<AssetModel> _getMockAssets() {
    return [
      AssetModel(
        symbol: 'AAPL',
        name: 'Apple Inc.',
        type: 'stock',
        price: 150.25,
        change24h: 2.50,
        changePercent24h: 1.69,
        lastUpdated: DateTime.now(),
      ),
      AssetModel(
        symbol: 'GOOGL',
        name: 'Alphabet Inc.',
        type: 'stock',
        price: 2750.80,
        change24h: -15.20,
        changePercent24h: -0.55,
        lastUpdated: DateTime.now(),
      ),
      AssetModel(
        symbol: 'BITCOIN',
        name: 'Bitcoin',
        type: 'crypto',
        price: 45000.00,
        change24h: 1500.00,
        changePercent24h: 3.45,
        lastUpdated: DateTime.now(),
      ),
      AssetModel(
        symbol: 'SPY',
        name: 'SPDR S&P 500 ETF',
        type: 'etf',
        price: 425.75,
        change24h: 3.25,
        changePercent24h: 0.77,
        lastUpdated: DateTime.now(),
      ),
    ];
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
      for (final symbol in [...topStocks, ...topEtfs]) {
        final response = await http.get(
          Uri.parse('https://finnhub.io/api/v1/quote?symbol=$symbol&token=${ApiKeys.finnhubApiKey}'),
        );

        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          
          await _supabase.from('market_prices').upsert({
            'symbol': symbol,
            'price': data['c'],
            'change_24h': data['d'],
            'change_percent_24h': data['dp'],
            'type': topStocks.contains(symbol) ? 'stock' : 'etf',
            'last_updated': DateTime.now().toIso8601String(),
          });
        }
      }
    } catch (e) {
      throw Exception('Failed to update stock prices: $e');
    }
  }

  Future<void> updateCryptoPrices() async {
    try {
      final response = await http.get(
        Uri.parse('https://api.coingecko.com/api/v3/simple/price?ids=${topCryptos.join(',')}&vs_currencies=usd&include_24hr_change=true'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        for (final entry in data.entries) {
          final id = entry.key;
          final priceData = entry.value;
          
          await _supabase.from('market_prices').upsert({
            'symbol': id.toUpperCase(),
            'price': priceData['usd'],
            'change_percent_24h': priceData['usd_24h_change'],
            'type': 'crypto',
            'last_updated': DateTime.now().toIso8601String(),
          });
        }
      }
    } catch (e) {
      throw Exception('Failed to update crypto prices: $e');
    }
  }

  Future<void> updateAllPrices() async {
    await Future.wait([
      updateStockPrices(),
      updateCryptoPrices(),
    ]);
  }
}