/// Configuration for market data sources
/// Update these settings to control data accuracy and reliability
class MarketDataConfig {
  
  /// Timeout settings (in seconds)
  static const int apiTimeout = 10;
  static const int batchTimeout = 30;
  static const int historicalTimeout = 15;
  
  /// Rate limiting settings
  static const Duration apiCallDelay = Duration(milliseconds: 500);
  static const Duration retryDelay = Duration(seconds: 2);
  
  /// Fallback behavior
  /// If true, falls back to Yahoo Finance when YFinance backend fails
  /// If false, skips symbols that fail in YFinance backend
  static const bool enableFallbacks = true;
  
  /// Success threshold for batch updates
  /// Minimum percentage of successful updates to consider batch successful
  static const double batchSuccessThreshold = 0.8; // 80%
  
  /// Data sources priority order
  /// 1 = highest priority, higher numbers = lower priority
  static const Map<String, int> dataSourcePriority = {
    'yahoo_finance': 1,       // Fast, free, and reliable
    'finnhub': 2,            // Professional grade
    'alpha_vantage': 3,      // Additional reliability
  };
  
  /// Debug logging
  static const bool enableDebugLogs = true;
  
  /// API endpoint configurations
  static const String yahooFinanceBaseUrl = 'https://query1.finance.yahoo.com/v8/finance/chart/';
  static const String finnhubBaseUrl = 'https://finnhub.io/api/v1';
  static const String alphaVantageBaseUrl = 'https://www.alphavantage.co/query';
}