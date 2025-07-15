import 'package:google_sign_in/google_sign_in.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user_model.dart';

class AuthService {
  final SupabaseClient _supabase = Supabase.instance.client;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  User? get currentUser => _supabase.auth.currentUser;
  bool get isSignedIn => currentUser != null;

  Future<UserModel?> signInWithGoogle() async {
    try {
      final googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        // User cancelled sign-in, return mock user for demo
        return await _createMockUser();
      }

      final googleAuth = await googleUser.authentication;
      final accessToken = googleAuth.accessToken;
      final idToken = googleAuth.idToken;

      if (accessToken == null || idToken == null) {
        // Token issue, use mock user for demo
        return await _createMockUser();
      }

      final response = await _supabase.auth.signInWithIdToken(
        provider: OAuthProvider.google,
        idToken: idToken,
        accessToken: accessToken,
      );

      if (response.user != null) {
        return await _createOrUpdateUser(response.user!);
      }

      return await _createMockUser();
    } catch (e) {
      // Always fallback to mock user for development/demo
      return await _createMockUser();
    }
  }

  Future<UserModel?> _createMockUser() async {
    try {
      // Create a mock user for testing - game-like names
      final gameNames = [
        'Wall Street Wolf',
        'Stock Shark',
        'Trading Tiger',
        'Market Master',
        'Bull Runner',
        'Bear Slayer',
        'Profit Prophet',
        'Gold Getter'
      ];
      
      final randomName = gameNames[DateTime.now().millisecondsSinceEpoch % gameNames.length];
      
      final mockUser = UserModel(
        id: 'player_${DateTime.now().millisecondsSinceEpoch}',
        email: 'trader@stoxgame.com',
        username: randomName,
        avatarUrl: null,
        colorTheme: 'dark',
        cashBalance: 10000.0,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      
      return mockUser;
    } catch (e) {
      throw Exception('Failed to create mock user: $e');
    }
  }

  Future<UserModel?> _createOrUpdateUser(User user) async {
    try {
      final existingUser = await _supabase
          .from('users')
          .select()
          .eq('id', user.id)
          .maybeSingle();

      if (existingUser == null) {
        final newUser = {
          'id': user.id,
          'email': user.email!,
          'username': user.userMetadata?['full_name'] ?? user.email!.split('@')[0],
          'avatar_url': user.userMetadata?['avatar_url'],
          'color_theme': 'light',
          'cash_balance': 10000.0,
          'created_at': DateTime.now().toIso8601String(),
          'updated_at': DateTime.now().toIso8601String(),
        };

        final response = await _supabase
            .from('users')
            .insert(newUser)
            .select()
            .single();

        return UserModel.fromJson(response);
      } else {
        final updatedUser = {
          'updated_at': DateTime.now().toIso8601String(),
        };

        final response = await _supabase
            .from('users')
            .update(updatedUser)
            .eq('id', user.id)
            .select()
            .single();

        return UserModel.fromJson(response);
      }
    } catch (e) {
      throw Exception('Failed to create/update user: $e');
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
    } catch (e) {
      throw Exception('Failed to update user data: $e');
    }
  }

  Future<void> signOut() async {
    try {
      await _googleSignIn.signOut();
      await _supabase.auth.signOut();
    } catch (e) {
      throw Exception('Failed to sign out: $e');
    }
  }
}