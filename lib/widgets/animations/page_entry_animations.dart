import 'package:flutter/material.dart';

/// Page entry animations for widgets floating, sliding, and popping in
class PageEntryAnimations {

  /// Staggered slide-in animation for multiple widgets
  static Widget staggeredSlideIn({
    required List<Widget> children,
    Duration delay = const Duration(milliseconds: 100),
    Duration duration = const Duration(milliseconds: 600),
    Curve curve = Curves.easeOutCubic,
    Offset? slideOffset,
  }) {
    return StaggeredSlideInWidget(
      children: children,
      delay: delay,
      duration: duration,
      curve: curve,
      slideOffset: slideOffset ?? const Offset(0, 0.1),
    );
  }

  /// Float in animation with gentle bounce
  static Widget floatIn({
    required Widget child,
    Duration delay = Duration.zero,
    Duration duration = const Duration(milliseconds: 800),
  }) {
    return FloatInWidget(
      child: child,
      delay: delay,
      duration: duration,
    );
  }

  /// Pop in animation with scale effect
  static Widget popIn({
    required Widget child,
    Duration delay = Duration.zero,
    Duration duration = const Duration(milliseconds: 500),
  }) {
    return PopInWidget(
      child: child,
      delay: delay,
      duration: duration,
    );
  }

  /// Fade and slide combination
  static Widget fadeSlideIn({
    required Widget child,
    Duration delay = Duration.zero,
    Duration duration = const Duration(milliseconds: 700),
    Offset slideOffset = const Offset(0, 0.05),
  }) {
    return FadeSlideInWidget(
      child: child,
      delay: delay,
      duration: duration,
      slideOffset: slideOffset,
    );
  }

  /// Ripple effect entry
  static Widget rippleIn({
    required Widget child,
    Duration delay = Duration.zero,
    Duration duration = const Duration(milliseconds: 1000),
    Color rippleColor = Colors.white,
  }) {
    return RippleInWidget(
      child: child,
      delay: delay,
      duration: duration,
      rippleColor: rippleColor,
    );
  }
}

/// Staggered slide-in animation widget
class StaggeredSlideInWidget extends StatefulWidget {
  final List<Widget> children;
  final Duration delay;
  final Duration duration;
  final Curve curve;
  final Offset slideOffset;

  const StaggeredSlideInWidget({
    super.key,
    required this.children,
    required this.delay,
    required this.duration,
    required this.curve,
    required this.slideOffset,
  });

  @override
  State<StaggeredSlideInWidget> createState() => _StaggeredSlideInWidgetState();
}

class _StaggeredSlideInWidgetState extends State<StaggeredSlideInWidget>
    with TickerProviderStateMixin {
  late List<AnimationController> _controllers;
  late List<Animation<Offset>> _slideAnimations;
  late List<Animation<double>> _fadeAnimations;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _startAnimations();
  }

  void _initializeAnimations() {
    _controllers = List.generate(
      widget.children.length,
      (index) => AnimationController(
        duration: widget.duration,
        vsync: this,
      ),
    );

    _slideAnimations = _controllers.map((controller) {
      return Tween<Offset>(
        begin: widget.slideOffset,
        end: Offset.zero,
      ).animate(CurvedAnimation(
        parent: controller,
        curve: widget.curve,
      ));
    }).toList();

    _fadeAnimations = _controllers.map((controller) {
      return Tween<double>(
        begin: 0.0,
        end: 1.0,
      ).animate(CurvedAnimation(
        parent: controller,
        curve: widget.curve,
      ));
    }).toList();
  }

  void _startAnimations() {
    for (int i = 0; i < _controllers.length; i++) {
      Future.delayed(
        widget.delay * i,
        () {
          if (mounted) {
            _controllers[i].forward();
          }
        },
      );
    }
  }

  @override
  void dispose() {
    for (final controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(widget.children.length, (index) {
        return SlideTransition(
          position: _slideAnimations[index],
          child: FadeTransition(
            opacity: _fadeAnimations[index],
            child: widget.children[index],
          ),
        );
      }),
    );
  }
}

/// Float in animation widget
class FloatInWidget extends StatefulWidget {
  final Widget child;
  final Duration delay;
  final Duration duration;

  const FloatInWidget({
    super.key,
    required this.child,
    required this.delay,
    required this.duration,
  });

  @override
  State<FloatInWidget> createState() => _FloatInWidgetState();
}

class _FloatInWidgetState extends State<FloatInWidget>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _startAnimation();
  }

  void _initializeAnimations() {
    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.8, curve: Curves.elasticOut),
    ));

    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.2, 1.0, curve: Curves.elasticOut),
    ));
  }

  void _startAnimation() {
    Future.delayed(widget.delay, () {
      if (mounted) {
        _controller.forward();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SlideTransition(
      position: _slideAnimation,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: widget.child,
        ),
      ),
    );
  }
}

/// Pop in animation widget
class PopInWidget extends StatefulWidget {
  final Widget child;
  final Duration delay;
  final Duration duration;

  const PopInWidget({
    super.key,
    required this.child,
    required this.delay,
    required this.duration,
  });

  @override
  State<PopInWidget> createState() => _PopInWidgetState();
}

class _PopInWidgetState extends State<PopInWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _startAnimation();
  }

  void _initializeAnimations() {
    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.elasticOut,
    ));

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
    ));
  }

  void _startAnimation() {
    Future.delayed(widget.delay, () {
      if (mounted) {
        _controller.forward();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scaleAnimation,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: widget.child,
      ),
    );
  }
}

/// Fade and slide animation widget
class FadeSlideInWidget extends StatefulWidget {
  final Widget child;
  final Duration delay;
  final Duration duration;
  final Offset slideOffset;

  const FadeSlideInWidget({
    super.key,
    required this.child,
    required this.delay,
    required this.duration,
    required this.slideOffset,
  });

  @override
  State<FadeSlideInWidget> createState() => _FadeSlideInWidgetState();
}

class _FadeSlideInWidgetState extends State<FadeSlideInWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _startAnimation();
  }

  void _initializeAnimations() {
    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    ));

    _slideAnimation = Tween<Offset>(
      begin: widget.slideOffset,
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    ));
  }

  void _startAnimation() {
    Future.delayed(widget.delay, () {
      if (mounted) {
        _controller.forward();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SlideTransition(
      position: _slideAnimation,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: widget.child,
      ),
    );
  }
}

/// Ripple in animation widget
class RippleInWidget extends StatefulWidget {
  final Widget child;
  final Duration delay;
  final Duration duration;
  final Color rippleColor;

  const RippleInWidget({
    super.key,
    required this.child,
    required this.delay,
    required this.duration,
    required this.rippleColor,
  });

  @override
  State<RippleInWidget> createState() => _RippleInWidgetState();
}

class _RippleInWidgetState extends State<RippleInWidget>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _rippleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _startAnimation();
  }

  void _initializeAnimations() {
    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    );

    _rippleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    ));

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.3, 1.0, curve: Curves.easeOut),
    ));
  }

  void _startAnimation() {
    Future.delayed(widget.delay, () {
      if (mounted) {
        _controller.forward();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return CustomPaint(
          painter: PageEntryRipplePainter(
            progress: _rippleAnimation.value,
            color: widget.rippleColor,
          ),
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: widget.child,
          ),
        );
      },
    );
  }
}

/// Custom painter for page entry ripple effect
class PageEntryRipplePainter extends CustomPainter {
  final double progress;
  final Color color;

  PageEntryRipplePainter({
    required this.progress,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0) return;

    final center = Offset(size.width / 2, size.height / 2);
    final maxRadius = size.shortestSide / 2;
    final radius = maxRadius * progress;

    final paint = Paint()
      ..color = color.withOpacity(0.1 * (1 - progress))
      ..style = PaintingStyle.fill;

    canvas.drawCircle(center, radius, paint);
  }

  @override
  bool shouldRepaint(covariant PageEntryRipplePainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}