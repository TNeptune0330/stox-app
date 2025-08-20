import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/portfolio_provider.dart';
import '../providers/market_data_provider.dart';
import '../providers/theme_provider.dart';
import '../services/local_database_service.dart';
import '../services/enhanced_market_data_service.dart';
import '../services/revenue_admob_service.dart';
import '../utils/responsive_utils.dart';
import '../services/storage_service.dart';
import '../screens/auth/login_screen.dart';
import '../screens/main_navigation.dart';
import '../screens/onboarding/onboarding_screen.dart';
import '../screens/tutorial/tutorial_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with TickerProviderStateMixin {
  late AnimationController _morphController;
  late AnimationController _pulseController;
  
  String _currentStatus = 'Preparing your portfolio…';
  bool _hasError = false;
  String? _errorMessage;
  bool _reducedMotion = false;
  int _currentShape = 0; // 0=triangle, 1=circle, 2=square
  
  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _startInitialization();
  }
  
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _checkReducedMotion();
  }
  
  void _checkReducedMotion() {
    final newReducedMotion = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    if (newReducedMotion != _reducedMotion) {
      _reducedMotion = newReducedMotion;
      _updateAnimations();
    }
  }
  
  void _updateAnimations() {
    if (_reducedMotion) {
      _morphController.stop();
      _pulseController.repeat(reverse: true);
    } else {
      _pulseController.stop();
      _morphController.repeat();
      _startShapeCycle();
    }
  }
  
  void _initializeAnimations() {
    // Morph animation - 2000ms per shape cycle
    _morphController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );
    
    // Pulse animation for reduced motion - 1400ms
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1400),
      vsync: this,
    );
    
    // Start with normal motion (will be updated in didChangeDependencies)
    _morphController.repeat();
    _startShapeCycle();
  }
  
  void _startShapeCycle() {
    Timer.periodic(const Duration(milliseconds: 2000), (timer) {
      if (mounted && !_reducedMotion) {
        setState(() {
          _currentShape = (_currentShape + 1) % 3; // Cycle through 0, 1, 2
        });
      } else {
        timer.cancel();
      }
    });
  }
  
  Future<void> _startInitialization() async {
    try {
      await _initializeApp();
      await _checkAuthentication();
    } catch (e) {
      setState(() {
        _hasError = true;
        _errorMessage = e.toString();
      });
    }
  }
  
  Future<void> _initializeApp() async {
    // Step 1: Initialize Database
    await _updateStatus('Initializing database…');
    await Future.delayed(const Duration(milliseconds: 300));
    
    final dbStats = await LocalDatabaseService.getDatabaseStats();
    print('📊 Database initialized - ${dbStats['market_assets']} assets');
    
    // Step 2: Initialize Market Data Provider
    await _updateStatus('Loading market data…');
    await Future.delayed(const Duration(milliseconds: 500));
    
    final marketProvider = Provider.of<MarketDataProvider>(context, listen: false);
    await marketProvider.initialize();
    
    // Step 3: Initialize Auth Provider
    await _updateStatus('Checking authentication…');
    await Future.delayed(const Duration(milliseconds: 300));
    
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    await authProvider.initialize();
    
    // Step 4: Initialize Portfolio Provider
    await _updateStatus('Loading portfolio…');
    await Future.delayed(const Duration(milliseconds: 400));
    
    final portfolioProvider = Provider.of<PortfolioProvider>(context, listen: false);
    
    // Only load portfolio if user is authenticated with proper Supabase user
    if (authProvider.isAuthenticated && authProvider.user != null) {
      print('🏦 SplashScreen: Loading portfolio for authenticated user: ${authProvider.user!.id}');
      await portfolioProvider.loadPortfolio(authProvider.user!.id);
    } else {
      print('⚠️ SplashScreen: No authenticated user, skipping portfolio load');
    }
    
    // Step 5: Final checks
    await _updateStatus('Ready to trade!');
    await Future.delayed(const Duration(milliseconds: 300));
  }
  
  Future<void> _updateStatus(String status) async {
    if (mounted) {
      setState(() {
        _currentStatus = status;
      });
    }
  }
  
  Future<void> _checkAuthentication() async {
    // First check if user has completed onboarding
    await _updateStatus('Checking onboarding status…');
    await Future.delayed(const Duration(milliseconds: 300));
    
    final hasCompletedOnboarding = StorageService.isOnboardingCompleted();
    
    if (!hasCompletedOnboarding) {
      await _navigateToOnboarding();
      return;
    }
    
    await _updateStatus('Checking authentication…');
    await Future.delayed(const Duration(milliseconds: 300));
    
    final currentUser = LocalDatabaseService.getCurrentUser();
    
    if (currentUser != null) {
      final hasTutorial = StorageService.isTutorialCompleted();
      if (hasTutorial) {
        await _navigateToMain();
      } else {
        await _navigateToTutorial();
      }
    } else {
      await _navigateToLogin();
    }
  }
  
  Future<void> _navigateToMain() async {
    await Future.delayed(const Duration(milliseconds: 500));
    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => const MainNavigation(),
        ),
      );
    }
  }
  
  Future<void> _navigateToLogin() async {
    await Future.delayed(const Duration(milliseconds: 500));
    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => const LoginScreen(),
        ),
      );
    }
  }

  Future<void> _navigateToOnboarding() async {
    await Future.delayed(const Duration(milliseconds: 500));
    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => const OnboardingScreen(),
        ),
      );
    }
  }

  Future<void> _navigateToTutorial() async {
    await Future.delayed(const Duration(milliseconds: 500));
    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => const TutorialScreen(),
        ),
      );
    }
  }
  
  void _retryInitialization() {
    setState(() {
      _hasError = false;
      _errorMessage = null;
    });
    _startInitialization();
  }
  
  @override
  void dispose() {
    _morphController.dispose();
    _pulseController.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return Scaffold(
          backgroundColor: themeProvider.background, // BG_DARK
          body: SafeArea(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // App Name and Version
                  Text(
                    'Stox',
                    style: TextStyle(
                      fontSize: 48,
                      fontWeight: FontWeight.w900,
                      color: themeProvider.contrast,
                      letterSpacing: -1,
                    ),
                  ),
                  
                  const SizedBox(height: 8),
                  
                  Text(
                    'version 1.0.0',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: themeProvider.contrast.withOpacity(0.6),
                      letterSpacing: 0.5,
                    ),
                  ),
                  
                  const SizedBox(height: 48),
                  
                  // Morphing shape loader
                  _hasError
                      ? Icon(
                          Icons.error_outline,
                          size: 64,
                          color: themeProvider.themeData.colorScheme.error,
                        )
                      : _MorphingLoader(
                          controller: _reducedMotion ? _pulseController : _morphController,
                          reducedMotion: _reducedMotion,
                          currentShape: _currentShape,
                          size: 64,
                        ),
                  
                  const SizedBox(height: 24),
                  
                  // Status caption
                  Text(
                    _hasError ? 'Initialization failed' : _currentStatus,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: const Color(0xFFA7B4C7), // TEXT_SECONDARY
                    ),
                    textAlign: TextAlign.center,
                  ),
                  
                  // Error message and retry button
                  if (_hasError) ...[
                    const SizedBox(height: 16),
                    if (_errorMessage != null)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 32),
                        child: Text(
                          _errorMessage!,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: themeProvider.themeData.colorScheme.error,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    const SizedBox(height: 24),
                    TextButton(
                      onPressed: _retryInitialization,
                      child: Text(
                        'Retry',
                        style: TextStyle(
                          color: themeProvider.themeData.colorScheme.primary,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

// Private morphing loader widget
class _MorphingLoader extends StatelessWidget {
  final AnimationController controller;
  final bool reducedMotion;
  final int currentShape; // 0=triangle, 1=circle, 2=square
  final double size;

  const _MorphingLoader({
    required this.controller,
    required this.reducedMotion,
    required this.currentShape,
    this.size = 64,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.35),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: AnimatedBuilder(
        animation: controller,
        builder: (context, child) {
          return Semantics(
            label: 'Loading',
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Shape morphing animation
                if (currentShape == 0)
                  // Green Triangle (spinning)
                  Transform.rotate(
                    angle: reducedMotion ? 0 : (controller.value * 2 * pi),
                    child: Transform.scale(
                      scale: reducedMotion 
                          ? 0.98 + (controller.value * 0.02) // Pulse between 0.98 and 1.0
                          : 1.0,
                      child: CustomPaint(
                        size: Size(size, size),
                        painter: _TrianglePainter(
                          color: const Color(0xFF22C55E), // Green
                        ),
                      ),
                    ),
                  )
                else if (currentShape == 1)
                  // Pink Circle (bouncing)
                  Transform.translate(
                    offset: Offset(0, reducedMotion ? 0 : sin(controller.value * 4 * pi) * 8),
                    child: Transform.scale(
                      scale: reducedMotion 
                          ? 0.98 + (controller.value * 0.02)
                          : 0.9 + (sin(controller.value * 4 * pi).abs() * 0.1),
                      child: Container(
                        width: size * 0.8,
                        height: size * 0.8,
                        decoration: const BoxDecoration(
                          color: Color(0xFFEC4899), // Pink
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                  )
                else
                  // Orange Square (expanding/contracting)
                  Transform.scale(
                    scale: reducedMotion 
                        ? 0.98 + (controller.value * 0.02)
                        : 0.7 + (sin(controller.value * 3 * pi).abs() * 0.3),
                    child: Transform.rotate(
                      angle: reducedMotion ? 0 : (controller.value * pi / 4),
                      child: Container(
                        width: size * 0.7,
                        height: size * 0.7,
                        decoration: BoxDecoration(
                          color: const Color(0xFFEA580C), // Orange
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}

// Private triangle painter
class _TrianglePainter extends CustomPainter {
  final Color color;

  _TrianglePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final path = Path();
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width * 0.4; // Make it slightly smaller than full size

    // Create equilateral triangle
    for (int i = 0; i < 3; i++) {
      final angle = (i * 120 - 90) * (pi / 180); // Start from top
      final x = center.dx + radius * cos(angle);
      final y = center.dy + radius * sin(angle);
      
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}