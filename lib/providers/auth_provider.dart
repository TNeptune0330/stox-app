import 'dart:io';
import 'package:flutter/foundation.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';
import '../services/auth_service_ios.dart';
import '../services/ios_signin_test_service.dart';
import '../services/storage_service.dart';

class AuthProvider with ChangeNotifier {
  final AuthService _authService = AuthService();
  final AuthServiceIOS _authServiceIOS = AuthServiceIOS();
  
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

  Future<bool> signInWithGoogle() async {
    _setLoading(true);
    _clearError();
    
    try {
      print('AuthProvider: Starting sign in process...');
      
      // Run comprehensive tests on iOS
      if (Platform.isIOS) {
        print('AuthProvider: Running iOS-specific tests...');
        await IOSSignInTestService.runAllTests();
        await _authServiceIOS.debugGoogleSignInConfiguration();
      }
      
      // Use platform-specific service
      final user = Platform.isIOS 
          ? await _authServiceIOS.signInWithGoogle()
          : await _authService.signInWithGoogle();
      
      if (user != null) {
        print('AuthProvider: User signed in successfully: ${user.username}');
        _user = user;
        
        // Cache user with error handling
        try {
          await StorageService.cacheUser(user);
        } catch (cacheError) {
          print('AuthProvider: Failed to cache user: $cacheError');
          // Don't fail the sign in process if caching fails
        }
        
        notifyListeners();
        return true;
      } else {
        print('AuthProvider: Sign in returned null user');
        return false;
      }
    } catch (e) {
      print('AuthProvider: Sign in error: $e');
      _setError('Failed to sign in: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> signOut() async {
    _setLoading(true);
    
    try {
      // Use platform-specific service
      if (Platform.isIOS) {
        await _authServiceIOS.signOut();
      } else {
        await _authService.signOut();
      }
      
      await StorageService.clearUserData();
      _user = null;
      notifyListeners();
    } catch (e) {
      _setError('Failed to sign out: $e');
    } finally {
      _setLoading(false);
    }
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