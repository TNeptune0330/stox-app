import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/market_asset_model.dart';

class GoogleStockSearchService {
  
  /// Search for stock by ticker using Google Finance scraping
  /// Waits for user to hit enter, then checks if ticker exists on various exchanges
  static Future<List<MarketAssetModel>> searchStocks(String query) async {
    if (query.trim().isEmpty) return [];
    
    final ticker = query.trim().toUpperCase();
    print('🔍 GoogleStockSearchService: Searching for ticker "$ticker"');
    
    try {
      // Try different exchanges in order of priority
      final exchanges = ['NASDAQ', 'NYSE', 'AMEX', 'LON', 'TSE', 'HKG'];
      final results = <MarketAssetModel>[];
      
      for (String exchange in exchanges) {
        try {
          final asset = await _checkGoogleFinance(ticker, exchange);
          if (asset != null) {
            results.add(asset);
            print('✅ Found $ticker on $exchange');
            break; // Stop after finding the first valid match
          }
        } catch (e) {
          print('❌ $ticker not found on $exchange: $e');
          continue;
        }
      }
      
      if (results.isEmpty) {
        // Try company name search as fallback
        final fallbackResult = await _searchByCompanyName(query);
        if (fallbackResult.isNotEmpty) {
          results.addAll(fallbackResult);
        }
      }
      
      print('✅ Search completed: ${results.length} results found');
      return results;
      
    } catch (e) {
      print('❌ GoogleStockSearchService error: $e');
      return [];
    }
  }
  
  /// Check if ticker exists on Google Finance for a specific exchange
  static Future<MarketAssetModel?> _checkGoogleFinance(String ticker, String exchange) async {
    try {
      final url = 'https://www.google.com/finance/quote/$ticker:$exchange';
      print('🌐 Checking: $url');
      
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'User-Agent': 'Mozilla/5.0 (iPhone; CPU iPhone OS 16_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/16.0 Mobile/15E148 Safari/604.1',
          'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8',
          'Accept-Language': 'en-US,en;q=0.5',
          'Accept-Encoding': 'gzip, deflate',
          'Connection': 'keep-alive',
          'Upgrade-Insecure-Requests': '1',
        },
      );
      
      if (response.statusCode == 200) {
        return _parseGoogleFinancePage(response.body, ticker, exchange);
      } else {
        print('❌ HTTP ${response.statusCode} for $ticker:$exchange');
        return null;
      }
    } catch (e) {
      print('❌ Error checking $ticker:$exchange - $e');
      return null;
    }
  }
  
  /// Parse Google Finance page to extract stock data
  static MarketAssetModel? _parseGoogleFinancePage(String html, String ticker, String exchange) {
    try {
      // Look for the stock data in the HTML
      if (html.contains('Sorry, we couldn\'t find') || 
          html.contains('We couldn\'t find') ||
          html.contains('No results found')) {
        return null;
      }
      
      // Extract company name
      String companyName = ticker;
      final nameRegex = RegExp(r'<title>([^-]+) - ([^|]+)', multiLine: true);
      final nameMatch = nameRegex.firstMatch(html);
      if (nameMatch != null) {
        companyName = nameMatch.group(2)?.trim() ?? ticker;
        // Remove "Stock Price" or similar suffixes
        companyName = companyName.replaceAll(RegExp(r'\s*(Stock Price|Quote|Share Price).*', caseSensitive: false), '');
      }
      
      // Extract current price
      double currentPrice = 0.0;
      final priceRegex = RegExp(r'data-currency-code="[^"]*"[^>]*>([0-9,]+\.?[0-9]*)', multiLine: true);
      final priceMatch = priceRegex.firstMatch(html);
      if (priceMatch != null) {
        final priceStr = priceMatch.group(1)?.replaceAll(',', '') ?? '0';
        currentPrice = double.tryParse(priceStr) ?? 0.0;
      }
      
      // If price extraction failed, try alternative patterns
      if (currentPrice == 0.0) {
        final altPriceRegex = RegExp(r'\$([0-9,]+\.?[0-9]*)', multiLine: true);
        final altPriceMatch = altPriceRegex.firstMatch(html);
        if (altPriceMatch != null) {
          final priceStr = altPriceMatch.group(1)?.replaceAll(',', '') ?? '0';
          currentPrice = double.tryParse(priceStr) ?? 0.0;
        }
      }
      
      // Extract change percentage
      double changePercent = 0.0;
      final changeRegex = RegExp(r'(\+|-)?([0-9]+\.?[0-9]*)%', multiLine: true);
      final changeMatch = changeRegex.firstMatch(html);
      if (changeMatch != null) {
        final sign = changeMatch.group(1) ?? '';
        final percentStr = changeMatch.group(2) ?? '0';
        final percent = double.tryParse(percentStr) ?? 0.0;
        changePercent = sign == '-' ? -percent : percent;
      }
      
      if (currentPrice > 0) {
        print('✅ Parsed: $companyName ($ticker) - \$${currentPrice.toStringAsFixed(2)} (${changePercent >= 0 ? '+' : ''}${changePercent.toStringAsFixed(2)}%)');
        
        return MarketAssetModel(
          symbol: ticker,
          name: companyName,
          price: currentPrice,
          changePercent: changePercent,
          type: 'stock',
          exchange: exchange,
        );
      } else {
        print('❌ Could not extract valid price for $ticker');
        return null;
      }
      
    } catch (e) {
      print('❌ Error parsing Google Finance page for $ticker: $e');
      return null;
    }
  }
  
  /// Fallback: Search by company name using predefined database
  static Future<List<MarketAssetModel>> _searchByCompanyName(String query) async {
    final queryLower = query.toLowerCase();
    
    // Comprehensive company name to ticker mapping
    final companyDatabase = {
      'apple': 'AAPL', 'microsoft': 'MSFT', 'amazon': 'AMZN', 'google': 'GOOGL', 
      'alphabet': 'GOOGL', 'meta': 'META', 'facebook': 'META', 'tesla': 'TSLA',
      'nvidia': 'NVDA', 'netflix': 'NFLX', 'disney': 'DIS', 'boeing': 'BA',
      'jpmorgan': 'JPM', 'jp morgan': 'JPM', 'johnson': 'JNJ', 'johnson & johnson': 'JNJ',
      'visa': 'V', 'mastercard': 'MA', 'procter': 'PG', 'procter & gamble': 'PG',
      'coca cola': 'KO', 'coca-cola': 'KO', 'coke': 'KO', 'pepsi': 'PEP', 'pepsico': 'PEP',
      'berkshire': 'BRK.B', 'berkshire hathaway': 'BRK.B', 'goldman': 'GS', 'goldman sachs': 'GS',
      'walmart': 'WMT', 'target': 'TGT', 'costco': 'COST', 'home depot': 'HD',
      'mcdonalds': 'MCD', "mcdonald's": 'MCD', 'starbucks': 'SBUX', 'ford': 'F',
      'general motors': 'GM', 'uber': 'UBER', 'lyft': 'LYFT', 'exxon': 'XOM',
      'chevron': 'CVX', 'pfizer': 'PFE', 'merck': 'MRK', 'verizon': 'VZ',
      'at&t': 'T', 'intel': 'INTC', 'amd': 'AMD', 'oracle': 'ORCL', 'salesforce': 'CRM',
      'adobe': 'ADBE', 'cisco': 'CSCO', 'ibm': 'IBM', 'spotify': 'SPOT',
      'zoom': 'ZM', 'roku': 'ROKU', 'snap': 'SNAP', 'snapchat': 'SNAP',
      'paypal': 'PYPL', 'shopify': 'SHOP', 'delta': 'DAL', 'american airlines': 'AAL',
    };
    
    // Look for company name matches
    for (final entry in companyDatabase.entries) {
      if (entry.key.contains(queryLower) || queryLower.contains(entry.key)) {
        try {
          // Try to get this stock from Google Finance
          final exchanges = ['NASDAQ', 'NYSE'];
          for (String exchange in exchanges) {
            final asset = await _checkGoogleFinance(entry.value, exchange);
            if (asset != null) {
              print('✅ Found ${entry.key} -> ${entry.value}');
              return [asset];
            }
          }
        } catch (e) {
          print('❌ Error loading ${entry.value}: $e');
        }
      }
    }
    
    return [];
  }
}