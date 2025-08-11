import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/modern_theme.dart';

class InteractiveCard extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final VoidCallback? onSwipeLeft;
  final VoidCallback? onSwipeRight;
  final bool enableHover;
  final bool enableScale;
  final EdgeInsets? padding;
  final EdgeInsets? margin;
  final BorderRadius? borderRadius;
  final Color? backgroundColor;
  final List<BoxShadow>? boxShadow;

  const InteractiveCard({
    super.key,
    required this.child,
    this.onTap,
    this.onLongPress,
    this.onSwipeLeft,
    this.onSwipeRight,
    this.enableHover = true,
    this.enableScale = true,
    this.padding,
    this.margin,
    this.borderRadius,
    this.backgroundColor,
    this.boxShadow,
  });

  @override
  State<InteractiveCard> createState() => _InteractiveCardState();
}

class _InteractiveCardState extends State<InteractiveCard>
    with TickerProviderStateMixin {
  late AnimationController _scaleController;
  late AnimationController _hoverController;
  late AnimationController _slideController;
  
  late Animation<double> _scaleAnimation;
  late Animation<double> _elevationAnimation;
  late Animation<Offset> _slideAnimation;
  
  bool _isPressed = false;
  bool _isHovered = false;
  double _slideOffset = 0.0;

  @override
  void initState() {
    super.initState();
    
    _scaleController = AnimationController(
      duration: ModernTheme.fastAnimation,
      vsync: this,
    );
    
    _hoverController = AnimationController(
      duration: ModernTheme.mediumAnimation,
      vsync: this,
    );
    
    _slideController = AnimationController(
      duration: ModernTheme.mediumAnimation,
      vsync: this,
    );
    
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(
      parent: _scaleController,
      curve: ModernTheme.smoothCurve,
    ));
    
    _elevationAnimation = Tween<double>(
      begin: 0.0,
      end: 8.0,
    ).animate(CurvedAnimation(
      parent: _hoverController,
      curve: ModernTheme.smoothCurve,
    ));
    
    _slideAnimation = Tween<Offset>(
      begin: Offset.zero,
      end: const Offset(0.05, 0.0),
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: ModernTheme.bounceCurve,
    ));
  }

  @override
  void dispose() {
    _scaleController.dispose();
    _hoverController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  void _handleTapDown(TapDownDetails details) {
    if (widget.enableScale) {
      setState(() => _isPressed = true);
      _scaleController.forward();
      HapticFeedback.lightImpact();
    }
  }

  void _handleTapUp(TapUpDetails details) {
    _handleTapEnd();
  }

  void _handleTapCancel() {
    _handleTapEnd();
  }

  void _handleTapEnd() {
    if (_isPressed) {
      setState(() => _isPressed = false);
      _scaleController.reverse();
    }
  }

  void _handleHover(bool isHovered) {
    if (widget.enableHover) {
      setState(() => _isHovered = isHovered);
      if (isHovered) {
        _hoverController.forward();
      } else {
        _hoverController.reverse();
      }
    }
  }

  void _handlePanUpdate(DragUpdateDetails details) {
    setState(() {
      _slideOffset += details.delta.dx;
      _slideOffset = _slideOffset.clamp(-100.0, 100.0);
    });
  }

  void _handlePanEnd(DragEndDetails details) {
    if (_slideOffset.abs() > 50) {
      // Trigger swipe action
      if (_slideOffset > 0 && widget.onSwipeRight != null) {
        widget.onSwipeRight!();
        HapticFeedback.mediumImpact();
      } else if (_slideOffset < 0 && widget.onSwipeLeft != null) {
        widget.onSwipeLeft!();
        HapticFeedback.mediumImpact();
      }
    }
    
    // Reset slide position
    setState(() => _slideOffset = 0.0);
    _slideController.reset();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([
        _scaleAnimation,
        _elevationAnimation,
        _slideAnimation,
      ]),
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(_slideOffset * 0.01, 0),
          child: Transform.scale(
            scale: _scaleAnimation.value,
            child: MouseRegion(
              onEnter: (_) => _handleHover(true),
              onExit: (_) => _handleHover(false),
              child: GestureDetector(
                onTap: widget.onTap,
                onLongPress: widget.onLongPress,
                onTapDown: _handleTapDown,
                onTapUp: _handleTapUp,
                onTapCancel: _handleTapCancel,
                onPanUpdate: (widget.onSwipeLeft != null || widget.onSwipeRight != null) 
                    ? _handlePanUpdate : null,
                onPanEnd: (widget.onSwipeLeft != null || widget.onSwipeRight != null) 
                    ? _handlePanEnd : null,
                child: AnimatedContainer(
                  duration: ModernTheme.fastAnimation,
                  curve: ModernTheme.smoothCurve,
                  margin: widget.margin ?? const EdgeInsets.all(ModernTheme.spaceS),
                  padding: widget.padding ?? const EdgeInsets.all(ModernTheme.spaceM),
                  decoration: BoxDecoration(
                    color: widget.backgroundColor ?? ModernTheme.backgroundCard,
                    borderRadius: widget.borderRadius ?? 
                        BorderRadius.circular(ModernTheme.radiusL),
                    boxShadow: widget.boxShadow ?? [
                      BoxShadow(
                        color: ModernTheme.shadowColor,
                        blurRadius: 8 + _elevationAnimation.value,
                        offset: Offset(0, 2 + _elevationAnimation.value * 0.5),
                        spreadRadius: 0,
                      ),
                      if (_isHovered) ...ModernTheme.glowShadow,
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