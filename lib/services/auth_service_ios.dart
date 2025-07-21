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
          // Use web client ID for iOS to ensure compatibility with Supabase
          serverClientId: ApiKeys.googleSignInWebClientId,
          // Important: Don't set clientId to let it use the one from GoogleService-Info.plist
          // but ensure server validation uses web client ID
          scopes: [
            'email',
            'profile',
            'openid',
          ],
        );
      } else {
        // Android fallback
        _googleSignIn = GoogleSignIn(
          serverClientId: ApiKeys.googleSignInWebClientId,
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
      print('$_logPrefix Server Client ID: ${ApiKeys.googleSignInWebClientId}');
      
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
      
      // Step 7: Authenticate with Supabase
      print('$_logPrefix 🔐 Authenticating with Supabase...');
      
      if (googleAuth.idToken == null || googleAuth.accessToken == null) {
        throw Exception('Missing authentication tokens');
      }
      
      final response = await _supabase.auth.signInWithIdToken(
        provider: OAuthProvider.google,
        idToken: googleAuth.idToken!,
        accessToken: googleAuth.accessToken!,
      );
      
      if (response.user == null) {
        throw Exception('Failed to authenticate with Supabase');
      }
      
      print('$_logPrefix ✅ Successfully authenticated with Supabase');
      print('$_logPrefix Supabase User ID: ${response.user!.id}');
      
      // Step 8: Create or update user in database
      final userData = await _createOrUpdateUser(response.user!, googleUser);
      
      if (userData != null) {
        print('$_logPrefix ✅ User profile created/updated: ${userData.email}');
        
        // Cache user data locally for persistence
        await StorageService.cacheUser(userData);
        print('$_logPrefix ✅ User data cached successfully');
        
        return userData;
      }
      
      throw Exception('Failed to create user profile');
      
    } catch (e) {
      print('$_logPrefix ❌ Google Sign In error: $e');
      print('$_logPrefix Error type: ${e.runtimeType}');
      rethrow;
    }
  }

  Future<UserModel?> signInSilently() async {
    try {
      print('$_logPrefix 🔄 Attempting silent sign-in...');
      
      // First check if there's an existing Supabase session
      if (_supabase.auth.currentUser != null) {
        print('$_logPrefix Found existing Supabase session');
        
        // Get user data from database
        final response = await _supabase
            .from('users')
            .select()
            .eq('id', _supabase.auth.currentUser!.id)
            .maybeSingle();
        
        if (response != null) {
          final userData = UserModel.fromJson(response);
          await StorageService.cacheUser(userData);
          print('$_logPrefix ✅ Silent sign-in successful from Supabase: ${userData.email}');
          return userData;
        }
      }
      
      print('$_logPrefix No existing session found');
      return null;
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
      print('$_logPrefix Server Client ID: ${ApiKeys.googleSignInWebClientId}');
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

  Future<UserModel?> _createOrUpdateUser(User user, GoogleSignInAccount googleUser) async {
    try {
      print('$_logPrefix 👤 Creating/updating user profile...');
      
      // Use the Supabase Auth user ID directly
      final supabaseUserId = user.id;
      print('$_logPrefix Using Supabase Auth user ID: $supabaseUserId');
      
      // Check if user already exists
      final existingUser = await _supabase
          .from('users')
          .select()
          .eq('id', supabaseUserId)
          .maybeSingle();

      if (existingUser == null) {
        print('$_logPrefix 📝 Creating new user profile...');
        
        // Extract name from user metadata or Google user
        final fullName = googleUser.displayName ?? 
                        user.userMetadata?['full_name'] ?? 
                        user.userMetadata?['name'] ?? 
                        user.email!.split('@')[0];
        
        final newUser = {
          'id': supabaseUserId,
          'email': user.email!,
          'username': fullName,
          'avatar_url': googleUser.photoUrl ?? user.userMetadata?['avatar_url'],
          'color_theme': 'light',
          'cash_balance': 10000.0,
          'total_trades': 0,
          'created_at': DateTime.now().toIso8601String(),
          'last_login': DateTime.now().toIso8601String(),
          'updated_at': DateTime.now().toIso8601String(),
        };

        final response = await _supabase
            .from('users')
            .insert(newUser)
            .select()
            .single();

        print('$_logPrefix ✅ New user created successfully');
        return UserModel.fromJson(response);
      } else {
        print('$_logPrefix 🔄 Updating existing user...');
        
        // Update last login and other fields
        final updatedUser = {
          'last_login': DateTime.now().toIso8601String(),
          'updated_at': DateTime.now().toIso8601String(),
        };

        final response = await _supabase
            .from('users')
            .update(updatedUser)
            .eq('id', supabaseUserId)
            .select()
            .single();

        print('$_logPrefix ✅ User updated successfully');
        return UserModel.fromJson(response);
      }
    } catch (e) {
      print('$_logPrefix ❌ Failed to create/update user: $e');
      throw Exception('Failed to create/update user profile: $e');
    }
  }
}