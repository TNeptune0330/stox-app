import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Hover effects for web and desktop platforms
class HoverEffects {
  
  /// Animated hover scale effect
  static Widget scaleOnHover({
    required Widget child,
    double scale = 1.05,
    Duration duration = const Duration(milliseconds: 200),
    Curve curve = Curves.easeInOut,
    bool enableHaptics = true,
  }) {
    if (!kIsWeb && !_isDesktop()) {
      return child;
    }

    return ScaleHoverEffect(
      scale: scale,
      duration: duration,
      curve: curve,
      enableHaptics: enableHaptics,
      child: child,
    );
  }

  /// Animated hover elevation effect
  static Widget elevateOnHover({
    required Widget child,
    double elevation = 8.0,
    Duration duration = const Duration(milliseconds: 200),
    Color shadowColor = Colors.black26,
    bool enableHaptics = true,
  }) {
    if (!kIsWeb && !_isDesktop()) {
      return child;
    }

    return ElevationHoverEffect(
      elevation: elevation,
      duration: duration,
      shadowColor: shadowColor,
      enableHaptics: enableHaptics,
      child: child,
    );
  }

  /// Animated hover color change effect
  static Widget colorOnHover({
    required Widget child,
    Color? hoverColor,
    Duration duration = const Duration(milliseconds: 200),
    bool enableHaptics = true,
  }) {
    if (!kIsWeb && !_isDesktop()) {
      return child;
    }

    return ColorHoverEffect(
      hoverColor: hoverColor,
      duration: duration,
      enableHaptics: enableHaptics,
      child: child,
    );
  }

  /// Animated hover glow effect
  static Widget glowOnHover({
    required Widget child,
    Color glowColor = Colors.blue,
    double glowRadius = 10.0,
    Duration duration = const Duration(milliseconds: 200),
    bool enableHaptics = true,
  }) {
    if (!kIsWeb && !_isDesktop()) {
      return child;
    }

    return GlowHoverEffect(
      glowColor: glowColor,
      glowRadius: glowRadius,
      duration: duration,
      enableHaptics: enableHaptics,
      child: child,
    );
  }

  /// Animated hover tilt effect
  static Widget tiltOnHover({
    required Widget child,
    double tiltAngle = 0.05,
    Duration duration = const Duration(milliseconds: 200),
    bool enableHaptics = true,
  }) {
    if (!kIsWeb && !_isDesktop()) {
      return child;
    }

    return TiltHoverEffect(
      tiltAngle: tiltAngle,
      duration: duration,
      enableHaptics: enableHaptics,
      child: child,
    );
  }

  /// Check if running on desktop
  static bool _isDesktop() {
    return defaultTargetPlatform == TargetPlatform.windows ||
           defaultTargetPlatform == TargetPlatform.linux ||
           defaultTargetPlatform == TargetPlatform.macOS;
  }
}

/// Scale hover effect widget
class ScaleHoverEffect extends StatefulWidget {
  final Widget child;
  final double scale;
  final Duration duration;
  final Curve curve;
  final bool enableHaptics;

  const ScaleHoverEffect({
    super.key,
    required this.child,
    required this.scale,
    required this.duration,
    required this.curve,
    required this.enableHaptics,
  });

  @override
  State<ScaleHoverEffect> createState() => _ScaleHoverEffectState();
}

class _ScaleHoverEffectState extends State<ScaleHoverEffect>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  bool _isHovered = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: widget.scale,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: widget.curve,
    ));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onHover(bool isHovered) {
    setState(() {
      _isHovered = isHovered;
    });

    if (isHovered) {
      _controller.forward();
      if (widget.enableHaptics) {
        HapticFeedback.selectionClick();
      }
    } else {
      _controller.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => _onHover(true),
      onExit: (_) => _onHover(false),
      cursor: SystemMouseCursors.click,
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: widget.child,
          );
        },
      ),
    );
  }
}

/// Elevation hover effect widget
class ElevationHoverEffect extends StatefulWidget {
  final Widget child;
  final double elevation;
  final Duration duration;
  final Color shadowColor;
  final bool enableHaptics;

  const ElevationHoverEffect({
    super.key,
    required this.child,
    required this.elevation,
    required this.duration,
    required this.shadowColor,
    required this.enableHaptics,
  });

  @override
  State<ElevationHoverEffect> createState() => _ElevationHoverEffectState();
}

class _ElevationHoverEffectState extends State<ElevationHoverEffect>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _elevationAnimation;
  bool _isHovered = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    );

    _elevationAnimation = Tween<double>(
      begin: 0.0,
      end: widget.elevation,
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

  void _onHover(bool isHovered) {
    setState(() {
      _isHovered = isHovered;
    });

    if (isHovered) {
      _controller.forward();
      if (widget.enableHaptics) {
        HapticFeedback.selectionClick();
      }
    } else {
      _controller.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => _onHover(true),
      onExit: (_) => _onHover(false),
      cursor: SystemMouseCursors.click,
      child: AnimatedBuilder(
        animation: _elevationAnimation,
        builder: (context, child) {
          return Container(
            decoration: BoxDecoration(
              boxShadow: _elevationAnimation.value > 0
                  ? [
                      BoxShadow(
                        color: widget.shadowColor,
                        blurRadius: _elevationAnimation.value,
                        offset: Offset(0, _elevationAnimation.value / 2),
                      ),
                    ]
                  : null,
            ),
            child: widget.child,
          );
        },
      ),
    );
  }
}

/// Color hover effect widget
class ColorHoverEffect extends StatefulWidget {
  final Widget child;
  final Color? hoverColor;
  final Duration duration;
  final bool enableHaptics;

  const ColorHoverEffect({
    super.key,
    required this.child,
    this.hoverColor,
    required this.duration,
    required this.enableHaptics,
  });

  @override
  State<ColorHoverEffect> createState() => _ColorHoverEffectState();
}

class _ColorHoverEffectState extends State<ColorHoverEffect>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _colorAnimation;
  bool _isHovered = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    );

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

  void _onHover(bool isHovered) {
    setState(() {
      _isHovered = isHovered;
    });

    if (isHovered) {
      _controller.forward();
      if (widget.enableHaptics) {
        HapticFeedback.selectionClick();
      }
    } else {
      _controller.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => _onHover(true),
      onExit: (_) => _onHover(false),
      cursor: SystemMouseCursors.click,
      child: AnimatedBuilder(
        animation: _colorAnimation,
        builder: (context, child) {
          final hoverColor = widget.hoverColor ?? Theme.of(context).primaryColor.withOpacity(0.1);
          return Container(
            decoration: BoxDecoration(
              color: Color.lerp(Colors.transparent, hoverColor, _colorAnimation.value),
            ),
            child: widget.child,
          );
        },
      ),
    );
  }
}

/// Glow hover effect widget
class GlowHoverEffect extends StatefulWidget {
  final Widget child;
  final Color glowColor;
  final double glowRadius;
  final Duration duration;
  final bool enableHaptics;

  const GlowHoverEffect({
    super.key,
    required this.child,
    required this.glowColor,
    required this.glowRadius,
    required this.duration,
    required this.enableHaptics,
  });

  @override
  State<GlowHoverEffect> createState() => _GlowHoverEffectState();
}

class _GlowHoverEffectState extends State<GlowHoverEffect>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _glowAnimation;
  bool _isHovered = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    );

    _glowAnimation = Tween<double>(
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

  void _onHover(bool isHovered) {
    setState(() {
      _isHovered = isHovered;
    });

    if (isHovered) {
      _controller.forward();
      if (widget.enableHaptics) {
        HapticFeedback.selectionClick();
      }
    } else {
      _controller.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => _onHover(true),
      onExit: (_) => _onHover(false),
      cursor: SystemMouseCursors.click,
      child: AnimatedBuilder(
        animation: _glowAnimation,
        builder: (context, child) {
          return Container(
            decoration: BoxDecoration(
              boxShadow: _glowAnimation.value > 0
                  ? [
                      BoxShadow(
                        color: widget.glowColor.withOpacity(_glowAnimation.value * 0.6),
                        blurRadius: widget.glowRadius * _glowAnimation.value,
                        spreadRadius: (widget.glowRadius / 4) * _glowAnimation.value,
                      ),
                    ]
                  : null,
            ),
            child: widget.child,
          );
        },
      ),
    );
  }
}

/// Tilt hover effect widget
class TiltHoverEffect extends StatefulWidget {
  final Widget child;
  final double tiltAngle;
  final Duration duration;
  final bool enableHaptics;

  const TiltHoverEffect({
    super.key,
    required this.child,
    required this.tiltAngle,
    required this.duration,
    required this.enableHaptics,
  });

  @override
  State<TiltHoverEffect> createState() => _TiltHoverEffectState();
}

class _TiltHoverEffectState extends State<TiltHoverEffect>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _tiltAnimation;
  bool _isHovered = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    );

    _tiltAnimation = Tween<double>(
      begin: 0.0,
      end: widget.tiltAngle,
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

  void _onHover(bool isHovered) {
    setState(() {
      _isHovered = isHovered;
    });

    if (isHovered) {
      _controller.forward();
      if (widget.enableHaptics) {
        HapticFeedback.selectionClick();
      }
    } else {
      _controller.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => _onHover(true),
      onExit: (_) => _onHover(false),
      cursor: SystemMouseCursors.click,
      child: AnimatedBuilder(
        animation: _tiltAnimation,
        builder: (context, child) {
          return Transform.rotate(
            angle: _tiltAnimation.value,
            child: widget.child,
          );
        },
      ),
    );
  }
}