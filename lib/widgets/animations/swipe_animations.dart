import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Swipeable card with smooth animations and physics
class SwipeableCard extends StatefulWidget {
  final Widget child;
  final VoidCallback? onSwipeLeft;
  final VoidCallback? onSwipeRight;
  final double swipeThreshold;
  final Duration animationDuration;
  final bool enableHaptics;

  const SwipeableCard({
    super.key,
    required this.child,
    this.onSwipeLeft,
    this.onSwipeRight,
    this.swipeThreshold = 100.0,
    this.animationDuration = const Duration(milliseconds: 300),
    this.enableHaptics = true,
  });

  @override
  State<SwipeableCard> createState() => _SwipeableCardState();
}

class _SwipeableCardState extends State<SwipeableCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _rotationAnimation;
  late Animation<double> _scaleAnimation;

  double _dragOffset = 0.0;
  bool _isDragging = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: widget.animationDuration,
    );

    _slideAnimation = Tween<Offset>(
      begin: Offset.zero,
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.elasticOut,
    ));

    _rotationAnimation = Tween<double>(
      begin: 0.0,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.95,
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

  void _onPanStart(DragStartDetails details) {
    setState(() {
      _isDragging = true;
    });
    _animationController.forward();
  }

  void _onPanUpdate(DragUpdateDetails details) {
    setState(() {
      _dragOffset += details.delta.dx;
    });

    // Update animations based on drag
    final progress = (_dragOffset.abs() / widget.swipeThreshold).clamp(0.0, 1.0);
    
    _slideAnimation = Tween<Offset>(
      begin: Offset.zero,
      end: Offset(_dragOffset / 200, 0),
    ).animate(_animationController);

    _rotationAnimation = Tween<double>(
      begin: 0.0,
      end: _dragOffset / 1000,
    ).animate(_animationController);
  }

  void _onPanEnd(DragEndDetails details) {
    setState(() {
      _isDragging = false;
    });

    if (_dragOffset.abs() > widget.swipeThreshold) {
      // Swipe completed
      if (widget.enableHaptics) {
        HapticFeedback.mediumImpact();
      }

      if (_dragOffset > 0) {
        widget.onSwipeRight?.call();
      } else {
        widget.onSwipeLeft?.call();
      }

      // Animate off screen
      _slideAnimation = Tween<Offset>(
        begin: Offset(_dragOffset / 200, 0),
        end: Offset(_dragOffset > 0 ? 3.0 : -3.0, 0),
      ).animate(CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ));
      
      _animationController.forward();
    } else {
      // Snap back
      _dragOffset = 0.0;
      _slideAnimation = Tween<Offset>(
        begin: Offset(_dragOffset / 200, 0),
        end: Offset.zero,
      ).animate(CurvedAnimation(
        parent: _animationController,
        curve: Curves.elasticOut,
      ));
      
      _animationController.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onPanStart: _onPanStart,
      onPanUpdate: _onPanUpdate,
      onPanEnd: _onPanEnd,
      child: AnimatedBuilder(
        animation: _animationController,
        builder: (context, child) {
          return Transform.translate(
            offset: _slideAnimation.value * 200,
            child: Transform.rotate(
              angle: _rotationAnimation.value,
              child: Transform.scale(
                scale: _scaleAnimation.value,
                child: widget.child,
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Page transition with swipe gestures
class SwipeablePageView extends StatefulWidget {
  final List<Widget> pages;
  final Function(int)? onPageChanged;
  final PageController? controller;
  final bool enableSwipeBack;

  const SwipeablePageView({
    super.key,
    required this.pages,
    this.onPageChanged,
    this.controller,
    this.enableSwipeBack = true,
  });

  @override
  State<SwipeablePageView> createState() => _SwipeablePageViewState();
}

class _SwipeablePageViewState extends State<SwipeablePageView>
    with TickerProviderStateMixin {
  late PageController _pageController;
  late AnimationController _transitionController;
  late Animation<double> _slideAnimation;

  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _pageController = widget.controller ?? PageController();
    _transitionController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );

    _slideAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _transitionController,
      curve: Curves.easeInOutCubic,
    ));
  }

  @override
  void dispose() {
    if (widget.controller == null) {
      _pageController.dispose();
    }
    _transitionController.dispose();
    super.dispose();
  }

  void _animateToPage(int page) {
    HapticFeedback.selectionClick();
    _transitionController.forward();
    
    _pageController.animateToPage(
      page,
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    return PageView.builder(
      controller: _pageController,
      onPageChanged: (index) {
        setState(() {
          _currentPage = index;
        });
        widget.onPageChanged?.call(index);
        _transitionController.reset();
      },
      itemCount: widget.pages.length,
      itemBuilder: (context, index) {
        return AnimatedBuilder(
          animation: _slideAnimation,
          builder: (context, child) {
            return Transform.translate(
              offset: Offset(
                (index - _currentPage) * MediaQuery.of(context).size.width * (1 - _slideAnimation.value),
                0,
              ),
              child: widget.pages[index],
            );
          },
        );
      },
    );
  }
}

/// 3D Flip Card Animation
class FlipCard extends StatefulWidget {
  final Widget front;
  final Widget back;
  final Duration animationDuration;
  final bool autoFlip;
  final VoidCallback? onFlip;

  const FlipCard({
    super.key,
    required this.front,
    required this.back,
    this.animationDuration = const Duration(milliseconds: 600),
    this.autoFlip = false,
    this.onFlip,
  });

  @override
  State<FlipCard> createState() => _FlipCardState();
}

class _FlipCardState extends State<FlipCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _flipAnimation;
  bool _isShowingFront = true;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: widget.animationDuration,
    );

    _flipAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    if (widget.autoFlip) {
      _flip();
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _flip() {
    if (_isShowingFront) {
      _animationController.forward();
    } else {
      _animationController.reverse();
    }
    setState(() {
      _isShowingFront = !_isShowingFront;
    });
    widget.onFlip?.call();
    HapticFeedback.lightImpact();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _flip,
      child: AnimatedBuilder(
        animation: _flipAnimation,
        builder: (context, child) {
          final isShowingFront = _flipAnimation.value < 0.5;
          return Transform(
            alignment: Alignment.center,
            transform: Matrix4.identity()
              ..setEntry(3, 2, 0.001)
              ..rotateY(_flipAnimation.value * 3.14159),
            child: isShowingFront
                ? widget.front
                : Transform(
                    alignment: Alignment.center,
                    transform: Matrix4.identity()..rotateY(3.14159),
                    child: widget.back,
                  ),
          );
        },
      ),
    );
  }
}