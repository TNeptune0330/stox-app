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

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          const AppBarTitle(title: 'Settings'),
          
          SliverList(
            delegate: SliverChildListDelegate([
              // User Profile Section
              Consumer<AuthProvider>(
                builder: (context, authProvider, child) {
                  if (authProvider.isLoading) {
                    return Card(
                      margin: const EdgeInsets.all(16),
                      child: const ListTile(
                        leading: CircleAvatar(
                          child: CircularProgressIndicator(),
                        ),
                        title: Text('Loading...'),
                        subtitle: Text('Please wait'),
                      ),
                    );
                  }

                  if (authProvider.user == null) {
                    return Card(
                      margin: const EdgeInsets.all(16),
                      child: ListTile(
                        leading: const CircleAvatar(
                          child: Icon(Icons.person_outline),
                        ),
                        title: const Text('Guest User'),
                        subtitle: const Text('Sign in to save your progress'),
                        trailing: const Icon(Icons.arrow_forward_ios),
                        onTap: () {
                          Navigator.pushReplacementNamed(context, '/login');
                        },
                      ),
                    );
                  }

                  return Card(
                    margin: const EdgeInsets.all(16),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundImage: authProvider.user!.avatarUrl != null
                            ? NetworkImage(authProvider.user!.avatarUrl!)
                            : null,
                        child: authProvider.user!.avatarUrl == null
                            ? Text(
                                authProvider.user!.username?.substring(0, 1).toUpperCase() ?? 
                                authProvider.user!.email.substring(0, 1).toUpperCase(),
                              )
                            : null,
                      ),
                      title: Text(
                        authProvider.user!.username ?? 'User',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(authProvider.user!.email),
                          const SizedBox(height: 4),
                          Text(
                            'Cash Balance: \$${authProvider.user!.cashBalance.toStringAsFixed(2)}',
                            style: const TextStyle(
                              color: Colors.green,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      trailing: const Icon(Icons.arrow_forward_ios),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const ProfileEditScreen(),
                          ),
                        );
                      },
                    ),
                  );
                },
              ),

              // Theme Section
              Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(
                        'Theme',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Consumer<ThemeProvider>(
                      builder: (context, themeProvider, child) {
                        return Column(
                          children: ThemeProvider.themes.map((theme) {
                            return RadioListTile<String>(
                              value: theme['value'],
                              groupValue: themeProvider.selectedTheme,
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
                              title: Text(theme['name']),
                              secondary: Icon(
                                theme['icon'],
                                color: theme['color'],
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
              Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ListTile(
                  leading: const Icon(Icons.palette, color: Colors.purple),
                  title: const Text('5-Color Design System'),
                  subtitle: const Text('See the new simplified color palette'),
                  trailing: const Icon(Icons.arrow_forward_ios),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const FiveColorDemoScreen(),
                      ),
                    );
                  },
                ),
              ),

              // App Info Section
              Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Column(
                  children: [
                    ListTile(
                      leading: const Icon(Icons.info_outline),
                      title: const Text('About'),
                      subtitle: const Text('App version and info'),
                      trailing: const Icon(Icons.arrow_forward_ios),
                      onTap: () {
                        showAboutDialog(
                          context: context,
                          applicationName: 'Stox',
                          applicationVersion: '1.0.0',
                          applicationIcon: const Icon(Icons.trending_up),
                          children: [
                            const Text(
                              'A stock trading simulator with real market data. '
                              'Practice trading without risking real money.',
                            ),
                          ],
                        );
                      },
                    ),
                    ListTile(
                      leading: const Icon(Icons.help_outline),
                      title: const Text('Help & Support'),
                      subtitle: const Text('Get help with using the app'),
                      trailing: const Icon(Icons.arrow_forward_ios),
                      onTap: () {
                        // TODO: Implement help screen
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Help & Support coming soon!'),
                          ),
                        );
                      },
                    ),
                    ListTile(
                      leading: const Icon(Icons.description_outlined),
                      title: const Text('Terms of Service'),
                      subtitle: const Text('App terms and conditions'),
                      trailing: const Icon(Icons.arrow_forward_ios),
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
                    ListTile(
                      leading: const Icon(Icons.privacy_tip_outlined),
                      title: const Text('Privacy Policy'),
                      subtitle: const Text('How we protect your data'),
                      trailing: const Icon(Icons.arrow_forward_ios),
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
                Card(
                  margin: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      ListTile(
                        leading: const Icon(Icons.bug_report, color: Colors.orange),
                        title: const Text('Auth Test Screen'),
                        subtitle: const Text('Test authentication flow'),
                        trailing: const Icon(Icons.arrow_forward_ios),
                        onTap: () {
                          Navigator.pushNamed(context, '/auth-test');
                        },
                      ),
                      ListTile(
                        leading: const Icon(Icons.login, color: Colors.blue),
                        title: const Text('Auth Flow Test'),
                        subtitle: const Text('Complete sign-in/sign-out flow test'),
                        trailing: const Icon(Icons.arrow_forward_ios),
                        onTap: () {
                          Navigator.pushNamed(context, '/auth-flow-test');
                        },
                      ),
                    ],
                  ),
                ),

              // Sign Out Section
              Card(
                margin: const EdgeInsets.all(16),
                child: ListTile(
                  leading: const Icon(Icons.logout, color: Colors.red),
                  title: const Text(
                    'Sign Out',
                    style: TextStyle(color: Colors.red),
                  ),
                  onTap: () => _showSignOutDialog(context),
                ),
              ),
            ]),
          ),
        ],
      ),
    );
  }

  void _showSignOutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sign Out'),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
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
                  foregroundColor: Colors.red,
                ),
                child: authProvider.isLoading
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
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