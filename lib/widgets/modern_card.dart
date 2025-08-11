import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/modern_theme.dart';

class ModernCard extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsets? padding;
  final EdgeInsets? margin;
  final Color? backgroundColor;
  final BorderRadius? borderRadius;
  final List<BoxShadow>? boxShadow;
  final Border? border;
  final bool enableHoverEffect;
  final bool enableTapEffect;
  final Duration animationDuration;

  const ModernCard({
    super.key,
    required this.child,
    this.onTap,
    this.padding,
    this.margin,
    this.backgroundColor,
    this.borderRadius,
    this.boxShadow,
    this.border,
    this.enableHoverEffect = true,
    this.enableTapEffect = true,
    this.animationDuration = const Duration(milliseconds: 200),
  });

  @override
  State<ModernCard> createState() => _ModernCardState();
}

class _ModernCardState extends State<ModernCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _elevationAnimation;
  bool _isHovered = false;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: widget.animationDuration,
      vsync: this,
    );
    
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.98,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: ModernTheme.defaultCurve,
    ));
    
    _elevationAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: ModernTheme.defaultCurve,
    ));
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails details) {
    if (widget.onTap != null && widget.enableTapEffect) {
      setState(() => _isPressed = true);
      _animationController.forward();
      HapticFeedback.lightImpact();
    }
  }

  void _onTapUp(TapUpDetails details) {
    _onTapEnd();
  }

  void _onTapCancel() {
    _onTapEnd();
  }

  void _onTapEnd() {
    if (_isPressed) {
      setState(() => _isPressed = false);
      if (!_isHovered) {
        _animationController.reverse();
      }
    }
  }

  void _onHoverStart(PointerEnterEvent event) {
    if (widget.enableHoverEffect) {
      setState(() => _isHovered = true);
      _animationController.forward();
    }
  }

  void _onHoverEnd(PointerExitEvent event) {
    if (widget.enableHoverEffect) {
      setState(() => _isHovered = false);
      if (!_isPressed) {
        _animationController.reverse();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Container(
          margin: widget.margin,
          child: MouseRegion(
            onEnter: _onHoverStart,
            onExit: _onHoverEnd,
            child: Transform.scale(
              scale: _scaleAnimation.value,
              child: GestureDetector(
                onTapDown: _onTapDown,
                onTapUp: _onTapUp,
                onTapCancel: _onTapCancel,
                onTap: widget.onTap,
                child: AnimatedContainer(
                  duration: widget.animationDuration,
                  curve: ModernTheme.defaultCurve,
                  padding: widget.padding ?? const EdgeInsets.all(ModernTheme.spaceM),
                  decoration: BoxDecoration(
                    color: widget.backgroundColor ?? ModernTheme.backgroundCard,
                    borderRadius: widget.borderRadius ?? 
                        BorderRadius.circular(ModernTheme.radiusL),
                    border: widget.border,
                    boxShadow: widget.boxShadow ?? [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1 + (_elevationAnimation.value * 0.05)),
                        blurRadius: 8 + (_elevationAnimation.value * 4),
                        offset: Offset(0, 4 + (_elevationAnimation.value * 2)),
                      ),
                    ],
                  ),
                  child: widget.child,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets? padding;
  final EdgeInsets? margin;
  final BorderRadius? borderRadius;
  final VoidCallback? onTap;

  const GlassCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.borderRadius,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin,
      child: ClipRRect(
        borderRadius: borderRadius ?? BorderRadius.circular(ModernTheme.radiusL),
        child: GestureDetector(
          onTap: onTap,
          child: Container(
            padding: padding ?? const EdgeInsets.all(ModernTheme.spaceM),
            decoration: BoxDecoration(
              color: ModernTheme.backgroundCard.withOpacity(0.8),
              borderRadius: borderRadius ?? BorderRadius.circular(ModernTheme.radiusL),
              border: Border.all(
                color: Colors.white.withOpacity(0.1),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}

class GradientCard extends StatefulWidget {
  final Widget child;
  final List<Color> gradientColors;
  final EdgeInsets? padding;
  final EdgeInsets? margin;
  final BorderRadius? borderRadius;
  final VoidCallback? onTap;
  final Alignment begin;
  final Alignment end;

  const GradientCard({
    super.key,
    required this.child,
    required this.gradientColors,
    this.padding,
    this.margin,
    this.borderRadius,
    this.onTap,
    this.begin = Alignment.topLeft,
    this.end = Alignment.bottomRight,
  });

  @override
  State<GradientCard> createState() => _GradientCardState();
}

class _GradientCardState extends State<GradientCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: ModernTheme.fastAnimation,
      vsync: this,
    );
    
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: ModernTheme.defaultCurve,
    ));
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails details) {
    if (widget.onTap != null) {
      _animationController.forward();
      HapticFeedback.lightImpact();
    }
  }

  void _onTapUp(TapUpDetails details) {
    _animationController.reverse();
  }

  void _onTapCancel() {
    _animationController.reverse();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Container(
          margin: widget.margin,
          child: Transform.scale(
            scale: _scaleAnimation.value,
            child: GestureDetector(
              onTapDown: _onTapDown,
              onTapUp: _onTapUp,
              onTapCancel: _onTapCancel,
              onTap: widget.onTap,
              child: Container(
                padding: widget.padding ?? const EdgeInsets.all(ModernTheme.spaceM),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: widget.begin,
                    end: widget.end,
                    colors: widget.gradientColors,
                  ),
                  borderRadius: widget.borderRadius ?? 
                      BorderRadius.circular(ModernTheme.radiusL),
                  boxShadow: ModernTheme.cardShadow,
                ),
                child: widget.child,
              ),
            ),
          ),
        );
      },
    );
  }
}