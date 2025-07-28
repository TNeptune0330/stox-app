import 'dart:collection';

class TelemetryLog {
  final String message;
  final String level; // INFO, WARNING, ERROR, SUCCESS
  final String category; // MarketData, Auth, Database, etc.
  final DateTime timestamp;

  TelemetryLog({
    required this.message,
    required this.level,
    required this.category,
    required this.timestamp,
  });
}

class TelemetryService {
  static final Queue<TelemetryLog> _logs = Queue<TelemetryLog>();
  static const int _maxLogs = 1000;
  
  static int _errorCount = 0;
  static int _apiCallCount = 0;

  /// Add a log entry
  static void log(String message, {
    String level = 'INFO',
    String category = 'General',
  }) {
    final log = TelemetryLog(
      message: message,
      level: level,
      category: category,
      timestamp: DateTime.now(),
    );

    _logs.addLast(log);
    
    // Keep only the most recent logs
    if (_logs.length > _maxLogs) {
      _logs.removeFirst();
    }

    // Update counters
    if (level == 'ERROR') {
      _errorCount++;
    }
    if (category == 'API' || message.contains('API')) {
      _apiCallCount++;
    }

    // Also print to console for development
    print('[$category] $message');
  }

  /// Log market data events
  static void logMarketData(String message, {String level = 'INFO'}) {
    log(message, level: level, category: 'MarketData');
  }

  /// Log authentication events
  static void logAuth(String message, {String level = 'INFO'}) {
    log(message, level: level, category: 'Auth');
  }

  /// Log database events
  static void logDatabase(String message, {String level = 'INFO'}) {
    log(message, level: level, category: 'Database');
  }

  /// Log news events
  static void logNews(String message, {String level = 'INFO'}) {
    log(message, level: level, category: 'News');
  }

  /// Log trading events
  static void logTrading(String message, {String level = 'INFO'}) {
    log(message, level: level, category: 'Trading');
  }

  /// Log API calls
  static void logApi(String message, {String level = 'INFO'}) {
    log(message, level: level, category: 'API');
  }

  /// Log errors
  static void logError(String message, {String category = 'Error'}) {
    log(message, level: 'ERROR', category: category);
  }

  /// Log success events
  static void logSuccess(String message, {String category = 'General'}) {
    log(message, level: 'SUCCESS', category: category);
  }

  /// Log warnings
  static void logWarning(String message, {String category = 'General'}) {
    log(message, level: 'WARNING', category: category);
  }

  /// Get all logs
  static List<TelemetryLog> getAllLogs() {
    return _logs.toList();
  }

  /// Get filtered logs by category
  static List<TelemetryLog> getFilteredLogs(String category) {
    if (category == 'All') {
      return _logs.toList();
    }
    
    if (category == 'Errors') {
      return _logs.where((log) => log.level == 'ERROR').toList();
    }
    
    return _logs.where((log) => log.category == category).toList();
  }

  /// Get logs by level
  static List<TelemetryLog> getLogsByLevel(String level) {
    return _logs.where((log) => log.level == level).toList();
  }

  /// Get recent logs (last N entries)
  static List<TelemetryLog> getRecentLogs(int count) {
    final logs = _logs.toList();
    if (logs.length <= count) {
      return logs;
    }
    return logs.sublist(logs.length - count);
  }

  /// Clear all logs
  static void clearLogs() {
    _logs.clear();
    _errorCount = 0;
    _apiCallCount = 0;
  }

  /// Get statistics
  static int getTotalLogCount() => _logs.length;
  static int getErrorCount() => _errorCount;
  static int getApiCallCount() => _apiCallCount;
  
  static Map<String, int> getCategoryStats() {
    final stats = <String, int>{};
    for (final log in _logs) {
      stats[log.category] = (stats[log.category] ?? 0) + 1;
    }
    return stats;
  }

  static Map<String, int> getLevelStats() {
    final stats = <String, int>{};
    for (final log in _logs) {
      stats[log.level] = (stats[log.level] ?? 0) + 1;
    }
    return stats;
  }

  /// Export logs as text
  static String exportLogsAsText() {
    final buffer = StringBuffer();
    buffer.writeln('=== STOX APP TELEMETRY EXPORT ===');
    buffer.writeln('Generated: ${DateTime.now()}');
    buffer.writeln('Total Logs: ${_logs.length}');
    buffer.writeln('');
    
    for (final log in _logs) {
      buffer.writeln('[${log.timestamp}] [${log.level}] [${log.category}] ${log.message}');
    }
    
    return buffer.toString();
  }
}