import 'dart:convert';
import 'package:http/http.dart' as http;

// Test script to verify API keys work
void main() async {
  print('🧪 Testing API Keys...\n');
  
  // Test Finnhub API
  await testFinnhubAPI();
  
  // Test CoinGecko API
  await testCoinGeckoAPI();
  
  // Test Alpha Vantage API
  await testAlphaVantageAPI();
}

Future<void> testFinnhubAPI() async {
  print('📈 Testing Finnhub API...');
  try {
    final response = await http.get(
      Uri.parse('https://finnhub.io/api/v1/quote?symbol=AAPL&token=D18tcuhr01qkcat4omj0d18tcuhr01qkcat4omjg'),
      headers: {'Content-Type': 'application/json'},
    );
    
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['c'] != null && data['c'] != 0) {
        print('✅ Finnhub API working! AAPL price: \$${data['c']}');
      } else {
        print('❌ Finnhub API returned empty data');
      }
    } else {
      print('❌ Finnhub API failed with status: ${response.statusCode}');
      print('Response: ${response.body}');
    }
  } catch (e) {
    print('❌ Finnhub API error: $e');
  }
  print('');
}

Future<void> testCoinGeckoAPI() async {
  print('🪙 Testing CoinGecko API...');
  try {
    final response = await http.get(
      Uri.parse('https://api.coingecko.com/api/v3/simple/price?ids=bitcoin&vs_currencies=usd&include_24hr_change=true'),
      headers: {'Content-Type': 'application/json'},
    );
    
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['bitcoin'] != null && data['bitcoin']['usd'] != null) {
        print('✅ CoinGecko API working! Bitcoin price: \$${data['bitcoin']['usd']}');
      } else {
        print('❌ CoinGecko API returned empty data');
      }
    } else {
      print('❌ CoinGecko API failed with status: ${response.statusCode}');
      print('Response: ${response.body}');
    }
  } catch (e) {
    print('❌ CoinGecko API error: $e');
  }
  print('');
}

Future<void> testAlphaVantageAPI() async {
  print('📊 Testing Alpha Vantage API...');
  try {
    final response = await http.get(
      Uri.parse('https://www.alphavantage.co/query?function=GLOBAL_QUOTE&symbol=AAPL&apikey=RIBXT1ACQKJQM3YU'),
      headers: {'Content-Type': 'application/json'},
    );
    
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final quote = data['Global Quote'];
      if (quote != null && quote['05. price'] != null) {
        print('✅ Alpha Vantage API working! AAPL price: \$${quote['05. price']}');
      } else {
        print('❌ Alpha Vantage API returned empty data');
        print('Response: ${response.body}');
      }
    } else {
      print('❌ Alpha Vantage API failed with status: ${response.statusCode}');
      print('Response: ${response.body}');
    }
  } catch (e) {
    print('❌ Alpha Vantage API error: $e');
  }
  print('');
}