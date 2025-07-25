import 'dart:async';
import 'dart:io';
import 'package:flutter/services.dart';
// import 'package:google_sign_in/google_sign_in.dart'; // Temporarily disabled
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user_model.dart';
import '../config/api_keys.dart';
import '../services/storage_service.dart';

class AuthServiceIOS {
  final SupabaseClient _supabase = Supabase.instance.client;
  // late final GoogleSignIn _googleSignIn; // Temporarily disabled to prevent crashes
  
  static const String _logPrefix = '[iOS-Auth]';

  AuthServiceIOS() {
    _initializeGoogleSignIn();
  }

  void _initializeGoogleSignIn() {
    try {
      print('$_logPrefix 🚧 Temporarily bypassing Google Sign-In initialization to prevent crashes');
      // Completely disable Google Sign-In initialization
      // _googleSignIn = GoogleSignIn();
      print('$_logPrefix ✅ Bypassed Google Sign-In initialization');
    } catch (e) {
      print('$_logPrefix ❌ Error during bypass: $e');
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
    print('$_logPrefix 🚧 Google Sign-In temporarily disabled to prevent crashes');
    throw Exception('Google Sign-In is temporarily disabled. Please contact support or try again later.');
    
    /*
    try {
      print('$_logPrefix 🔑 Starting Google Sign In...');
      print('$_logPrefix Platform: ${Platform.operatingSystem}');
      print('$_logPrefix Server Client ID: ${ApiKeys.googleSignInWebClientId}');
      
      // Step 1: Validate Google Sign-In object
      if (_googleSignIn == null) {
        print('$_logPrefix ❌ GoogleSignIn object is null, reinitializing...');
        _initializeGoogleSignIn();
        if (_googleSignIn == null) {
          throw Exception('Failed to initialize Google Sign-In');
        }
      }
      
      // Step 2: Check if Google Play Services are available (iOS doesn't need this)
      if (Platform.isIOS) {
        print('$_logPrefix Running on iOS - skipping Google Play Services check');
      }
      
      // Step 3: Check current sign-in status with error handling
      GoogleSignInAccount? currentGoogleUser;
      try {
        currentGoogleUser = _googleSignIn.currentUser;
        print('$_logPrefix Current Google user: ${currentGoogleUser?.email ?? 'None'}');
      } catch (e) {
        print('$_logPrefix ⚠️ Error checking current user: $e');
      }
      
      // Step 4: Sign out any existing user first
      if (currentGoogleUser != null) {
        try {
          print('$_logPrefix Signing out existing user...');
          await _googleSignIn.signOut();
        } catch (e) {
          print('$_logPrefix ⚠️ Error signing out existing user: $e');
        }
      }
      
      // Step 5: Start sign-in process with comprehensive error handling
      print('$_logPrefix Starting Google Sign-In flow...');
      GoogleSignInAccount? googleUser;
      
      try {
        // Double-check that Google Sign-In is properly configured
        print('$_logPrefix Verifying Google Sign-In configuration...');
        
        // Add timeout to prevent hanging
        googleUser = await _googleSignIn.signIn().timeout(
          const Duration(seconds: 30),
          onTimeout: () {
            print('$_logPrefix ❌ Sign-in timed out after 30 seconds');
            throw Exception('Sign-in timed out. Please try again.');
          },
        );
        
        print('$_logPrefix ✅ Google Sign-In call completed successfully');
        
      } on PlatformException catch (e) {
        print('$_logPrefix ❌ PlatformException during sign-in: $e');
        print('$_logPrefix Error code: ${e.code}');
        print('$_logPrefix Error message: ${e.message}');
        print('$_logPrefix Error details: ${e.details}');
        
        // Handle specific iOS errors
        switch (e.code) {
          case 'sign_in_failed':
            throw Exception('Google Sign-In configuration error. Please check app setup.');
          case 'network_error':
            throw Exception('Network error. Please check your connection and try again.');
          case 'sign_in_canceled':
            return null; // User canceled, don't throw error
          case 'sign_in_required':
            throw Exception('Sign-in required. Please try again.');
          default:
            throw Exception('Sign-in failed: ${e.message ?? e.code}');
        }
      } on TimeoutException catch (e) {
        print('$_logPrefix ❌ Timeout during sign-in: $e');
        throw Exception('Sign-in timed out. Please try again.');
      } on Exception catch (e) {
        print('$_logPrefix ❌ Exception during sign-in: $e');
        print('$_logPrefix Exception type: ${e.runtimeType}');
        throw Exception('Sign-in failed due to configuration issue: $e');
      } catch (e) {
        print('$_logPrefix ❌ Unexpected error during sign-in: $e');
        print('$_logPrefix Error type: ${e.runtimeType}');
        
        // This catches native crashes that bubble up as generic errors
        if (e.toString().contains('SIGABRT') || 
            e.toString().contains('abort') ||
            e.toString().contains('crash')) {
          throw Exception('Google Sign-In crashed. Please restart the app and try again.');
        }
        
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
    */
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
      
      // Skip Google sign-out - temporarily disabled
      print('$_logPrefix ⚠️ Google sign-out skipped (temporarily disabled)');
      
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
    print('$_logPrefix Google Sign-In temporarily disabled');
    return false; // Always return false while disabled
  }

  Future<void> debugGoogleSignInConfiguration() async {
    print('$_logPrefix === DEBUG: Google Sign-In DISABLED ===');
    print('$_logPrefix Google Sign-In temporarily disabled to prevent crashes');
    print('$_logPrefix === END DEBUG ===');
  }

  /*Future<UserModel?> _createOrUpdateUser(User user, GoogleSignInAccount googleUser) async {
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
  }*/
}