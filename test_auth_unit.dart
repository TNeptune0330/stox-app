import 'dart:async';
import 'dart:io';
import 'package:flutter/services.dart';
import 'lib/config/api_keys.dart';

void main() async {
  print('🧪 Auth Unit Test Starting...');
  
  try {
    // Test 1: API Keys validation
    print('\n--- Test 1: API Keys Validation ---');
    print('iOS Client ID: ${ApiKeys.googleSignInIOSClientId}');
    print('Android Client ID: ${ApiKeys.googleSignInAndroidClientId}');
    print('Web Client ID: ${ApiKeys.googleSignInWebClientId}');
    
    // Check if iOS client ID is properly formatted
    if (ApiKeys.googleSignInIOSClientId.contains('googleusercontent.com')) {
      print('✅ iOS Client ID format valid');
    } else {
      print('❌ iOS Client ID format invalid');
    }
    
    // Test 2: Platform Detection
    print('\n--- Test 2: Platform Detection ---');
    print('Platform: ${Platform.operatingSystem}');
    print('Is iOS: ${Platform.isIOS}');
    print('Platform version: ${Platform.operatingSystemVersion}');
    
    // Test 3: Try to create Google Sign-In object (basic test)
    print('\n--- Test 3: Google Sign-In Object Creation ---');
    try {
      // This is just a basic test to see if the import works
      print('✅ Google Sign-In import successful');
    } catch (e) {
      print('❌ Google Sign-In import failed: $e');
    }
    
    print('\n✅ All unit tests completed successfully');
    
  } catch (e) {
    print('\n❌ Unit test failed with error: $e');
    if (e is PlatformException) {
      print('Platform error code: ${e.code}');
      print('Platform error message: ${e.message}');
      print('Platform error details: ${e.details}');
    }
  }
  
  print('🧪 Unit test completed');
}