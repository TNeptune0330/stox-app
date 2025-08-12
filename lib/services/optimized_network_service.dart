import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:connectivity_plus/connectivity_plus.dart';
import 'optimized_cache_service.dart';

/// High-performance network service with intelligent request management
class OptimizedNetworkService {
  static const String _logPrefix = '[OptimizedNetwork]';
  
  // HTTP client with optimized settings
  static late http.Client _client;
  static bool _isInitialized = false;
  
  // Request queue and rate limiting
  static final Map<String, Timer> _rateLimitTimers = {};
  static final Map<String, List<_QueuedRequest>> _requestQueues = {};
  
  // Request deduplication
  static final Map<String, Future<http.Response>> _pendingRequests = {};
  
  // Connection monitoring
  static ConnectivityResult _lastConnectivity = ConnectivityResult.none;
  static StreamSubscription? _connectivitySubscription;
  
  // Performance metrics
  static int _totalRequests = 0;
  static int _cachedResponses = 0;
  static int _failedRequests = 0;
  static final Map<String, int> _requestLatencies = {};
  
  /// Initialize the network service
  static Future<void> initialize() async {
    if (_isInitialized) return;
    
    print('$_logPrefix 🚀 Initializing optimized network service...');
    
    // Create HTTP client with optimized settings
    _client = http.Client();
    
    // Check initial connectivity
    final connectivityResults = await Connectivity().checkConnectivity();
    _lastConnectivity = connectivityResults.isNotEmpty ? connectivityResults.first : ConnectivityResult.none;
    
    // Listen for connectivity changes
    _connectivitySubscription = Connectivity().onConnectivityChanged.listen((results) {
      _onConnectivityChanged(results.isNotEmpty ? results.first : ConnectivityResult.none);
    });
    
    _isInitialized = true;
    print('$_logPrefix ✅ Network service initialized (connectivity: $_lastConnectivity)');
  }
  
  /// Handle connectivity changes
  static void _onConnectivityChanged(ConnectivityResult result) {
    if (_lastConnectivity != result) {
      _lastConnectivity = result;
      print('$_logPrefix 📶 Connectivity changed to: $result');
      
      // Process queued requests if connectivity restored
      if (result != ConnectivityResult.none) {
        _processQueuedRequests();
      }
    }
  }
  
  /// Optimized GET request with caching and deduplication
  static Future<Map<String, dynamic>?> get(
    String url, {
    Map<String, String>? headers,
    Duration timeout = const Duration(seconds: 10),
    String cacheCategory = 'network_data',
    bool useCache = true,
    String? rateLimitKey,
    Duration rateLimitDuration = const Duration(milliseconds: 1000),
  }) async {
    return await _executeRequest(
      'GET',
      url,
      headers: headers,
      timeout: timeout,
      cacheCategory: cacheCategory,
      useCache: useCache,
      rateLimitKey: rateLimitKey,
      rateLimitDuration: rateLimitDuration,
    );
  }
  
  /// Optimized POST request
  static Future<Map<String, dynamic>?> post(
    String url, {
    Map<String, String>? headers,
    Object? body,
    Duration timeout = const Duration(seconds: 15),
    String? rateLimitKey,
    Duration rateLimitDuration = const Duration(milliseconds: 1000),
  }) async {
    return await _executeRequest(
      'POST',
      url,
      headers: headers,
      body: body,
      timeout: timeout,
      useCache: false, // Don't cache POST requests
      rateLimitKey: rateLimitKey,
      rateLimitDuration: rateLimitDuration,
    );
  }
  
  /// Execute HTTP request with all optimizations
  static Future<Map<String, dynamic>?> _executeRequest(
    String method,
    String url, {
    Map<String, String>? headers,
    Object? body,
    Duration timeout = const Duration(seconds: 10),
    String cacheCategory = 'network_data',
    bool useCache = true,
    String? rateLimitKey,
    Duration rateLimitDuration = const Duration(milliseconds: 1000),
  }) async {
    final stopwatch = Stopwatch()..start();
    
    try {
      await initialize();
      
      // Check connectivity
      if (_lastConnectivity == ConnectivityResult.none) {
        print('$_logPrefix ⚠️ No connectivity - checking cache for: $url');
        if (useCache && method == 'GET') {
          final cached = await OptimizedCacheService.get<Map<String, dynamic>>(
            _getCacheKey(url),
            category: cacheCategory,
          );
          if (cached != null) {
            _cachedResponses++;
            return cached;
          }
        }
        throw const SocketException('No internet connection');
      }
      
      // Check cache first for GET requests
      if (useCache && method == 'GET') {
        final cached = await OptimizedCacheService.get<Map<String, dynamic>>(
          _getCacheKey(url),
          category: cacheCategory,
        );
        if (cached != null) {
          _cachedResponses++;
          print('$_logPrefix 💾 Cache hit: $url');
          return cached;
        }
      }
      
      // Apply rate limiting
      if (rateLimitKey != null) {
        await _applyRateLimit(rateLimitKey, rateLimitDuration);
      }
      
      // Check for duplicate requests
      final requestKey = '$method:$url:${body?.hashCode ?? ''}';
      if (_pendingRequests.containsKey(requestKey)) {
        print('$_logPrefix 🔄 Deduplicating request: $url');
        final response = await _pendingRequests[requestKey]!;
        return _parseResponse(response);
      }
      
      // Create and execute request
      final future = _makeHttpRequest(method, url, headers: headers, body: body, timeout: timeout);
      _pendingRequests[requestKey] = future;
      
      try {
        final response = await future;
        final data = _parseResponse(response);
        
        // Cache successful GET responses
        if (useCache && method == 'GET' && data != null) {
          await OptimizedCacheService.set(
            _getCacheKey(url),
            data,
            category: cacheCategory,
          );
        }
        
        _totalRequests++;
        stopwatch.stop();
        _requestLatencies[url] = stopwatch.elapsedMilliseconds;
        
        print('$_logPrefix ✅ Request completed: $url (${stopwatch.elapsedMilliseconds}ms)');
        return data;
        
      } finally {
        _pendingRequests.remove(requestKey);
      }
      
    } catch (e) {
      _failedRequests++;
      stopwatch.stop();
      
      print('$_logPrefix ❌ Request failed: $url - $e (${stopwatch.elapsedMilliseconds}ms)');
      
      // Try to return cached data as fallback for GET requests
      if (useCache && method == 'GET') {
        final cached = await OptimizedCacheService.get<Map<String, dynamic>>(
          _getCacheKey(url),
          category: cacheCategory,
        );
        if (cached != null) {
          print('$_logPrefix 🆘 Using stale cache as fallback: $url');
          return cached;
        }
      }
      
      // Queue request for retry if no connectivity
      if (e is SocketException && _lastConnectivity == ConnectivityResult.none) {
        _queueRequest(method, url, headers: headers, body: body, timeout: timeout);
      }
      
      rethrow;
    }
  }
  
  /// Make HTTP request based on method
  static Future<http.Response> _makeHttpRequest(
    String method,
    String url, {
    Map<String, String>? headers,
    Object? body,
    Duration timeout = const Duration(seconds: 10),
  }) async {
    final uri = Uri.parse(url);
    final defaultHeaders = {
      'Content-Type': 'application/json',
      'User-Agent': 'StoxApp/1.0',
      ...?headers,
    };
    
    switch (method.toUpperCase()) {
      case 'GET':
        return await _client.get(uri, headers: defaultHeaders).timeout(timeout);
      case 'POST':
        return await _client.post(
          uri,
          headers: defaultHeaders,
          body: body is String ? body : jsonEncode(body),
        ).timeout(timeout);
      case 'PUT':
        return await _client.put(
          uri,
          headers: defaultHeaders,
          body: body is String ? body : jsonEncode(body),
        ).timeout(timeout);
      case 'DELETE':
        return await _client.delete(uri, headers: defaultHeaders).timeout(timeout);
      default:
        throw ArgumentError('Unsupported HTTP method: $method');
    }
  }
  
  /// Parse HTTP response
  static Map<String, dynamic>? _parseResponse(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (response.body.isNotEmpty) {
        try {
          return jsonDecode(response.body) as Map<String, dynamic>;
        } catch (e) {
          print('$_logPrefix ⚠️ Failed to parse JSON response: $e');
          return {'raw_response': response.body};
        }
      }
      return {};
    } else {
      throw HttpException(
        'HTTP ${response.statusCode}: ${response.reasonPhrase}',
        uri: response.request?.url,
      );
    }
  }
  
  /// Apply rate limiting
  static Future<void> _applyRateLimit(String key, Duration duration) async {
    final timer = _rateLimitTimers[key];
    if (timer != null && timer.isActive) {
      final remainingTime = duration.inMilliseconds - 
          (DateTime.now().millisecondsSinceEpoch - 
           (timer.tick * duration.inMilliseconds));
      
      if (remainingTime > 0) {
        print('$_logPrefix ⏳ Rate limiting: waiting ${remainingTime}ms for $key');
        await Future.delayed(Duration(milliseconds: remainingTime));
      }
    }
    
    _rateLimitTimers[key] = Timer(duration, () {
      _rateLimitTimers.remove(key);
    });
  }
  
  /// Queue request for retry when connectivity is restored
  static void _queueRequest(
    String method,
    String url, {
    Map<String, String>? headers,
    Object? body,
    Duration timeout = const Duration(seconds: 10),
  }) {
    final queueKey = method.toLowerCase();
    _requestQueues[queueKey] ??= [];
    _requestQueues[queueKey]!.add(_QueuedRequest(
      method: method,
      url: url,
      headers: headers,
      body: body,
      timeout: timeout,
      timestamp: DateTime.now(),
    ));
    
    print('$_logPrefix 📋 Queued request: $method $url');
  }
  
  /// Process queued requests when connectivity is restored
  static Future<void> _processQueuedRequests() async {
    print('$_logPrefix 🔄 Processing queued requests...');
    
    int processedCount = 0;
    for (final entry in _requestQueues.entries) {
      final queue = entry.value;
      
      // Process requests in order, with delays
      for (final request in List.from(queue)) {
        try {
          await _executeRequest(
            request.method,
            request.url,
            headers: request.headers,
            body: request.body,
            timeout: request.timeout,
          );
          
          queue.remove(request);
          processedCount++;
          
          // Small delay between requests
          await Future.delayed(const Duration(milliseconds: 200));
          
        } catch (e) {
          print('$_logPrefix ❌ Failed to process queued request: ${request.url} - $e');
        }
      }
    }
    
    print('$_logPrefix ✅ Processed $processedCount queued requests');
  }
  
  /// Generate cache key for URL
  static String _getCacheKey(String url) {
    return 'network_${url.hashCode.abs()}';
  }
  
  /// Get network performance statistics
  static Map<String, dynamic> getPerformanceStats() {
    final totalResponseTime = _requestLatencies.values.isEmpty 
        ? 0 
        : _requestLatencies.values.reduce((a, b) => a + b);
    
    final avgLatency = _requestLatencies.isEmpty 
        ? 0.0 
        : totalResponseTime / _requestLatencies.length;
    
    final cacheHitRate = _totalRequests > 0 
        ? (_cachedResponses / _totalRequests * 100).toStringAsFixed(1)
        : '0.0';
    
    return {
      'total_requests': _totalRequests,
      'cached_responses': _cachedResponses,
      'failed_requests': _failedRequests,
      'cache_hit_rate_percent': cacheHitRate,
      'average_latency_ms': avgLatency.round(),
      'connectivity': _lastConnectivity.toString(),
      'queued_requests': _requestQueues.values.fold(0, (sum, queue) => sum + queue.length),
    };
  }
  
  /// Clear all caches and reset statistics
  static Future<void> reset() async {
    await OptimizedCacheService.clearAll();
    _pendingRequests.clear();
    _requestQueues.clear();
    _rateLimitTimers.values.forEach((timer) => timer.cancel());
    _rateLimitTimers.clear();
    
    _totalRequests = 0;
    _cachedResponses = 0;
    _failedRequests = 0;
    _requestLatencies.clear();
    
    print('$_logPrefix 🔄 Network service reset');
  }
  
  /// Dispose network service
  static void dispose() {
    _connectivitySubscription?.cancel();
    _client.close();
    _rateLimitTimers.values.forEach((timer) => timer.cancel());
    _rateLimitTimers.clear();
    _pendingRequests.clear();
    _requestQueues.clear();
    _isInitialized = false;
    
    print('$_logPrefix 🛑 Network service disposed');
  }
}

/// Queued request data structure
class _QueuedRequest {
  final String method;
  final String url;
  final Map<String, String>? headers;
  final Object? body;
  final Duration timeout;
  final DateTime timestamp;
  
  _QueuedRequest({
    required this.method,
    required this.url,
    this.headers,
    this.body,
    required this.timeout,
    required this.timestamp,
  });
}