import 'dart:io';
import 'package:flutter/foundation.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';
import '../services/auth_service_ios.dart';
import '../services/ios_signin_test_service.dart';
import '../services/storage_service.dart';

class AuthProvider with ChangeNotifier {
  final AuthService _authService = AuthService();
  // final AuthServiceIOS _authServiceIOS = AuthServiceIOS(); // Disabled - using main AuthService now
  
  UserModel? _user;
  bool _isLoading = false;
  String? _error;

  UserModel? get user => _user;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isAuthenticated => _user != null;

  Future<void> initialize() async {
    _setLoading(true);
    
    try {
      print('AuthProvider: Initializing...');
      
      // Check for existing Supabase session first
      if (_authService.isSignedIn) {
        print('AuthProvider: Found existing Supabase session');
        _user = await _authService.getCurrentUserData();
        if (_user != null) {
          await StorageService.cacheUser(_user!);
          print('AuthProvider: Restored user from Supabase: ${_user!.email}');
        }
      } else {
        // Try to restore from cache
        _user = StorageService.getCachedUser();
        if (_user != null) {
          print('AuthProvider: Restored user from cache: ${_user!.email}');
          print('AuthProvider: User ID: ${_user!.id}');
        } else {
          print('AuthProvider: No existing session found');
        }
      }
    } catch (e) {
      print('AuthProvider: Error during initialization: $e');
      _setError('Failed to initialize auth: $e');
    } finally {
      _setLoading(false);
    }
  }

  // Helper method to notify achievement provider of user changes
  void _notifyUserChange() {
    notifyListeners();
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
}