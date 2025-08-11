import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../models/user_model.dart';
import '../../theme/modern_theme.dart';
import '../../widgets/animations/animations.dart';
import '../main_navigation.dart';

class ModernSignInScreen extends StatefulWidget {
  const ModernSignInScreen({super.key});

  @override
  State<ModernSignInScreen> createState() => _ModernSignInScreenState();
}

class _ModernSignInScreenState extends State<ModernSignInScreen> {
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ModernTheme.backgroundPrimary,
      body: SafeArea(
        child: SingleChildScrollView(
          child: PageEntryAnimations.staggeredSlideIn(
            children: [
              _buildHeader(),
              _buildFeatures(),
              _buildSignInOptions(),
              _buildFooter(),
            ],
            delay: const Duration(milliseconds: 100),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(ModernTheme.spaceXL),
      child: Column(
        children: [
          const SizedBox(height: 60),
          
          // Modern Logo
          PageEntryAnimations.floatIn(
            delay: const Duration(milliseconds: 200),
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    ModernTheme.accentBlue,
                    ModernTheme.accentPurple,
                  ],
                ),
                borderRadius: BorderRadius.circular(30),
                boxShadow: [
                  BoxShadow(
                    color: ModernTheme.accentBlue.withOpacity(0.3),
                    blurRadius: 30,
                    offset: const Offset(0, 15),
                  ),
                ],
              ),
              child: const Icon(
                Icons.trending_up,
                size: 60,
                color: Colors.white,
              ),
            ),
          ),
          
          const SizedBox(height: ModernTheme.spaceXL),
          
          // App Name
          PageEntryAnimations.fadeSlideIn(
            delay: const Duration(milliseconds: 400),
            child: Text(
              'STOX',
              style: ModernTheme.displayLarge.copyWith(
                fontWeight: FontWeight.w900,
                letterSpacing: 8,
                color: ModernTheme.textPrimary,
              ),
            ),
          ),
          
          const SizedBox(height: ModernTheme.spaceS),
          
          // Tagline
          PageEntryAnimations.fadeSlideIn(
            delay: const Duration(milliseconds: 500),
            child: Text(
              'Trading Simulator',
              style: ModernTheme.titleLarge.copyWith(
                color: ModernTheme.textSecondary,
                letterSpacing: 2,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          
          const SizedBox(height: ModernTheme.spaceM),
          
          // Subtitle
          PageEntryAnimations.fadeSlideIn(
            delay: const Duration(milliseconds: 600),
            child: Text(
              'Master the markets with virtual currency',
              style: ModernTheme.bodyLarge.copyWith(
                color: ModernTheme.textMuted,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          
          const SizedBox(height: ModernTheme.spaceM),
          
          // Disclaimer
          PageEntryAnimations.fadeSlideIn(
            delay: const Duration(milliseconds: 700),
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: ModernTheme.spaceM,
                vertical: ModernTheme.spaceS,
              ),
              decoration: BoxDecoration(
                color: ModernTheme.accentOrange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(ModernTheme.radiusM),
                border: Border.all(
                  color: ModernTheme.accentOrange.withOpacity(0.3),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.info_outline,
                    color: ModernTheme.accentOrange,
                    size: 16,
                  ),
                  const SizedBox(width: ModernTheme.spaceS),
                  Text(
                    'Simulation using virtual currency only',
                    style: ModernTheme.bodySmall.copyWith(
                      color: ModernTheme.accentOrange,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatures() {
    final features = [
      _FeatureData(
        icon: Icons.account_balance_wallet,
        title: '\$10,000 Starting Balance',
        subtitle: 'Begin with virtual funds',
        color: ModernTheme.accentGreen,
      ),
      _FeatureData(
        icon: Icons.show_chart,
        title: 'Real Market Data',
        subtitle: 'Live prices, virtual trades',
        color: ModernTheme.accentBlue,
      ),
      _FeatureData(
        icon: Icons.emoji_events,
        title: 'Achievements',
        subtitle: 'Unlock trading milestones',
        color: ModernTheme.accentOrange,
      ),
      _FeatureData(
        icon: Icons.leaderboard,
        title: 'Compete',
        subtitle: 'Global leaderboards',
        color: ModernTheme.accentPurple,
      ),
    ];

    return PageEntryAnimations.fadeSlideIn(
      delay: const Duration(milliseconds: 800),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: ModernTheme.spaceL),
        child: Container(
          padding: const EdgeInsets.all(ModernTheme.spaceL),
          decoration: BoxDecoration(
            color: ModernTheme.backgroundCard,
            borderRadius: BorderRadius.circular(ModernTheme.radiusXL),
            boxShadow: ModernTheme.shadowCard,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.stars,
                    color: ModernTheme.accentBlue,
                    size: 24,
                  ),
                  const SizedBox(width: ModernTheme.spaceM),
                  Text(
                    'Features',
                    style: ModernTheme.titleLarge.copyWith(
                      fontWeight: FontWeight.bold,
                      color: ModernTheme.textPrimary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: ModernTheme.spaceL),
              ...features.asMap().entries.map((entry) {
                final index = entry.key;
                final feature = entry.value;
                return PageEntryAnimations.fadeSlideIn(
                  delay: Duration(milliseconds: 900 + (index * 100)),
                  child: _buildFeatureItem(feature),
                );
              }).toList(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureItem(_FeatureData feature) {
    return Padding(
      padding: const EdgeInsets.only(bottom: ModernTheme.spaceM),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: feature.color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(ModernTheme.radiusM),
              border: Border.all(
                color: feature.color.withOpacity(0.3),
              ),
            ),
            child: Icon(
              feature.icon,
              color: feature.color,
              size: 24,
            ),
          ),
          const SizedBox(width: ModernTheme.spaceM),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  feature.title,
                  style: ModernTheme.bodyLarge.copyWith(
                    fontWeight: FontWeight.bold,
                    color: ModernTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  feature.subtitle,
                  style: ModernTheme.bodyMedium.copyWith(
                    color: ModernTheme.textMuted,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSignInOptions() {
    return PageEntryAnimations.fadeSlideIn(
      delay: const Duration(milliseconds: 1200),
      child: Padding(
        padding: const EdgeInsets.all(ModernTheme.spaceXL),
        child: Column(
          children: [
            // Google Sign-In Button
            Consumer<AuthProvider>(
              builder: (context, authProvider, child) {
                return PageEntryAnimations.popIn(
                  delay: const Duration(milliseconds: 1300),
                  child: HoverEffects.scaleOnHover(
                    child: Microinteractions.animatedButton(
                      onPressed: authProvider.isLoading 
                          ? null 
                          : () => _handleGoogleSignIn(context),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(ModernTheme.spaceL),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              ModernTheme.accentBlue,
                              ModernTheme.accentPurple,
                            ],
                          ),
                          borderRadius: BorderRadius.circular(ModernTheme.radiusL),
                          boxShadow: [
                            BoxShadow(
                              color: ModernTheme.accentBlue.withOpacity(0.3),
                              blurRadius: 15,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            if (authProvider.isLoading)
                              const SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                ),
                              )
                            else
                              const Icon(
                                Icons.login,
                                color: Colors.white,
                                size: 24,
                              ),
                            const SizedBox(width: ModernTheme.spaceM),
                            Text(
                              authProvider.isLoading 
                                  ? 'SIGNING IN...' 
                                  : 'SIGN IN WITH GOOGLE',
                              style: ModernTheme.titleMedium.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
            
            const SizedBox(height: ModernTheme.spaceL),
            
            // Demo Mode Button
            PageEntryAnimations.popIn(
              delay: const Duration(milliseconds: 1400),
              child: HoverEffects.scaleOnHover(
                child: Microinteractions.animatedButton(
                  onPressed: () => _handleDemoMode(context),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(ModernTheme.spaceL),
                    decoration: BoxDecoration(
                      color: ModernTheme.backgroundCard,
                      borderRadius: BorderRadius.circular(ModernTheme.radiusL),
                      border: Border.all(
                        color: ModernTheme.borderLight,
                        width: 2,
                      ),
                      boxShadow: ModernTheme.shadowCard,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.play_arrow,
                          color: ModernTheme.textSecondary,
                          size: 24,
                        ),
                        const SizedBox(width: ModernTheme.spaceM),
                        Text(
                          'TRY DEMO MODE',
                          style: ModernTheme.titleMedium.copyWith(
                            color: ModernTheme.textSecondary,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFooter() {
    return PageEntryAnimations.fadeSlideIn(
      delay: const Duration(milliseconds: 1500),
      child: Padding(
        padding: const EdgeInsets.all(ModernTheme.spaceXL),
        child: Column(
          children: [
            Text(
              'This is a trading simulation using virtual currency.\nNo real money is involved.',
              textAlign: TextAlign.center,
              style: ModernTheme.bodyMedium.copyWith(
                color: ModernTheme.textMuted,
                height: 1.5,
              ),
            ),
            const SizedBox(height: ModernTheme.spaceM),
            Text(
              'By continuing, you agree to our Terms & Privacy Policy',
              textAlign: TextAlign.center,
              style: ModernTheme.bodySmall.copyWith(
                color: ModernTheme.textMuted.withOpacity(0.7),
              ),
            ),
          ],
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
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (context) => const MainNavigation(),
            ),
          );
        } else if (authProvider.error != null) {
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
          backgroundColor: ModernTheme.backgroundCard,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(ModernTheme.radiusXL),
          ),
          title: Row(
            children: [
              Icon(
                Icons.error_outline,
                color: ModernTheme.accentRed,
                size: 24,
              ),
              const SizedBox(width: ModernTheme.spaceS),
              Text(
                title,
                style: ModernTheme.titleLarge.copyWith(
                  color: ModernTheme.textPrimary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          content: Text(
            message,
            style: ModernTheme.bodyMedium.copyWith(
              color: ModernTheme.textSecondary,
              height: 1.4,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'Try Again',
                style: TextStyle(color: ModernTheme.textMuted),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _handleDemoMode(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: ModernTheme.accentBlue,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(ModernTheme.radiusM),
                ),
              ),
              child: const Text('Use Demo Mode'),
            ),
          ],
        );
      },
    );
  }
}

class _FeatureData {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;

  _FeatureData({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
  });
}