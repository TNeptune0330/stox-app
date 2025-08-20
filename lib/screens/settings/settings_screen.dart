import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/theme_provider.dart';
import '../main_navigation.dart';
import '../legal/legal_document_screen.dart';
import '../tutorial/tutorial_screen.dart';
import 'profile_edit_screen.dart';
import 'color_picker_screen.dart';
import '../../widgets/profile_picture_widget.dart';
import '../admin/analytics_screen.dart';
import '../support/support_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});
  
  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _isThemeExpanded = false;

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return Scaffold(
          backgroundColor: themeProvider.background,
          body: CustomScrollView(
            slivers: [
              // Simple app bar
              SliverAppBar(
                backgroundColor: themeProvider.background,
                elevation: 0,
                pinned: true,
                title: Text(
                  'Settings',
                  style: Theme.of(context).textTheme.headlineLarge,
                ),
              ),
              
              SliverPadding(
                padding: const EdgeInsets.all(16),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    // User Header Section
                    _buildUserHeader(themeProvider),
                    const SizedBox(height: 32),
                    
                    // Settings Items
                    _buildSettingsItem(
                      themeProvider,
                      Icons.description,
                      'Terms of Use',
                      () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => const LegalDocumentScreen(
                              title: 'Terms of Service',
                              assetPath: 'assets/legal/terms_of_service.md',
                              showAcceptButton: false,
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 8),
                    
                    _buildSettingsItem(
                      themeProvider,
                      Icons.privacy_tip,
                      'Privacy Policy',
                      () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => const LegalDocumentScreen(
                              title: 'Privacy Policy',
                              assetPath: 'assets/legal/privacy_policy.md',
                              showAcceptButton: false,
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 8),
                    
                    _buildSettingsItem(
                      themeProvider,
                      Icons.help_outline,
                      'Help & Support',
                      () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => const SupportScreen(),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 8),
                    
                    _buildSettingsItem(
                      themeProvider,
                      Icons.logout,
                      'Logout',
                      () => _showSignOutDialog(context, themeProvider),
                      isDestructive: true,
                    ),
                    
                    const SizedBox(height: 100), // Bottom padding for nav bar
                  ]),
                ),
              ),

            ],
          ),
        );
      },
    );
  }
  
  Widget _buildUserHeader(ThemeProvider themeProvider) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        if (authProvider.isLoading) {
          return Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: themeProvider.backgroundHigh,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: themeProvider.contrast.withOpacity(0.1)),
            ),
            child: Row(
              children: [
                SizedBox(
                  width: 60,
                  height: 60,
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(themeProvider.theme),
                  ),
                ),
                const SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Loading...',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: themeProvider.contrast,
                      ),
                    ),
                    Text(
                      'Please wait',
                      style: TextStyle(
                        color: themeProvider.contrast.withOpacity(0.7),
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        }

        if (authProvider.user == null) {
          return GestureDetector(
            onTap: () {
              Navigator.pushReplacementNamed(context, '/login');
            },
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: themeProvider.backgroundHigh,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: themeProvider.contrast.withOpacity(0.1)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.24),
                    blurRadius: 24,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: themeProvider.contrast.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.person_outline,
                      size: 30,
                      color: themeProvider.contrast,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Guest User',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: themeProvider.contrast,
                          ),
                        ),
                        Text(
                          'Sign in to save your progress',
                          style: TextStyle(
                            color: themeProvider.contrast.withOpacity(0.7),
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.arrow_forward_ios,
                    color: themeProvider.theme,
                    size: 20,
                  ),
                ],
              ),
            ),
          );
        }

        return GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const ProfileEditScreen(),
              ),
            );
          },
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: themeProvider.backgroundHigh,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: themeProvider.contrast.withOpacity(0.1)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.24),
                  blurRadius: 24,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Row(
              children: [
                ProfilePictureWidget(
                  size: 60,
                  showEditButton: false,
                  onImageChanged: () {
                    authProvider.notifyListeners();
                  },
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        authProvider.user!.username ?? 'User',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: themeProvider.contrast,
                        ),
                      ),
                      Text(
                        authProvider.user!.email,
                        style: TextStyle(
                          color: themeProvider.contrast.withOpacity(0.7),
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios,
                  color: themeProvider.theme,
                  size: 20,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
  
  Widget _buildSettingsItem(
    ThemeProvider themeProvider,
    IconData icon,
    String title,
    VoidCallback onTap, {
    bool isDestructive = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: themeProvider.backgroundHigh,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: themeProvider.contrast.withOpacity(0.1)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.24),
              blurRadius: 24,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: isDestructive 
                    ? const Color(0xFFEF4444).withOpacity(0.1) 
                    : themeProvider.theme.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: isDestructive ? const Color(0xFFEF4444) : themeProvider.theme,
                size: 22,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: isDestructive ? const Color(0xFFEF4444) : themeProvider.contrast,
                ),
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              color: themeProvider.contrast.withOpacity(0.5),
              size: 16,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required ThemeProvider themeProvider,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: color,
                size: 20,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: themeProvider.contrast,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 14,
                      color: themeProvider.contrast.withOpacity(0.7),
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              color: themeProvider.theme,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }

  void _showSignOutDialog(BuildContext context, ThemeProvider themeProvider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: themeProvider.theme.withOpacity(0.05),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: themeProvider.contrast.withOpacity(0.2),
            width: 1,
          ),
        ),
        title: Text(
          'Sign Out',
          style: TextStyle(
            color: themeProvider.contrast,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          'Are you sure you want to sign out?',
          style: TextStyle(
            color: themeProvider.contrast.withOpacity(0.8),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            style: TextButton.styleFrom(
              foregroundColor: themeProvider.theme,
              backgroundColor: themeProvider.theme.withOpacity(0.1),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('Cancel'),
          ),
          Consumer<AuthProvider>(
            builder: (context, authProvider, child) {
              return TextButton(
                onPressed: authProvider.isLoading ? null : () async {
                  Navigator.of(context).pop();
                  await authProvider.signOut();
                  
                  // Navigate to login screen after sign out
                  if (context.mounted) {
                    Navigator.pushReplacementNamed(context, '/login');
                  }
                },
                style: TextButton.styleFrom(
                  foregroundColor: themeProvider.contrast,
                  backgroundColor: themeProvider.contrast,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: authProvider.isLoading
                    ? SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(themeProvider.background),
                        ),
                      )
                    : const Text('Sign Out'),
              );
            },
          ),
        ],
      ),
    );
  }
}