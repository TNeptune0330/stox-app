import 'package:flutter/foundation.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';
import '../services/storage_service.dart';

class AuthProvider with ChangeNotifier {
  final AuthService _authService = AuthService();
  
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
      if (_authService.isSignedIn) {
        _user = await _authService.getCurrentUserData();
        if (_user != null) {
          await StorageService.cacheUser(_user!);
        }
      } else {
        _user = StorageService.getCachedUser();
      }
    } catch (e) {
      _setError('Failed to initialize auth: $e');
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> signInWithGoogle() async {
    _setLoading(true);
    _clearError();
    
    try {
      final user = await _authService.signInWithGoogle();
      if (user != null) {
        _user = user;
        await StorageService.cacheUser(user);
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      _setError('Failed to sign in: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> signOut() async {
    _setLoading(true);
    
    try {
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