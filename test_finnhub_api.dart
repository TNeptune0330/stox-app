import 'dart:convert';
import 'package:http/http.dart' as http;

void main() async {
  print('🧪 Testing Finnhub API Connection');
  
  const apiKey = 'd1raaj1r01qk8n65pv5gd1raaj1r01qk8n65pv60';
  
  // Test general news
  print('\n📰 Testing general news...');
  try {
    final url = 'https://finnhub.io/api/v1/news?category=general&token=$apiKey';
    final response = await http.get(Uri.parse(url));
    
    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      print('✅ General news: ${data.length} articles retrieved');
      if (data.isNotEmpty) {
        final first = data.first;
        print('   Sample: ${first['headline']}');
      }
    } else {
      print('❌ General news failed: ${response.statusCode}');
      print('   Response: ${response.body}');
    }
  } catch (e) {
    print('❌ General news error: $e');
  }
  
  // Test company news
  print('\n📈 Testing AAPL company news...');
  try {
    final toDate = DateTime.now();
    final fromDate = toDate.subtract(const Duration(days: 7));
    final formatDate = (DateTime date) => 
        '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    
    final url = 'https://finnhub.io/api/v1/company-news?symbol=AAPL&from=${formatDate(fromDate)}&to=${formatDate(toDate)}&token=$apiKey';
    final response = await http.get(Uri.parse(url));
    
    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      print('✅ AAPL news: ${data.length} articles retrieved');
      if (data.isNotEmpty) {
        final first = data.first;
        print('   Sample: ${first['headline']}');
        print('   Source: ${first['source']}');
      }
    } else {
      print('❌ AAPL news failed: ${response.statusCode}');
      print('   Response: ${response.body}');
    }
  } catch (e) {
    print('❌ AAPL news error: $e');
  }
  
  print('\n✅ Finnhub API test completed');
}