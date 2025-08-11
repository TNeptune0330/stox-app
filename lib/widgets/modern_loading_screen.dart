import 'package:flutter/material.dart';
import '../theme/modern_theme.dart';

class ModernLoadingScreen extends StatefulWidget {
  final String? message;
  final bool showProgress;
  final double? progress;
  
  const ModernLoadingScreen({
    super.key,
    this.message,
    this.showProgress = false,
    this.progress,
  });

  @override
  State<ModernLoadingScreen> createState() => _ModernLoadingScreenState();
}

class _ModernLoadingScreenState extends State<ModernLoadingScreen>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _rotateController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _rotateAnimation;

  @override
  void initState() {
    super.initState();
    
    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    
    _rotateController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    );

    _pulseAnimation = Tween<double>(
      begin: 0.8,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));

    _rotateAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _rotateController,
      curve: Curves.linear,
    ));

    _pulseController.repeat(reverse: true);
    _rotateController.repeat();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _rotateController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ModernTheme.backgroundPrimary,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              ModernTheme.backgroundPrimary,
              Color(0xFF1A1D23),
            ],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Animated Logo/Icon
              AnimatedBuilder(
                animation: _pulseAnimation,
                builder: (context, child) {
                  return Transform.scale(
                    scale: _pulseAnimation.value,
                    child: AnimatedBuilder(
                      animation: _rotateAnimation,
                      builder: (context, child) {
                        return Transform.rotate(
                          angle: _rotateAnimation.value * 2 * 3.14159,
                          child: Container(
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  ModernTheme.accentBlue,
                                  ModernTheme.accentPurple,
                                ],
                              ),
                              borderRadius: BorderRadius.circular(25),
                              boxShadow: [
                                BoxShadow(
                                  color: ModernTheme.accentBlue.withOpacity(0.5),
                                  blurRadius: 20,
                                  spreadRadius: 5,
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.trending_up,
                              color: Colors.white,
                              size: 40,
                            ),
                          ),
                        );
                      },
                    ),
                  );
                },
              ),
              
              const SizedBox(height: ModernTheme.spaceXL),
              
              // App Name
              ShaderMask(
                shaderCallback: (bounds) => const LinearGradient(
                  colors: [
                    ModernTheme.accentBlue,
                    ModernTheme.accentPurple,
                  ],
                ).createShader(bounds),
                child: Text(
                  'STOX',
                  style: ModernTheme.displayLarge.copyWith(
                    fontWeight: FontWeight.w900,
                    letterSpacing: 4,
                    color: Colors.white,
                  ),
                ),
              ),
              
              const SizedBox(height: ModernTheme.spaceM),
              
              Text(
                'Stock Trading Simulator',
                style: ModernTheme.titleMedium.copyWith(
                  color: ModernTheme.textMuted,
                  letterSpacing: 1,
                ),
              ),
              
              const SizedBox(height: ModernTheme.spaceXL),
              
              // Progress Indicator
              if (widget.showProgress && widget.progress != null) ...[
                Container(
                  width: 250,
                  height: 6,
                  decoration: BoxDecoration(
                    color: ModernTheme.backgroundCard,
                    borderRadius: BorderRadius.circular(3),
                  ),
                  child: FractionallySizedBox(
                    alignment: Alignment.centerLeft,
                    widthFactor: widget.progress,
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [
                            ModernTheme.accentBlue,
                            ModernTheme.accentPurple,
                          ],
                        ),
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: ModernTheme.spaceM),
                Text(
                  '${((widget.progress ?? 0) * 100).toInt()}%',
                  style: ModernTheme.bodyLarge.copyWith(
                    color: ModernTheme.accentBlue,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ] else ...[
                // Circular progress indicator
                SizedBox(
                  width: 40,
                  height: 40,
                  child: CircularProgressIndicator(
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      ModernTheme.accentBlue,
                    ),
                    backgroundColor: ModernTheme.backgroundCard,
                    strokeWidth: 3,
                  ),
                ),
              ],
              
              const SizedBox(height: ModernTheme.spaceL),
              
              // Loading Message
              Text(
                widget.message ?? 'Loading your portfolio...',
                style: ModernTheme.bodyMedium.copyWith(
                  color: ModernTheme.textMuted,
                ),
                textAlign: TextAlign.center,
              ),
              
              const SizedBox(height: ModernTheme.spaceXXL),
              
              // Animated dots
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(3, (index) {
                  return AnimatedBuilder(
                    animation: _pulseController,
                    builder: (context, child) {
                      final delay = index * 0.3;
                      final animationValue = (_pulseController.value + delay) % 1.0;
                      final opacity = (1.0 - (animationValue - 0.5).abs() * 2).clamp(0.3, 1.0);
                      
                      return Container(
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: ModernTheme.accentBlue.withOpacity(opacity),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      );
                    },
                  );
                }),
              ),
            ],
          ),
        ),
      ),
    );
  }
}