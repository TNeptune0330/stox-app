import 'package:flutter/material.dart';
import 'dart:math' as math;

/// Custom loading indicators with smooth animations
class CustomLoadingIndicators {
  
  /// Shimmer loading effect for cards and lists
  static Widget shimmerCard({
    double height = 80,
    double? width,
    BorderRadius? borderRadius,
  }) {
    return ShimmerWidget(
      child: Container(
        height: height,
        width: width,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: borderRadius ?? BorderRadius.circular(12),
        ),
      ),
    );
  }

  /// Pulsing dot indicator
  static Widget pulsingDots({
    Color color = Colors.blue,
    double size = 8.0,
    int dotCount = 3,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(dotCount, (index) {
        return PulsingDot(
          color: color,
          size: size,
          delay: Duration(milliseconds: index * 200),
        );
      }),
    );
  }

  /// Rotating circular indicator
  static Widget rotatingCircle({
    Color color = Colors.blue,
    double size = 24.0,
    Duration duration = const Duration(milliseconds: 1200),
  }) {
    return RotatingCircle(
      color: color,
      size: size,
      duration: duration,
    );
  }

  /// Wave loading animation
  static Widget waveLoading({
    Color color = Colors.blue,
    double width = 40.0,
    double height = 20.0,
  }) {
    return WaveLoading(
      color: color,
      width: width,
      height: height,
    );
  }

  /// Floating particles effect
  static Widget floatingParticles({
    Color color = Colors.blue,
    int particleCount = 6,
    double size = 100.0,
  }) {
    return FloatingParticles(
      color: color,
      particleCount: particleCount,
      size: size,
    );
  }
}

/// Shimmer effect widget
class ShimmerWidget extends StatefulWidget {
  final Widget child;
  final Color baseColor;
  final Color highlightColor;
  final Duration duration;

  const ShimmerWidget({
    super.key,
    required this.child,
    this.baseColor = const Color(0xFFE0E0E0),
    this.highlightColor = const Color(0xFFF5F5F5),
    this.duration = const Duration(milliseconds: 1500),
  });

  @override
  State<ShimmerWidget> createState() => _ShimmerWidgetState();
}

class _ShimmerWidgetState extends State<ShimmerWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: widget.duration,
    )..repeat();

    _animation = Tween<double>(
      begin: -2.0,
      end: 2.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return ShaderMask(
          shaderCallback: (bounds) {
            return LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [
                widget.baseColor,
                widget.highlightColor,
                widget.baseColor,
              ],
              stops: [
                math.max(0.0, _animation.value - 0.5),
                _animation.value,
                math.min(1.0, _animation.value + 0.5),
              ],
            ).createShader(bounds);
          },
          child: widget.child,
        );
      },
    );
  }
}

/// Pulsing dot animation
class PulsingDot extends StatefulWidget {
  final Color color;
  final double size;
  final Duration delay;

  const PulsingDot({
    super.key,
    required this.color,
    required this.size,
    this.delay = Duration.zero,
  });

  @override
  State<PulsingDot> createState() => _PulsingDotState();
}

class _PulsingDotState extends State<PulsingDot>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    _opacityAnimation = Tween<double>(
      begin: 0.5,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    Future.delayed(widget.delay, () {
      if (mounted) {
        _animationController.repeat(reverse: true);
      }
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 2),
          child: Transform.scale(
            scale: _scaleAnimation.value,
            child: Opacity(
              opacity: _opacityAnimation.value,
              child: Container(
                width: widget.size,
                height: widget.size,
                decoration: BoxDecoration(
                  color: widget.color,
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Rotating circle indicator
class RotatingCircle extends StatefulWidget {
  final Color color;
  final double size;
  final Duration duration;

  const RotatingCircle({
    super.key,
    required this.color,
    required this.size,
    required this.duration,
  });

  @override
  State<RotatingCircle> createState() => _RotatingCircleState();
}

class _RotatingCircleState extends State<RotatingCircle>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: widget.duration,
    )..repeat();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Transform.rotate(
          angle: _animationController.value * 2 * math.pi,
          child: CustomPaint(
            size: Size(widget.size, widget.size),
            painter: CirclePainter(color: widget.color),
          ),
        );
      },
    );
  }
}

class CirclePainter extends CustomPainter {
  final Color color;

  CirclePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 3.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // Draw partial circle
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      0,
      math.pi * 1.5,
      false,
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Wave loading animation
class WaveLoading extends StatefulWidget {
  final Color color;
  final double width;
  final double height;

  const WaveLoading({
    super.key,
    required this.color,
    required this.width,
    required this.height,
  });

  @override
  State<WaveLoading> createState() => _WaveLoadingState();
}

class _WaveLoadingState extends State<WaveLoading>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return CustomPaint(
          size: Size(widget.width, widget.height),
          painter: WavePainter(
            color: widget.color,
            animationValue: _animationController.value,
          ),
        );
      },
    );
  }
}

class WavePainter extends CustomPainter {
  final Color color;
  final double animationValue;

  WavePainter({required this.color, required this.animationValue});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final path = Path();
    final waveHeight = size.height * 0.5;
    final waveLength = size.width;
    final frequency = 2.0;

    for (double x = 0; x <= waveLength; x++) {
      final y = waveHeight +
          math.sin((x / waveLength * frequency * math.pi * 2) +
                  (animationValue * math.pi * 2)) *
              (waveHeight * 0.5);

      if (x == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

/// Floating particles animation
class FloatingParticles extends StatefulWidget {
  final Color color;
  final int particleCount;
  final double size;

  const FloatingParticles({
    super.key,
    required this.color,
    required this.particleCount,
    required this.size,
  });

  @override
  State<FloatingParticles> createState() => _FloatingParticlesState();
}

class _FloatingParticlesState extends State<FloatingParticles>
    with TickerProviderStateMixin {
  late List<AnimationController> _controllers;
  late List<Animation<double>> _animations;

  @override
  void initState() {
    super.initState();
    _controllers = [];
    _animations = [];

    for (int i = 0; i < widget.particleCount; i++) {
      final controller = AnimationController(
        vsync: this,
        duration: Duration(milliseconds: 2000 + (i * 200)),
      );

      final animation = Tween<double>(
        begin: 0.0,
        end: 1.0,
      ).animate(CurvedAnimation(
        parent: controller,
        curve: Curves.easeInOut,
      ));

      _controllers.add(controller);
      _animations.add(animation);

      // Start each controller with a delay
      Future.delayed(Duration(milliseconds: i * 100), () {
        if (mounted) {
          controller.repeat(reverse: true);
        }
      });
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
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: Stack(
        children: List.generate(widget.particleCount, (index) {
          final angle = (index / widget.particleCount) * 2 * math.pi;
          final radius = widget.size * 0.3;

          return AnimatedBuilder(
            animation: _animations[index],
            builder: (context, child) {
              final animatedRadius = radius * (0.5 + 0.5 * _animations[index].value);
              final x = widget.size / 2 + animatedRadius * math.cos(angle);
              final y = widget.size / 2 + animatedRadius * math.sin(angle);

              return Positioned(
                left: x - 3,
                top: y - 3,
                child: Opacity(
                  opacity: 0.3 + 0.7 * _animations[index].value,
                  child: Container(
                    width: 6,
                    height: 6,
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
      ),
    );
  }
}

/// Loading overlay for full screen loading
class LoadingOverlay extends StatelessWidget {
  final String? message;
  final Color backgroundColor;
  final Widget? customIndicator;

  const LoadingOverlay({
    super.key,
    this.message,
    this.backgroundColor = Colors.black54,
    this.customIndicator,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: backgroundColor,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            customIndicator ?? CustomLoadingIndicators.rotatingCircle(),
            if (message != null) ...[
              const SizedBox(height: 16),
              Text(
                message!,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ),
      ),
    );
  }
}