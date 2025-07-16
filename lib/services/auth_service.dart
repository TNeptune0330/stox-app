import 'package:google_sign_in/google_sign_in.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user_model.dart';
import '../config/api_keys.dart';
import '../services/storage_service.dart';

class AuthService {
  final SupabaseClient _supabase = Supabase.instance.client;
  late final GoogleSignIn _googleSignIn;

  AuthService() {
    _googleSignIn = GoogleSignIn(
      // Remove serverClientId for local testing to avoid DEVELOPER_ERROR
      scopes: [
        'email',
        'profile',
      ],
    );
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
    try {
      print('🔑 Starting Google Sign In...');
      
      // Start Google Sign In flow
      final googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        print('❌ User cancelled Google Sign In');
        return null;
      }

      print('✅ Got Google user: ${googleUser.displayName}');
      
      // For demo purposes, create a local user without Supabase authentication
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
      
      print('✅ Successfully signed in with Google: ${userData.email}');
      
      // Cache user data locally for persistence
      await StorageService.cacheUser(userData);
      
      return userData;
      
    } catch (e) {
      print('❌ Google Sign In error: $e');
      rethrow;
    }
  }

  Future<UserModel?> _createOrUpdateUser(User user) async {
    try {
      print('👤 Creating/updating user profile...');
      
      // Check if user already exists
      final existingUser = await _supabase
          .from('users')
          .select()
          .eq('id', user.id)
          .maybeSingle();

      if (existingUser == null) {
        print('📝 Creating new user profile...');
        
        // Extract name from user metadata
        final fullName = user.userMetadata?['full_name'] ?? 
                        user.userMetadata?['name'] ?? 
                        user.email!.split('@')[0];
        
        final newUser = {
          'id': user.id,
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
        return UserModel.fromJson(response);
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
            .eq('id', user.id)
            .select()
            .single();

        print('✅ User updated successfully');
        return UserModel.fromJson(response);
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
          .single();

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
      
      await _supabase
          .from('users')
          .update(updates)
          .eq('id', currentUser!.id);
          
      print('✅ User data updated successfully');
    } catch (e) {
      print('❌ Failed to update user data: $e');
      throw Exception('Failed to update user data: $e');
    }
  }

  Future<void> signOut() async {
    try {
      print('🔓 Signing out...');
      
      // Clear local cache
      await StorageService.clearCache();
      
      // Sign out from Google
      await _googleSignIn.signOut();
      
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
      
      // Check if session is expired
      final now = DateTime.now();
      final expiresAt = DateTime.fromMillisecondsSinceEpoch(session.expiresAt! * 1000);
      
      return now.isBefore(expiresAt);
    } catch (e) {
      print('❌ Error checking session validity: $e');
      return false;
    }
  }

  Future<void> refreshSession() async {
    try {
      if (!isSignedIn) return;
      
      final session = await _supabase.auth.refreshSession();
      if (session.session == null) {
        throw Exception('Failed to refresh session');
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
        return null;
      }
      
      // Check if session is valid
      if (!await isSessionValid()) {
        print('⚠️ Session expired, attempting to refresh...');
        await refreshSession();
      }
      
      // Get user data
      final userData = await getCurrentUserData();
      if (userData != null) {
        print('✅ Session restored successfully');
        return userData;
      }
      
      return null;
    } catch (e) {
      print('❌ Failed to restore session: $e');
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