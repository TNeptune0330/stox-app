import 'package:http/http.dart' as http;
import '../models/market_asset_model.dart';
import '../services/finnhub_limiter_service.dart';

class GoogleStockSearchService {
  
  /// Search for stock by ticker using Finnhub API (primary) with Google Finance fallback
  /// Waits for user to hit enter, then checks if ticker exists
  static Future<List<MarketAssetModel>> searchStocks(String query) async {
    if (query.trim().isEmpty) return [];
    
    final ticker = query.trim().toUpperCase();
    print('🔍 StockSearchService: Searching for ticker "$ticker"');
    
    try {
      final results = <MarketAssetModel>[];
      
      // Primary method: Always use Finnhub API (UNLIMITED) for most accurate data
      print('🎯 PRIMARY: Using Finnhub API for $ticker (UNLIMITED - most accurate data)');
      final finnhubAsset = await FinnhubLimiterService.getStockQuote(ticker);
      if (finnhubAsset != null) {
        // Try to get company name from symbol lookup
        final companyName = _getCompanyName(ticker);
        final enhancedAsset = MarketAssetModel(
          symbol: finnhubAsset.symbol,
          name: companyName ?? finnhubAsset.name,
          price: finnhubAsset.price,
          change: finnhubAsset.change,
          changePercent: finnhubAsset.changePercent,
          type: finnhubAsset.type,
          exchange: 'NASDAQ', // Default exchange
          lastUpdated: finnhubAsset.lastUpdated,
        );
        results.add(enhancedAsset);
        print('✅ FINNHUB SUCCESS: $ticker = \$${finnhubAsset.price.toStringAsFixed(2)} (${finnhubAsset.changePercent >= 0 ? '+' : ''}${finnhubAsset.changePercent.toStringAsFixed(2)}%)');
        return results;
      } else {
        print('⚠️ Finnhub returned null for $ticker (rate limited or invalid symbol), trying fallback methods');
      }
      
      // Fallback: Try company name search
      final fallbackResult = await _searchByCompanyName(query);
      if (fallbackResult.isNotEmpty) {
        results.addAll(fallbackResult);
        print('✅ Found $ticker via company name search');
        return results;
      }
      
      // Last resort: Try Google Finance for international stocks
      final exchanges = ['NASDAQ', 'NYSE', 'NYSEARCA', 'AMEX'];
      for (String exchange in exchanges) {
        try {
          final asset = await _checkGoogleFinance(ticker, exchange);
          if (asset != null) {
            results.add(asset);
            print('✅ Found $ticker on $exchange via Google Finance (fallback)');
            break;
          }
        } catch (e) {
          continue;
        }
      }
      
      print('📊 Search completed: ${results.length} results found');
      return results;
      
    } catch (e) {
      print('❌ StockSearchService error: $e');
      return [];
    }
  }
  
  /// Get company name from ticker symbol
  static String? _getCompanyName(String ticker) {
    final companyNames = {
      'AAPL': 'Apple Inc',
      'MSFT': 'Microsoft Corporation',
      'GOOGL': 'Alphabet Inc',
      'GOOG': 'Alphabet Inc',
      'AMZN': 'Amazon.com Inc',
      'TSLA': 'Tesla Inc',
      'META': 'Meta Platforms Inc',
      'NVDA': 'NVIDIA Corporation',
      'NFLX': 'Netflix Inc',
      'DIS': 'The Walt Disney Company',
      'BA': 'The Boeing Company',
      'JPM': 'JPMorgan Chase & Co',
      'JNJ': 'Johnson & Johnson',
      'V': 'Visa Inc',
      'MA': 'Mastercard Incorporated',
      'PG': 'The Procter & Gamble Company',
      'KO': 'The Coca-Cola Company',
      'PEP': 'PepsiCo Inc',
      'WMT': 'Walmart Inc',
      'HD': 'The Home Depot Inc',
      'MCD': 'McDonald\'s Corporation',
      'SBUX': 'Starbucks Corporation',
      'AMD': 'Advanced Micro Devices Inc',
      'INTC': 'Intel Corporation',
      'ORCL': 'Oracle Corporation',
      'CRM': 'Salesforce Inc',
      'ADBE': 'Adobe Inc',
      'CSCO': 'Cisco Systems Inc',
      'IBM': 'International Business Machines Corporation',
      'PYPL': 'PayPal Holdings Inc',
      'UBER': 'Uber Technologies Inc',
      'SPY': 'SPDR S&P 500 ETF Trust',
      'QQQ': 'Invesco QQQ Trust',
      'VOO': 'Vanguard S&P 500 ETF',
      'VTI': 'Vanguard Total Stock Market ETF',
    };
    
    return companyNames[ticker];
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
      
      // Extract company name from title
      String companyName = ticker;
      final titleRegex = RegExp(r'<title>([^(]+)\s*\([^)]+\)', multiLine: true);
      final titleMatch = titleRegex.firstMatch(html);
      if (titleMatch != null) {
        companyName = titleMatch.group(1)?.trim() ?? ticker;
      }
      
      // Extract current price using the exact data attribute
      double currentPrice = 0.0;
      final priceRegex = RegExp(r'data-last-price="([0-9.]+)"', multiLine: true);
      final priceMatch = priceRegex.firstMatch(html);
      if (priceMatch != null) {
        final priceStr = priceMatch.group(1) ?? '0';
        currentPrice = double.tryParse(priceStr) ?? 0.0;
        print('🎯 Found exact price: $priceStr');
      }
      
      // If data-last-price not found, try the display price in YMlKec class
      if (currentPrice == 0.0) {
        final displayPriceRegex = RegExp(r'class="YMlKec[^"]*"[^>]*>\$([0-9,]+\.?[0-9]*)</div>', multiLine: true);
        final displayMatch = displayPriceRegex.firstMatch(html);
        if (displayMatch != null) {
          final priceStr = displayMatch.group(1)?.replaceAll(',', '') ?? '0';
          currentPrice = double.tryParse(priceStr) ?? 0.0;
          print('🎯 Found display price: $priceStr');
        }
      }
      
      // Extract change percentage using multiple approaches
      double changePercent = 0.0;
      
      // Method 1: Look for data-source attribute with change percentage
      final dataSourceRegex = RegExp(r'data-source="[^"]*"[^>]*>([+-]?[0-9]+\.?[0-9]*)%', multiLine: true);
      final dataSourceMatch = dataSourceRegex.firstMatch(html);
      
      if (dataSourceMatch != null) {
        final percentStr = dataSourceMatch.group(1) ?? '0';
        changePercent = double.tryParse(percentStr) ?? 0.0;
        print('🎯 Found change percent via data-source: ${percentStr}%');
      } else {
        // Method 2: Look for specific CSS class pattern (JwB6zf V7hZne)
        final percentClassRegex = RegExp(r'class="JwB6zf[^"]*"[^>]*>([+-]?[0-9]+\.?[0-9]*)%</div>', multiLine: true);
        final percentClassMatch = percentClassRegex.firstMatch(html);
        
        if (percentClassMatch != null) {
          final percentStr = percentClassMatch.group(1) ?? '0';
          changePercent = double.tryParse(percentStr) ?? 0.0;
          print('🎯 Found change percent via class: ${percentStr}%');
        } else {
          // Method 3: Look for percentage in price change context (near price data)
          final priceChangeRegex = RegExp(r'\$[0-9,]+\.[0-9]+.*?([+-])([0-9]+\.?[0-9]*)%', multiLine: true);
          final priceChangeMatch = priceChangeRegex.firstMatch(html);
          
          if (priceChangeMatch != null) {
            final sign = priceChangeMatch.group(1) ?? '';
            final percentStr = priceChangeMatch.group(2) ?? '0';
            final percent = double.tryParse(percentStr) ?? 0.0;
            
            if (percent >= 0.01 && percent < 50.0) {
              changePercent = sign == '-' ? -percent : percent;
              print('🎯 Found change percent via price context: ${sign}${percent}%');
            }
          } else {
            // Method 4: Generic fallback with strict filtering
            final percentRegex = RegExp(r'([+-])([0-9]+\.?[0-9]*)%', multiLine: true);
            final percentMatches = percentRegex.allMatches(html);
            
            // Look for percentages that are likely stock changes (exclude CSS animations)
            for (final match in percentMatches) {
              final sign = match.group(1) ?? '';
              final percentStr = match.group(2) ?? '0';
              final percent = double.tryParse(percentStr) ?? 0.0;
              
              // Only consider reasonable stock change percentages
              if (percent >= 0.01 && percent < 20.0) {
                // Skip common CSS animation values
                if (percent == 12.5 || percent == 25.0 || percent == 50.0 || percent == 75.0 || percent == 100.0) {
                  continue;
                }
                changePercent = sign == '-' ? -percent : percent;
                print('🎯 Found change percent via generic fallback: ${sign}${percent}%');
                break;
              }
            }
          }
        }
      }
      
      if (currentPrice > 0) {
        // Calculate change amount from price and change percent
        final change = changePercent != 0 ? (currentPrice * changePercent) / 100 : 0.0;
        
        print('✅ Successfully parsed: $companyName ($ticker)');
        print('   💰 Price: \$${currentPrice.toStringAsFixed(2)}');
        print('   📈 Change: ${changePercent >= 0 ? '+' : ''}${changePercent.toStringAsFixed(2)}% (\$${change.toStringAsFixed(2)})');
        print('   🏢 Exchange: $exchange');
        
        return MarketAssetModel(
          symbol: ticker,
          name: companyName,
          price: currentPrice,
          change: change,
          changePercent: changePercent,
          type: 'stock',
          lastUpdated: DateTime.now(),
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
      // ETFs (typically on NYSEARCA)
      'spy': 'SPY', 'qqq': 'QQQ', 'ixn': 'IXN', 'xlk': 'XLK', 'soxl': 'SOXL',
      // Indian companies (NSE/BOM)
      'reliance': 'RELIANCE', 'tcs': 'TCS', 'infosys': 'INFY', 'hdfc': 'HDFCBANK',
      'icici': 'ICICIBANK', 'wipro': 'WIPRO', 'bharti': 'BHARTIARTL',
    };
    
    // Look for company name matches
    for (final entry in companyDatabase.entries) {
      if (entry.key.contains(queryLower) || queryLower.contains(entry.key)) {
        try {
          // Try to get this stock from Google Finance using comprehensive exchange list
          final exchanges = [
            'NASDAQ',    // NASDAQ
            'NYSE',      // New York Stock Exchange
            'NYSEARCA',  // NYSE Arca (ETFs)
            'AMEX',      // American Stock Exchange
            'NSE',       // National Stock Exchange of India
            'BOM',       // Bombay Stock Exchange (BSE India)
          ];
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