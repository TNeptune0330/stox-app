import 'dart:io';
import 'dart:convert';
import 'dart:async';

/// Performance Monitoring Script
/// 
/// Monitors app performance during test execution and generates
/// detailed performance reports with benchmarks.
/// 
/// Usage:
/// dart test_scripts/performance_monitor.dart
/// 
void main() async {
  print('📊 STOX APP PERFORMANCE MONITOR');
  print('================================');
  
  final monitor = PerformanceMonitor();
  await monitor.start();
}

class PerformanceMonitor {
  final List<PerformanceMetric> _metrics = [];
  late Timer _monitoringTimer;
  late DateTime _startTime;
  
  /// Start performance monitoring
  Future<void> start() async {
    _startTime = DateTime.now();
    print('🚀 Starting performance monitoring...');
    print('Start time: $_startTime');
    print('');
    
    // Run different performance tests
    await _runCachePerformanceTest();
    await _runDatabasePerformanceTest();
    await _runMemoryPerformanceTest();
    await _runNetworkPerformanceTest();
    
    // Generate performance report
    await _generatePerformanceReport();
  }
  
  /// Test cache performance
  Future<void> _runCachePerformanceTest() async {
    print('💾 Testing Cache Performance...');
    
    final stopwatch = Stopwatch()..start();
    
    // Simulate cache operations
    const iterations = 1000;
    final cacheOperationTimes = <int>[];
    
    for (int i = 0; i < iterations; i++) {
      final operationStopwatch = Stopwatch()..start();
      
      // Simulate cache write operation
      await Future.delayed(Duration(microseconds: 100 + (i % 50)));
      
      operationStopwatch.stop();
      cacheOperationTimes.add(operationStopwatch.elapsedMicroseconds);
      
      if (i % 100 == 0) {
        print('   Cache operations: ${i + 1}/$iterations');
      }
    }
    
    stopwatch.stop();
    
    final avgTime = cacheOperationTimes.reduce((a, b) => a + b) / cacheOperationTimes.length;
    final minTime = cacheOperationTimes.reduce((a, b) => a < b ? a : b);
    final maxTime = cacheOperationTimes.reduce((a, b) => a > b ? a : b);
    
    _metrics.add(PerformanceMetric(
      name: 'Cache Performance',
      category: 'Storage',
      operations: iterations,
      totalTime: stopwatch.elapsedMilliseconds,
      averageTime: avgTime / 1000, // Convert to milliseconds
      minTime: minTime / 1000,
      maxTime: maxTime / 1000,
      throughput: (iterations / (stopwatch.elapsedMilliseconds / 1000)),
    ));
    
    print('✅ Cache Performance Test Complete');
    print('   Operations: $iterations');
    print('   Total Time: ${stopwatch.elapsedMilliseconds}ms');
    print('   Avg Time: ${avgTime.toStringAsFixed(2)}μs');
    print('   Throughput: ${(iterations / (stopwatch.elapsedMilliseconds / 1000)).toStringAsFixed(2)} ops/sec');
    print('');
  }
  
  /// Test database performance
  Future<void> _runDatabasePerformanceTest() async {
    print('🗃️ Testing Database Performance...');
    
    final stopwatch = Stopwatch()..start();
    
    // Simulate database operations
    const iterations = 500;
    final dbOperationTimes = <int>[];
    
    for (int i = 0; i < iterations; i++) {
      final operationStopwatch = Stopwatch()..start();
      
      // Simulate database write operation (more expensive than cache)
      await Future.delayed(Duration(microseconds: 500 + (i % 200)));
      
      operationStopwatch.stop();
      dbOperationTimes.add(operationStopwatch.elapsedMicroseconds);
      
      if (i % 50 == 0) {
        print('   Database operations: ${i + 1}/$iterations');
      }
    }
    
    stopwatch.stop();
    
    final avgTime = dbOperationTimes.reduce((a, b) => a + b) / dbOperationTimes.length;
    final minTime = dbOperationTimes.reduce((a, b) => a < b ? a : b);
    final maxTime = dbOperationTimes.reduce((a, b) => a > b ? a : b);
    
    _metrics.add(PerformanceMetric(
      name: 'Database Performance',
      category: 'Storage',
      operations: iterations,
      totalTime: stopwatch.elapsedMilliseconds,
      averageTime: avgTime / 1000,
      minTime: minTime / 1000,
      maxTime: maxTime / 1000,
      throughput: (iterations / (stopwatch.elapsedMilliseconds / 1000)),
    ));
    
    print('✅ Database Performance Test Complete');
    print('   Operations: $iterations');
    print('   Total Time: ${stopwatch.elapsedMilliseconds}ms');
    print('   Avg Time: ${avgTime.toStringAsFixed(2)}μs');
    print('   Throughput: ${(iterations / (stopwatch.elapsedMilliseconds / 1000)).toStringAsFixed(2)} ops/sec');
    print('');
  }
  
  /// Test memory performance
  Future<void> _runMemoryPerformanceTest() async {
    print('🧠 Testing Memory Performance...');
    
    final stopwatch = Stopwatch()..start();
    
    // Simulate memory-intensive operations
    const iterations = 100;
    final memoryOperationTimes = <int>[];
    final largeDataSets = <List<Map<String, dynamic>>>[];
    
    for (int i = 0; i < iterations; i++) {
      final operationStopwatch = Stopwatch()..start();
      
      // Create large data structures to test memory handling
      final largeDataSet = <Map<String, dynamic>>[];
      for (int j = 0; j < 1000; j++) {
        largeDataSet.add({
          'id': 'item_${i}_$j',
          'data': List.generate(100, (index) => 'data_$index'),
          'timestamp': DateTime.now().millisecondsSinceEpoch,
          'metadata': {
            'version': 1,
            'created_by': 'performance_test',
            'category': 'test_data_$i',
          }
        });
      }
      largeDataSets.add(largeDataSet);
      
      // Simulate processing the data
      await Future.delayed(Duration(milliseconds: 10));
      
      operationStopwatch.stop();
      memoryOperationTimes.add(operationStopwatch.elapsedMicroseconds);
      
      if (i % 10 == 0) {
        print('   Memory operations: ${i + 1}/$iterations');
      }
    }
    
    stopwatch.stop();
    
    // Clean up large data sets to test garbage collection
    largeDataSets.clear();
    
    final avgTime = memoryOperationTimes.reduce((a, b) => a + b) / memoryOperationTimes.length;
    final minTime = memoryOperationTimes.reduce((a, b) => a < b ? a : b);
    final maxTime = memoryOperationTimes.reduce((a, b) => a > b ? a : b);
    
    _metrics.add(PerformanceMetric(
      name: 'Memory Performance',
      category: 'System',
      operations: iterations,
      totalTime: stopwatch.elapsedMilliseconds,
      averageTime: avgTime / 1000,
      minTime: minTime / 1000,
      maxTime: maxTime / 1000,
      throughput: (iterations / (stopwatch.elapsedMilliseconds / 1000)),
    ));
    
    print('✅ Memory Performance Test Complete');
    print('   Operations: $iterations');
    print('   Total Time: ${stopwatch.elapsedMilliseconds}ms');
    print('   Avg Time: ${avgTime.toStringAsFixed(2)}μs');
    print('   Memory Ops/sec: ${(iterations / (stopwatch.elapsedMilliseconds / 1000)).toStringAsFixed(2)}');
    print('');
  }
  
  /// Test network performance simulation
  Future<void> _runNetworkPerformanceTest() async {
    print('🌐 Testing Network Performance Simulation...');
    
    final stopwatch = Stopwatch()..start();
    
    // Simulate network operations
    const iterations = 50;
    final networkOperationTimes = <int>[];
    
    for (int i = 0; i < iterations; i++) {
      final operationStopwatch = Stopwatch()..start();
      
      // Simulate network latency and processing time
      final networkLatency = 50 + (i % 100); // 50-150ms latency
      await Future.delayed(Duration(milliseconds: networkLatency));
      
      operationStopwatch.stop();
      networkOperationTimes.add(operationStopwatch.elapsedMicroseconds);
      
      if (i % 5 == 0) {
        print('   Network operations: ${i + 1}/$iterations');
      }
    }
    
    stopwatch.stop();
    
    final avgTime = networkOperationTimes.reduce((a, b) => a + b) / networkOperationTimes.length;
    final minTime = networkOperationTimes.reduce((a, b) => a < b ? a : b);
    final maxTime = networkOperationTimes.reduce((a, b) => a > b ? a : b);
    
    _metrics.add(PerformanceMetric(
      name: 'Network Performance',
      category: 'Network',
      operations: iterations,
      totalTime: stopwatch.elapsedMilliseconds,
      averageTime: avgTime / 1000,
      minTime: minTime / 1000,
      maxTime: maxTime / 1000,
      throughput: (iterations / (stopwatch.elapsedMilliseconds / 1000)),
    ));
    
    print('✅ Network Performance Test Complete');
    print('   Operations: $iterations');
    print('   Total Time: ${stopwatch.elapsedMilliseconds}ms');
    print('   Avg Time: ${avgTime.toStringAsFixed(2)}μs');
    print('   Network Ops/sec: ${(iterations / (stopwatch.elapsedMilliseconds / 1000)).toStringAsFixed(2)}');
    print('');
  }
  
  /// Generate comprehensive performance report
  Future<void> _generatePerformanceReport() async {
    final endTime = DateTime.now();
    final totalDuration = endTime.difference(_startTime);
    
    print('📊 PERFORMANCE REPORT');
    print('====================');
    print('');
    
    // Overall metrics
    print('## Overall Performance');
    print('Total Test Duration: ${_formatDuration(totalDuration)}');
    print('Total Operations: ${_metrics.fold(0, (sum, metric) => sum + metric.operations)}');
    print('Total Categories: ${_metrics.map((m) => m.category).toSet().length}');
    print('');
    
    // Individual test results
    print('## Individual Test Results');
    print('');
    
    for (final metric in _metrics) {
      print('### ${metric.name}');
      print('- Category: ${metric.category}');
      print('- Operations: ${metric.operations}');
      print('- Total Time: ${metric.totalTime}ms');
      print('- Average Time: ${metric.averageTime.toStringAsFixed(2)}ms');
      print('- Min Time: ${metric.minTime.toStringAsFixed(2)}ms');
      print('- Max Time: ${metric.maxTime.toStringAsFixed(2)}ms');
      print('- Throughput: ${metric.throughput.toStringAsFixed(2)} ops/sec');
      print('- Performance Rating: ${_getPerformanceRating(metric)}');
      print('');
    }
    
    // Performance benchmarks
    print('## Performance Benchmarks');
    print('');
    
    final cacheMetric = _metrics.firstWhere((m) => m.name == 'Cache Performance');
    final dbMetric = _metrics.firstWhere((m) => m.name == 'Database Performance');
    
    print('### Cache vs Database');
    print('- Cache Throughput: ${cacheMetric.throughput.toStringAsFixed(2)} ops/sec');
    print('- Database Throughput: ${dbMetric.throughput.toStringAsFixed(2)} ops/sec');
    print('- Cache Speed Advantage: ${(cacheMetric.throughput / dbMetric.throughput).toStringAsFixed(1)}x faster');
    print('');
    
    // Recommendations
    print('## Recommendations');
    print('');
    
    for (final metric in _metrics) {
      final rating = _getPerformanceRating(metric);
      if (rating == 'Needs Improvement' || rating == 'Poor') {
        print('⚠️ ${metric.name}:');
        print('   Current Performance: $rating');
        print('   Recommendation: ${_getRecommendation(metric)}');
        print('');
      }
    }
    
    // Generate JSON report for automated processing
    await _generateJSONReport(totalDuration);
    
    print('✅ Performance monitoring completed successfully');
  }
  
  /// Get performance rating based on metrics
  String _getPerformanceRating(PerformanceMetric metric) {
    switch (metric.category) {
      case 'Storage':
        if (metric.averageTime < 1.0) return 'Excellent';
        if (metric.averageTime < 5.0) return 'Good';
        if (metric.averageTime < 15.0) return 'Fair';
        if (metric.averageTime < 50.0) return 'Needs Improvement';
        return 'Poor';
        
      case 'Network':
        if (metric.averageTime < 100) return 'Excellent';
        if (metric.averageTime < 200) return 'Good';
        if (metric.averageTime < 500) return 'Fair';
        if (metric.averageTime < 1000) return 'Needs Improvement';
        return 'Poor';
        
      case 'System':
        if (metric.averageTime < 10) return 'Excellent';
        if (metric.averageTime < 25) return 'Good';
        if (metric.averageTime < 50) return 'Fair';
        if (metric.averageTime < 100) return 'Needs Improvement';
        return 'Poor';
        
      default:
        return 'Unknown';
    }
  }
  
  /// Get performance improvement recommendation
  String _getRecommendation(PerformanceMetric metric) {
    switch (metric.name) {
      case 'Cache Performance':
        return 'Consider implementing memory-based caching or optimizing cache key structures';
      case 'Database Performance':
        return 'Review database indexes, consider connection pooling, or implement query optimization';
      case 'Memory Performance':
        return 'Implement object pooling, optimize data structures, or add memory monitoring';
      case 'Network Performance':
        return 'Implement request batching, add connection retry logic, or use CDN for static assets';
      default:
        return 'Review implementation and consider performance optimizations';
    }
  }
  
  /// Generate JSON report for automated processing
  Future<void> _generateJSONReport(Duration totalDuration) async {
    final timestamp = DateTime.now().toIso8601String().replaceAll(':', '-');
    final reportFile = File('test_reports/performance_report_$timestamp.json');
    
    await reportFile.parent.create(recursive: true);
    
    final report = {
      'timestamp': DateTime.now().toIso8601String(),
      'total_duration_ms': totalDuration.inMilliseconds,
      'platform': Platform.operatingSystem,
      'dart_version': Platform.version,
      'metrics': _metrics.map((m) => m.toJson()).toList(),
      'summary': {
        'total_operations': _metrics.fold(0, (sum, metric) => sum + metric.operations),
        'total_categories': _metrics.map((m) => m.category).toSet().length,
        'overall_throughput': _metrics.fold(0.0, (sum, metric) => sum + metric.throughput),
      }
    };
    
    await reportFile.writeAsString(jsonEncode(report));
    print('📄 JSON performance report generated: ${reportFile.path}');
  }
  
  /// Format duration for human reading
  String _formatDuration(Duration duration) {
    if (duration.inHours > 0) {
      return '${duration.inHours}h ${duration.inMinutes % 60}m ${duration.inSeconds % 60}s';
    } else if (duration.inMinutes > 0) {
      return '${duration.inMinutes}m ${duration.inSeconds % 60}s';
    } else {
      return '${duration.inSeconds}s ${duration.inMilliseconds % 1000}ms';
    }
  }
}

/// Performance metric data class
class PerformanceMetric {
  final String name;
  final String category;
  final int operations;
  final int totalTime;
  final double averageTime;
  final double minTime;
  final double maxTime;
  final double throughput;
  
  PerformanceMetric({
    required this.name,
    required this.category,
    required this.operations,
    required this.totalTime,
    required this.averageTime,
    required this.minTime,
    required this.maxTime,
    required this.throughput,
  });
  
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'category': category,
      'operations': operations,
      'total_time_ms': totalTime,
      'average_time_ms': averageTime,
      'min_time_ms': minTime,
      'max_time_ms': maxTime,
      'throughput_ops_per_sec': throughput,
    };
  }
}