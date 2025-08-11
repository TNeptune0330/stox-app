import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/modern_theme.dart';

class AnimatedButton extends StatefulWidget {
  final String text;
  final VoidCallback? onPressed;
  final Widget? icon;
  final Color? backgroundColor;
  final Color? textColor;
  final double? width;
  final double? height;
  final EdgeInsets? padding;
  final BorderRadius? borderRadius;
  final bool isLoading;
  final AnimatedButtonStyle style;

  const AnimatedButton({
    super.key,
    required this.text,
    this.onPressed,
    this.icon,
    this.backgroundColor,
    this.textColor,
    this.width,
    this.height,
    this.padding,
    this.borderRadius,
    this.isLoading = false,
    this.style = AnimatedButtonStyle.primary,
  });

  @override
  State<AnimatedButton> createState() => _AnimatedButtonState();
}

enum AnimatedButtonStyle {
  primary,
  secondary,
  success,
  danger,
  ghost,
}

class _AnimatedButtonState extends State<AnimatedButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;
  bool _isPressed = false;

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
    
    _opacityAnimation = Tween<double>(
      begin: 1.0,
      end: 0.8,
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
    if (widget.onPressed != null && !widget.isLoading) {
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
      _animationController.reverse();
    }
  }

  Color get _backgroundColor {
    if (widget.backgroundColor != null) return widget.backgroundColor!;
    
    switch (widget.style) {
      case AnimatedButtonStyle.primary:
        return ModernTheme.accentGreen;
      case AnimatedButtonStyle.secondary:
        return ModernTheme.backgroundCard;
      case AnimatedButtonStyle.success:
        return ModernTheme.accentSuccess;
      case AnimatedButtonStyle.danger:
        return ModernTheme.accentDanger;
      case AnimatedButtonStyle.ghost:
        return Colors.transparent;
    }
  }

  Color get _textColor {
    if (widget.textColor != null) return widget.textColor!;
    
    switch (widget.style) {
      case AnimatedButtonStyle.primary:
      case AnimatedButtonStyle.success:
      case AnimatedButtonStyle.danger:
        return ModernTheme.textOnGreen;
      case AnimatedButtonStyle.secondary:
        return ModernTheme.textPrimary;
      case AnimatedButtonStyle.ghost:
        return ModernTheme.accentGreen;
    }
  }

  Border? get _border {
    switch (widget.style) {
      case AnimatedButtonStyle.ghost:
        return Border.all(color: ModernTheme.accentGreen.withOpacity(0.3));
      case AnimatedButtonStyle.secondary:
        return Border.all(color: ModernTheme.borderDark);
      default:
        return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Opacity(
            opacity: _opacityAnimation.value,
            child: GestureDetector(
              onTapDown: _onTapDown,
              onTapUp: _onTapUp,
              onTapCancel: _onTapCancel,
              onTap: widget.onPressed,
              child: AnimatedContainer(
                duration: ModernTheme.fastAnimation,
                curve: ModernTheme.defaultCurve,
                width: widget.width,
                height: widget.height ?? 50,
                padding: widget.padding ?? const EdgeInsets.symmetric(
                  horizontal: ModernTheme.spaceL,
                  vertical: ModernTheme.spaceM,
                ),
                decoration: BoxDecoration(
                  color: widget.onPressed == null 
                      ? _backgroundColor.withOpacity(0.5) 
                      : _backgroundColor,
                  borderRadius: widget.borderRadius ?? 
                      BorderRadius.circular(ModernTheme.radiusM),
                  border: _border,
                  boxShadow: widget.onPressed != null && !_isPressed
                      ? ModernTheme.buttonShadow
                      : null,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (widget.isLoading) ...[
                      SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(_textColor),
                        ),
                      ),
                      const SizedBox(width: ModernTheme.spaceS),
                    ] else if (widget.icon != null) ...[
                      widget.icon!,
                      const SizedBox(width: ModernTheme.spaceS),
                    ],
                    Text(
                      widget.text,
                      style: TextStyle(
                        color: widget.onPressed == null 
                            ? _textColor.withOpacity(0.5) 
                            : _textColor,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class AnimatedIconButton extends StatefulWidget {
  final IconData icon;
  final VoidCallback? onPressed;
  final Color? backgroundColor;
  final Color? iconColor;
  final double size;
  final double? padding;
  final String? tooltip;

  const AnimatedIconButton({
    super.key,
    required this.icon,
    this.onPressed,
    this.backgroundColor,
    this.iconColor,
    this.size = 24,
    this.padding,
    this.tooltip,
  });

  @override
  State<AnimatedIconButton> createState() => _AnimatedIconButtonState();
}

class _AnimatedIconButtonState extends State<AnimatedIconButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: ModernTheme.fastAnimation,
      vsync: this,
    );
    
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.9,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: ModernTheme.bounceCurve,
    ));
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails details) {
    if (widget.onPressed != null) {
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
      _animationController.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    final button = AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: GestureDetector(
            onTapDown: _onTapDown,
            onTapUp: _onTapUp,
            onTapCancel: _onTapCancel,
            onTap: widget.onPressed,
            child: AnimatedContainer(
              duration: ModernTheme.fastAnimation,
              curve: ModernTheme.defaultCurve,
              padding: EdgeInsets.all(widget.padding ?? ModernTheme.spaceM),
              decoration: BoxDecoration(
                color: widget.backgroundColor ?? ModernTheme.backgroundElevated,
                borderRadius: BorderRadius.circular(ModernTheme.radiusM),
                boxShadow: widget.onPressed != null && !_isPressed
                    ? ModernTheme.cardShadow
                    : null,
              ),
              child: Icon(
                widget.icon,
                size: widget.size,
                color: widget.onPressed == null 
                    ? (widget.iconColor ?? ModernTheme.textSecondary).withOpacity(0.5)
                    : widget.iconColor ?? ModernTheme.textSecondary,
              ),
            ),
          ),
        );
      },
    );

    if (widget.tooltip != null) {
      return Tooltip(
        message: widget.tooltip!,
        child: button,
      );
    }

    return button;
  }
}