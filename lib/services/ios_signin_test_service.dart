import 'dart:io';
import 'package:flutter/services.dart';
// import 'package:google_sign_in/google_sign_in.dart'; // Temporarily disabled
import '../config/api_keys.dart';

class IOSSignInTestService {
  static const String _logPrefix = '[iOS-Test]';

  static Future<void> runAllTests() async {
    print('$_logPrefix ========================================');
    print('$_logPrefix iOS GOOGLE SIGN-IN TESTS TEMPORARILY DISABLED');
    print('$_logPrefix ========================================');
    return; // Exit early to prevent Google Sign-In crashes
  }
  
  /*
  static Future<void> _testPlatformInfo() async {
    print('$_logPrefix Test 1: Platform Information');
    try {
      print('$_logPrefix Platform: ${Platform.operatingSystem}');
      print('$_logPrefix Platform version: ${Platform.operatingSystemVersion}');
      print('$_logPrefix Is iOS: ${Platform.isIOS}');
      print('$_logPrefix Is Android: ${Platform.isAndroid}');
      print('$_logPrefix ✅ Platform info test passed');
    } catch (e) {
      print('$_logPrefix ❌ Platform info test failed: $e');
    }
    print('$_logPrefix ----------------------------------------');
  }

  static Future<void> _testGoogleSignInConfiguration() async {
    print('$_logPrefix Test 2: Google Sign-In Configuration');
    try {
      print('$_logPrefix iOS Client ID: ${ApiKeys.googleSignInIOSClientId}');
      print('$_logPrefix Android Client ID: ${ApiKeys.googleSignInAndroidClientId}');
      print('$_logPrefix Web Client ID: ${ApiKeys.googleSignInWebClientId}');
      
      // Validate client IDs
      if (ApiKeys.googleSignInIOSClientId.isEmpty) {
        print('$_logPrefix ❌ iOS Client ID is empty');
      } else if (!ApiKeys.googleSignInIOSClientId.contains('googleusercontent.com')) {
        print('$_logPrefix ❌ iOS Client ID format invalid');
      } else {
        print('$_logPrefix ✅ iOS Client ID format valid');
      }
      
      print('$_logPrefix ✅ Configuration test passed');
    } catch (e) {
      print('$_logPrefix ❌ Configuration test failed: $e');
    }
    print('$_logPrefix ----------------------------------------');
  }

  static Future<void> _testGoogleSignInInitialization() async {
    print('$_logPrefix Test 3: Google Sign-In Initialization');
    try {
      GoogleSignIn? googleSignIn;
      
      if (Platform.isIOS) {
        print('$_logPrefix Initializing for iOS...');
        googleSignIn = GoogleSignIn(
          clientId: ApiKeys.googleSignInIOSClientId,
          scopes: ['email', 'profile', 'openid'],
        );
      } else {
        print('$_logPrefix Initializing for Android...');
        googleSignIn = GoogleSignIn(
          scopes: ['email', 'profile'],
        );
      }
      
      print('$_logPrefix Google Sign-In object created');
      print('$_logPrefix Scopes: ${googleSignIn.scopes}');
      print('$_logPrefix Current user: ${googleSignIn.currentUser?.email ?? 'None'}');
      
      print('$_logPrefix ✅ Initialization test passed');
    } catch (e) {
      print('$_logPrefix ❌ Initialization test failed: $e');
    }
    print('$_logPrefix ----------------------------------------');
  }

  static Future<void> _testGoogleSignInAvailability() async {
    print('$_logPrefix Test 4: Google Sign-In Availability');
    try {
      final googleSignIn = GoogleSignIn(
        clientId: Platform.isIOS ? ApiKeys.googleSignInIOSClientId : null,
        scopes: ['email', 'profile'],
      );
      
      print('$_logPrefix Checking if already signed in...');
      final isSignedIn = await googleSignIn.isSignedIn();
      print('$_logPrefix Is signed in: $isSignedIn');
      
      if (isSignedIn) {
        print('$_logPrefix Current user: ${googleSignIn.currentUser?.email}');
      }
      
      print('$_logPrefix ✅ Availability test passed');
    } catch (e) {
      print('$_logPrefix ❌ Availability test failed: $e');
    }
    print('$_logPrefix ----------------------------------------');
  }

  static Future<void> _testSignInProcess() async {
    print('$_logPrefix Test 5: Sign-In Process (Safe Test)');
    try {
      final googleSignIn = GoogleSignIn(
        clientId: Platform.isIOS ? ApiKeys.googleSignInIOSClientId : null,
        scopes: ['email', 'profile'],
      );
      
      print('$_logPrefix Testing silent sign-in...');
      final silentUser = await googleSignIn.signInSilently();
      
      if (silentUser != null) {
        print('$_logPrefix ✅ Silent sign-in successful');
        print('$_logPrefix User: ${silentUser.email}');
        print('$_logPrefix Display name: ${silentUser.displayName}');
      } else {
        print('$_logPrefix ℹ️ No existing session for silent sign-in');
      }
      
      print('$_logPrefix ✅ Sign-in process test passed');
    } catch (e) {
      print('$_logPrefix ❌ Sign-in process test failed: $e');
    }
    print('$_logPrefix ----------------------------------------');
  }

  static Future<void> testFullSignInFlow() async {
    print('$_logPrefix ========================================');
    print('$_logPrefix      FULL SIGN-IN FLOW TEST');
    print('$_logPrefix ========================================');
    
    try {
      final googleSignIn = GoogleSignIn(
        clientId: Platform.isIOS ? ApiKeys.googleSignInIOSClientId : null,
        scopes: ['email', 'profile'],
      );
      
      print('$_logPrefix Step 1: Sign out any existing user...');
      await googleSignIn.signOut();
      print('$_logPrefix ✅ Sign out completed');
      
      print('$_logPrefix Step 2: Starting sign-in flow...');
      print('$_logPrefix WARNING: This will trigger the actual sign-in UI');
      
      final googleUser = await googleSignIn.signIn();
      
      if (googleUser != null) {
        print('$_logPrefix ✅ Sign-in successful!');
        print('$_logPrefix User: ${googleUser.email}');
        print('$_logPrefix Display name: ${googleUser.displayName}');
        print('$_logPrefix ID: ${googleUser.id}');
        print('$_logPrefix Photo URL: ${googleUser.photoUrl}');
        
        print('$_logPrefix Step 3: Getting authentication...');
        final googleAuth = await googleUser.authentication;
        print('$_logPrefix ✅ Authentication obtained');
        print('$_logPrefix Access token length: ${googleAuth.accessToken?.length ?? 0}');
        print('$_logPrefix ID token length: ${googleAuth.idToken?.length ?? 0}');
        
      } else {
        print('$_logPrefix ❌ Sign-in was cancelled or failed');
      }
      
    } catch (e) {
      print('$_logPrefix ❌ Full sign-in flow test failed: $e');
      if (e is PlatformException) {
        print('$_logPrefix Error code: ${e.code}');
        print('$_logPrefix Error message: ${e.message}');
        print('$_logPrefix Error details: ${e.details}');
      }
    }
    
    print('$_logPrefix ========================================');
    print('$_logPrefix        FULL TEST COMPLETED');
    print('$_logPrefix ========================================');
  }
  */
}