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
        _lastMemoryCacheUpdate = DateTime.now();
        return cachedNews.take(limit).toList();
      }
      
      // If no valid cache, fetch real news only
      print('$_logPrefix 🆕 Fetching fresh news from API (no fake news)');
      final freshNews = await _fetchRealNewsOnly(symbol: symbol, limit: limit);
      
      if (freshNews.isNotEmpty) {
        // Cache the news for 24 hours only if we got real news
        await _saveNewsToCache(symbol, freshNews);
        
        // Update memory cache
        _memoryCache[cacheKey] = freshNews;
        _lastMemoryCacheUpdate = DateTime.now();
        
        return freshNews;
      } else {
        // Return empty list if no real news available - NO FAKE NEWS
        print('$_logPrefix ℹ️ No real news available, returning empty list (no fake news)');
        return [];
      }
      
    } catch (e) {
      print('$_logPrefix ❌ Error fetching news: $e');
      // Return empty list instead of fake news
      print('$_logPrefix ℹ️ Returning empty list due to error (no fake news fallback)');
      return [];
    }
  }
  
  /// Check if we need to update news (called daily)
  static Future<bool> shouldUpdateNews() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lastUpdateStr = prefs.getString(_lastUpdateKey);
      
      if (lastUpdateStr == null) return true;
      
      final lastUpdate = DateTime.parse(lastUpdateStr);
      final now = DateTime.now();
      
      // Update if it's been more than 24 hours OR if it's a new day
      final daysSinceUpdate = now.difference(lastUpdate).inDays;
      final isDifferentDay = now.day != lastUpdate.day || 
                           now.month != lastUpdate.month || 
                           now.year != lastUpdate.year;
      
      return daysSinceUpdate >= 1 || isDifferentDay;
    } catch (e) {
      print('$_logPrefix ❌ Error checking update status: $e');
      return true; // Default to updating if we can't determine
    }
  }
  
  /// Force update news cache (called at app startup if needed)
  static Future<void> updateDailyNews() async {
    try {
      if (await shouldUpdateNews()) {
        print('$_logPrefix 🔄 Updating daily news cache...');
        
        // Clear memory cache
        _memoryCache.clear();
        _lastMemoryCacheUpdate = null;
        
        // Update general market news first (real news only)
        final generalNews = await _fetchRealNewsOnly(limit: 15);
        if (generalNews.isNotEmpty) {
          await _saveNewsToCache(null, generalNews);
          print('$_logPrefix ✅ Updated general market news (${generalNews.length} real articles)');
        }
        
        // Update news for most popular stocks (within rate limits)
        final popularStocks = [
          'AAPL', 'GOOGL', 'MSFT', 'TSLA', 'NVDA', 'AMZN', 'META', 'NFLX',
          'SPY', 'QQQ', 'JPM', 'V', 'JNJ', 'PG', 'UNH', 'HD', 'MA', 'DIS'
        ];
        
        // Limit to 15 stocks per day to stay within rate limits (60 calls/minute)
        final dailyStocks = popularStocks.take(15).toList();
        
        for (final stock in dailyStocks) {
          try {
            final stockNews = await _fetchRealNewsOnly(symbol: stock, limit: 8);
            if (stockNews.isNotEmpty) {
              await _saveNewsToCache(stock, stockNews);
              print('$_logPrefix ✅ Updated news for $stock (${stockNews.length} real articles)');
            } else {
              print('$_logPrefix ℹ️ No real news found for $stock');
            }
          } catch (e) {
            print('$_logPrefix ⚠️ Failed to update news for $stock: $e');
          }
        }
        
        // Mark as updated
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_lastUpdateKey, DateTime.now().toIso8601String());
        
        print('$_logPrefix ✅ Daily news cache updated');
      } else {
        print('$_logPrefix ℹ️ News cache is still fresh, no update needed');
      }
    } catch (e) {
      print('$_logPrefix ❌ Error updating daily news: $e');
    }
  }
  
  /// Get cached news from persistent storage
  static Future<List<NewsArticle>?> _getCachedNews(String? symbol) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cacheKey = symbol != null 
          ? '$_stockNewsCachePrefix$symbol' 
          : _generalNewsCacheKey;
      
      final cachedData = prefs.getString(cacheKey);
      if (cachedData == null) return null;
      
      final data = json.decode(cachedData);
      final cacheTime = DateTime.parse(data['timestamp']);
      
      // Check if cache is still valid (within 24 hours)
      if (DateTime.now().difference(cacheTime) > _cacheDuration) {
        print('$_logPrefix ⏰ Cache expired for ${symbol ?? 'general'}');
        return null;
      }
      
      final List<dynamic> articlesJson = data['articles'];
      return articlesJson.map((json) => NewsArticle.fromCachedJson(json)).toList();
    } catch (e) {
      print('$_logPrefix ❌ Error reading cached news: $e');
      return null;
    }
  }
  
  /// Save news to persistent cache
  static Future<void> _saveNewsToCache(String? symbol, List<NewsArticle> articles) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cacheKey = symbol != null 
          ? '$_stockNewsCachePrefix$symbol' 
          : _generalNewsCacheKey;
      
      final cacheData = {
        'timestamp': DateTime.now().toIso8601String(),
        'articles': articles.map((article) => article.toCacheJson()).toList(),
      };
      
      await prefs.setString(cacheKey, json.encode(cacheData));
      print('$_logPrefix 💾 Cached news for ${symbol ?? 'general'} (${articles.length} articles)');
    } catch (e) {
      print('$_logPrefix ❌ Error saving news to cache: $e');
    }
  }
  
  /// Fetch real news only from Finnhub API - NO FAKE NEWS
  static Future<List<NewsArticle>> _fetchRealNewsOnly({String? symbol, int limit = 10}) async {
    print('$_logPrefix 🆕 Fetching REAL news only from Finnhub API (no fake fallback)');
    
    try {
      await _waitForRateLimit();
      
      String url;
      Map<String, String> params;
      
      if (symbol != null) {
        // Company-specific news
        final toDate = DateTime.now();
        final fromDate = toDate.subtract(const Duration(days: 7)); // Last 7 days
        
        url = _companyNewsUrl;
        params = {
          'symbol': symbol,
          'from': _formatDateForApi(fromDate),
          'to': _formatDateForApi(toDate),
          'token': ApiKeys.finnhubApiKey,
        };
      } else {
        // General market news
        url = _generalNewsUrl;
        params = {
          'category': 'general',
          'token': ApiKeys.finnhubApiKey,
        };
      }
      
      final uri = Uri.parse(url).replace(queryParameters: params);
      print('$_logPrefix 🌐 API Request: ${uri.toString().replaceAll(ApiKeys.finnhubApiKey, 'API_KEY')}');
      
      final response = await http.get(uri);
      
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        
        if (data.isNotEmpty) {
          final articles = data
              .take(limit)
              .map((article) => NewsArticle.fromFinnhubJson(article))
              .where((article) => article.title.isNotEmpty && article.summary.isNotEmpty)
              .toList();
          
          if (articles.isNotEmpty) {
            print('$_logPrefix ✅ Retrieved ${articles.length} REAL news articles from Finnhub');
            return articles;
          }
        }
      } else {
        print('$_logPrefix ❌ Finnhub API error: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('$_logPrefix ❌ Error fetching from Finnhub: $e');
    }
    
    // NO FALLBACK TO FAKE NEWS - return empty list if API fails
    print('$_logPrefix ℹ️ API failed, returning empty list (NO FAKE NEWS FALLBACK)');
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
  
  /// Format date for Finnhub API (YYYY-MM-DD)
  static String _formatDateForApi(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
  
  // ALL FAKE NEWS GENERATION METHODS REMOVED
  // This service now only provides real news from Finnhub API
  // If no real news is available, it returns an empty list
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
      timePublished: DateTime.tryParse(json['time_published'] ?? '') ?? DateTime.now(),
      source: json['source'] ?? 'Unknown',
      sentiment: _getSentimentLabel(json['overall_sentiment_score']?.toDouble() ?? 0.0),
    );
  }
  
  factory NewsArticle.fromFinnhubJson(Map<String, dynamic> json) {
    // Parse Finnhub datetime format (Unix timestamp)
    DateTime publishedTime;
    try {
      final timestamp = json['datetime'] as int;
      publishedTime = DateTime.fromMillisecondsSinceEpoch(timestamp * 1000);
    } catch (e) {
      publishedTime = DateTime.now();
    }
    
    return NewsArticle(
      title: json['headline'] ?? '',
      summary: json['summary'] ?? '',
      url: json['url'] ?? '',
      timePublished: publishedTime,
      source: json['source'] ?? 'Finnhub',
      sentiment: _inferSentimentFromText(json['headline'] ?? '', json['summary'] ?? ''),
    );
  }
  
  factory NewsArticle.fromCachedJson(Map<String, dynamic> json) {
    return NewsArticle(
      title: json['title'] ?? '',
      summary: json['summary'] ?? '',
      url: json['url'] ?? '',
      timePublished: DateTime.tryParse(json['timePublished'] ?? '') ?? DateTime.now(),
      source: json['source'] ?? 'Unknown',
      sentiment: json['sentiment'] ?? 'Neutral',
    );
  }
  
  Map<String, dynamic> toCacheJson() {
    return {
      'title': title,
      'summary': summary,
      'url': url,
      'timePublished': timePublished.toIso8601String(),
      'source': source,
      'sentiment': sentiment,
    };
  }
  
  static String _getSentimentLabel(double score) {
    if (score > 0.15) return 'Bullish';
    if (score < -0.15) return 'Bearish';
    return 'Neutral';
  }
  
  /// Infer sentiment from headline and summary text
  static String _inferSentimentFromText(String headline, String summary) {
    final text = '$headline $summary'.toLowerCase();
    
    // Bullish keywords
    final bullishKeywords = [
      'beats', 'exceeds', 'surpasses', 'upgrade', 'upgraded', 'raises', 'increased',
      'growth', 'profit', 'revenue', 'earnings', 'positive', 'strong', 'solid',
      'gains', 'rally', 'bull', 'bullish', 'optimistic', 'confident', 'partnership',
      'expansion', 'acquisition', 'merger', 'breakthrough', 'innovation', 'launch',
      'approval', 'success', 'record', 'highest', 'outperform', 'buy', 'investment'
    ];
    
    // Bearish keywords
    final bearishKeywords = [
      'misses', 'falls short', 'disappoints', 'downgrade', 'downgraded', 'cuts', 'reduced',
      'decline', 'loss', 'losses', 'negative', 'weak', 'poor', 'falls', 'crash',
      'bear', 'bearish', 'pessimistic', 'concern', 'worried', 'lawsuit', 'investigation',
      'scandal', 'bankruptcy', 'closure', 'layoffs', 'firing', 'resignation', 'sell',
      'warning', 'alert', 'risk', 'volatility', 'uncertainty', 'regulatory'
    ];
    
    int bullishCount = 0;
    int bearishCount = 0;
    
    // Count keyword occurrences
    for (final keyword in bullishKeywords) {
      if (text.contains(keyword)) {
        bullishCount++;
      }
    }
    
    for (final keyword in bearishKeywords) {
      if (text.contains(keyword)) {
        bearishCount++;
      }
    }
    
    // Determine sentiment based on keyword counts
    if (bullishCount > bearishCount) {
      return 'Bullish';
    } else if (bearishCount > bullishCount) {
      return 'Bearish';
    } else {
      return 'Neutral';
    }
  }
  
  String get timeAgo {
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