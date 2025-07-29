import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/api_keys.dart';

class FinancialNewsService {
  static const String _logPrefix = '[FinancialNews]';
  
  // Finnhub News API endpoints
  static const String _finnhubBaseUrl = 'https://finnhub.io/api/v1';
  static const String _generalNewsUrl = '$_finnhubBaseUrl/news';
  static const String _companyNewsUrl = '$_finnhubBaseUrl/company-news';
  
  // Rate limiting
  static DateTime _lastApiCall = DateTime.now().subtract(const Duration(seconds: 2));
  static const Duration _apiCallDelay = Duration(milliseconds: 1200); // ~50 calls/minute
  
  // Cache keys
  static const String _generalNewsCacheKey = 'general_news_cache';
  static const String _lastUpdateKey = 'news_last_update';
  static const String _stockNewsCachePrefix = 'stock_news_';
  
  // Cache duration (24 hours)
  static const Duration _cacheDuration = Duration(hours: 24);
  
  // In-memory cache for current session
  static final Map<String, List<NewsArticle>> _memoryCache = {};
  static DateTime? _lastMemoryCacheUpdate;
  
  static Future<List<NewsArticle>> getNews({
    String? symbol,
    int limit = 10,
  }) async {
    try {
      print('$_logPrefix 📰 Fetching news for ${symbol ?? 'general market'}');
      
      // Check memory cache first (for current session)
      final cacheKey = symbol ?? 'general';
      if (_memoryCache.containsKey(cacheKey) && 
          _lastMemoryCacheUpdate != null &&
          DateTime.now().difference(_lastMemoryCacheUpdate!).inMinutes < 30) {
        print('$_logPrefix 💾 Using memory cache for $cacheKey');
        return _memoryCache[cacheKey]!.take(limit).toList();
      }
      
      // Check persistent cache (shared across all users)
      final cachedNews = await _getCachedNews(symbol);
      if (cachedNews != null && cachedNews.isNotEmpty) {
        print('$_logPrefix 📱 Using cached news for ${symbol ?? 'general'}');
        _memoryCache[cacheKey] = cachedNews;
        return cachedNews.take(limit).toList();
      }
      
      // Fetch fresh news if cache is empty or expired
      print('$_logPrefix 🆕 Generating fresh daily news');
      final freshNews = await _fetchFreshNews(symbol: symbol, limit: limit);
      
      // Cache the results
      if (freshNews.isNotEmpty) {
        await _cacheNews(symbol, freshNews);
        _memoryCache[cacheKey] = freshNews;
      }
      _lastMemoryCacheUpdate = DateTime.now();
      
      return freshNews;
      
    } catch (e) {
      print('$_logPrefix ❌ Error fetching news: $e');
      // Return empty list instead of mock data
      return [];
    }
  }
  
  /// Check if we need to update news (called daily)
  static Future<bool> shouldUpdateNews() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lastUpdateString = prefs.getString(_lastUpdateKey);
      
      if (lastUpdateString == null) return true;
      
      final lastUpdate = DateTime.parse(lastUpdateString);
      final now = DateTime.now();
      
      // Update if it's been more than 24 hours
      return now.difference(lastUpdate) > _cacheDuration;
    } catch (e) {
      print('$_logPrefix ❌ Error checking news update: $e');
      return true; // Default to updating if there's an error
    }
  }
  
  /// Update news in background (called periodically)
  static Future<void> updateNewsInBackground() async {
    try {
      if (await shouldUpdateNews()) {
        print('$_logPrefix 🔄 Updating news in background...');
        
        // Clear memory cache
        _memoryCache.clear();
        
        // Fetch fresh general news
        await getNews(limit: 20);
        
        // Mark as updated
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_lastUpdateKey, DateTime.now().toIso8601String());
        
        print('$_logPrefix ✅ Background news update completed');
      } else {
        print('$_logPrefix ℹ️ News cache is still fresh, no update needed');
      }
    } catch (e) {
      print('$_logPrefix ❌ Error updating news in background: $e');
    }
  }

  /// Get cached news from SharedPreferences
  static Future<List<NewsArticle>?> _getCachedNews(String? symbol) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cacheKey = symbol != null ? '$_stockNewsCachePrefix$symbol' : _generalNewsCacheKey;
      final cachedJson = prefs.getString(cacheKey);
      
      if (cachedJson != null) {
        final List<dynamic> cachedList = json.decode(cachedJson);
        return cachedList.map((json) => NewsArticle.fromJson(json)).toList();
      }
    } catch (e) {
      print('$_logPrefix ❌ Error reading cached news: $e');
    }
    return null;
  }
  
  /// Cache news to SharedPreferences
  static Future<void> _cacheNews(String? symbol, List<NewsArticle> articles) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cacheKey = symbol != null ? '$_stockNewsCachePrefix$symbol' : _generalNewsCacheKey;
      final jsonList = articles.map((article) => article.toJson()).toList();
      await prefs.setString(cacheKey, json.encode(jsonList));
      print('$_logPrefix 💾 Cached news for ${symbol ?? 'general'} (${articles.length} articles)');
    } catch (e) {
      print('$_logPrefix ❌ Error caching news: $e');
    }
  }
  
  /// Fetch fresh news from Finnhub API
  static Future<List<NewsArticle>> _fetchFreshNews({String? symbol, int limit = 10}) async {
    try {
      print('$_logPrefix 🆕 Fetching fresh news from Finnhub API');
      
      await _waitForRateLimit();
      
      final now = DateTime.now();
      final lastWeek = now.subtract(const Duration(days: 7));
      
      final String url;
      final Map<String, String> queryParams;
      
      if (symbol != null) {
        // Company-specific news
        queryParams = {
          'symbol': symbol,
          'from': _formatDateForApi(lastWeek),
          'to': _formatDateForApi(now),
          'token': ApiKeys.finnhubApiKey,
        };
        url = '$_companyNewsUrl?${Uri(queryParameters: queryParams).query}';
      } else {
        // General market news
        queryParams = {
          'category': 'general',
          'token': ApiKeys.finnhubApiKey,
        };
        url = '$_generalNewsUrl?${Uri(queryParameters: queryParams).query}';
      }
      
      print('$_logPrefix 🌐 API Request: $url');
      
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'X-Finnhub-Token': ApiKeys.finnhubApiKey,
          'User-Agent': 'StoxApp/1.0',
        },
      ).timeout(const Duration(seconds: 15));
      
      if (response.statusCode == 200) {
        final List<dynamic> newsData = json.decode(response.body);
        print('$_logPrefix 📈 Retrieved ${newsData.length} news articles');
        
        if (newsData.isNotEmpty) {
          final articles = <NewsArticle>[];
          
          for (final item in newsData.take(limit)) {
            try {
              final article = NewsArticle(
                title: item['headline'] ?? 'Market News',
                summary: item['summary'] ?? item['headline'] ?? 'Financial market update',
                url: item['url'] ?? '',
                timePublished: DateTime.fromMillisecondsSinceEpoch(
                  (item['datetime'] ?? 0) * 1000,
                ),
                source: item['source'] ?? 'Finnhub',
                sentiment: _analyzeSentiment(item['headline'] ?? ''),
              );
              
              articles.add(article);
            } catch (e) {
              print('$_logPrefix ⚠️ Error parsing news item: $e');
              continue; // Skip invalid items
            }
          }
          
          return articles;
        }
      } else {
        print('$_logPrefix ❌ Finnhub API error: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('$_logPrefix ❌ Error fetching from Finnhub: $e');
    }
    
    // Return empty list if API fails - no mock data
    print('$_logPrefix ❌ No real news data available - returning empty list');
    return [];
  }
  
  /// Wait for rate limit to avoid API throttling
  static Future<void> _waitForRateLimit() async {
    final now = DateTime.now();
    final timeSinceLastCall = now.difference(_lastApiCall);
    
    if (timeSinceLastCall < _apiCallDelay) {
      final waitTime = _apiCallDelay - timeSinceLastCall;
      print('$_logPrefix ⏳ Rate limiting: waiting ${waitTime.inMilliseconds}ms');
      await Future.delayed(waitTime);
    }
    
    _lastApiCall = DateTime.now();
  }
  
  /// Format date for API requests
  static String _formatDateForApi(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
  
  /// Simple sentiment analysis based on keywords
  static String _analyzeSentiment(String text) {
    final lowerText = text.toLowerCase();
    
    final bullishKeywords = ['gains', 'up', 'rise', 'growth', 'increase', 'bull', 'positive', 'surge', 'rally', 'strong', 'beat', 'outperform'];
    final bearishKeywords = ['falls', 'down', 'drop', 'decline', 'decrease', 'bear', 'negative', 'plunge', 'crash', 'weak', 'miss', 'underperform'];
    
    int bullishScore = bullishKeywords.where((keyword) => lowerText.contains(keyword)).length;
    int bearishScore = bearishKeywords.where((keyword) => lowerText.contains(keyword)).length;
    
    if (bullishScore > bearishScore) return 'Bullish';
    if (bearishScore > bullishScore) return 'Bearish';
    return 'Neutral';
  }
}

class NewsArticle {
  final String title;
  final String summary;
  final String url;
  final DateTime timePublished;
  final String source;
  final String sentiment;
  
  NewsArticle({
    required this.title,
    required this.summary,
    required this.url,
    required this.timePublished,
    required this.source,
    required this.sentiment,
  });

  factory NewsArticle.fromJson(Map<String, dynamic> json) {
    return NewsArticle(
      title: json['title'] ?? '',
      summary: json['summary'] ?? '',
      url: json['url'] ?? '',
      timePublished: DateTime.parse(json['timePublished']),
      source: json['source'] ?? '',
      sentiment: json['sentiment'] ?? 'Neutral',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'summary': summary,
      'url': url,
      'timePublished': timePublished.toIso8601String(),
      'source': source,
      'sentiment': sentiment,
    };
  }

  String get formattedTimeAgo {
    final now = DateTime.now();
    final difference = now.difference(timePublished);
    
    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }
}