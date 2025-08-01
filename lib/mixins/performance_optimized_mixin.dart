import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

/// Mixin that provides performance optimizations for widgets
mixin PerformanceOptimizedMixin<T extends StatefulWidget> on State<T> {
  
  /// Debounced notifier for expensive operations
  Timer? _debounceTimer;
  
  /// Track if widget is mounted to prevent setState on disposed widgets
  bool get isMounted => mounted;
  
  /// Debounced setState with automatic mounting check
  void debouncedSetState(VoidCallback callback, {Duration delay = const Duration(milliseconds: 300)}) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(delay, () {
      if (isMounted) {
        setState(callback);
      }
    });
  }
  
  /// Safe setState that checks if widget is mounted
  void safeSetState(VoidCallback callback) {
    if (isMounted) {
      setState(callback);
    }
  }
  
  /// Throttled function execution to prevent excessive calls
  final Map<String, Timer> _throttleTimers = {};
  
  void throttle(String key, VoidCallback callback, {Duration duration = const Duration(milliseconds: 500)}) {
    if (_throttleTimers[key]?.isActive ?? false) {
      return; // Skip if already running
    }
    
    callback();
    _throttleTimers[key] = Timer(duration, () {
      _throttleTimers.remove(key);
    });
  }
  
  /// Batch state updates to reduce rebuild frequency
  final List<VoidCallback> _batchedUpdates = [];
  Timer? _batchTimer;
  
  void batchStateUpdate(VoidCallback update) {
    _batchedUpdates.add(update);
    
    _batchTimer?.cancel();
    _batchTimer = Timer(const Duration(milliseconds: 16), () { // ~60fps
      if (isMounted && _batchedUpdates.isNotEmpty) {
        setState(() {
          for (final update in _batchedUpdates) {
            update();
          }
          _batchedUpdates.clear();
        });
      }
    });
  }
  
  /// Memory-efficient list building for large datasets
  Widget buildOptimizedList<E>({
    required List<E> items,
    required Widget Function(BuildContext context, E item, int index) itemBuilder,
    IndexedWidgetBuilder? separatorBuilder,
    ScrollController? controller,
    bool shrinkWrap = false,
    ScrollPhysics? physics,
    EdgeInsetsGeometry? padding,
  }) {
    if (items.isEmpty) {
      return const SizedBox.shrink();
    }
    
    // Use ListView.separated for better performance with large lists
    if (separatorBuilder != null) {
      return ListView.separated(
        controller: controller,
        shrinkWrap: shrinkWrap,
        physics: physics,
        padding: padding,
        itemCount: items.length,
        itemBuilder: (context, index) => itemBuilder(context, items[index], index),
        separatorBuilder: separatorBuilder,
      );
    }
    
    // Use ListView.builder for optimal performance
    return ListView.builder(
      controller: controller,
      shrinkWrap: shrinkWrap,
      physics: physics,
      padding: padding,
      itemCount: items.length,
      itemBuilder: (context, index) => itemBuilder(context, items[index], index),
    );
  }
  
  /// Create memoized widgets to prevent unnecessary rebuilds
  final Map<String, Widget> _memoizedWidgets = {};
  
  Widget memoize(String key, Widget Function() builder) {
    return _memoizedWidgets[key] ??= builder();
  }
  
  /// Clear memoized widgets (call when data changes)
  void clearMemoization([String? key]) {
    if (key != null) {
      _memoizedWidgets.remove(key);
    } else {
      _memoizedWidgets.clear();
    }
  }
  
  /// Preload widget for smoother transitions
  void preloadWidget(String key, Widget Function() builder) {
    if (!_memoizedWidgets.containsKey(key)) {
      _memoizedWidgets[key] = builder();
    }
  }
  
  /// Optimized future builder that handles loading and error states
  Widget buildOptimizedFuture<E>({
    required Future<E> future,
    required Widget Function(BuildContext context, E data) builder,
    Widget? loadingWidget,
    Widget Function(BuildContext context, Object error)? errorBuilder,
    E? initialData,
  }) {
    return FutureBuilder<E>(
      future: future,
      initialData: initialData,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return errorBuilder?.call(context, snapshot.error!) ?? 
                 Center(child: Text('Error: ${snapshot.error}'));
        }
        
        if (snapshot.connectionState == ConnectionState.waiting) {
          return loadingWidget ?? const Center(child: CircularProgressIndicator());
        }
        
        if (snapshot.hasData) {
          return builder(context, snapshot.data!);
        }
        
        return const SizedBox.shrink();
      },
    );
  }
  
  /// Optimized stream builder
  Widget buildOptimizedStream<E>({
    required Stream<E> stream,
    required Widget Function(BuildContext context, E data) builder,
    Widget? loadingWidget,
    Widget Function(BuildContext context, Object error)? errorBuilder,
    E? initialData,
  }) {
    return StreamBuilder<E>(
      stream: stream,
      initialData: initialData,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return errorBuilder?.call(context, snapshot.error!) ?? 
                 Center(child: Text('Error: ${snapshot.error}'));
        }
        
        if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
          return loadingWidget ?? const Center(child: CircularProgressIndicator());
        }
        
        if (snapshot.hasData) {
          return builder(context, snapshot.data!);
        }
        
        return const SizedBox.shrink();
      },
    );
  }
  
  /// Performance-optimized animation controller management
  final Map<String, AnimationController> _animationControllers = {};
  
  AnimationController getAnimationController(
    String key, {
    required Duration duration,
    Duration? reverseDuration,
    String? debugLabel,
    double lowerBound = 0.0,
    double upperBound = 1.0,
    AnimationBehavior animationBehavior = AnimationBehavior.normal,
  }) {
    return _animationControllers[key] ??= AnimationController(
      duration: duration,
      reverseDuration: reverseDuration,
      debugLabel: debugLabel,
      lowerBound: lowerBound,
      upperBound: upperBound,
      animationBehavior: animationBehavior,
      vsync: this as TickerProvider,
    );
  }
  
  /// Dispose animation controllers
  void disposeAnimationController(String key) {
    _animationControllers[key]?.dispose();
    _animationControllers.remove(key);
  }
  
  @override
  void dispose() {
    // Clean up timers
    _debounceTimer?.cancel();
    _batchTimer?.cancel();
    for (final timer in _throttleTimers.values) {
      timer.cancel();
    }
    _throttleTimers.clear();
    
    // Clean up animation controllers
    for (final controller in _animationControllers.values) {
      controller.dispose();
    }
    _animationControllers.clear();
    
    // Clear memoized widgets
    _memoizedWidgets.clear();
    
    super.dispose();
  }
}

/// Optimized consumer widget for Provider pattern
class OptimizedConsumer<T extends ChangeNotifier> extends StatefulWidget {
  final Widget Function(BuildContext context, T value, Widget? child) builder;
  final Widget? child;
  final bool Function(T previous, T current)? listenWhen;
  
  const OptimizedConsumer({
    super.key,
    required this.builder,
    this.child,
    this.listenWhen,
  });
  
  @override
  State<OptimizedConsumer<T>> createState() => _OptimizedConsumerState<T>();
}

class _OptimizedConsumerState<T extends ChangeNotifier> extends State<OptimizedConsumer<T>> {
  T? _previousValue;
  
  @override
  Widget build(BuildContext context) {
    return Consumer<T>(
      builder: (context, value, child) {
        // Check if we should rebuild
        if (widget.listenWhen != null && _previousValue != null) {
          final shouldUpdate = widget.listenWhen!(_previousValue!, value);
          if (!shouldUpdate) {
            return widget.builder(context, _previousValue!, child);
          }
        }
        
        _previousValue = value;
        return widget.builder(context, value, child);
      },
      child: widget.child,
    );
  }
}

/// Performance metrics tracking
class PerformanceTracker {
  static final Map<String, Stopwatch> _timers = {};
  static final Map<String, List<int>> _metrics = {};
  
  static void startTimer(String name) {
    _timers[name] = Stopwatch()..start();
  }
  
  static void stopTimer(String name) {
    final timer = _timers[name];
    if (timer != null) {
      timer.stop();
      _metrics[name] ??= [];
      _metrics[name]!.add(timer.elapsedMilliseconds);
      _timers.remove(name);
      
      if (kDebugMode) {
        print('⏱️ Performance: $name took ${timer.elapsedMilliseconds}ms');
      }
    }
  }
  
  static Map<String, double> getAverageMetrics() {
    final averages = <String, double>{};
    for (final entry in _metrics.entries) {
      if (entry.value.isNotEmpty) {
        final average = entry.value.reduce((a, b) => a + b) / entry.value.length;
        averages[entry.key] = average;
      }
    }
    return averages;
  }
  
  static void clearMetrics() {
    _metrics.clear();
    _timers.clear();
  }
}