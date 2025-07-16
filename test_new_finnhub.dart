import 'dart:convert';
import 'package:http/http.dart' as http;

void main() async {
  print('🧪 Testing updated Finnhub API key...');
  try {
    final response = await http.get(
      Uri.parse('https://finnhub.io/api/v1/quote?symbol=AAPL&token=d1raaj1r01qk8n65pv5gd1raaj1r01qk8n65pv60'),
      headers: {'Content-Type': 'application/json'},
    );
    
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['c'] != null && data['c'] != 0) {
        print('✅ New Finnhub API key working! AAPL price: \$${data['c']}');
      } else {
        print('❌ Finnhub API returned empty data');
        print('Response: ${response.body}');
      }
    } else {
      print('❌ Finnhub API failed: ${response.statusCode} - ${response.body}');
    }
  } catch (e) {
    print('❌ Finnhub API error: $e');
  }
}