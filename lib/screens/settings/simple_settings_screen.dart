import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../theme/modern_theme.dart';
import '../legal/terms_of_service_screen.dart';
import '../legal/privacy_policy_screen.dart';
import '../legal/help_support_screen.dart';
import '../main_navigation.dart';

class SimpleSettingsScreen extends StatefulWidget {
  const SimpleSettingsScreen({super.key});
  
  @override
  State<SimpleSettingsScreen> createState() => _SimpleSettingsScreenState();
}

class _SimpleSettingsScreenState extends State<SimpleSettingsScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ModernTheme.backgroundPrimary,
      resizeToAvoidBottomInset: false,
      body: CustomScrollView(
        slivers: [
          // Modern App Bar with Colorful Header
          SliverAppBar(
            expandedHeight: 120,
            floating: false,
            pinned: true,
            backgroundColor: ModernTheme.backgroundPrimary,
            foregroundColor: ModernTheme.textPrimary,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      ModernTheme.accentBlue,
                      ModernTheme.accentPurple,
                    ],
                  ),
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.settings,
                          size: 36,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'SETTINGS',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          letterSpacing: 2,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          
          // Content
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
            // User Profile Section
            Consumer<AuthProvider>(
              builder: (context, authProvider, child) {
                if (authProvider.isLoading) {
                  return Card(
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      child: Row(
                        children: [
                          SizedBox(
                            width: 60,
                            height: 60,
                            child: CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation<Color>(ModernTheme.accentBlue),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Loading...',
                                style: ModernTheme.titleLarge,
                              ),
                              Text(
                                'Please wait',
                                style: ModernTheme.bodyMedium,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                }

                if (authProvider.user == null) {
                  return Card(
                    child: InkWell(
                      onTap: () {
                        Navigator.pushReplacementNamed(context, '/login');
                      },
                      borderRadius: BorderRadius.circular(ModernTheme.radiusL),
                      child: Container(
                        padding: const EdgeInsets.all(20),
                        child: Row(
                          children: [
                            Container(
                              width: 60,
                              height: 60,
                              decoration: BoxDecoration(
                                color: ModernTheme.textMuted.withOpacity(0.1),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.person_outline,
                                size: 30,
                                color: ModernTheme.textSecondary,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Guest User',
                                    style: ModernTheme.titleLarge,
                                  ),
                                  Text(
                                    'Sign in to save your progress',
                                    style: ModernTheme.bodyMedium,
                                  ),
                                ],
                              ),
                            ),
                            Icon(
                              Icons.arrow_forward_ios,
                              color: ModernTheme.accentBlue,
                              size: 20,
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }

                return Card(
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 30,
                          backgroundColor: ModernTheme.accentBlue.withOpacity(0.1),
                          child: Text(
                            authProvider.user!.username?.substring(0, 1).toUpperCase() ?? 'U',
                            style: ModernTheme.headlineMedium.copyWith(
                              color: ModernTheme.accentBlue,
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                authProvider.user!.username ?? 'User',
                                style: ModernTheme.titleLarge,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                authProvider.user!.email,
                                style: ModernTheme.bodyMedium,
                              ),
                              const SizedBox(height: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: ModernTheme.accentGreen.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: ModernTheme.accentGreen.withOpacity(0.3),
                                  ),
                                ),
                                child: Text(
                                  'Balance: \$${authProvider.user!.cashBalance.toStringAsFixed(2)}',
                                  style: ModernTheme.labelMedium.copyWith(
                                    color: ModernTheme.accentGreen,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),

            const SizedBox(height: ModernTheme.spaceL),

            // App Settings Section
            Card(
              child: Column(
                children: [
                  _buildSettingsTile(
                    icon: Icons.info_outline,
                    title: 'About',
                    subtitle: 'App version and info',
                    onTap: () {
                      showAboutDialog(
                        context: context,
                        applicationName: 'Stox',
                        applicationVersion: '1.0.0',
                        applicationIcon: const Icon(
                          Icons.trending_up,
                          size: 32,
                        ),
                        children: [
                          Text(
                            'A stock trading simulator with real market data. '
                            'Practice trading without risking real money.',
                            style: ModernTheme.bodyMedium,
                          ),
                        ],
                      );
                    },
                  ),
                  const Divider(height: 1),
                  _buildSettingsTile(
                    icon: Icons.help_outline,
                    title: 'Help & Support',
                    subtitle: 'Get help with using the app',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const HelpSupportScreen(),
                        ),
                      );
                    },
                  ),
                  const Divider(height: 1),
                  _buildSettingsTile(
                    icon: Icons.description_outlined,
                    title: 'Terms of Service',
                    subtitle: 'App terms and conditions',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const TermsOfServiceScreen(),
                        ),
                      );
                    },
                  ),
                  const Divider(height: 1),
                  _buildSettingsTile(
                    icon: Icons.privacy_tip_outlined,
                    title: 'Privacy Policy',
                    subtitle: 'How we protect your data',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const PrivacyPolicyScreen(),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),

            const SizedBox(height: ModernTheme.spaceL),

            // Tutorial Section
            Card(
              child: _buildSettingsTile(
                icon: Icons.school,
                title: 'Replay Tutorial',
                subtitle: 'Learn how to use the app again',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const MainNavigation(),
                    ),
                  );
                },
              ),
            ),

                  const SizedBox(height: ModernTheme.spaceL),

                  // Sign Out Section
                  Consumer<AuthProvider>(
                    builder: (context, authProvider, child) {
                      if (authProvider.user == null) {
                        return const SizedBox.shrink();
                      }
                      
                      return Card(
                        child: InkWell(
                          onTap: () => _showSignOutDialog(context, authProvider),
                          borderRadius: BorderRadius.circular(ModernTheme.radiusL),
                          child: Container(
                            padding: const EdgeInsets.all(20),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: ModernTheme.accentRed.withOpacity(0.1),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    Icons.logout,
                                    color: ModernTheme.accentRed,
                                    size: 24,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Text(
                                    'Sign Out',
                                    style: ModernTheme.titleMedium.copyWith(
                                      color: ModernTheme.accentRed,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                                Icon(
                                  Icons.arrow_forward_ios,
                                  color: ModernTheme.accentRed,
                                  size: 18,
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    Color? iconColor,
  }) {
    // Define colors for different settings
    final settingColors = {
      Icons.info_outline: ModernTheme.accentBlue,
      Icons.help_outline: ModernTheme.accentGreen,
      Icons.description_outlined: ModernTheme.accentOrange,
      Icons.privacy_tip_outlined: ModernTheme.accentPurple,
      Icons.school: ModernTheme.accentPink,
    };
    
    final color = iconColor ?? settingColors[icon] ?? ModernTheme.accentBlue;
    
    return AnimatedContainer(
      duration: ModernTheme.animationFast,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(ModernTheme.radiusM),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(ModernTheme.radiusM),
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: ModernTheme.titleMedium.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: ModernTheme.bodyMedium.copyWith(
                        color: ModernTheme.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                color: ModernTheme.textMuted,
                size: 16,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showSignOutDialog(BuildContext context, AuthProvider authProvider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: ModernTheme.backgroundPrimary,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Text(
          'Sign Out',
          style: ModernTheme.headlineMedium,
        ),
        content: Text(
          'Are you sure you want to sign out?',
          style: ModernTheme.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: authProvider.isLoading ? null : () async {
              Navigator.of(context).pop();
              await authProvider.signOut();
              
              // Navigate to login screen after sign out
              if (context.mounted) {
                Navigator.pushReplacementNamed(context, '/login');
              }
            },
            style: TextButton.styleFrom(
              foregroundColor: ModernTheme.accentRed,
            ),
            child: authProvider.isLoading
                ? SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(ModernTheme.accentRed),
                    ),
                  )
                : const Text('Sign Out'),
          ),
        ],
      ),
    );
  }
}