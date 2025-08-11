import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:math' as math;

/// Microinteractions and feedback animations
class Microinteractions {
  
  /// Animated button with press feedback
  static Widget animatedButton({
    required Widget child,
    required VoidCallback? onPressed,
    Duration duration = const Duration(milliseconds: 150),
    double pressedScale = 0.95,
    Color? pressedColor,
    bool enableHaptics = true,
  }) {
    return AnimatedButton(
      onPressed: onPressed,
      duration: duration,
      pressedScale: pressedScale,
      pressedColor: pressedColor,
      enableHaptics: enableHaptics,
      child: child,
    );
  }

  /// Ripple effect animation
  static Widget rippleEffect({
    required Widget child,
    required VoidCallback? onTap,
    Color rippleColor = Colors.white24,
    Duration duration = const Duration(milliseconds: 300),
    bool enableHaptics = true,
  }) {
    return RippleEffect(
      onTap: onTap,
      rippleColor: rippleColor,
      duration: duration,
      enableHaptics: enableHaptics,
      child: child,
    );
  }

  /// Bouncing animation
  static Widget bounceOnInteraction({
    required Widget child,
    required VoidCallback? onTap,
    Duration duration = const Duration(milliseconds: 400),
    double bounceFactor = 0.2,
    bool enableHaptics = true,
  }) {
    return BounceInteraction(
      onTap: onTap,
      duration: duration,
      bounceFactor: bounceFactor,
      enableHaptics: enableHaptics,
      child: child,
    );
  }

  /// Shake animation for errors
  static Widget shakeOnError({
    required Widget child,
    required bool triggerShake,
    Duration duration = const Duration(milliseconds: 500),
    double shakeOffset = 10.0,
    VoidCallback? onShakeComplete,
  }) {
    return ShakeAnimation(
      triggerShake: triggerShake,
      duration: duration,
      shakeOffset: shakeOffset,
      onShakeComplete: onShakeComplete,
      child: child,
    );
  }

  /// Pulse animation for notifications
  static Widget pulseNotification({
    required Widget child,
    required bool triggerPulse,
    Duration duration = const Duration(milliseconds: 1000),
    double pulseFactor = 1.1,
    Color? pulseColor,
  }) {
    return PulseAnimation(
      triggerPulse: triggerPulse,
      duration: duration,
      pulseFactor: pulseFactor,
      pulseColor: pulseColor,
      child: child,
    );
  }

  /// Success checkmark animation
  static Widget successCheckmark({
    double size = 24.0,
    Color color = Colors.green,
    Duration duration = const Duration(milliseconds: 600),
  }) {
    return SuccessCheckmark(
      size: size,
      color: color,
      duration: duration,
    );
  }

  /// Loading dots animation
  static Widget loadingDots({
    Color color = Colors.blue,
    double size = 8.0,
    int dotCount = 3,
    Duration duration = const Duration(milliseconds: 1200),
  }) {
    return LoadingDots(
      color: color,
      size: size,
      dotCount: dotCount,
      duration: duration,
    );
  }

  /// Floating action button with micro animations
  static Widget animatedFAB({
    required VoidCallback onPressed,
    required Widget child,
    Color? backgroundColor,
    Duration duration = const Duration(milliseconds: 200),
    bool enableHaptics = true,
  }) {
    return AnimatedFAB(
      onPressed: onPressed,
      backgroundColor: backgroundColor,
      duration: duration,
      enableHaptics: enableHaptics,
      child: child,
    );
  }
}

/// Animated button with press feedback
class AnimatedButton extends StatefulWidget {
  final Widget child;
  final VoidCallback? onPressed;
  final Duration duration;
  final double pressedScale;
  final Color? pressedColor;
  final bool enableHaptics;

  const AnimatedButton({
    super.key,
    required this.child,
    required this.onPressed,
    required this.duration,
    required this.pressedScale,
    this.pressedColor,
    required this.enableHaptics,
  });

  @override
  State<AnimatedButton> createState() => _AnimatedButtonState();
}

class _AnimatedButtonState extends State<AnimatedButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _colorAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: widget.pressedScale,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));

    _colorAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTapDown() {
    _controller.forward();
    if (widget.enableHaptics) {
      HapticFeedback.lightImpact();
    }
  }

  void _handleTapUp() {
    _controller.reverse();
  }

  void _handleTap() {
    widget.onPressed?.call();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _handleTapDown(),
      onTapUp: (_) => _handleTapUp(),
      onTapCancel: _handleTapUp,
      onTap: widget.onPressed != null ? _handleTap : null,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: Container(
              decoration: widget.pressedColor != null
                  ? BoxDecoration(
                      color: Color.lerp(
                        Colors.transparent,
                        widget.pressedColor!.withOpacity(0.1),
                        _colorAnimation.value,
                      ),
                    )
                  : null,
              child: widget.child,
            ),
          );
        },
      ),
    );
  }
}

/// Ripple effect animation
class RippleEffect extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final Color rippleColor;
  final Duration duration;
  final bool enableHaptics;

  const RippleEffect({
    super.key,
    required this.child,
    required this.onTap,
    required this.rippleColor,
    required this.duration,
    required this.enableHaptics,
  });

  @override
  State<RippleEffect> createState() => _RippleEffectState();
}

class _RippleEffectState extends State<RippleEffect>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _rippleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    );

    _rippleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.fastOutSlowIn,
    ));

    _fadeAnimation = Tween<double>(
      begin: 1.0,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.6, 1.0, curve: Curves.easeOut),
    ));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTap() {
    _controller.forward().then((_) => _controller.reset());
    widget.onTap?.call();
    if (widget.enableHaptics) {
      HapticFeedback.lightImpact();
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap != null ? _handleTap : null,
      child: Stack(
        clipBehavior: Clip.hardEdge,
        children: [
          widget.child,
          AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return Positioned.fill(
                child: CustomPaint(
                  painter: RipplePainter(
                    progress: _rippleAnimation.value,
                    color: widget.rippleColor.withOpacity(_fadeAnimation.value),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class RipplePainter extends CustomPainter {
  final double progress;
  final Color color;

  RipplePainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final center = Offset(size.width / 2, size.height / 2);
    final maxRadius = math.sqrt(size.width * size.width + size.height * size.height) / 2;
    final radius = maxRadius * progress;

    canvas.drawCircle(center, radius, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

/// Bounce interaction animation
class BounceInteraction extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final Duration duration;
  final double bounceFactor;
  final bool enableHaptics;

  const BounceInteraction({
    super.key,
    required this.child,
    required this.onTap,
    required this.duration,
    required this.bounceFactor,
    required this.enableHaptics,
  });

  @override
  State<BounceInteraction> createState() => _BounceInteractionState();
}

class _BounceInteractionState extends State<BounceInteraction>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _bounceAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    );

    _bounceAnimation = Tween<double>(
      begin: 1.0,
      end: 1.0 + widget.bounceFactor,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.elasticOut,
    ));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTap() {
    _controller.forward().then((_) => _controller.reverse());
    widget.onTap?.call();
    if (widget.enableHaptics) {
      HapticFeedback.mediumImpact();
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap != null ? _handleTap : null,
      child: AnimatedBuilder(
        animation: _bounceAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _bounceAnimation.value,
            child: widget.child,
          );
        },
      ),
    );
  }
}

/// Shake animation for errors
class ShakeAnimation extends StatefulWidget {
  final Widget child;
  final bool triggerShake;
  final Duration duration;
  final double shakeOffset;
  final VoidCallback? onShakeComplete;

  const ShakeAnimation({
    super.key,
    required this.child,
    required this.triggerShake,
    required this.duration,
    required this.shakeOffset,
    this.onShakeComplete,
  });

  @override
  State<ShakeAnimation> createState() => _ShakeAnimationState();
}

class _ShakeAnimationState extends State<ShakeAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _shakeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    );

    _shakeAnimation = Tween<double>(
      begin: -1.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.elasticIn,
    ));

    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _controller.reset();
        widget.onShakeComplete?.call();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(ShakeAnimation oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.triggerShake && !oldWidget.triggerShake) {
      _controller.forward();
      HapticFeedback.heavyImpact();
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _shakeAnimation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(_shakeAnimation.value * widget.shakeOffset, 0),
          child: widget.child,
        );
      },
    );
  }
}

/// Pulse animation for notifications
class PulseAnimation extends StatefulWidget {
  final Widget child;
  final bool triggerPulse;
  final Duration duration;
  final double pulseFactor;
  final Color? pulseColor;

  const PulseAnimation({
    super.key,
    required this.child,
    required this.triggerPulse,
    required this.duration,
    required this.pulseFactor,
    this.pulseColor,
  });

  @override
  State<PulseAnimation> createState() => _PulseAnimationState();
}

class _PulseAnimationState extends State<PulseAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    );

    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: widget.pulseFactor,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(PulseAnimation oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.triggerPulse && !oldWidget.triggerPulse) {
      _controller.repeat(reverse: true);
    } else if (!widget.triggerPulse && oldWidget.triggerPulse) {
      _controller.stop();
      _controller.reset();
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _pulseAnimation.value,
          child: Container(
            decoration: widget.pulseColor != null
                ? BoxDecoration(
                    boxShadow: [
                      BoxShadow(
                        color: widget.pulseColor!.withOpacity(0.3),
                        blurRadius: 10 * _pulseAnimation.value,
                        spreadRadius: 5 * _pulseAnimation.value,
                      ),
                    ],
                  )
                : null,
            child: widget.child,
          ),
        );
      },
    );
  }
}

/// Success checkmark animation
class SuccessCheckmark extends StatefulWidget {
  final double size;
  final Color color;
  final Duration duration;

  const SuccessCheckmark({
    super.key,
    required this.size,
    required this.color,
    required this.duration,
  });

  @override
  State<SuccessCheckmark> createState() => _SuccessCheckmarkState();
}

class _SuccessCheckmarkState extends State<SuccessCheckmark>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _checkAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    );

    _checkAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _checkAnimation,
      builder: (context, child) {
        return CustomPaint(
          size: Size(widget.size, widget.size),
          painter: CheckmarkPainter(
            progress: _checkAnimation.value,
            color: widget.color,
          ),
        );
      },
    );
  }
}

class CheckmarkPainter extends CustomPainter {
  final double progress;
  final Color color;

  CheckmarkPainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = size.width * 0.1
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final path = Path();
    final checkPath = Path();

    // Define checkmark path
    checkPath.moveTo(size.width * 0.2, size.height * 0.5);
    checkPath.lineTo(size.width * 0.45, size.height * 0.7);
    checkPath.lineTo(size.width * 0.8, size.height * 0.3);

    // Get path metrics for animation
    final pathMetrics = checkPath.computeMetrics();
    for (final pathMetric in pathMetrics) {
      final extractedPath = pathMetric.extractPath(
        0,
        pathMetric.length * progress,
      );
      path.addPath(extractedPath, Offset.zero);
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

/// Loading dots animation
class LoadingDots extends StatefulWidget {
  final Color color;
  final double size;
  final int dotCount;
  final Duration duration;

  const LoadingDots({
    super.key,
    required this.color,
    required this.size,
    required this.dotCount,
    required this.duration,
  });

  @override
  State<LoadingDots> createState() => _LoadingDotsState();
}

class _LoadingDotsState extends State<LoadingDots>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(widget.dotCount, (index) {
        return AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            final delay = index / widget.dotCount;
            final animationValue = (_controller.value - delay) % 1.0;
            final opacity = animationValue < 0.5
                ? (animationValue * 2).clamp(0.0, 1.0)
                : (2 - animationValue * 2).clamp(0.0, 1.0);

            return Container(
              margin: EdgeInsets.symmetric(horizontal: widget.size * 0.2),
              child: Opacity(
                opacity: opacity,
                child: Container(
                  width: widget.size,
                  height: widget.size,
                  decoration: BoxDecoration(
                    color: widget.color,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            );
          },
        );
      }),
    );
  }
}

/// Animated FAB
class AnimatedFAB extends StatefulWidget {
  final VoidCallback onPressed;
  final Widget child;
  final Color? backgroundColor;
  final Duration duration;
  final bool enableHaptics;

  const AnimatedFAB({
    super.key,
    required this.onPressed,
    required this.child,
    this.backgroundColor,
    required this.duration,
    required this.enableHaptics,
  });

  @override
  State<AnimatedFAB> createState() => _AnimatedFABState();
}

class _AnimatedFABState extends State<AnimatedFAB>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _rotationAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.9,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));

    _rotationAnimation = Tween<double>(
      begin: 0.0,
      end: 0.1,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTap() {
    _controller.forward().then((_) => _controller.reverse());
    widget.onPressed();
    if (widget.enableHaptics) {
      HapticFeedback.lightImpact();
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Transform.rotate(
            angle: _rotationAnimation.value,
            child: FloatingActionButton(
              onPressed: _handleTap,
              backgroundColor: widget.backgroundColor,
              child: widget.child,
            ),
          ),
        );
      },
    );
  }
}