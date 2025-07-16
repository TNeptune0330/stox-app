import 'dart:convert';
import 'package:http/http.dart' as http;

// Test to see if the market data service will work with real APIs
void main() async {
  print('🧪 Testing Market Data Service Logic...\n');
  
  final testSymbols = ['AAPL', 'GOOGL', 'MSFT'];
  
  for (final symbol in testSymbols) {
    print('📊 Testing $symbol...');
    
    // Try Alpha Vantage first (working API)
    if (await tryAlphaVantage(symbol)) {
      print('✅ $symbol: Alpha Vantage success\n');
      continue;
    }
    
    // Try CoinGecko for crypto fallback
    print('⚠️ $symbol: Alpha Vantage failed, would use mock data\n');
    
    // Add delay to respect rate limits
    await Future.delayed(const Duration(seconds: 2));
  }
  
  // Test crypto
  print('🪙 Testing Bitcoin...');
  if (await tryCoinGecko('bitcoin')) {
    print('✅ Bitcoin: CoinGecko success\n');
  } else {
    print('❌ Bitcoin: CoinGecko failed\n');
  }
}

Future<bool> tryAlphaVantage(String symbol) async {
  try {
    final response = await http.get(
      Uri.parse('https://www.alphavantage.co/query?function=GLOBAL_QUOTE&symbol=$symbol&apikey=RIBXT1ACQKJQM3YU'),
      headers: {'Content-Type': 'application/json'},
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final quote = data['Global Quote'];
      
      if (quote != null && quote['05. price'] != null) {
        final price = double.tryParse(quote['05. price']) ?? 0.0;
        final changePercent = double.tryParse(quote['10. change percent']?.replaceAll('%', '') ?? '0') ?? 0.0;
        
        if (price > 0) {
          print('   📈 Price: \$${price.toStringAsFixed(2)}, Change: ${changePercent.toStringAsFixed(2)}%');
          return true;
        }
      }
    }
  } catch (e) {
    print('   ❌ Alpha Vantage error: $e');
  }
  return false;
}

Future<bool> tryCoinGecko(String id) async {
  try {
    final response = await http.get(
      Uri.parse('https://api.coingecko.com/api/v3/simple/price?ids=$id&vs_currencies=usd&include_24hr_change=true'),
      headers: {'Content-Type': 'application/json'},
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      
      if (data[id] != null && data[id]['usd'] != null) {
        final price = data[id]['usd'].toDouble();
        final changePercent = data[id]['usd_24h_change']?.toDouble() ?? 0.0;
        
        print('   🪙 Price: \$${price.toStringAsFixed(2)}, Change: ${changePercent.toStringAsFixed(2)}%');
        return true;
      }
    }
  } catch (e) {
    print('   ❌ CoinGecko error: $e');
  }
  return false;
}