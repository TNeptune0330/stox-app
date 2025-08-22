import 'dart:developer' as developer;
import 'package:flutter/foundation.dart';

enum LogLevel { debug, info, warning, error }

class AppLogger {
  static const String _appName = 'Stox';
  
  // Configuration flags
  static bool enableDebugLogs = kDebugMode;
  static bool enableInfoLogs = true;
  static bool enableWarningLogs = true;
  static bool enableErrorLogs = true;
  
  // Core logging method
  static void _log(LogLevel level, String message, {String? tag, Object? error, StackTrace? stackTrace}) {
    // Check if this log level is enabled
    switch (level) {
      case LogLevel.debug:
        if (!enableDebugLogs) return;
        break;
      case LogLevel.info:
        if (!enableInfoLogs) return;
        break;
      case LogLevel.warning:
        if (!enableWarningLogs) return;
        break;
      case LogLevel.error:
        if (!enableErrorLogs) return;
        break;
    }
    
    // Format the message
    final String formattedTag = tag != null ? '[$tag] ' : '';
    final String levelPrefix = _getLevelPrefix(level);
    final String finalMessage = '$levelPrefix$formattedTag$message';
    
    // Log based on environment
    if (kDebugMode) {
      developer.log(
        finalMessage,
        name: _appName,
        level: _getLogLevelValue(level),
        error: error,
        stackTrace: stackTrace,
      );
    } else if (level == LogLevel.error || level == LogLevel.warning) {
      // Only log warnings and errors in release mode
      developer.log(
        finalMessage,
        name: _appName,
        level: _getLogLevelValue(level),
        error: error,
        stackTrace: stackTrace,
      );
    }
  }
  
  // Public logging methods
  static void debug(String message, {String? tag}) {
    _log(LogLevel.debug, message, tag: tag);
  }
  
  static void info(String message, {String? tag}) {
    _log(LogLevel.info, message, tag: tag);
  }
  
  static void warning(String message, {String? tag, Object? error}) {
    _log(LogLevel.warning, message, tag: tag, error: error);
  }
  
  static void error(String message, {String? tag, Object? error, StackTrace? stackTrace}) {
    _log(LogLevel.error, message, tag: tag, error: error, stackTrace: stackTrace);
  }
  
  // Helper methods
  static String _getLevelPrefix(LogLevel level) {
    switch (level) {
      case LogLevel.debug:
        return '🔍 ';
      case LogLevel.info:
        return 'ℹ️ ';
      case LogLevel.warning:
        return '⚠️ ';
      case LogLevel.error:
        return '❌ ';
    }
  }
  
  static int _getLogLevelValue(LogLevel level) {
    switch (level) {
      case LogLevel.debug:
        return 500;
      case LogLevel.info:
        return 800;
      case LogLevel.warning:
        return 900;
      case LogLevel.error:
        return 1000;
    }
  }
  
  // Feature-specific loggers
  static void auth(String message, {LogLevel level = LogLevel.info}) {
    _log(level, message, tag: 'Auth');
  }
  
  static void trading(String message, {LogLevel level = LogLevel.info}) {
    _log(level, message, tag: 'Trading');
  }
  
  static void market(String message, {LogLevel level = LogLevel.info}) {
    _log(level, message, tag: 'Market');
  }
  
  static void network(String message, {LogLevel level = LogLevel.info}) {
    _log(level, message, tag: 'Network');
  }
  
  static void performance(String message, {LogLevel level = LogLevel.debug}) {
    _log(level, message, tag: 'Performance');
  }
  
  static void achievement(String message, {LogLevel level = LogLevel.info}) {
    _log(level, message, tag: 'Achievement');
  }
  
  // Disable verbose logging for production
  static void disableVerboseLogging() {
    enableDebugLogs = false;
    enableInfoLogs = false;
    enableWarningLogs = true;
    enableErrorLogs = true;
  }
  
  // Enable full logging for development
  static void enableFullLogging() {
    enableDebugLogs = true;
    enableInfoLogs = true;
    enableWarningLogs = true;
    enableErrorLogs = true;
  }
}