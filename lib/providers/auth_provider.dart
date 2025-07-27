import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';
import '../services/storage_service.dart';

class AuthProvider with ChangeNotifier {
  final AuthService _authService = AuthService();
  
  UserModel? _user;
  bool _isLoading = false;
  String? _error;
  
  // Session refresh timer for persistent login
  Timer? _sessionRefreshTimer;

  UserModel? get user => _user;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isAuthenticated => _user != null;

  Future<void> initialize() async {
    _setLoading(true);
    
    try {
      print('AuthProvider: Initializing with persistent session support...');
      
      // Step 1: Try to restore session from Supabase with automatic refresh
      final restoredUser = await _authService.restoreSession();
      if (restoredUser != null) {
        _user = restoredUser;
        print('AuthProvider: Session restored successfully: ${_user!.email}');
        print('AuthProvider: User will stay logged in indefinitely');
        
        // Set up automatic session refresh timer
        _startSessionRefreshTimer();
        
        notifyListeners();
        return;
      }
      
      // Step 2: If no session, try cached user (offline mode)
      final cachedUser = StorageService.getCachedUser();
      if (cachedUser != null) {
        _user = cachedUser;
        print('AuthProvider: Using cached user (offline mode): ${_user!.email}');
        notifyListeners();
        return;
      }
      
      print('AuthProvider: No session or cached user found - user needs to sign in');
      
    } catch (e) {
      print('AuthProvider: Error during initialization: $e');
      // Try cached user as fallback
      try {
        final cachedUser = StorageService.getCachedUser();
        if (cachedUser != null) {
          _user = cachedUser;
          print('AuthProvider: Using cached user as fallback: ${_user!.email}');
        }
      } catch (cacheError) {
        print('AuthProvider: Cache fallback failed: $cacheError');
        _setError('Failed to initialize auth: $e');
      }
    } finally {
      _setLoading(false);
    }
  }


  Future<bool> signInWithGoogle() async {
    _setLoading(true);
    _clearError();
    
    try {
      print('AuthProvider: Starting sign in process...');
      
      // Use only the standard auth service with enhanced error handling
      UserModel? user;
      
      print('AuthProvider: Using standard auth service for all platforms...');
      user = await _authService.signInWithGoogle();
      
      if (user != null) {
        print('AuthProvider: User signed in successfully: ${user.username} (${user.email})');
        _user = user;
        
        // Cache user with error handling
        try {
          await StorageService.cacheUser(user);
          print('AuthProvider: User cached successfully');
        } catch (cacheError) {
          print('AuthProvider: Failed to cache user: $cacheError');
          // Don't fail the sign in process if caching fails
        }
        
        // Start session refresh timer for persistent login
        _startSessionRefreshTimer();
        
        _clearError();
        notifyListeners();
        return true;
      } else {
        print('AuthProvider: Sign in returned null user - user canceled');
        _setError('Sign in was canceled');
        return false;
      }
    } catch (e) {
      print('AuthProvider: Sign in error: $e');
      String errorMessage = 'Failed to sign in';
      
      // Provide more specific error messages
      final errorStr = e.toString().toLowerCase();
      if (errorStr.contains('canceled') || errorStr.contains('cancelled')) {
        errorMessage = 'Sign in was canceled';
        return false; // Don't show error for user cancellation
      } else if (errorStr.contains('timeout')) {
        errorMessage = 'Sign in timed out - please try again';
      } else if (errorStr.contains('network')) {
        errorMessage = 'Network error - please check your connection';
      } else if (errorStr.contains('configuration')) {
        errorMessage = 'App configuration error - please contact support';
      } else if (errorStr.contains('crash') || errorStr.contains('abort')) {
        errorMessage = 'Google Sign-In encountered an error. Please try again or restart the app.';
      } else if (errorStr.contains('google')) {
        errorMessage = 'Google Sign-In failed - please try again';
      } else {
        errorMessage = 'Sign-in failed - please try again';
      }
      
      _setError(errorMessage);
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> signOut() async {
    _setLoading(true);
    
    try {
      // Cancel session refresh timer
      _sessionRefreshTimer?.cancel();
      _sessionRefreshTimer = null;
      
      // Use standard auth service for all platforms to avoid crashes
      await _authService.signOut();
      
      await StorageService.clearUserData();
      _user = null;
      notifyListeners();
    } catch (e) {
      _setError('Failed to sign out: $e');
    } finally {
      _setLoading(false);
    }
  }

  // Test methods for authentication testing
  void setUser(UserModel user) {
    _user = user;
    _clearError();
    notifyListeners();
    
    // Cache the user
    StorageService.cacheUser(user);
    
    print('🧪 Test user set: ${user.username} (${user.email})');
    print('🧪 User ID: ${user.id}');
  }

  void clearUser() {
    _user = null;
    _clearError();
    notifyListeners();
    
    print('🧪 Test user cleared');
  }

  Future<void> updateProfile({
    String? username,
    String? avatarUrl,
    String? colorTheme,
  }) async {
    if (_user == null) return;

    _setLoading(true);
    
    try {
      final updates = <String, dynamic>{};
      if (username != null) updates['username'] = username;
      if (avatarUrl != null) updates['avatar_url'] = avatarUrl;
      if (colorTheme != null) updates['color_theme'] = colorTheme;

      await _authService.updateUserData(updates);
      
      _user = _user!.copyWith(
        username: username ?? _user!.username,
        avatarUrl: avatarUrl ?? _user!.avatarUrl,
        colorTheme: colorTheme ?? _user!.colorTheme,
        updatedAt: DateTime.now(),
      );

      await StorageService.cacheUser(_user!);
      notifyListeners();
    } catch (e) {
      _setError('Failed to update profile: $e');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> updateCashBalance(double newBalance) async {
    if (_user == null) return;

    try {
      await _authService.updateUserData({'cash_balance': newBalance});
      
      _user = _user!.copyWith(
        cashBalance: newBalance,
        updatedAt: DateTime.now(),
      );

      await StorageService.cacheUser(_user!);
      notifyListeners();
    } catch (e) {
      _setError('Failed to update cash balance: $e');
    }
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String error) {
    _error = error;
    notifyListeners();
  }

  void _clearError() {
    _error = null;
    notifyListeners();
  }
  
  // Start automatic session refresh for persistent login
  void _startSessionRefreshTimer() {
    // Cancel existing timer if any
    _sessionRefreshTimer?.cancel();
    
    // Refresh session every 50 minutes (tokens expire in 60 minutes)
    _sessionRefreshTimer = Timer.periodic(const Duration(minutes: 50), (timer) async {
      try {
        print('AuthProvider: Auto-refreshing session for persistent login...');
        
        if (_authService.isSignedIn) {
          // Check if session needs refresh
          final isValid = await _authService.isSessionValid();
          if (!isValid) {
            print('AuthProvider: Session needs refresh');
            await _authService.refreshSession();
            
            // Update cached user data
            final userData = await _authService.getCurrentUserData();
            if (userData != null) {
              _user = userData;
              await StorageService.cacheUser(userData);
              notifyListeners();
            }
            
            print('AuthProvider: Session auto-refreshed successfully');
          } else {
            print('AuthProvider: Session still valid, no refresh needed');
          }
        } else {
          print('AuthProvider: No active session, stopping refresh timer');
          timer.cancel();
          _sessionRefreshTimer = null;
        }
      } catch (e) {
        print('AuthProvider: Auto-refresh failed: $e');
        // Don't stop the timer on single failures
      }
    });
    
    print('AuthProvider: Session auto-refresh timer started (50min intervals)');
  }
  
  @override
  void dispose() {
    _sessionRefreshTimer?.cancel();
    super.dispose();
  }
}