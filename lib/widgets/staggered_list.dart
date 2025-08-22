import 'package:flutter/material.dart';
import '../providers/theme_provider.dart';

// Staggered list with animated item entry
class StaggeredList extends StatefulWidget {
  final List<Widget> children;
  final Duration? staggerDelay;
  final Axis direction;
  final CrossAxisAlignment crossAxisAlignment;
  final MainAxisAlignment mainAxisAlignment;
  final MainAxisSize mainAxisSize;
  
  const StaggeredList({
    super.key,
    required this.children,
    this.staggerDelay,
    this.direction = Axis.vertical,
    this.crossAxisAlignment = CrossAxisAlignment.center,
    this.mainAxisAlignment = MainAxisAlignment.start,
    this.mainAxisSize = MainAxisSize.max,
  });
  
  @override State<StaggeredList> createState() => _StaggeredListState();
}

class _StaggeredListState extends State<StaggeredList> 
    with TickerProviderStateMixin {
  late final List<AnimationController> _controllers;
  late final List<Animation<double>> _fadeAnimations;
  late final List<Animation<Offset>> _slideAnimations;
  
  @override
  void initState() {
    super.initState();
    
    _controllers = List.generate(widget.children.length, (index) => 
      AnimationController(
        duration: Motion.med,
        vsync: this,
      ),
    );
    
    _fadeAnimations = _controllers.map((controller) => Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: controller,
      curve: Motion.easeOut,
    ))).toList();
    
    _slideAnimations = _controllers.map((controller) => Tween<Offset>(
      begin: widget.direction == Axis.vertical 
          ? const Offset(0, 0.1) 
          : const Offset(0.1, 0),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: controller,
      curve: Motion.spring,
    ))).toList();
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startStaggeredAnimations();
    });
  }
  
  void _startStaggeredAnimations() async {
    if (!mounted) return;
    
    final reducedMotion = MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    final delay = widget.staggerDelay ?? 
        (reducedMotion ? const Duration(milliseconds: 50) : const Duration(milliseconds: 200));
    
    for (int i = 0; i < _controllers.length; i++) {
      if (!mounted) break;
      
      await Future.delayed(delay);
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
    
    final animatedChildren = widget.children.asMap().entries.map((entry) {
      final index = entry.key;
      final child = entry.value;
      
      return AnimatedBuilder(
        animation: _controllers[index],
        builder: (context, _) {
          if (reducedMotion) {
            return FadeTransition(
              opacity: _fadeAnimations[index],
              child: child,
            );
          }
          
          return FadeTransition(
            opacity: _fadeAnimations[index],
            child: SlideTransition(
              position: _slideAnimations[index],
              child: child,
            ),
          );
        },
      );
    }).toList();
    
    if (widget.direction == Axis.vertical) {
      return Column(
        crossAxisAlignment: widget.crossAxisAlignment,
        mainAxisAlignment: widget.mainAxisAlignment,
        mainAxisSize: widget.mainAxisSize,
        children: animatedChildren,
      );
    } else {
      return Row(
        crossAxisAlignment: widget.crossAxisAlignment,
        mainAxisAlignment: widget.mainAxisAlignment,
        mainAxisSize: widget.mainAxisSize,
        children: animatedChildren,
      );
    }
  }
}

// Staggered grid with animated item entry
class StaggeredGrid extends StatefulWidget {
  final List<Widget> children;
  final int crossAxisCount;
  final double childAspectRatio;
  final double crossAxisSpacing;
  final double mainAxisSpacing;
  final Duration? staggerDelay;
  final bool shrinkWrap;
  final ScrollPhysics? physics;
  
  const StaggeredGrid({
    super.key,
    required this.children,
    this.crossAxisCount = 2,
    this.childAspectRatio = 1.0,
    this.crossAxisSpacing = 8.0,
    this.mainAxisSpacing = 8.0,
    this.staggerDelay,
    this.shrinkWrap = false,
    this.physics,
  });
  
  @override State<StaggeredGrid> createState() => _StaggeredGridState();
}

class _StaggeredGridState extends State<StaggeredGrid> 
    with TickerProviderStateMixin {
  late final List<AnimationController> _controllers;
  late final List<Animation<double>> _fadeAnimations;
  late final List<Animation<double>> _scaleAnimations;
  
  @override
  void initState() {
    super.initState();
    
    _controllers = List.generate(widget.children.length, (index) => 
      AnimationController(
        duration: Motion.med,
        vsync: this,
      ),
    );
    
    _fadeAnimations = _controllers.map((controller) => Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: controller,
      curve: Motion.easeOut,
    ))).toList();
    
    _scaleAnimations = _controllers.map((controller) => Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: controller,
      curve: Motion.spring,
    ))).toList();
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startStaggeredAnimations();
    });
  }
  
  void _startStaggeredAnimations() async {
    if (!mounted) return;
    
    final reducedMotion = MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    final delay = widget.staggerDelay ?? 
        (reducedMotion ? const Duration(milliseconds: 40) : const Duration(milliseconds: 150));
    
    for (int i = 0; i < _controllers.length; i++) {
      if (!mounted) break;
      
      await Future.delayed(delay);
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
    
    return GridView.builder(
      shrinkWrap: widget.shrinkWrap,
      physics: widget.physics,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: widget.crossAxisCount,
        childAspectRatio: widget.childAspectRatio,
        crossAxisSpacing: widget.crossAxisSpacing,
        mainAxisSpacing: widget.mainAxisSpacing,
      ),
      itemCount: widget.children.length,
      itemBuilder: (context, index) {
        return AnimatedBuilder(
          animation: _controllers[index],
          builder: (context, child) {
            if (reducedMotion) {
              return FadeTransition(
                opacity: _fadeAnimations[index],
                child: widget.children[index],
              );
            }
            
            return FadeTransition(
              opacity: _fadeAnimations[index],
              child: ScaleTransition(
                scale: _scaleAnimations[index],
                child: widget.children[index],
              ),
            );
          },
        );
      },
    );
  }
}