import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'optimized_cache_service.dart';
import 'optimized_network_service.dart';

/// Comprehensive performance monitoring service
class PerformanceMonitorService {
  static const String _logPrefix = '[PerformanceMonitor]';
  
  // Performance metrics
  static final Stopwatch _appStartupTimer = Stopwatch();
  static final Map<String, Stopwatch> _featureTimers = {};
  static final Map<String, List<double>> _performanceMetrics = {};
  static final List<_PerformanceEvent> _performanceEvents = [];
  
  // Device and app info
  static Map<String, dynamic>? _deviceInfo;
  static PackageInfo? _packageInfo;
  
  // Monitoring flags
  static bool _isMonitoring = false;
  static Timer? _reportTimer;
  
  /// Initialize performance monitoring
  static Future<void> initialize() async {
    if (_isMonitoring) return;
    
    print('$_logPrefix 🚀 Initializing performance monitoring...');
    
    try {
      // Start app startup timer
      _appStartupTimer.start();
      
      // Get device info
      await _collectDeviceInfo();
      
      // Get package info
      _packageInfo = await PackageInfo.fromPlatform();
      
      // Start periodic reporting in debug mode
      if (kDebugMode) {
        _startPeriodicReporting();
      }
      
      _isMonitoring = true;
      print('$_logPrefix ✅ Performance monitoring initialized');
      
    } catch (e) {
      print('$_logPrefix ❌ Failed to initialize: $e');
    }
  }
  
  /// Start app startup measurement
  static void startAppStartup() {
    if (!_appStartupTimer.isRunning) {
      _appStartupTimer.start();
      print('$_logPrefix ⏱️ App startup timer started');
    }
  }
  
  /// Complete app startup measurement
  static void completeAppStartup() {
    if (_appStartupTimer.isRunning) {
      _appStartupTimer.stop();
      final startupTime = _appStartupTimer.elapsedMilliseconds;
      
      recordMetric('app_startup_time', startupTime.toDouble());
      recordEvent('app_startup_completed', {
        'startup_time_ms': startupTime,
        'device_info': _deviceInfo,
        'app_version': _packageInfo?.version,
      });
      
      print('$_logPrefix 🎯 App startup completed in ${startupTime}ms');
    }
  }
  
  /// Start measuring a feature/operation
  static void startFeatureTimer(String featureName) {
    _featureTimers[featureName] = Stopwatch()..start();
    print('$_logPrefix ⏱️ Started timer for: $featureName');
  }
  
  /// Stop measuring a feature/operation
  static void stopFeatureTimer(String featureName) {
    final timer = _featureTimers[featureName];
    if (timer != null && timer.isRunning) {
      timer.stop();
      final elapsed = timer.elapsedMilliseconds.toDouble();
      
      recordMetric(featureName, elapsed);
      _featureTimers.remove(featureName);
      
      print('$_logPrefix ✅ $featureName completed in ${elapsed.toInt()}ms');
    }
  }
  
  /// Record a performance metric
  static void recordMetric(String name, double value) {
    _performanceMetrics[name] ??= [];
    _performanceMetrics[name]!.add(value);
    
    // Keep only last 100 measurements to manage memory
    if (_performanceMetrics[name]!.length > 100) {
      _performanceMetrics[name]!.removeAt(0);
    }
    
    if (kDebugMode && value > 1000) { // Log slow operations
      print('$_logPrefix ⚠️ Slow operation detected: $name took ${value.toInt()}ms');
    }
  }
  
  /// Record a performance event
  static void recordEvent(String eventName, Map<String, dynamic> data) {
    final event = _PerformanceEvent(
      name: eventName,
      timestamp: DateTime.now(),
      data: data,
    );
    
    _performanceEvents.add(event);
    
    // Keep only last 50 events to manage memory
    if (_performanceEvents.length > 50) {
      _performanceEvents.removeAt(0);
    }
    
    if (kDebugMode) {
      print('$_logPrefix 📊 Event recorded: $eventName');
    }
  }
  
  /// Measure execution time of a function
  static Future<T> measureAsync<T>(String name, Future<T> Function() function) async {
    final stopwatch = Stopwatch()..start();
    
    try {
      final result = await function();
      stopwatch.stop();
      recordMetric(name, stopwatch.elapsedMilliseconds.toDouble());
      return result;
    } catch (e) {
      stopwatch.stop();
      recordEvent('${name}_error', {
        'error': e.toString(),
        'duration_ms': stopwatch.elapsedMilliseconds,
      });
      rethrow;
    }
  }
  
  /// Measure execution time of a synchronous function
  static T measureSync<T>(String name, T Function() function) {
    final stopwatch = Stopwatch()..start();
    
    try {
      final result = function();
      stopwatch.stop();
      recordMetric(name, stopwatch.elapsedMilliseconds.toDouble());
      return result;
    } catch (e) {
      stopwatch.stop();
      recordEvent('${name}_error', {
        'error': e.toString(),
        'duration_ms': stopwatch.elapsedMilliseconds,
      });
      rethrow;
    }
  }
  
  /// Get comprehensive performance report
  static Map<String, dynamic> getPerformanceReport() {
    final report = <String, dynamic>{
      'timestamp': DateTime.now().toIso8601String(),
      'app_info': {
        'version': _packageInfo?.version,
        'build_number': _packageInfo?.buildNumber,
        'package_name': _packageInfo?.packageName,
      },
      'device_info': _deviceInfo,
      'metrics': _calculateMetricsSummary(),
      'cache_stats': OptimizedCacheService.getStats(),
      'network_stats': OptimizedNetworkService.getPerformanceStats(),
      'recent_events': _performanceEvents.map((e) => e.toJson()).toList(),
      'memory_usage': _getMemoryUsage(),
    };
    
    return report;
  }
  
  /// Calculate summary statistics for metrics
  static Map<String, dynamic> _calculateMetricsSummary() {
    final summary = <String, dynamic>{};
    
    for (final entry in _performanceMetrics.entries) {
      final values = entry.value;
      if (values.isNotEmpty) {
        values.sort();
        
        final avg = values.reduce((a, b) => a + b) / values.length;
        final p50 = values[values.length ~/ 2];
        final p95 = values[(values.length * 0.95).floor()];
        final p99 = values[(values.length * 0.99).floor()];
        
        summary[entry.key] = {
          'count': values.length,
          'avg': avg.round(),
          'min': values.first.round(),
          'max': values.last.round(),
          'p50': p50.round(),
          'p95': p95.round(),
          'p99': p99.round(),
        };
      }
    }
    
    return summary;
  }
  
  /// Get memory usage information
  static Map<String, dynamic> _getMemoryUsage() {
    try {
      if (Platform.isAndroid || Platform.isIOS) {
        return {
          'platform': Platform.operatingSystem,
          'available_processors': Platform.numberOfProcessors,
          'locale': Platform.localeName,
        };
      }
    } catch (e) {
      print('$_logPrefix ⚠️ Could not get memory info: $e');
    }
    
    return {'platform': 'unknown'};
  }
  
  /// Collect device information
  static Future<void> _collectDeviceInfo() async {
    try {
      final deviceInfo = DeviceInfoPlugin();
      
      if (Platform.isAndroid) {
        final androidInfo = await deviceInfo.androidInfo;
        _deviceInfo = {
          'platform': 'android',
          'model': androidInfo.model,
          'manufacturer': androidInfo.manufacturer,
          'android_version': androidInfo.version.release,
          'sdk_int': androidInfo.version.sdkInt,
          'brand': androidInfo.brand,
          'physical_device': androidInfo.isPhysicalDevice,
        };
      } else if (Platform.isIOS) {
        final iosInfo = await deviceInfo.iosInfo;
        _deviceInfo = {
          'platform': 'ios',
          'model': iosInfo.model,
          'name': iosInfo.name,
          'system_name': iosInfo.systemName,
          'system_version': iosInfo.systemVersion,
          'physical_device': iosInfo.isPhysicalDevice,
        };
      } else {
        _deviceInfo = {
          'platform': Platform.operatingSystem,
          'version': Platform.operatingSystemVersion,
        };
      }
    } catch (e) {
      print('$_logPrefix ⚠️ Could not collect device info: $e');
      _deviceInfo = {'platform': 'unknown'};
    }
  }
  
  /// Start periodic performance reporting
  static void _startPeriodicReporting() {
    _reportTimer = Timer.periodic(const Duration(minutes: 5), (timer) {
      final report = getPerformanceReport();
      print('$_logPrefix 📊 Performance Report:');
      print('  • Cache hit rate: ${report['cache_stats']['hit_rate_percent']}%');
      print('  • Network requests: ${report['network_stats']['total_requests']}');
      print('  • Average network latency: ${report['network_stats']['average_latency_ms']}ms');
      
      final metrics = report['metrics'] as Map<String, dynamic>;
      for (final entry in metrics.entries.take(5)) {
        final stats = entry.value as Map<String, dynamic>;
        print('  • ${entry.key}: avg ${stats['avg']}ms (p95: ${stats['p95']}ms)');
      }
    });
  }
  
  /// Get top slow operations
  static List<Map<String, dynamic>> getSlowOperations({int limit = 10}) {
    final slowOps = <Map<String, dynamic>>[];
    
    for (final entry in _performanceMetrics.entries) {
      final values = entry.value;
      if (values.isNotEmpty) {
        final avg = values.reduce((a, b) => a + b) / values.length;
        if (avg > 500) { // Operations slower than 500ms
          slowOps.add({
            'operation': entry.key,
            'avg_time_ms': avg.round(),
            'max_time_ms': values.reduce((a, b) => a > b ? a : b).round(),
            'count': values.length,
          });
        }
      }
    }
    
    slowOps.sort((a, b) => b['avg_time_ms'].compareTo(a['avg_time_ms']));
    return slowOps.take(limit).toList();
  }
  
  /// Export performance data for analysis
  static Future<String?> exportPerformanceData() async {
    try {
      final report = getPerformanceReport();
      final jsonData = jsonEncode(report);
      
      // In a real app, you might save this to a file or send to analytics
      print('$_logPrefix 📤 Performance data exported (${jsonData.length} characters)');
      return jsonData;
      
    } catch (e) {
      print('$_logPrefix ❌ Failed to export performance data: $e');
      return null;
    }
  }
  
  /// Reset all performance data
  static void reset() {
    _performanceMetrics.clear();
    _performanceEvents.clear();
    _featureTimers.clear();
    _appStartupTimer.reset();
    
    print('$_logPrefix 🔄 Performance data reset');
  }
  
  /// Dispose performance monitoring
  static void dispose() {
    _reportTimer?.cancel();
    _featureTimers.values.forEach((timer) => timer.stop());
    _featureTimers.clear();
    _isMonitoring = false;
    
    print('$_logPrefix 🛑 Performance monitoring disposed');
  }
}

/// Performance event data structure
class _PerformanceEvent {
  final String name;
  final DateTime timestamp;
  final Map<String, dynamic> data;
  
  _PerformanceEvent({
    required this.name,
    required this.timestamp,
    required this.data,
  });
  
  Map<String, dynamic> toJson() => {
    'name': name,
    'timestamp': timestamp.toIso8601String(),
    'data': data,
  };
}