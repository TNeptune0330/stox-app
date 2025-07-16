import 'dart:async';
import 'dart:io';

class ConnectionManager {
  static final ConnectionManager _instance = ConnectionManager._internal();
  factory ConnectionManager() => _instance;
  ConnectionManager._internal();

  bool _isOnline = true;
  DateTime? _lastFailureTime;
  int _consecutiveFailures = 0;
  static const int _maxConsecutiveFailures = 3;
  static const Duration _backoffDuration = Duration(minutes: 5);

  bool get isOnline => _isOnline;
  bool get shouldRetry {
    if (_lastFailureTime == null) return true;
    if (_consecutiveFailures < _maxConsecutiveFailures) return true;
    
    final timeSinceFailure = DateTime.now().difference(_lastFailureTime!);
    return timeSinceFailure > _backoffDuration;
  }

  void recordSuccess() {
    _isOnline = true;
    _consecutiveFailures = 0;
    _lastFailureTime = null;
  }

  void recordFailure() {
    _isOnline = false;
    _consecutiveFailures++;
    _lastFailureTime = DateTime.now();
    
    print('🔌 Connection failure #$_consecutiveFailures. Next retry: ${_getNextRetryTime()}');
  }

  DateTime? _getNextRetryTime() {
    if (_lastFailureTime == null) return null;
    return _lastFailureTime!.add(_backoffDuration);
  }

  Future<T?> executeWithFallback<T>(
    Future<T> Function() networkCall,
    Future<T> Function() fallbackCall,
  ) async {
    if (!shouldRetry) {
      print('⚠️ Skipping network call due to connection backoff');
      return await fallbackCall();
    }

    try {
      final result = await networkCall();
      recordSuccess();
      return result;
    } catch (e) {
      recordFailure();
      print('⚠️ Network call failed, using fallback: $e');
      return await fallbackCall();
    }
  }

  Future<bool> checkConnection() async {
    try {
      final result = await InternetAddress.lookup('google.com');
      if (result.isNotEmpty && result[0].rawAddress.isNotEmpty) {
        recordSuccess();
        return true;
      }
    } catch (e) {
      recordFailure();
    }
    return false;
  }
}