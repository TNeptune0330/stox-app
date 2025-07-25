import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../services/auth_service_ios.dart';
import '../services/storage_service.dart';
import '../models/user_model.dart';

class AuthFlowTestScreen extends StatefulWidget {
  const AuthFlowTestScreen({super.key});

  @override
  State<AuthFlowTestScreen> createState() => _AuthFlowTestScreenState();
}

class _AuthFlowTestScreenState extends State<AuthFlowTestScreen> {
  final AuthServiceIOS _authService = AuthServiceIOS();
  bool _isLoading = false;
  String _statusMessage = 'Ready to test authentication flow';
  UserModel? _currentUser;
  Map<String, dynamic> _testResults = {};

  @override
  void initState() {
    super.initState();
    _checkInitialState();
  }

  Future<void> _checkInitialState() async {
    setState(() {
      _isLoading = true;
      _statusMessage = 'Checking initial authentication state...';
    });

    try {
      final isSignedIn = _authService.isSignedIn;
      final currentUser = _authService.currentUser;
      final cachedUser = StorageService.getCachedUser();

      setState(() {
        _currentUser = cachedUser;
        _testResults['initial_signed_in'] = isSignedIn;
        _testResults['has_current_user'] = currentUser != null;
        _testResults['has_cached_user'] = cachedUser != null;
        _statusMessage = 'Initial state checked - Signed in: $isSignedIn';
      });
    } catch (e) {
      setState(() {
        _statusMessage = 'Error checking initial state: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _performSignOut() async {
    setState(() {
      _isLoading = true;
      _statusMessage = 'Signing out...';
    });

    try {
      await _authService.signOut();
      
      final isSignedInAfter = _authService.isSignedIn;
      final currentUserAfter = _authService.currentUser;
      final cachedUserAfter = StorageService.getCachedUser();

      setState(() {
        _currentUser = null;
        _testResults['signout_success'] = !isSignedInAfter;
        _testResults['current_user_cleared'] = currentUserAfter == null;
        _testResults['cached_user_cleared'] = cachedUserAfter == null;
        _statusMessage = 'Sign out completed - All user data cleared';
      });

      // Update the auth provider
      if (mounted) {
        final authProvider = context.read<AuthProvider>();
        authProvider.signOut();
      }
    } catch (e) {
      setState(() {
        _statusMessage = 'Sign out failed: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _performSignIn() async {
    setState(() {
      _isLoading = true;
      _statusMessage = 'Starting Google Sign-In...';
    });

    try {
      final userData = await _authService.signInWithGoogle();
      
      if (userData != null) {
        setState(() {
          _currentUser = userData;
          _testResults['signin_success'] = true;
          _testResults['user_id_format'] = _isValidUUID(userData.id);
          _testResults['user_email'] = userData.email;
          _testResults['user_id'] = userData.id;
          _statusMessage = 'Sign in successful: ${userData.email}';
        });

        // Update the auth provider
        if (mounted) {
          final authProvider = context.read<AuthProvider>();
          authProvider.setUser(userData);
        }
      } else {
        setState(() {
          _testResults['signin_success'] = false;
          _statusMessage = 'Sign in was cancelled or failed';
        });
      }
    } catch (e) {
      setState(() {
        _testResults['signin_success'] = false;
        _testResults['signin_error'] = e.toString();
        _statusMessage = 'Sign in failed: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _testSilentSignIn() async {
    setState(() {
      _isLoading = true;
      _statusMessage = 'Testing silent sign-in...';
    });

    try {
      final userData = await _authService.signInSilently();
      
      setState(() {
        _testResults['silent_signin_result'] = userData != null;
        if (userData != null) {
          _currentUser = userData;
          _statusMessage = 'Silent sign-in successful: ${userData.email}';
        } else {
          _statusMessage = 'Silent sign-in failed (no existing session)';
        }
      });
    } catch (e) {
      setState(() {
        _testResults['silent_signin_error'] = e.toString();
        _statusMessage = 'Silent sign-in error: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  bool _isValidUUID(String uuid) {
    final regex = RegExp(r'^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$');
    return regex.hasMatch(uuid.toLowerCase());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Authentication Flow Test'),
        backgroundColor: Colors.deepPurple,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.deepPurple, Colors.indigo],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Status Card
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Status',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _statusMessage,
                        style: const TextStyle(fontSize: 14),
                      ),
                      if (_isLoading) ...[
                        const SizedBox(height: 8),
                        const LinearProgressIndicator(),
                      ],
                    ],
                  ),
                ),
              ),

              // Current User Card
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Current User',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      if (_currentUser != null) ...[
                        Text('Email: ${_currentUser!.email}'),
                        Text('Name: ${_currentUser!.username}'),
                        Text('ID: ${_currentUser!.id}'),
                        Text('Valid UUID: ${_isValidUUID(_currentUser!.id)}'),
                        Text('Cash Balance: \$${_currentUser!.cashBalance.toStringAsFixed(2)}'),
                      ] else ...[
                        const Text('No user signed in'),
                      ],
                    ],
                  ),
                ),
              ),

              // Test Actions
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Test Actions',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: _isLoading ? null : _performSignOut,
                              icon: const Icon(Icons.logout),
                              label: const Text('Sign Out'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red,
                                foregroundColor: Colors.white,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: _isLoading ? null : _performSignIn,
                              icon: const Icon(Icons.login),
                              label: const Text('Sign In'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                                foregroundColor: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: _isLoading ? null : _testSilentSignIn,
                              icon: const Icon(Icons.refresh),
                              label: const Text('Silent Sign-In'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blue,
                                foregroundColor: Colors.white,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: _isLoading ? null : _checkInitialState,
                              icon: const Icon(Icons.info),
                              label: const Text('Check State'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.orange,
                                foregroundColor: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              // Test Results
              Expanded(
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Test Results',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Expanded(
                          child: ListView(
                            children: _testResults.entries.map((entry) {
                              final value = entry.value;
                              final valueStr = value is bool 
                                  ? (value ? '✅ True' : '❌ False')
                                  : value.toString();
                              
                              return Padding(
                                padding: const EdgeInsets.symmetric(vertical: 4.0),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '${entry.key}: ',
                                      style: const TextStyle(fontWeight: FontWeight.w500),
                                    ),
                                    Expanded(
                                      child: Text(
                                        valueStr,
                                        style: TextStyle(
                                          color: value is bool 
                                              ? (value ? Colors.green : Colors.red)
                                              : null,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}