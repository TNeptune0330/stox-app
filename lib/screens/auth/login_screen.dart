import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/theme_provider.dart';
import '../../models/user_model.dart';
import '../main_navigation.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with TickerProviderStateMixin {
  late AnimationController _gradientController;
  late AnimationController _cardController;
  bool _reducedMotion = false;
  
  @override
  void initState() {
    super.initState();
    _checkReducedMotion();
    _initializeAnimations();
  }
  
  void _checkReducedMotion() {
    _reducedMotion = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
  }
  
  void _initializeAnimations() {
    // Gradient animation - 1600ms ping-pong
    _gradientController = AnimationController(
      duration: const Duration(milliseconds: 1600),
      vsync: this,
    );
    
    // Card entrance animation
    _cardController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    if (!_reducedMotion) {
      _gradientController.repeat(reverse: true);
    }
    
    // Start card entrance animation
    _cardController.forward();
  }
  
  @override
  void dispose() {
    _gradientController.dispose();
    _cardController.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return Scaffold(
          backgroundColor: themeProvider.background, // BG_DARK
          body: Stack(
            children: [
              // Animated diagonal gradient background
              AnimatedBuilder(
                animation: _gradientController,
                builder: (context, child) {
                  return Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: _reducedMotion 
                            ? Alignment.topLeft 
                            : Alignment.lerp(
                                Alignment.topLeft, 
                                Alignment.bottomRight, 
                                _gradientController.value
                              )!,
                        end: _reducedMotion 
                            ? Alignment.bottomRight 
                            : Alignment.lerp(
                                Alignment.bottomRight, 
                                Alignment.topLeft, 
                                _gradientController.value
                              )!,
                        colors: [
                          const Color(0xFF0F172A), // BG_DARK
                          const Color(0xFF1D2A3B), // SURFACE_DARK_2
                          const Color(0xFF3B82F6), // PRIMARY
                        ],
                      ),
                    ),
                  );
                },
              ),
              
              // Safe area content
              SafeArea(
                child: Center(
                  child: SingleChildScrollView(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: SlideTransition(
                        position: Tween<Offset>(
                          begin: const Offset(0, 0.1),
                          end: Offset.zero,
                        ).animate(CurvedAnimation(
                          parent: _cardController,
                          curve: Curves.easeOutCubic,
                        )),
                        child: FadeTransition(
                          opacity: _cardController,
                          child: _AuthCard(
                            onGoogleSignIn: () => _handleGoogleSignIn(context),
                            onDemoMode: () => _handleDemoMode(context),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showSignInError(BuildContext context, String error) {
    String message = 'There was an issue with Google Sign-In.';
    
    // Check for specific error types
    if (error.contains('cancelled') || error.contains('canceled')) {
      message = 'You cancelled the sign-in process. You can try again or use Demo Mode.';
    } else if (error.contains('network') || error.contains('connection')) {
      message = 'Please check your internet connection and try again, or use Demo Mode.';
    } else {
      message = 'Google Sign-In encountered an error. You can try again or use Demo Mode.';
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: const Color(0xFFEF4444), // ERROR color
        duration: const Duration(seconds: 4),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        margin: const EdgeInsets.all(16),
        action: SnackBarAction(
          label: 'Demo Mode',
          textColor: Colors.white,
          onPressed: () => _handleDemoMode(context),
        ),
      ),
    );
  }


  Future<void> _handleGoogleSignIn(BuildContext context) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    
    try {
      final success = await authProvider.signInWithGoogle();
      
      if (mounted) {
        if (success) {
          // Navigate to main app on successful sign-in
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (context) => const MainNavigation(),
            ),
          );
        } else if (authProvider.error != null) {
          // Show error via SnackBar
          _showSignInError(context, authProvider.error!);
        }
      }
    } catch (e) {
      if (mounted) {
        _showSignInError(context, e.toString());
      }
    }
  }

  Future<void> _handleDemoMode(BuildContext context) async {
    print('🧪 Creating Demo User...');
    await _createDemoUser(context);
  }


  Future<void> _createDemoUser(BuildContext context) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    
    // Create a demo user
    authProvider.setUser(
      UserModel(
        id: 'demo_user_${DateTime.now().millisecondsSinceEpoch}',
        email: 'demo@stoxtrading.com',
        username: 'Demo Trader',
        avatarUrl: null,
        colorTheme: 'light',
        isAdmin: false,
        cashBalance: 10000.0,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
    );

    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => const MainNavigation(),
        ),
      );
    }
  }
}

// Private auth card widget
class _AuthCard extends StatelessWidget {
  final VoidCallback onGoogleSignIn;
  final VoidCallback onDemoMode;

  const _AuthCard({
    required this.onGoogleSignIn,
    required this.onDemoMode,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return Container(
          constraints: const BoxConstraints(maxWidth: 420),
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: const Color(0xFF1D2A3B), // SURFACE_DARK_2
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: const Color(0xFF3B82F6).withOpacity(0.3), // PRIMARY with opacity
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.24),
                blurRadius: 48,
                offset: const Offset(0, 24),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // App mark
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: const Color(0xFF3B82F6), // PRIMARY
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.trending_up,
                  size: 40,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 24),
              
              // Title
              Text(
                'STOX',
                style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                  color: const Color(0xFFE9F1FF), // TEXT_PRIMARY
                  fontSize: 36,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 4,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Trading Simulator',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: const Color(0xFFA7B4C7), // TEXT_SECONDARY
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(height: 32),
              
              // Disclaimer
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF59E0B).withOpacity(0.1), // WARNING with opacity
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: const Color(0xFFF59E0B).withOpacity(0.3),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.info_outline,
                      color: Color(0xFFF59E0B), // WARNING
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Practice trading with virtual currency only',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: const Color(0xFFF59E0B), // WARNING
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              
              // Sign-In Button
              Consumer<AuthProvider>(
                builder: (context, authProvider, child) {
                  return SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: authProvider.isLoading ? null : onGoogleSignIn,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF3B82F6), // PRIMARY
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 0,
                      ),
                      child: authProvider.isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : Text(
                              'Sign In with Google',
                              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 16),
              
              // Demo Mode Button
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: onDemoMode,
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(
                      color: const Color(0xFFA7B4C7).withOpacity(0.3), // TEXT_SECONDARY with opacity
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: Text(
                    'Continue as Demo User',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: const Color(0xFFA7B4C7), // TEXT_SECONDARY
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              
              // Terms text
              Text(
                'By continuing, you agree to our Terms of Service and Privacy Policy',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: const Color(0xFFA7B4C7).withOpacity(0.8), // TEXT_SECONDARY with opacity
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        );
      },
    );
  }
}