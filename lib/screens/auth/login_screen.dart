import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/ios_signin_test_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
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
                  
                  // Game-like Sign In Button
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
                              : const Icon(Icons.play_arrow, size: 24),
                          label: Text(
                            authProvider.isLoading ? 'LOADING...' : 'START TRADING SIMULATOR',
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
                  
                  // iOS Debug Test Button
                  if (Platform.isIOS) ...[
                    ElevatedButton(
                      onPressed: () async {
                        await IOSSignInTestService.testFullSignInFlow();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text(
                        'DEBUG: Test iOS Sign-In',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                  
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

  Future<void> _handleGoogleSignIn(BuildContext context) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    
    final success = await authProvider.signInWithGoogle();
    
    if (!success && authProvider.error != null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(authProvider.error!),
            backgroundColor: Colors.red,
          ),
        );
      }
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