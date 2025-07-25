import 'dart:io';
import 'package:flutter/services.dart';
import 'lib/services/auth_service.dart';
import 'lib/config/api_keys.dart';

void main() async {
  print('🧪 Simple Sign-In Test Starting...');
  
  try {
    // Initialize the auth service
    print('Initializing auth service...');
    final authService = AuthService();
    print('✅ Auth service initialized');
    
    // Test sign-in
    print('Testing sign-in...');
    final user = await authService.signInWithGoogle();
    
    if (user != null) {
      print('✅ Sign-in successful: ${user.email}');
    } else {
      print('❌ Sign-in failed or was canceled');
    }
    
  } catch (e) {
    print('❌ Test failed with error: $e');
    if (e is PlatformException) {
      print('Platform error code: ${e.code}');
      print('Platform error message: ${e.message}');
      print('Platform error details: ${e.details}');
    }
  }
  
  print('🧪 Test completed');
}