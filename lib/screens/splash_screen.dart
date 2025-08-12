import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/portfolio_provider.dart';
import '../providers/market_data_provider.dart';
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
  late AnimationController _logoController;
  late AnimationController _progressController;
  late Animation<double> _logoAnimation;
  late Animation<double> _progressAnimation;
  
  String _currentStatus = 'Initializing...';
  double _progress = 0.0;
  bool _hasError = false;
  String? _errorMessage;
  
  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _startInitialization();
  }
  
  void _initializeAnimations() {
    _logoController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    
    _progressController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    );
    
    _logoAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _logoController,
      curve: Curves.elasticOut,
    ));
    
    _progressAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _progressController,
      curve: Curves.easeInOut,
    ));
    
    _logoController.forward();
    _progressController.forward();
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
    await _updateStatus('Initializing database...', 0.1);
    await Future.delayed(const Duration(milliseconds: 300));
    
    // Database should already be initialized in main.dart
    final dbStats = await LocalDatabaseService.getDatabaseStats();
    print('📊 Database initialized - ${dbStats['market_assets']} assets');
    
    // Step 2: Initialize Market Data Provider
    await _updateStatus('Loading market data...', 0.3);
    await Future.delayed(const Duration(milliseconds: 500));
    
    final marketProvider = Provider.of<MarketDataProvider>(context, listen: false);
    await marketProvider.initialize();
    
    // Step 3: Initialize Auth Provider
    await _updateStatus('Checking authentication...', 0.5);
    await Future.delayed(const Duration(milliseconds: 300));
    
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    await authProvider.initialize();
    
    // Step 4: Initialize Portfolio Provider
    await _updateStatus('Loading portfolio...', 0.7);
    await Future.delayed(const Duration(milliseconds: 400));
    
    final portfolioProvider = Provider.of<PortfolioProvider>(context, listen: false);
    
    // Only load portfolio if user is authenticated with proper Supabase user
    if (authProvider.isAuthenticated && authProvider.user != null) {
      print('🏦 SplashScreen: Loading portfolio for authenticated user: ${authProvider.user!.id}');
      await portfolioProvider.loadPortfolio(authProvider.user!.id);
    } else {
      print('⚠️ SplashScreen: No authenticated user, skipping portfolio load');
      // Don't load portfolio with default user - wait for proper authentication
    }
    
    // Step 5: Final checks
    await _updateStatus('Finalizing setup...', 0.9);
    await Future.delayed(const Duration(milliseconds: 300));
    
    // Check AdMob status
    final adStats = RevenueAdMobService.getAdStats();
    print('🎯 AdMob Status: ${adStats['banner_loaded'] ? 'Ready' : 'Loading'}');
    
    await _updateStatus('Ready to trade!', 1.0);
    await Future.delayed(const Duration(milliseconds: 500));
  }
  
  Future<void> _updateStatus(String status, double progress) async {
    if (mounted) {
      setState(() {
        _currentStatus = status;
        _progress = progress;
      });
    }
  }
  
  Future<void> _checkAuthentication() async {
    // First check if user has completed onboarding
    await _updateStatus('Checking onboarding status...', 0.7);
    await Future.delayed(const Duration(milliseconds: 300));
    
    final hasCompletedOnboarding = StorageService.isOnboardingCompleted();
    
    if (!hasCompletedOnboarding) {
      // User needs to complete onboarding first
      await _navigateToOnboarding();
      return;
    }
    
    await _updateStatus('Checking authentication...', 0.9);
    await Future.delayed(const Duration(milliseconds: 300));
    
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final currentUser = LocalDatabaseService.getCurrentUser();
    
    if (currentUser != null) {
      // User is logged in, check if tutorial is completed
      final hasTutorial = StorageService.isTutorialCompleted();
      if (hasTutorial) {
        await _navigateToMain();
      } else {
        await _navigateToTutorial();
      }
    } else {
      // No user, go to login
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
  
  @override
  void dispose() {
    _logoController.dispose();
    _progressController.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF1a1a2e),
              Color(0xFF0f1419),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Top section with logo
              Expanded(
                flex: 3,
                child: Center(
                  child: AnimatedBuilder(
                    animation: _logoAnimation,
                    builder: (context, child) {
                      return Transform.scale(
                        scale: _logoAnimation.value,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // Logo
                            Container(
                              width: ResponsiveUtils.getIconSize(context, 120),
                              height: ResponsiveUtils.getIconSize(context, 120),
                              decoration: BoxDecoration(
                                color: const Color(0xFF7209b7),
                                borderRadius: BorderRadius.circular(24),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFF7209b7).withOpacity(0.3),
                                    blurRadius: 20,
                                    spreadRadius: 5,
                                  ),
                                ],
                              ),
                              child: Icon(
                                Icons.trending_up,
                                size: ResponsiveUtils.getIconSize(context, 64),
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 24),
                            
                            // App Name
                            Text(
                              'STOX',
                              style: TextStyle(
                                fontSize: ResponsiveUtils.getFontSize(context, 42),
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                                letterSpacing: 4,
                              ),
                            ),
                            const SizedBox(height: 8),
                            
                            // Subtitle
                            Text(
                              'TRADING SIMULATOR',
                              style: TextStyle(
                                fontSize: ResponsiveUtils.getFontSize(context, 16),
                                fontWeight: FontWeight.w500,
                                color: Colors.white70,
                                letterSpacing: 2,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ),
              
              // Bottom section with progress
              Expanded(
                flex: 2,
                child: Padding(
                  padding: const EdgeInsets.all(32.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (_hasError) ...[
                        // Error state
                        const Icon(
                          Icons.error_outline,
                          size: 48,
                          color: Colors.red,
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Initialization Failed',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.red,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _errorMessage ?? 'Unknown error occurred',
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.white70,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton(
                          onPressed: () {
                            setState(() {
                              _hasError = false;
                              _errorMessage = null;
                              _progress = 0.0;
                            });
                            _startInitialization();
                          },
                          child: const Text('Retry'),
                        ),
                      ] else ...[
                        // Loading state
                        AnimatedBuilder(
                          animation: _progressAnimation,
                          builder: (context, child) {
                            return Column(
                              children: [
                                // Progress bar
                                Container(
                                  width: double.infinity,
                                  height: 4,
                                  decoration: BoxDecoration(
                                    color: Colors.white24,
                                    borderRadius: BorderRadius.circular(2),
                                  ),
                                  child: FractionallySizedBox(
                                    alignment: Alignment.centerLeft,
                                    widthFactor: _progress,
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF7209b7),
                                        borderRadius: BorderRadius.circular(2),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 16),
                                
                                // Status text
                                Text(
                                  _currentStatus,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                
                                // Progress percentage
                                Text(
                                  '${(_progress * 100).toInt()}%',
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color: Colors.white70,
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              
              // Footer
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    const Text(
                      'Practice trading with virtual currency',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.white54,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Real market prices • No real money involved',
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.white38,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: RevenueAdMobService.isBannerAdLoaded 
                                ? Colors.green 
                                : Colors.orange,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'AdMob ${RevenueAdMobService.isBannerAdLoaded ? 'Ready' : 'Loading'}',
                          style: const TextStyle(
                            fontSize: 10,
                            color: Colors.white38,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}