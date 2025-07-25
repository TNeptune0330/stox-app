import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../services/auth_test_service.dart';
import '../models/user_model.dart';

class AuthTestScreen extends StatefulWidget {
  const AuthTestScreen({Key? key}) : super(key: key);

  @override
  State<AuthTestScreen> createState() => _AuthTestScreenState();
}

class _AuthTestScreenState extends State<AuthTestScreen> {
  bool _isLoading = false;
  String _statusMessage = '';
  List<Map<String, String>> _testUsers = [];

  @override
  void initState() {
    super.initState();
    _testUsers = AuthTestService.getTestUsers();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Authentication Test'),
        backgroundColor: Theme.of(context).primaryColor,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Current User Status
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Current User Status',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 12),
                    Consumer<AuthProvider>(
                      builder: (context, authProvider, child) {
                        if (authProvider.isLoading) {
                          return const Row(
                            children: [
                              CircularProgressIndicator(),
                              SizedBox(width: 16),
                              Text('Loading...'),
                            ],
                          );
                        }

                        if (authProvider.user == null) {
                          return const Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('❌ No user signed in'),
                              Text('Status: Not authenticated'),
                            ],
                          );
                        }

                        final user = authProvider.user!;
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('✅ User signed in'),
                            Text('Name: ${user.username ?? 'No name'}'),
                            Text('Email: ${user.email}'),
                            Text('ID: ${user.id}'),
                            Text('Cash Balance: \$${user.cashBalance.toStringAsFixed(2)}'),
                            Text('Created: ${user.createdAt.toLocal()}'),
                          ],
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Test Actions
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Test Actions',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 16),
                    
                    // Sign Out Button
                    Consumer<AuthProvider>(
                      builder: (context, authProvider, child) {
                        return ElevatedButton.icon(
                          onPressed: authProvider.user == null ? null : () async {
                            setState(() {
                              _isLoading = true;
                              _statusMessage = 'Signing out...';
                            });
                            
                            try {
                              await authProvider.signOut();
                              setState(() {
                                _statusMessage = '✅ Successfully signed out';
                              });
                            } catch (e) {
                              setState(() {
                                _statusMessage = '❌ Sign out failed: $e';
                              });
                            } finally {
                              setState(() {
                                _isLoading = false;
                              });
                            }
                          },
                          icon: const Icon(Icons.logout),
                          label: const Text('Sign Out'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            foregroundColor: Colors.white,
                          ),
                        );
                      },
                    ),
                    
                    const SizedBox(height: 12),
                    
                    // Simulate Google Sign In
                    ElevatedButton.icon(
                      onPressed: _isLoading ? null : () async {
                        setState(() {
                          _isLoading = true;
                          _statusMessage = 'Simulating Google Sign In...';
                        });
                        
                        try {
                          final user = await AuthTestService.simulateGoogleSignIn();
                          
                          // Update the auth provider with the fake user
                          final authProvider = context.read<AuthProvider>();
                          authProvider.setUser(user);
                          
                          setState(() {
                            _statusMessage = '✅ Successfully signed in as ${user.username}';
                          });
                        } catch (e) {
                          setState(() {
                            _statusMessage = '❌ Sign in failed: $e';
                          });
                        } finally {
                          setState(() {
                            _isLoading = false;
                          });
                        }
                      },
                      icon: const Icon(Icons.login),
                      label: const Text('Simulate Google Sign In'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                      ),
                    ),
                    
                    const SizedBox(height: 12),
                    
                    // Test UUID Conversion
                    ElevatedButton.icon(
                      onPressed: _isLoading ? null : () {
                        setState(() {
                          _statusMessage = 'Testing UUID conversion...';
                        });
                        
                        AuthTestService.testUuidConversion();
                        
                        setState(() {
                          _statusMessage = '✅ UUID conversion test completed (check logs)';
                        });
                      },
                      icon: const Icon(Icons.transform),
                      label: const Text('Test UUID Conversion'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                      ),
                    ),
                    
                    const SizedBox(height: 12),
                    
                    // Clear Test Data
                    ElevatedButton.icon(
                      onPressed: _isLoading ? null : () async {
                        setState(() {
                          _isLoading = true;
                          _statusMessage = 'Clearing test data...';
                        });
                        
                        try {
                          await AuthTestService.clearTestData();
                          final authProvider = context.read<AuthProvider>();
                          authProvider.clearUser();
                          
                          setState(() {
                            _statusMessage = '✅ Test data cleared';
                          });
                        } catch (e) {
                          setState(() {
                            _statusMessage = '❌ Clear failed: $e';
                          });
                        } finally {
                          setState(() {
                            _isLoading = false;
                          });
                        }
                      },
                      icon: const Icon(Icons.clear),
                      label: const Text('Clear Test Data'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Status Message
            if (_statusMessage.isNotEmpty)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Status',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      Text(_statusMessage),
                    ],
                  ),
                ),
              ),
            
            const SizedBox(height: 16),
            
            // Test Users List
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Available Test Users',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 12),
                    ...(_testUsers.map((user) => ListTile(
                      leading: CircleAvatar(
                        backgroundImage: NetworkImage(
                          'https://ui-avatars.com/api/?name=${user['name']!.replaceAll(' ', '+')}&background=random',
                        ),
                      ),
                      title: Text(user['name']!),
                      subtitle: Text(user['email']!),
                      trailing: TextButton(
                        onPressed: _isLoading ? null : () async {
                          setState(() {
                            _isLoading = true;
                            _statusMessage = 'Signing in as ${user['name']}...';
                          });
                          
                          try {
                            // Create a specific user
                            final testUser = UserModel(
                              id: user['googleId']!, // This will be converted to UUID
                              email: user['email']!,
                              username: user['name']!,
                              avatarUrl: 'https://ui-avatars.com/api/?name=${user['name']!.replaceAll(' ', '+')}&background=random',
                              colorTheme: 'darkBlue',
                              cashBalance: 10000.0,
                              createdAt: DateTime.now(),
                              updatedAt: DateTime.now(),
                            );
                            
                            final authProvider = context.read<AuthProvider>();
                            authProvider.setUser(testUser);
                            
                            setState(() {
                              _statusMessage = '✅ Successfully signed in as ${user['name']}';
                            });
                          } catch (e) {
                            setState(() {
                              _statusMessage = '❌ Sign in failed: $e';
                            });
                          } finally {
                            setState(() {
                              _isLoading = false;
                            });
                          }
                        },
                        child: const Text('Use'),
                      ),
                    ))),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}