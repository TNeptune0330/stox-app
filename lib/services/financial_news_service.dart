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
      
      // If no valid cache, generate and cache daily news
      print('$_logPrefix 🆕 Generating fresh daily news');
      final freshNews = await _generateDailyNews(symbol: symbol, limit: limit);
      
      // Cache the news for 24 hours
      await _saveNewsToCache(symbol, freshNews);
      
      // Update memory cache
      _memoryCache[cacheKey] = freshNews;
      _lastMemoryCacheUpdate = DateTime.now();
      
      return freshNews;
      
    } catch (e) {
      print('$_logPrefix ❌ Error fetching news: $e');
      // Fallback to basic mock news
      return _getMockNews(symbol: symbol, limit: limit);
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
        
        // Update general market news first
        await getNews(limit: 15);
        
        // Update news for most popular stocks (within rate limits)
        final popularStocks = [
          'AAPL', 'GOOGL', 'MSFT', 'TSLA', 'NVDA', 'AMZN', 'META', 'NFLX',
          'SPY', 'QQQ', 'JPM', 'V', 'JNJ', 'PG', 'UNH', 'HD', 'MA', 'DIS'
        ];
        
        // Limit to 15 stocks per day to stay within rate limits (60 calls/minute)
        final dailyStocks = popularStocks.take(15).toList();
        
        for (final stock in dailyStocks) {
          try {
            await getNews(symbol: stock, limit: 8);
            print('$_logPrefix ✅ Updated news for $stock');
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
  
  /// Generate fresh daily news from Finnhub API
  static Future<List<NewsArticle>> _generateDailyNews({String? symbol, int limit = 10}) async {
    print('$_logPrefix 🆕 Fetching fresh news from Finnhub API');
    
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
            print('$_logPrefix ✅ Retrieved ${articles.length} real news articles from Finnhub');
            return articles;
          }
        }
      } else {
        print('$_logPrefix ❌ Finnhub API error: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('$_logPrefix ❌ Error fetching from Finnhub: $e');
    }
    
    // Fallback to deterministic mock news if API fails
    print('$_logPrefix 🔄 Falling back to deterministic mock news');
    final today = DateTime.now();
    final dateString = '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
    final seed = dateString.hashCode;
    return _generateDeterministicMockNews(symbol: symbol, limit: limit, seed: seed);
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
  
  /// Generate consistent mock news based on date seed
  static List<NewsArticle> _generateDeterministicMockNews({String? symbol, int limit = 10, required int seed}) {
    final random = seed.abs() % 1000000; // Create deterministic "random" number
    final today = DateTime.now();
    
    final newsTemplates = symbol != null ? _getStockNewsTemplates(symbol) : _getGeneralNewsTemplates();
    final selectedNews = <NewsArticle>[];
    
    // Use seed to select which news items to show today
    for (int i = 0; i < limit && i < newsTemplates.length; i++) {
      final templateIndex = (random + i * 7) % newsTemplates.length;
      final template = newsTemplates[templateIndex];
      
      // Generate time with some variation but deterministic
      final hoursAgo = 1 + ((random + i * 3) % 12);
      final minutesAgo = (random + i * 11) % 60;
      
      selectedNews.add(NewsArticle(
        title: template['title']!,
        summary: template['summary']!,
        url: 'https://example.com/news/${random + i}',
        timePublished: today.subtract(Duration(hours: hoursAgo, minutes: minutesAgo)),
        source: template['source']!,
        sentiment: template['sentiment']!,
      ));
    }
    
    return selectedNews;
  }
  
  static List<Map<String, String>> _getStockNewsTemplates(String symbol) {
    return [
      {
        'title': '$symbol Reports Strong Q4 Earnings, Beats Expectations',
        'summary': 'The company reported revenue growth of 15% year-over-year, driven by strong demand across all segments.',
        'source': 'Financial Times',
        'sentiment': 'Bullish',
      },
      {
        'title': '$symbol Announces New Product Launch',
        'summary': 'The new product line is expected to drive significant revenue growth in the coming quarters.',
        'source': 'Reuters',
        'sentiment': 'Bullish',
      },
      {
        'title': 'Analysts Upgrade $symbol Price Target',
        'summary': 'Multiple analysts have raised their price targets following strong fundamentals and growth prospects.',
        'source': 'Bloomberg',
        'sentiment': 'Bullish',
      },
      {
        'title': '$symbol CEO to Speak at Industry Conference',
        'summary': 'The CEO will discuss the company\'s strategic vision and future growth opportunities.',
        'source': 'CNBC',
        'sentiment': 'Neutral',
      },
      {
        'title': '$symbol Partners with Major Technology Firm',
        'summary': 'Strategic partnership expected to accelerate digital transformation initiatives.',
        'source': 'Wall Street Journal',
        'sentiment': 'Bullish',
      },
      {
        'title': '$symbol Faces Regulatory Scrutiny',
        'summary': 'New regulations may impact the company\'s operations in key markets.',
        'source': 'MarketWatch',
        'sentiment': 'Bearish',
      },
      {
        'title': '$symbol Expands International Operations',
        'summary': 'Company announces expansion into three new international markets.',
        'source': 'Business Insider',
        'sentiment': 'Bullish',
      },
      {
        'title': '$symbol Insider Trading Activity Reported',
        'summary': 'Recent insider buying activity suggests confidence in the company\'s future performance.',
        'source': 'Yahoo Finance',
        'sentiment': 'Neutral',
      },
    ];
  }
  
  static List<Map<String, String>> _getGeneralNewsTemplates() {
    return [
      {
        'title': 'Market Rallies on Strong Economic Data',
        'summary': 'Markets closed higher as investors digested positive economic indicators and corporate earnings.',
        'source': 'Financial Times',
        'sentiment': 'Bullish',
      },
      {
        'title': 'Fed Signals Pause in Rate Hikes',
        'summary': 'Federal Reserve officials hint at maintaining current interest rates amid stable inflation.',
        'source': 'Reuters',
        'sentiment': 'Bullish',
      },
      {
        'title': 'Tech Stocks Lead Market Gains',
        'summary': 'Technology companies continue to outperform broader market indices with strong innovation.',
        'source': 'Bloomberg',
        'sentiment': 'Bullish',
      },
      {
        'title': 'Global Markets Mixed on Trade Concerns',
        'summary': 'International markets show mixed performance amid ongoing trade negotiations.',
        'source': 'CNBC',
        'sentiment': 'Neutral',
      },
      {
        'title': 'Oil Prices Surge on Supply Concerns',
        'summary': 'Crude oil prices jump as geopolitical tensions raise supply disruption concerns.',
        'source': 'MarketWatch',
        'sentiment': 'Neutral',
      },
      {
        'title': 'Cryptocurrency Market Sees Volatility',
        'summary': 'Digital assets experience significant price swings amid regulatory developments.',
        'source': 'Wall Street Journal',
        'sentiment': 'Neutral',
      },
      {
        'title': 'Inflation Data Shows Continued Moderation',
        'summary': 'Latest inflation figures suggest continued cooling in price pressures.',
        'source': 'Business Insider',
        'sentiment': 'Bullish',
      },
      {
        'title': 'Banking Sector Faces New Challenges',
        'summary': 'Regional banks navigate changing interest rate environment and regulatory landscape.',
        'source': 'Yahoo Finance',
        'sentiment': 'Bearish',
      },
    ];
  }
  
  static List<NewsArticle> _getMockNews({String? symbol, int limit = 10}) {
    final mockArticles = [
      NewsArticle(
        title: symbol != null 
            ? '$symbol Reports Strong Q4 Earnings, Beats Expectations'
            : 'Market Rallies on Strong Economic Data',
        summary: symbol != null
            ? 'The company reported revenue growth of 15% year-over-year, driven by strong demand across all segments.'
            : 'Markets closed higher as investors digested positive economic indicators and corporate earnings.',
        url: 'https://example.com/news/1',
        timePublished: DateTime.now().subtract(const Duration(hours: 2)),
        source: 'Financial Times',
        sentiment: 'Bullish',
      ),
      NewsArticle(
        title: symbol != null
            ? '$symbol Announces New Product Launch'
            : 'Fed Signals Pause in Rate Hikes',
        summary: symbol != null
            ? 'The new product line is expected to drive significant revenue growth in the coming quarters.'
            : 'Federal Reserve officials hint at maintaining current interest rates amid stable inflation.',
        url: 'https://example.com/news/2',
        timePublished: DateTime.now().subtract(const Duration(hours: 5)),
        source: 'Reuters',
        sentiment: 'Bullish',
      ),
      NewsArticle(
        title: symbol != null
            ? 'Analysts Upgrade $symbol Price Target'
            : 'Tech Stocks Lead Market Gains',
        summary: symbol != null
            ? 'Multiple analysts have raised their price targets following strong fundamentals and growth prospects.'
            : 'Technology companies continue to outperform broader market indices with strong innovation.',
        url: 'https://example.com/news/3',
        timePublished: DateTime.now().subtract(const Duration(hours: 8)),
        source: 'Bloomberg',
        sentiment: 'Bullish',
      ),
      NewsArticle(
        title: symbol != null
            ? '$symbol CEO to Speak at Industry Conference'
            : 'Global Markets Mixed on Trade Concerns',
        summary: symbol != null
            ? 'The CEO will discuss the company\'s strategic vision and future growth opportunities.'
            : 'International markets show mixed performance amid ongoing trade negotiations.',
        url: 'https://example.com/news/4',
        timePublished: DateTime.now().subtract(const Duration(hours: 12)),
        source: 'CNBC',
        sentiment: 'Neutral',
      ),
      NewsArticle(
        title: symbol != null
            ? '$symbol Insider Trading Activity Reported'
            : 'Oil Prices Surge on Supply Concerns',
        summary: symbol != null
            ? 'Recent insider buying activity suggests confidence in the company\'s future performance.'
            : 'Crude oil prices jump as geopolitical tensions raise supply disruption concerns.',
        url: 'https://example.com/news/5',
        timePublished: DateTime.now().subtract(const Duration(days: 1)),
        source: 'MarketWatch',
        sentiment: 'Neutral',
      ),
      NewsArticle(
        title: symbol != null
            ? '$symbol Partners with Major Technology Firm'
            : 'Cryptocurrency Market Sees Volatility',
        summary: symbol != null
            ? 'Strategic partnership expected to accelerate digital transformation initiatives.'
            : 'Digital assets experience significant price swings amid regulatory developments.',
        url: 'https://example.com/news/6',
        timePublished: DateTime.now().subtract(const Duration(days: 1, hours: 6)),
        source: 'Wall Street Journal',
        sentiment: 'Bullish',
      ),
    ];
    
    return mockArticles.take(limit).toList();
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