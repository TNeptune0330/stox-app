import 'package:flutter/services.dart';
import 'lib/services/financial_news_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  print('🧪 Testing Finnhub Financial News Service');
  
  // Test general news
  print('\n📰 Fetching general market news from Finnhub...');
  final generalNews = await FinancialNewsService.getNews(limit: 5);
  for (final article in generalNews) {
    print('- ${article.title} (${article.sentiment}) - ${article.source}');
    print('  📅 ${article.timeAgo}');
    print('  📝 ${article.summary.substring(0, 100)}...\n');
  }
  
  // Test stock-specific news
  print('\n📈 Fetching AAPL news from Finnhub...');
  final appleNews = await FinancialNewsService.getNews(symbol: 'AAPL', limit: 3);
  for (final article in appleNews) {
    print('- ${article.title} (${article.sentiment})');
    print('  📅 ${article.timeAgo}');
    print('  📝 ${article.summary.substring(0, 80)}...\n');
  }
  
  // Test caching
  print('\n🔄 Testing cache (should be instant)...');
  final cachedNews = await FinancialNewsService.getNews(limit: 2);
  print('✅ Retrieved ${cachedNews.length} cached articles');
  
  // Test update check
  print('\n⏰ Checking if update needed...');
  final shouldUpdate = await FinancialNewsService.shouldUpdateNews();
  print('Should update: $shouldUpdate');
  
  if (shouldUpdate) {
    print('\n🔄 Running daily news update...');
    await FinancialNewsService.updateDailyNews();
  }
  
  print('\n✅ Finnhub news service test completed');
}