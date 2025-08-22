import 'package:flutter/material.dart';
import '../providers/theme_provider.dart';

// Staggered dialog content with animated element entry
class StaggeredDialogContent extends StatefulWidget {
  final Widget child;
  const StaggeredDialogContent({super.key, required this.child});
  @override State<StaggeredDialogContent> createState() => _StaggeredDialogContentState();
}

class _StaggeredDialogContentState extends State<StaggeredDialogContent>
    with TickerProviderStateMixin {
  late final List<AnimationController> _controllers;
  late final List<Animation<double>> _fadeAnimations;
  late final List<Animation<Offset>> _slideAnimations;
  
  @override
  void initState() {
    super.initState();
    
    // Create controllers for different dialog elements
    _controllers = List.generate(3, (index) => AnimationController(
      duration: Motion.med,
      vsync: this,
    ));
    
    _fadeAnimations = _controllers.map((controller) => Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: controller,
      curve: Motion.easeOut,
    ))).toList();
    
    _slideAnimations = _controllers.map((controller) => Tween<Offset>(
      begin: const Offset(0, 0.05),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: controller,
      curve: Motion.spring,
    ))).toList();
    
    // Start staggered animations
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startStaggeredAnimations();
    });
  }
  
  void _startStaggeredAnimations() async {
    if (!mounted) return;
    
    final reducedMotion = MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    final delay = reducedMotion ? 0 : 180;
    
    for (int i = 0; i < _controllers.length; i++) {
      if (!mounted) break;
      
      await Future.delayed(Duration(milliseconds: delay * i));
      if (mounted) {
        _controllers[i].duration = reducedMotion ? Motion.fast : Motion.med;
        _controllers[i].forward();
      }
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
    final reducedMotion = MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    
    return AnimatedBuilder(
      animation: Listenable.merge(_controllers),
      builder: (context, child) {
        // For reduced motion, just show the content with basic fade
        if (reducedMotion) {
          return FadeTransition(
            opacity: _fadeAnimations[0],
            child: widget.child,
          );
        }
        
        // For full motion, add staggered element animations
        return _StaggeredContent(
          fadeAnimations: _fadeAnimations,
          slideAnimations: _slideAnimations,
          child: widget.child,
        );
      },
    );
  }
}

// Helper widget to apply staggered animations to dialog content
class _StaggeredContent extends StatelessWidget {
  final List<Animation<double>> fadeAnimations;
  final List<Animation<Offset>> slideAnimations;
  final Widget child;
  
  const _StaggeredContent({
    required this.fadeAnimations,
    required this.slideAnimations,
    required this.child,
  });
  
  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: fadeAnimations[0],
      child: SlideTransition(
        position: slideAnimations[0],
        child: child,
      ),
    );
  }
}

// Enhanced bottom sheet with slide-up animation
class AnimatedBottomSheet extends StatefulWidget {
  final Widget child;
  final double? height;
  const AnimatedBottomSheet({super.key, required this.child, this.height});
  
  static Future<T?> show<T>(BuildContext context, Widget child, {double? height}) {
    return showModalBottomSheet<T>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AnimatedBottomSheet(child: child, height: height),
    );
  }
  
  @override State<AnimatedBottomSheet> createState() => _AnimatedBottomSheetState();
}

class _AnimatedBottomSheetState extends State<AnimatedBottomSheet>
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
      begin: const Offset(0, 1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Motion.spring,
    ));
    
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