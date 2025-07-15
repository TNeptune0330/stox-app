import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/theme_provider.dart';
import '../main_navigation.dart';
import 'profile_edit_screen.dart';

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
                  if (authProvider.user == null) {
                    return const SizedBox.shrink();
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
                      subtitle: Text(authProvider.user!.email),
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
                                  themeProvider.setTheme(value);
                                  
                                  // Update user theme in database
                                  final authProvider = Provider.of<AuthProvider>(
                                    context, 
                                    listen: false,
                                  );
                                  authProvider.updateProfile(colorTheme: value);
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
                      leading: const Icon(Icons.privacy_tip_outlined),
                      title: const Text('Privacy Policy'),
                      subtitle: const Text('Read our privacy policy'),
                      trailing: const Icon(Icons.arrow_forward_ios),
                      onTap: () {
                        // TODO: Implement privacy policy screen
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Privacy Policy coming soon!'),
                          ),
                        );
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
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              Provider.of<AuthProvider>(context, listen: false).signOut();
            },
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );
  }
}