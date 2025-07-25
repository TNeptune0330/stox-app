import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../models/user_model.dart';
import '../../utils/responsive_utils.dart';
import '../main_navigation.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  
  @override
  void initState() {
    super.initState();
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              const Color(0xFF0a0a0a),
              const Color(0xFF1a1a1a),
              const Color(0xFF1565c0),
            ],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 100),
                  
                  // Game-like Logo and Title
                  Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(32),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1565c0),
                          borderRadius: BorderRadius.circular(25),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF1565c0).withOpacity(0.5),
                              blurRadius: 30,
                              offset: const Offset(0, 10),
                            ),
                          ],
                          border: Border.all(
                            color: const Color(0xFF42a5f5),
                            width: 2,
                          ),
                        ),
                        child: const Icon(
                          Icons.auto_graph,
                          size: 64,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 32),
                      
                      // Title
                      const Text(
                        'STOX',
                        style: TextStyle(
                          fontSize: 48,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          letterSpacing: 8,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'TRADING SIMULATOR',
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.white70,
                          letterSpacing: 3,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Practice Trading with Virtual Currency',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.white60,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        '⚠️ This is a simulation game using fictional currency',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.amber,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 40),
                  
                  // Game Features
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.1),
                        width: 1,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(
                              Icons.videogame_asset,
                              color: Color(0xFFf39c12),
                              size: 24,
                            ),
                            const SizedBox(width: 12),
                            Text(
                              'GAME FEATURES',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                color: const Color(0xFFf39c12),
                                letterSpacing: 1,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        const _FeatureItem(
                          icon: Icons.attach_money,
                          text: 'Start with \$10,000 Virtual Currency',
                          color: Color(0xFF27ae60),
                        ),
                        const _FeatureItem(
                          icon: Icons.trending_up,
                          text: 'Trade with Real Market Prices (Virtual Only)',
                          color: Color(0xFF3498db),
                        ),
                        const _FeatureItem(
                          icon: Icons.leaderboard,
                          text: 'Compete on Global Leaderboards',
                          color: Color(0xFFe74c3c),
                        ),
                        const _FeatureItem(
                          icon: Icons.emoji_events,
                          text: 'Unlock Trading Achievements',
                          color: Color(0xFFf39c12),
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 100),
                  
                  // Google Sign-In Primary Button
                  Consumer<AuthProvider>(
                    builder: (context, authProvider, child) {
                      return Container(
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFFf39c12), Color(0xFFe74c3c)],
                          ),
                          borderRadius: BorderRadius.circular(15),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFFf39c12).withOpacity(0.5),
                              blurRadius: 20,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: ElevatedButton.icon(
                          onPressed: authProvider.isLoading 
                              ? null 
                              : () => _handleGoogleSignIn(context),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 18),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15),
                            ),
                            elevation: 0,
                            shadowColor: Colors.transparent,
                          ),
                          icon: authProvider.isLoading 
                              ? const SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                  ),
                                )
                              : const Icon(Icons.login, size: 24),
                          label: Text(
                            authProvider.isLoading ? 'SIGNING IN...' : 'SIGN IN WITH GOOGLE',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Demo Mode Secondary Button
                  ElevatedButton(
                    onPressed: () => _handleDemoMode(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey.shade700,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(
                        vertical: ResponsiveUtils.isTablet(context) ? 20 : 16,
                        horizontal: ResponsiveUtils.isTablet(context) ? 32 : 16,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      'CONTINUE AS DEMO USER',
                      style: TextStyle(
                        fontSize: ResponsiveUtils.getFontSize(context, 16),
                        fontWeight: FontWeight.w600,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  
                  // Terms and Privacy
                  const Text(
                    'This is a trading simulation game using fictional currency.\nNo real money is involved. Real market prices are used for educational purposes only.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.white70,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'By continuing, you agree to our Terms of Service and Privacy Policy',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.white60,
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showSignInErrorDialog(BuildContext context, String error) {
    String title = 'Sign-In Error';
    String message = 'There was an issue with Google Sign-In.';
    
    // Check for specific error types
    if (error.contains('cancelled') || error.contains('canceled')) {
      title = 'Sign-In Cancelled';
      message = 'You cancelled the sign-in process. You can try again or use Demo Mode.';
    } else if (error.contains('network') || error.contains('connection')) {
      title = 'Network Error';
      message = 'Please check your internet connection and try again, or use Demo Mode.';
    } else {
      message = 'Google Sign-In encountered an error. You can try again or use Demo Mode.\n\nError: $error';
    }

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1a1a1a),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: Color(0xFF1565c0), width: 1),
          ),
          title: Row(
            children: [
              const Icon(
                Icons.error_outline,
                color: Color(0xFFe74c3c),
                size: 24,
              ),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          content: Text(
            message,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 14,
              height: 1.4,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              style: TextButton.styleFrom(
                foregroundColor: Colors.white70,
              ),
              child: const Text('Try Again'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _handleDemoMode(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1565c0),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('Use Demo Mode'),
            ),
          ],
        );
      },
    );
  }

  void _showGoogleSignInDisabledDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1a1a1a),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: Color(0xFF1565c0), width: 1),
          ),
          title: const Row(
            children: [
              Icon(
                Icons.construction,
                color: Color(0xFFf39c12),
                size: 24,
              ),
              SizedBox(width: 8),
              Text(
                'Under Maintenance',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          content: const Text(
            'Google Sign-In is temporarily disabled due to iOS compatibility issues. '
            'We are working on a fix.\n\n'
            'In the meantime, you can use the full trading simulator in Demo Mode with all features enabled.'
            '\n\n'
            '• Virtual \$10,000 starting balance\n'
            '• Real-time market data\n'
            '• Full portfolio management\n'
            '• Trading achievements\n'
            '• All app features',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 14,
              height: 1.4,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              style: TextButton.styleFrom(
                foregroundColor: Colors.white70,
              ),
              child: const Text('OK'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _handleDemoMode(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFf39c12),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('Try Demo Mode'),
            ),
          ],
        );
      },
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
          // Show error and fallback to demo mode
          _showSignInErrorDialog(context, authProvider.error!);
        }
      }
    } catch (e) {
      if (mounted) {
        _showSignInErrorDialog(context, e.toString());
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

class _FeatureItem extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color? color;
  
  const _FeatureItem({
    required this.icon,
    required this.text,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: (color ?? Colors.white).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: (color ?? Colors.white).withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Icon(
              icon,
              size: 20,
              color: color ?? Colors.white,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 15,
                color: Colors.white,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}