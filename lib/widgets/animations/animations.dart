/// Animation exports for easy imports throughout the app
/// Usage: import '../../widgets/animations/animations.dart';

// Core animation widgets
export 'swipe_animations.dart';
export 'custom_loading.dart';
export 'hover_effects.dart';
export 'screen_transitions.dart';
export 'microinteractions.dart';
export 'page_entry_animations.dart';

import 'package:flutter/material.dart';

/// Convenient animation presets for common use cases
class AnimationPresets {
  
  /// Quick card animation with hover and tap effects
  static Widget animatedCard({
    required Widget child,
    VoidCallback? onTap,
    bool enableHover = true,
    bool enableTap = true,
    Duration duration = const Duration(milliseconds: 200),
  }) {
    Widget animatedChild = child;

    if (enableTap && onTap != null) {
      animatedChild = GestureDetector(
        onTap: onTap,
        child: animatedChild,
      );
    }

    return animatedChild;
  }

  /// Standard page transition for the app
  static Route<T> defaultPageTransition<T>(Widget page) {
    return PageRouteBuilder<T>(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionDuration: const Duration(milliseconds: 300),
      reverseTransitionDuration: const Duration(milliseconds: 300),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        const begin = Offset(1.0, 0.0);
        const end = Offset.zero;
        const curve = Curves.easeOutCubic;

        final tween = Tween(begin: begin, end: end).chain(
          CurveTween(curve: curve),
        );

        return SlideTransition(
          position: animation.drive(tween),
          child: FadeTransition(
            opacity: animation,
            child: child,
          ),
        );
      },
    );
  }

  /// Standard loading indicator for the app
  static Widget defaultLoading({
    Color? color,
    String? message,
  }) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(
              color ?? Colors.blue,
            ),
          ),
          if (message != null) ...[
            const SizedBox(height: 16),
            Text(
              message,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// Shimmer loading for lists
  static Widget listShimmer({
    int itemCount = 5,
    double itemHeight = 80,
  }) {
    return ListView.builder(
      itemCount: itemCount,
      itemBuilder: (context, index) {
        return Container(
          margin: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 8,
          ),
          child: Container(
            height: itemHeight,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      },
    );
  }
}

/// Animation utilities
class AnimationUtils {
  
  /// Create a delayed animation
  static Animation<T> createDelayedAnimation<T>({
    required AnimationController controller,
    required Tween<T> tween,
    double delay = 0.0,
    Curve curve = Curves.easeOut,
  }) {
    final delayedStart = delay.clamp(0.0, 1.0);
    final animationEnd = 1.0;

    return tween.animate(
      CurvedAnimation(
        parent: controller,
        curve: Interval(
          delayedStart,
          animationEnd,
          curve: curve,
        ),
      ),
    );
  }

  /// Create staggered animations for lists
  static List<Animation<double>> createStaggeredAnimations({
    required AnimationController controller,
    required int itemCount,
    double stagger = 0.1,
    Curve curve = Curves.easeOut,
  }) {
    final animations = <Animation<double>>[];
    
    for (int i = 0; i < itemCount; i++) {
      final delay = (i * stagger).clamp(0.0, 1.0);
      final end = (delay + (1.0 - delay)).clamp(0.0, 1.0);
      
      animations.add(
        Tween<double>(
          begin: 0.0,
          end: 1.0,
        ).animate(
          CurvedAnimation(
            parent: controller,
            curve: Interval(
              delay,
              end,
              curve: curve,
            ),
          ),
        ),
      );
    }
    
    return animations;
  }

  /// Get platform-appropriate duration
  static Duration getPlatformDuration({
    Duration ios = const Duration(milliseconds: 350),
    Duration android = const Duration(milliseconds: 300),
    Duration web = const Duration(milliseconds: 200),
  }) {
    switch (Theme.of(WidgetsBinding.instance.rootElement!).platform) {
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.android:
        return android;
      default:
        return web;
    }
  }

  /// Get platform-appropriate curve
  static Curve getPlatformCurve({
    Curve ios = Curves.easeInOut,
    Curve android = Curves.fastOutSlowIn,
    Curve web = Curves.easeOut,
  }) {
    switch (Theme.of(WidgetsBinding.instance.rootElement!).platform) {
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.android:
        return android;
      default:
        return web;
    }
  }
}