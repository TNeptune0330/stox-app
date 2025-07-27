import 'dart:async';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user_model.dart';
import '../config/api_keys.dart';
import '../services/storage_service.dart';
import '../utils/uuid_utils.dart';

class AuthService {
  final SupabaseClient _supabase = Supabase.instance.client;
  late final GoogleSignIn _googleSignIn;
  GoogleSignInAccount? _currentGoogleUser;
  bool _isInitialized = false;

  AuthService() {
    _initializeGoogleSignInSafely();
  }
  
  void _initializeGoogleSignInSafely() {
    try {
      print('🔧 AuthService: Starting Google Sign-In v7.1.1 (singleton) for Supabase...');
      
      // Use GoogleSignIn v7.1.1 singleton pattern
      _googleSignIn = GoogleSignIn.instance;
      
      print('✅ AuthService: Google Sign-In v7.1.1 singleton ready for initialization');
      
    } catch (e) {
      print('❌ AuthService: Google Sign-In v7.1.1 singleton setup failed: $e');
      rethrow;
    }
  }
  
  Future<void> _ensureInitialized() async {
    if (_isInitialized) return;
    
    try {
      print('🔧 Initializing Google Sign-In v7.1.1 with client IDs...');
      
      // Use Supabase-recommended approach with both web and iOS client IDs
      const webClientId = '264305191086-ruelf34qlbnngfubd7m52418hta9c3oh.apps.googleusercontent.com';
      const iosClientId = '264305191086-jr22tsn1j8gl9ihv3heragdk310os4pe.apps.googleusercontent.com';
      
      await _googleSignIn.initialize(
        clientId: iosClientId,  // Use iOS client ID for sign-in
        serverClientId: webClientId,  // Web client ID for Supabase
      );
      
      _isInitialized = true;
      print('✅ AuthService: Google Sign-In v7.1.1 initialized with both client IDs');
      
    } catch (e) {
      print('❌ AuthService: Google Sign-In v7.1.1 initialization failed: $e');
      rethrow;
    }
  }
  

  User? get currentUser => _supabase.auth.currentUser;
  bool get isSignedIn => currentUser != null;
  
  Future<UserModel?> getCurrentUserFromStorage() async {
    try {
      return await StorageService.getCachedUser();
    } catch (e) {
      print('❌ Error getting cached user: $e');
      return null;
    }
  }

  Future<UserModel?> signInWithGoogle() async {
    print('🔑 === STARTING GOOGLE SIGN-IN PROCESS ===');
    
    try {
      // Step 1: Ensure GoogleSignIn is initialized (v7.1.1 requirement)
      await _ensureInitialized();
      
      // Step 2: Perform pre-sign-in checks
      await _performPreSignInChecks();
      
      // Step 3: Execute sign-in with comprehensive error handling
      final googleUser = await _executeGoogleSignIn();
      
      if (googleUser == null) {
        print('ℹ️ User cancelled Google Sign In');
        return null;
      }
      
      // Step 4: Get authentication tokens with required scopes
      final googleAuth = await _getGoogleAuthentication(googleUser);
      
      // Step 5: Authenticate with Supabase
      final supabaseUser = await _authenticateWithSupabase(googleAuth);
      
      // Step 6: Create/update user profile
      final userData = await _createOrUpdateUser(supabaseUser, googleUser.id);
      
      if (userData != null) {
        print('✅ User profile created/updated: ${userData.email}');
        await StorageService.cacheUser(userData);
        print('✅ === GOOGLE SIGN-IN COMPLETED SUCCESSFULLY ===');
        return userData;
      }
      
      throw Exception('Failed to create user profile');
      
    } catch (e) {
      print('❌ === GOOGLE SIGN-IN FAILED ===');
      print('❌ Final error: $e');
      await _handleSignInError(e);
      rethrow;
    }
  }
  
  // No longer needed in v7 - singleton is always available
  
  Future<void> _performPreSignInChecks() async {
    print('🔍 Step 2: Performing pre-sign-in checks...');
    
    try {
      // In v7.1.1, we can try a lightweight authentication to check if user exists
      print('🔧 Attempting lightweight authentication check...');
      final existingUser = await _googleSignIn.attemptLightweightAuthentication();
      
      if (existingUser != null) {
        print('🔄 User already authenticated, signing out first...');
        await _googleSignIn.signOut();
        _currentGoogleUser = null; // Clear manual state
        print('✅ Successfully signed out existing user');
      } else {
        print('📊 No existing authentication found');
      }
      
      print('🧪 Google Sign-In v7.1.1 pre-checks completed');
      
    } catch (e) {
      print('⚠️ Pre-sign-in check warning: $e');
      // Continue anyway - these are non-critical checks
    }
  }
  
  Future<GoogleSignInAccount?> _executeGoogleSignIn() async {
    print('🔍 Step 3: Executing Google Sign-In v7.1.1 for Supabase...');
    
    // Add debugging before the sign-in call
    print('🔧 Pre-flight check: GoogleSignIn singleton exists');
    print('🔧 Pre-flight check: About to call authenticate()...');
    print('🔧 Pre-flight check: Using GoogleSignIn v7.1.1 authenticate method');
    
    try {
      print('🚀 Calling _googleSignIn.authenticate()...');
      print('✅ INFO: Using GoogleSignIn v7.1.1 authenticate() for Supabase');
      
      // Use v7.1.1 authenticate method (separate from authorization)
      final googleUser = await _googleSignIn.authenticate().timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          print('⏰ Google Sign-In timed out after 30 seconds');
          throw Exception('Sign-in request timed out. Please try again.');
        },
      );
      
      print('🎉 SUCCESS: Authentication completed without crashes!');
      
      if (googleUser != null) {
        _currentGoogleUser = googleUser; // Track user state manually
        print('✅ Google Sign-In successful!');
        print('📊 User: ${googleUser.displayName} (${googleUser.email})');
        print('📊 ID: ${googleUser.id}');
      } else {
        print('ℹ️ Google Sign-In returned null (likely user canceled)');
      }
      
      return googleUser;
      
    } on Exception catch (e) {
      print('❌ Google Sign-In Exception: $e');
      print('❌ Exception type: ${e.runtimeType}');
      
      if (e.toString().contains('cancel')) {
        print('ℹ️ User cancelled sign-in');
        return null;
      }
      
      throw Exception('Google Sign-In failed: ${e.toString()}');
    } catch (e) {
      print('❌ Unexpected Google Sign-In error: $e');
      print('❌ Error type: ${e.runtimeType}');
      throw Exception('Unexpected sign-in error: ${e.toString()}');
    }
  }
  
  Future<GoogleSignInAuthentication> _getGoogleAuthentication(GoogleSignInAccount googleUser) async {
    print('🔍 Step 4: Getting authentication tokens for Supabase...');
    
    try {
      // Use v6 async authentication property
      final googleAuth = await googleUser.authentication;
      
      print('📊 ID token available: ${googleAuth.idToken != null}');
      
      if (googleAuth.idToken == null) {
        throw Exception('Missing ID token from Google authentication');
      }
      
      print('✅ Successfully obtained authentication tokens');
      return googleAuth;
      
    } catch (e) {
      print('❌ Failed to get authentication tokens: $e');
      throw Exception('Failed to get authentication tokens: ${e.toString()}');
    }
  }
  
  Future<User> _authenticateWithSupabase(GoogleSignInAuthentication googleAuth) async {
    print('🔍 Step 5: Authenticating with Supabase...');
    
    try {
      print('📊 Using Google ID token for Supabase authentication');
      
      // For GoogleSignIn v7.1.1, only ID token is available
      // Note: Supabase may show warnings about missing access token, but this is expected for v7.1.1
      final response = await _supabase.auth.signInWithIdToken(
        provider: OAuthProvider.google,  
        idToken: googleAuth.idToken!,
      );
      
      if (response.user == null) {
        throw Exception('Supabase authentication returned null user');
      }
      
      print('✅ Successfully authenticated with Supabase');
      print('📊 Supabase User ID: ${response.user!.id}');
      print('📊 Supabase User Email: ${response.user!.email}');
      
      return response.user!;
      
    } catch (e) {
      print('❌ Supabase authentication failed: $e');
      print('❌ This might be due to client ID configuration mismatch');
      throw Exception('Supabase authentication failed: ${e.toString()}');
    }
  }
  
  Future<void> _handleSignInError(dynamic error) async {
    print('🚑 Handling sign-in error...');
    
    // Log detailed error information
    print('📊 Error details:');
    print('📊 - Type: ${error.runtimeType}');
    print('📊 - Message: $error');
    
    // Check Google Sign-In state after error (v7 manual tracking)
    final isSignedIn = _currentGoogleUser != null;
    print('📊 Google Sign-In state after error: signed in = $isSignedIn');
  }

  Future<UserModel?> _createOrUpdateUser(User user, String googleId) async {
    try {
      print('👤 Creating/updating user profile...');
      
      // Use the Supabase Auth user ID directly (not converted Google ID)
      final supabaseUserId = user.id;
      print('🔄 Using Supabase Auth user ID: $supabaseUserId');
      
      // Check if user already exists
      final existingUser = await _supabase
          .from('users')
          .select()
          .eq('id', supabaseUserId)
          .maybeSingle();

      if (existingUser == null) {
        print('📝 Creating new user profile...');
        
        // Extract name from user metadata
        final fullName = user.userMetadata?['full_name'] ?? 
                        user.userMetadata?['name'] ?? 
                        user.email!.split('@')[0];
        
        final newUser = {
          'id': supabaseUserId,
          'email': user.email!,
          'username': fullName,
          'avatar_url': user.userMetadata?['avatar_url'],
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

        print('✅ New user created successfully');
        // Create UserModel with Supabase Auth user ID
        final userData = UserModel.fromJson(response);
        return userData;
      } else {
        print('🔄 Updating existing user...');
        
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

        print('✅ User updated successfully');
        // Create UserModel with Supabase Auth user ID
        final userData = UserModel.fromJson(response);
        return userData;
      }
    } catch (e) {
      print('❌ Failed to create/update user: $e');
      throw Exception('Failed to create/update user profile: $e');
    }
  }

  Future<UserModel?> getCurrentUserData() async {
    if (!isSignedIn) return null;

    try {
      final response = await _supabase
          .from('users')
          .select()
          .eq('id', currentUser!.id)
          .maybeSingle();
      
      if (response == null) {
        print('⚠️ User not found in database for Auth ID: ${currentUser!.id}');
        return null;
      }

      return UserModel.fromJson(response);
    } catch (e) {
      print('❌ Failed to get current user data: $e');
      throw Exception('Failed to get user data: $e');
    }
  }

  Future<void> updateUserData(Map<String, dynamic> updates) async {
    if (!isSignedIn) throw Exception('User not signed in');

    try {
      updates['updated_at'] = DateTime.now().toIso8601String();
      
      // Handle theme enum constraint gracefully
      if (updates.containsKey('color_theme')) {
        final theme = updates['color_theme'] as String;
        // Map new theme names to compatible enum values
        final compatibleThemes = {
          'deepOcean': 'dark_blue',
          'forestTwilight': 'dark_green', 
          'royalPurple': 'dark_purple',
          'crimsonNight': 'dark_red',
          'goldenSunset': 'dark_orange',
          'arcticBlue': 'light_blue',
          'lightLavender': 'light_purple',
          'sunsetWarmth': 'light_orange',
          'lightMint': 'light_green',
          'monochromeLight': 'light',
          'monochromeDark': 'dark',
          'lightProfessional': 'light_blue',
          'custom': 'custom',
        };
        
        updates['color_theme'] = compatibleThemes[theme] ?? 'dark_blue';
        print('📱 Mapped theme $theme to ${updates['color_theme']}');
      }
      
      await _supabase
          .from('users')
          .update(updates)
          .eq('id', currentUser!.id);
          
      print('✅ User data updated successfully');
    } catch (e) {
      print('❌ Failed to update user data: $e');
      // Don't throw for theme constraint errors - just log and continue
      if (e.toString().contains('enum') || e.toString().contains('constraint')) {
        print('⚠️ Theme enum constraint error - app will continue with local theme');
      } else {
        throw Exception('Failed to update user data: $e');
      }
    }
  }

  Future<void> signOut() async {
    try {
      print('🔓 Signing out...');
      
      // Clear local cache
      await StorageService.clearCache();
      
      // Sign out from Google
      await _googleSignIn.signOut();
      _currentGoogleUser = null; // Clear manual state
      
      // Sign out from Supabase
      await _supabase.auth.signOut();
      
      print('✅ Successfully signed out');
    } catch (e) {
      print('❌ Failed to sign out: $e');
      throw Exception('Failed to sign out: $e');
    }
  }

  Future<bool> isSessionValid() async {
    try {
      final session = _supabase.auth.currentSession;
      if (session == null) return false;
      
      // Check if session is expired (with 5 minute buffer for refresh)
      final now = DateTime.now();
      final expiresAt = DateTime.fromMillisecondsSinceEpoch(session.expiresAt! * 1000);
      final bufferTime = expiresAt.subtract(const Duration(minutes: 5));
      
      final isValid = now.isBefore(bufferTime);
      if (!isValid) {
        print('⚠️ Session expires soon or expired. Current: $now, Expires: $expiresAt');
      }
      
      return isValid;
    } catch (e) {
      print('❌ Error checking session validity: $e');
      return false;
    }
  }

  Future<void> refreshSession() async {
    try {
      if (!isSignedIn) {
        print('⚠️ No user signed in, cannot refresh session');
        return;
      }
      
      final session = await _supabase.auth.refreshSession();
      if (session.session == null) {
        throw Exception('Failed to refresh session - session is null');
      }
      
      // Update user data after successful refresh
      final userData = await getCurrentUserData();
      if (userData != null) {
        await StorageService.cacheUser(userData);
      }
      
      print('✅ Session refreshed successfully');
    } catch (e) {
      print('❌ Failed to refresh session: $e');
      throw Exception('Failed to refresh session: $e');
    }
  }

  Future<UserModel?> restoreSession() async {
    try {
      print('🔄 Restoring session...');
      
      // Try to get current session
      final session = _supabase.auth.currentSession;
      if (session == null) {
        print('❌ No active session found');
        // Try to get cached user as fallback
        final cachedUser = StorageService.getCachedUser();
        if (cachedUser != null) {
          print('✅ Found cached user, attempting silent refresh...');
          return cachedUser;
        }
        return null;
      }
      
      // Check if session is valid
      if (!await isSessionValid()) {
        print('⚠️ Session expired, attempting to refresh...');
        try {
          await refreshSession();
          print('✅ Session refreshed successfully');
        } catch (refreshError) {
          print('❌ Session refresh failed: $refreshError');
          // Return cached user if refresh fails
          final cachedUser = StorageService.getCachedUser();
          return cachedUser;
        }
      }
      
      // Get user data
      final userData = await getCurrentUserData();
      if (userData != null) {
        print('✅ Session restored successfully');
        // Update cache with fresh data
        await StorageService.cacheUser(userData);
        return userData;
      }
      
      return null;
    } catch (e) {
      print('❌ Failed to restore session: $e');
      // Try to return cached user as final fallback
      try {
        final cachedUser = StorageService.getCachedUser();
        if (cachedUser != null) {
          print('✅ Using cached user as fallback');
          return cachedUser;
        }
      } catch (cacheError) {
        print('❌ Cache fallback failed: $cacheError');
      }
      return null;
    }
  }

  Future<void> deleteAccount() async {
    if (!isSignedIn) throw Exception('User not signed in');
    
    try {
      print('🗑️ Deleting user account...');
      
      final userId = currentUser!.id;
      
      // Delete all user data (cascade delete will handle related tables)
      await _supabase
          .from('users')
          .delete()
          .eq('id', userId);
      
      // Sign out
      await signOut();
      
      print('✅ Account deleted successfully');
    } catch (e) {
      print('❌ Failed to delete account: $e');
      throw Exception('Failed to delete account: $e');
    }
  }
}