import 'package:flutter/material.dart';
import '../providers/theme_provider.dart';

// Animated screen wrapper for smooth page transitions
class AnimatedScreen extends StatefulWidget {
  final Widget child;
  const AnimatedScreen({super.key, required this.child});
  @override State<AnimatedScreen> createState() => _AnimatedScreenState();
}

class _AnimatedScreenState extends State<AnimatedScreen> 
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fadeAnimation;
  late final Animation<Offset> _slideAnimation;
  
  @override
  void initState() {
    super.initState();
    
    _controller = AnimationController(
      duration: Motion.med,
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Motion.easeOut,
    ));
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.03),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Motion.spring,
    ));
    
    // Start animation after frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final reducedMotion = MediaQuery.maybeOf(context)?.disableAnimations ?? false;
        _controller.duration = reducedMotion ? Motion.fast : Motion.med;
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
    final reducedMotion = MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        if (reducedMotion) {
          return FadeTransition(
            opacity: _fadeAnimation,
            child: widget.child,
          );
        }
        
        return FadeTransition(
          opacity: _fadeAnimation,
          child: SlideTransition(
            position: _slideAnimation,
            child: widget.child,
          ),
        );
      },
    );
  }
}