import 'dart:io';
import 'package:flutter/services.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user_model.dart';
import '../config/api_keys.dart';
import '../services/storage_service.dart';

class AuthServiceIOS {
  final SupabaseClient _supabase = Supabase.instance.client;
  late final GoogleSignIn _googleSignIn;
  
  static const String _logPrefix = '[iOS-Auth]';

  AuthServiceIOS() {
    _initializeGoogleSignIn();
  }

  void _initializeGoogleSignIn() {
    try {
      print('$_logPrefix Initializing Google Sign-In for iOS...');
      
      if (Platform.isIOS) {
        // iOS-specific configuration
        _googleSignIn = GoogleSignIn(
          clientId: ApiKeys.googleSignInIOSClientId,
          scopes: [
            'email',
            'profile',
            'openid',
          ],
        );
      } else {
        // Android fallback
        _googleSignIn = GoogleSignIn(
          scopes: [
            'email',
            'profile',
          ],
        );
      }
      
      print('$_logPrefix Google Sign-In initialized successfully');
    } catch (e) {
      print('$_logPrefix ❌ Error initializing Google Sign-In: $e');
    }
  }

  User? get currentUser => _supabase.auth.currentUser;
  bool get isSignedIn => currentUser != null;
  
  Future<UserModel?> getCurrentUserFromStorage() async {
    try {
      print('$_logPrefix Getting cached user...');
      final cachedUser = await StorageService.getCachedUser();
      print('$_logPrefix Cached user: ${cachedUser?.email ?? 'None'}');
      return cachedUser;
    } catch (e) {
      print('$_logPrefix ❌ Error getting cached user: $e');
      return null;
    }
  }

  Future<UserModel?> signInWithGoogle() async {
    try {
      print('$_logPrefix 🔑 Starting Google Sign In...');
      print('$_logPrefix Platform: ${Platform.operatingSystem}');
      print('$_logPrefix Client ID: ${ApiKeys.googleSignInIOSClientId}');
      
      // Step 1: Check if Google Play Services are available (iOS doesn't need this)
      if (Platform.isIOS) {
        print('$_logPrefix Running on iOS - skipping Google Play Services check');
      }
      
      // Step 2: Check current sign-in status
      final currentGoogleUser = _googleSignIn.currentUser;
      print('$_logPrefix Current Google user: ${currentGoogleUser?.email ?? 'None'}');
      
      // Step 3: Sign out any existing user first
      if (currentGoogleUser != null) {
        print('$_logPrefix Signing out existing user...');
        await _googleSignIn.signOut();
      }
      
      // Step 4: Start sign-in process
      print('$_logPrefix Starting Google Sign-In flow...');
      GoogleSignInAccount? googleUser;
      
      try {
        googleUser = await _googleSignIn.signIn();
      } on PlatformException catch (e) {
        print('$_logPrefix ❌ PlatformException during sign-in: $e');
        print('$_logPrefix Error code: ${e.code}');
        print('$_logPrefix Error message: ${e.message}');
        print('$_logPrefix Error details: ${e.details}');
        
        // Handle specific iOS errors
        if (e.code == 'sign_in_failed') {
          throw Exception('Google Sign-In failed. Please check your network connection and try again.');
        } else if (e.code == 'network_error') {
          throw Exception('Network error. Please check your connection and try again.');
        } else if (e.code == 'sign_in_canceled') {
          throw Exception('Sign-in was canceled by user.');
        } else {
          throw Exception('Sign-in failed: ${e.message}');
        }
      } catch (e) {
        print('$_logPrefix ❌ Unexpected error during sign-in: $e');
        throw Exception('Unexpected error during sign-in: $e');
      }
      
      // Step 5: Check if user canceled
      if (googleUser == null) {
        print('$_logPrefix ❌ User cancelled Google Sign In');
        return null;
      }

      print('$_logPrefix ✅ Got Google user: ${googleUser.displayName}');
      print('$_logPrefix Google user email: ${googleUser.email}');
      print('$_logPrefix Google user ID: ${googleUser.id}');
      
      // Step 6: Get authentication details
      print('$_logPrefix Getting authentication details...');
      GoogleSignInAuthentication? googleAuth;
      
      try {
        googleAuth = await googleUser.authentication;
        print('$_logPrefix ✅ Got authentication details');
        print('$_logPrefix Access token length: ${googleAuth.accessToken?.length ?? 0}');
        print('$_logPrefix ID token length: ${googleAuth.idToken?.length ?? 0}');
      } catch (e) {
        print('$_logPrefix ❌ Error getting authentication details: $e');
        throw Exception('Failed to get authentication details: $e');
      }
      
      // Step 7: Create user data for local storage
      print('$_logPrefix Creating user data...');
      final userData = UserModel(
        id: googleUser.id,
        email: googleUser.email,
        username: googleUser.displayName ?? 'Unknown User',
        avatarUrl: googleUser.photoUrl,
        colorTheme: 'light',
        cashBalance: 10000.0, // Starting balance
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      
      print('$_logPrefix ✅ User data created: ${userData.email}');
      
      // Step 8: Cache user data locally
      print('$_logPrefix Caching user data...');
      try {
        await StorageService.cacheUser(userData);
        print('$_logPrefix ✅ User data cached successfully');
      } catch (e) {
        print('$_logPrefix ❌ Error caching user data: $e');
        // Don't fail the sign-in if caching fails
      }
      
      print('$_logPrefix ✅ Successfully signed in with Google: ${userData.email}');
      return userData;
      
    } catch (e) {
      print('$_logPrefix ❌ Google Sign In error: $e');
      print('$_logPrefix Error type: ${e.runtimeType}');
      rethrow;
    }
  }

  Future<UserModel?> signInSilently() async {
    try {
      print('$_logPrefix 🔄 Attempting silent sign-in...');
      
      final googleUser = await _googleSignIn.signInSilently();
      if (googleUser == null) {
        print('$_logPrefix No existing Google session found');
        return null;
      }
      
      print('$_logPrefix ✅ Silent sign-in successful: ${googleUser.email}');
      
      // Create user data
      final userData = UserModel(
        id: googleUser.id,
        email: googleUser.email,
        username: googleUser.displayName ?? 'Unknown User',
        avatarUrl: googleUser.photoUrl,
        colorTheme: 'light',
        cashBalance: 10000.0,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      
      // Cache user data
      await StorageService.cacheUser(userData);
      
      return userData;
    } catch (e) {
      print('$_logPrefix ❌ Silent sign-in failed: $e');
      return null;
    }
  }

  Future<void> signOut() async {
    try {
      print('$_logPrefix 🔓 Signing out...');
      
      // Clear local cache
      await StorageService.clearCache();
      print('$_logPrefix ✅ Local cache cleared');
      
      // Sign out from Google
      await _googleSignIn.signOut();
      print('$_logPrefix ✅ Google sign-out completed');
      
      // Sign out from Supabase
      try {
        await _supabase.auth.signOut();
        print('$_logPrefix ✅ Supabase sign-out completed');
      } catch (e) {
        print('$_logPrefix ⚠️ Supabase sign-out failed (non-critical): $e');
      }
      
      print('$_logPrefix ✅ Successfully signed out');
    } catch (e) {
      print('$_logPrefix ❌ Failed to sign out: $e');
      throw Exception('Failed to sign out: $e');
    }
  }

  Future<bool> isGoogleSignInAvailable() async {
    try {
      print('$_logPrefix Checking Google Sign-In availability...');
      
      if (Platform.isIOS) {
        // On iOS, Google Sign-In is generally available
        print('$_logPrefix iOS - Google Sign-In should be available');
        return true;
      } else {
        // On Android, check if Google Play Services are available
        final isAvailable = await _googleSignIn.isSignedIn();
        print('$_logPrefix Android - Google Play Services available: $isAvailable');
        return true; // Always return true, let the actual sign-in handle errors
      }
    } catch (e) {
      print('$_logPrefix ❌ Error checking Google Sign-In availability: $e');
      return false;
    }
  }

  Future<void> debugGoogleSignInConfiguration() async {
    try {
      print('$_logPrefix === DEBUG: Google Sign-In Configuration ===');
      print('$_logPrefix Platform: ${Platform.operatingSystem}');
      print('$_logPrefix Platform version: ${Platform.operatingSystemVersion}');
      print('$_logPrefix Client ID: ${ApiKeys.googleSignInIOSClientId}');
      print('$_logPrefix Scopes: ${_googleSignIn.scopes}');
      print('$_logPrefix Current user: ${_googleSignIn.currentUser?.email ?? 'None'}');
      
      // Try to get app configuration
      if (Platform.isIOS) {
        print('$_logPrefix iOS Bundle ID: ${Platform.resolvedExecutable}');
      }
      
      // Check if signed in
      final isSignedIn = await _googleSignIn.isSignedIn();
      print('$_logPrefix Is signed in: $isSignedIn');
      
      print('$_logPrefix === END DEBUG ===');
    } catch (e) {
      print('$_logPrefix ❌ Error during debug: $e');
    }
  }
}