import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/market_asset_model.dart';
import 'enhanced_market_data_service.dart';

class GoogleStockSearchService {
  // TODO: Add your Google Custom Search API key here
  static const String _googleApiKey = 'YOUR_GOOGLE_API_KEY';
  static const String _searchEngineId = 'YOUR_SEARCH_ENGINE_ID';
  
  /// Search for stock symbols using Google Custom Search API
  /// This will search for companies and extract their stock symbols
  static Future<List<MarketAssetModel>> searchStocks(String query) async {
    if (query.trim().isEmpty) return [];
    
    try {
      print('🔍 GoogleStockSearchService: Searching for "$query"');
      
      // For now, implement a comprehensive fallback search
      // In production, this would use Google Custom Search API
      return await _fallbackSearch(query);
      
    } catch (e) {
      print('❌ GoogleStockSearchService error: $e');
      return [];
    }
  }
  
  /// Fallback search implementation using predefined stock data
  /// TODO: Replace with actual Google Custom Search API call
  static Future<List<MarketAssetModel>> _fallbackSearch(String query) async {
    final searchResults = <MarketAssetModel>[];
    final queryLower = query.toLowerCase();
    
    // Comprehensive stock database for search
    final stockDatabase = {
      // Tech giants
      'apple': 'AAPL', 'aapl': 'AAPL',
      'microsoft': 'MSFT', 'msft': 'MSFT',
      'amazon': 'AMZN', 'amzn': 'AMZN',
      'google': 'GOOGL', 'alphabet': 'GOOGL', 'googl': 'GOOGL',
      'meta': 'META', 'facebook': 'META',
      'tesla': 'TSLA', 'tsla': 'TSLA',
      'nvidia': 'NVDA', 'nvda': 'NVDA',
      'netflix': 'NFLX', 'nflx': 'NFLX',
      
      // Major stocks
      'disney': 'DIS', 'dis': 'DIS',
      'boeing': 'BA', 'ba': 'BA',
      'jpmorgan': 'JPM', 'jp morgan': 'JPM', 'jpmorgan chase': 'JPM',
      'johnson': 'JNJ', 'johnson & johnson': 'JNJ', 'jnj': 'JNJ',
      'visa': 'V', 'v': 'V',
      'mastercard': 'MA', 'ma': 'MA',
      'procter': 'PG', 'procter & gamble': 'PG', 'pg': 'PG',
      'coca cola': 'KO', 'coca-cola': 'KO', 'coke': 'KO', 'ko': 'KO',
      'pepsi': 'PEP', 'pepsico': 'PEP', 'pep': 'PEP',
      
      // Financial
      'berkshire': 'BRK.B', 'berkshire hathaway': 'BRK.B',
      'goldman': 'GS', 'goldman sachs': 'GS', 'gs': 'GS',
      'morgan stanley': 'MS', 'ms': 'MS',
      'bank of america': 'BAC', 'bac': 'BAC',
      'wells fargo': 'WFC', 'wfc': 'WFC',
      
      // Retail & Consumer
      'walmart': 'WMT', 'wmt': 'WMT',
      'target': 'TGT', 'tgt': 'TGT',
      'costco': 'COST', 'cost': 'COST',
      'home depot': 'HD', 'hd': 'HD',
      'mcdonalds': 'MCD', "mcdonald's": 'MCD', 'mcd': 'MCD',
      'starbucks': 'SBUX', 'sbux': 'SBUX',
      
      // Automotive
      'ford': 'F', 'f': 'F',
      'general motors': 'GM', 'gm': 'GM',
      'uber': 'UBER',
      'lyft': 'LYFT',
      
      // Energy
      'exxon': 'XOM', 'exxon mobil': 'XOM', 'xom': 'XOM',
      'chevron': 'CVX', 'cvx': 'CVX',
      'conocophillips': 'COP', 'cop': 'COP',
      
      // Healthcare
      'pfizer': 'PFE', 'pfe': 'PFE',
      'merck': 'MRK', 'mrk': 'MRK',
      'abbvie': 'ABBV', 'abbv': 'ABBV',
      'unitedhealth': 'UNH', 'united health': 'UNH', 'unh': 'UNH',
      
      // Telecom
      'verizon': 'VZ', 'vz': 'VZ',
      'at&t': 'T', 'att': 'T', 't': 'T',
      't-mobile': 'TMUS', 'tmobile': 'TMUS', 'tmus': 'TMUS',
      
      // Tech (more)
      'intel': 'INTC', 'intc': 'INTC',
      'amd': 'AMD', 'advanced micro': 'AMD',
      'oracle': 'ORCL', 'orcl': 'ORCL',
      'salesforce': 'CRM', 'crm': 'CRM',
      'adobe': 'ADBE', 'adbe': 'ADBE',
      'cisco': 'CSCO', 'csco': 'CSCO',
      'ibm': 'IBM',
      
      // Popular growth stocks
      'spotify': 'SPOT', 'spot': 'SPOT',
      'zoom': 'ZM', 'zm': 'ZM',
      'roku': 'ROKU',
      'snap': 'SNAP', 'snapchat': 'SNAP',
      'twitter': 'TWTR', 'twtr': 'TWTR',
      'square': 'SQ', 'sq': 'SQ',
      'paypal': 'PYPL', 'pypl': 'PYPL',
      'shopify': 'SHOP', 'shop': 'SHOP',
      
      // Airlines
      'delta': 'DAL', 'delta air': 'DAL', 'dal': 'DAL',
      'american airlines': 'AAL', 'aal': 'AAL',
      'united airlines': 'UAL', 'ual': 'UAL',
      'southwest': 'LUV', 'luv': 'LUV',
    };
    
    // Search for exact matches first
    if (stockDatabase.containsKey(queryLower)) {
      final symbol = stockDatabase[queryLower]!;
      final asset = await EnhancedMarketDataService.getAsset(symbol);
      if (asset != null) {
        searchResults.add(asset);
      }
    }
    
    // Search for partial matches
    for (final entry in stockDatabase.entries) {
      if (entry.key.contains(queryLower) && 
          !searchResults.any((asset) => asset.symbol == entry.value)) {
        try {
          final asset = await EnhancedMarketDataService.getAsset(entry.value);
          if (asset != null) {
            searchResults.add(asset);
          }
        } catch (e) {
          print('Error loading ${entry.value}: $e');
        }
      }
    }
    
    // Also try direct symbol lookup if not found
    try {
      final directSymbol = query.toUpperCase();
      if (!searchResults.any((asset) => asset.symbol == directSymbol)) {
        final asset = await EnhancedMarketDataService.getAsset(directSymbol);
        if (asset != null) {
          searchResults.add(asset);
        }
      }
    } catch (e) {
      // Ignore if direct symbol lookup fails
    }
    
    print('✅ GoogleStockSearchService: Found ${searchResults.length} results for "$query"');
    return searchResults.take(20).toList(); // Limit to 20 results
  }
  
  /// TODO: Implement actual Google Custom Search API call
  static Future<List<MarketAssetModel>> _googleCustomSearch(String query) async {
    if (_googleApiKey == 'YOUR_GOOGLE_API_KEY') {
      print('⚠️ Google API key not configured, using fallback search');
      return _fallbackSearch(query);
    }
    
    try {
      final url = Uri.parse(
        'https://www.googleapis.com/customsearch/v1'
        '?key=$_googleApiKey'
        '&cx=$_searchEngineId'
        '&q=${Uri.encodeComponent(query)} stock symbol'
        '&num=10'
      );
      
      final response = await http.get(url);
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final items = data['items'] as List<dynamic>? ?? [];
        
        final searchResults = <MarketAssetModel>[];
        
        for (final item in items) {
          // Extract stock symbols from search results
          // This would require parsing the search results to find stock symbols
          // Implementation would depend on the specific search engine configuration
        }
        
        return searchResults;
      } else {
        print('❌ Google Custom Search API error: ${response.statusCode}');
        return _fallbackSearch(query);
      }
    } catch (e) {
      print('❌ Google Custom Search API error: $e');
      return _fallbackSearch(query);
    }
  }
}