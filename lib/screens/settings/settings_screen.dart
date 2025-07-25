import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/theme_provider.dart';
import '../main_navigation.dart';
import '../legal/legal_document_screen.dart';
import 'profile_edit_screen.dart';
import 'color_picker_screen.dart';
import 'five_color_demo_screen.dart';
import '../../widgets/profile_picture_widget.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return Scaffold(
          backgroundColor: themeProvider.background,
          body: CustomScrollView(
            slivers: [
              const AppBarTitle(title: 'Settings'),
              
              SliverList(
                delegate: SliverChildListDelegate([
                  // User Profile Section
                  Consumer<AuthProvider>(
                    builder: (context, authProvider, child) {
                      if (authProvider.isLoading) {
                        return Container(
                          margin: const EdgeInsets.all(16),
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: themeProvider.backgroundHigh,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: themeProvider.theme.withOpacity(0.2),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              SizedBox(
                                width: 60,
                                height: 60,
                                child: CircularProgressIndicator(
                                  valueColor: AlwaysStoppedAnimation<Color>(themeProvider.theme),
                                  backgroundColor: themeProvider.themeHigh.withOpacity(0.3),
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
                                      color: themeProvider.isDark ? Colors.white : Colors.black,
                                    ),
                                  ),
                                  Text(
                                    'Please wait',
                                    style: TextStyle(
                                      color: themeProvider.themeHigh,
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
                        return Container(
                          margin: const EdgeInsets.all(16),
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: themeProvider.backgroundHigh,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: themeProvider.contrast.withOpacity(0.3),
                              width: 1,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: themeProvider.contrast.withOpacity(0.1),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: GestureDetector(
                            onTap: () {
                              Navigator.pushReplacementNamed(context, '/login');
                            },
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
                                          color: themeProvider.isDark ? Colors.white : Colors.black,
                                        ),
                                      ),
                                      Text(
                                        'Sign in to save your progress',
                                        style: TextStyle(
                                          color: themeProvider.isDark ? Colors.white70 : Colors.black54,
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

                      return Container(
                        margin: const EdgeInsets.all(16),
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: themeProvider.backgroundHigh,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: themeProvider.theme.withOpacity(0.2),
                            width: 1,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: themeProvider.theme.withOpacity(0.1),
                              blurRadius: 12,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const ProfileEditScreen(),
                              ),
                            );
                          },
                          child: Row(
                            children: [
                              ProfilePictureWidget(
                                size: 80,
                                showEditButton: true,
                                onImageChanged: () {
                                  // Trigger UI refresh when image changes
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
                                        color: themeProvider.isDark ? Colors.white : Colors.black,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      authProvider.user!.email,
                                      style: TextStyle(
                                        color: themeProvider.isDark ? Colors.white70 : Colors.black54,
                                        fontSize: 14,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                      decoration: BoxDecoration(
                                        color: themeProvider.themeHigh.withOpacity(0.2),
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: themeProvider.themeHigh.withOpacity(0.5),
                                          width: 1,
                                        ),
                                      ),
                                      child: Text(
                                        'Balance: \$${authProvider.user!.cashBalance.toStringAsFixed(2)}',
                                        style: TextStyle(
                                          color: themeProvider.themeHigh,
                                          fontWeight: FontWeight.w600,
                                          fontSize: 14,
                                        ),
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
                  ),

                  // Theme Section
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: themeProvider.backgroundHigh,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: themeProvider.theme.withOpacity(0.2),
                        width: 1,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.centerLeft,
                              end: Alignment.centerRight,
                              colors: [
                                themeProvider.theme.withOpacity(0.1),
                                themeProvider.themeHigh.withOpacity(0.05),
                              ],
                            ),
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(16),
                              topRight: Radius.circular(16),
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.palette,
                                color: themeProvider.theme,
                                size: 24,
                              ),
                              const SizedBox(width: 12),
                              Text(
                                'Themes',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: themeProvider.isDark ? Colors.white : Colors.black,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Consumer<ThemeProvider>(
                          builder: (context, themeProvider, child) {
                            return Column(
                              children: ThemeProvider.themes.map((theme) {
                                final isSelected = themeProvider.selectedTheme == theme['value'];
                                return Container(
                                  margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: isSelected 
                                        ? themeProvider.theme.withOpacity(0.1)
                                        : Colors.transparent,
                                    borderRadius: BorderRadius.circular(12),
                                    border: isSelected
                                        ? Border.all(
                                            color: themeProvider.theme.withOpacity(0.5),
                                            width: 1,
                                          )
                                        : null,
                                  ),
                                  child: RadioListTile<String>(
                                    value: theme['value'],
                                    groupValue: themeProvider.selectedTheme,
                                    activeColor: themeProvider.theme,
                                    onChanged: (value) {
                                      if (value != null) {
                                        if (value == 'custom') {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) => const ColorPickerScreen(),
                                            ),
                                          );
                                        } else {
                                          themeProvider.setTheme(value);
                                          
                                          // Update user theme in database
                                          final authProvider = Provider.of<AuthProvider>(
                                            context, 
                                            listen: false,
                                          );
                                          authProvider.updateProfile(colorTheme: value);
                                        }
                                      }
                                    },
                                    title: Text(
                                      theme['name'],
                                      style: TextStyle(
                                        color: themeProvider.isDark ? Colors.white : Colors.black,
                                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                                      ),
                                    ),
                                    secondary: Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: (theme['color'] as Color).withOpacity(0.2),
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(
                                        theme['icon'],
                                        color: theme['color'],
                                        size: 20,
                                      ),
                                    ),
                                  ),
                                );
                              }).toList(),
                            );
                          },
                        ),
                      ],
                    ),
                  ),

                  // 5-Color Design System Demo
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: themeProvider.backgroundHigh,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: themeProvider.themeHigh.withOpacity(0.3),
                        width: 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: themeProvider.themeHigh.withOpacity(0.1),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const FiveColorDemoScreen(),
                          ),
                        );
                      },
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    themeProvider.themeHigh,
                                    themeProvider.theme,
                                  ],
                                ),
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: themeProvider.themeHigh.withOpacity(0.3),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.color_lens,
                                color: Colors.white,
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '5-Color Design System',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: themeProvider.isDark ? Colors.white : Colors.black,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'See the new simplified color palette in action',
                                    style: TextStyle(
                                      color: themeProvider.isDark ? Colors.white70 : Colors.black54,
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Icon(
                              Icons.arrow_forward_ios,
                              color: themeProvider.theme,
                              size: 18,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // App Info Section
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: themeProvider.backgroundHigh,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: themeProvider.contrast.withOpacity(0.2),
                        width: 1,
                      ),
                    ),
                    child: Column(
                      children: [
                        _buildInfoTile(
                          icon: Icons.info_outline,
                          title: 'About',
                          subtitle: 'App version and info',
                          color: themeProvider.themeHigh,
                          themeProvider: themeProvider,
                          onTap: () {
                            showAboutDialog(
                              context: context,
                              applicationName: 'Stox',
                              applicationVersion: '1.0.0',
                              applicationIcon: Icon(
                                Icons.trending_up,
                                color: themeProvider.theme,
                                size: 32,
                              ),
                              children: [
                                Text(
                                  'A stock trading simulator with real market data. '
                                  'Practice trading without risking real money.',
                                  style: TextStyle(
                                    color: themeProvider.isDark ? Colors.white70 : Colors.black87,
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                        Divider(
                          color: themeProvider.theme.withOpacity(0.1),
                          height: 1,
                          indent: 16,
                          endIndent: 16,
                        ),
                        _buildInfoTile(
                          icon: Icons.help_outline,
                          title: 'Help & Support',
                          subtitle: 'Get help with using the app',
                          color: themeProvider.theme,
                          themeProvider: themeProvider,
                          onTap: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: const Text('Help & Support coming soon!'),
                                backgroundColor: themeProvider.theme,
                                behavior: SnackBarBehavior.floating,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            );
                          },
                        ),
                        Divider(
                          color: themeProvider.theme.withOpacity(0.1),
                          height: 1,
                          indent: 16,
                          endIndent: 16,
                        ),
                        _buildInfoTile(
                          icon: Icons.description_outlined,
                          title: 'Terms of Service',
                          subtitle: 'App terms and conditions',
                          color: themeProvider.contrast,
                          themeProvider: themeProvider,
                          onTap: () {
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
                        Divider(
                          color: themeProvider.theme.withOpacity(0.1),
                          height: 1,
                          indent: 16,
                          endIndent: 16,
                        ),
                        _buildInfoTile(
                          icon: Icons.privacy_tip_outlined,
                          title: 'Privacy Policy',
                          subtitle: 'How we protect your data',
                          color: themeProvider.themeHigh,
                          themeProvider: themeProvider,
                          onTap: () {
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
                      ],
                    ),
                  ),

                  // Debug Section (only show in debug mode)
                  if (kDebugMode)
                    Container(
                      margin: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: themeProvider.backgroundHigh,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: Colors.orange.withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                      child: Column(
                        children: [
                          _buildInfoTile(
                            icon: Icons.bug_report,
                            title: 'Auth Test Screen',
                            subtitle: 'Test authentication flow',
                            color: Colors.orange,
                            themeProvider: themeProvider,
                            onTap: () {
                              Navigator.pushNamed(context, '/auth-test');
                            },
                          ),
                          Divider(
                            color: Colors.orange.withOpacity(0.2),
                            height: 1,
                            indent: 16,
                            endIndent: 16,
                          ),
                          _buildInfoTile(
                            icon: Icons.login,
                            title: 'Auth Flow Test',
                            subtitle: 'Complete sign-in/sign-out flow test',
                            color: Colors.blue,
                            themeProvider: themeProvider,
                            onTap: () {
                              Navigator.pushNamed(context, '/auth-flow-test');
                            },
                          ),
                        ],
                      ),
                    ),

                  // Sign Out Section
                  Container(
                    margin: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: themeProvider.backgroundHigh,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: themeProvider.contrast.withOpacity(0.3),
                        width: 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: themeProvider.contrast.withOpacity(0.1),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: GestureDetector(
                      onTap: () => _showSignOutDialog(context, themeProvider),
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: themeProvider.contrast.withOpacity(0.1),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.logout,
                                color: themeProvider.contrast,
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Text(
                                'Sign Out',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: themeProvider.contrast,
                                ),
                              ),
                            ),
                            Icon(
                              Icons.arrow_forward_ios,
                              color: themeProvider.contrast,
                              size: 18,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ]),
              ),
            ],
          ),
        );
      },
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
                      color: themeProvider.isDark ? Colors.white : Colors.black,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 14,
                      color: themeProvider.isDark ? Colors.white70 : Colors.black54,
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
        backgroundColor: themeProvider.backgroundHigh,
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
            color: themeProvider.isDark ? Colors.white : Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          'Are you sure you want to sign out?',
          style: TextStyle(
            color: themeProvider.isDark ? Colors.white70 : Colors.black87,
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
                  foregroundColor: Colors.white,
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
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
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