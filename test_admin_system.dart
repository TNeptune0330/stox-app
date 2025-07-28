#!/usr/bin/env dart

import 'dart:io';

void main() async {
  print('🧪 Testing Admin System Implementation');
  print('=====================================');
  
  // Test 1: Check UserModel has isAdmin field
  print('\n📊 Test 1: UserModel isAdmin field...');
  
  final userModelCheck = await Process.run('grep', ['-n', 'final bool isAdmin', 'lib/models/user_model.dart']);
  if (userModelCheck.exitCode == 0) {
    print('✅ UserModel has isAdmin field');
  } else {
    print('❌ UserModel missing isAdmin field');
  }
  
  // Test 2: Check UserModel constructor includes isAdmin
  print('\n🔧 Test 2: UserModel constructor...');
  
  final constructorCheck = await Process.run('grep', ['-A', '10', 'UserModel({', 'lib/models/user_model.dart']);
  if (constructorCheck.exitCode == 0 && constructorCheck.stdout.toString().contains('required this.isAdmin')) {
    print('✅ UserModel constructor requires isAdmin');
  } else {
    print('❌ UserModel constructor missing isAdmin requirement');
  }
  
  // Test 3: Check fromJson includes isAdmin
  print('\n📝 Test 3: UserModel fromJson...');
  
  final fromJsonCheck = await Process.run('grep', ['-A', '10', 'factory UserModel.fromJson', 'lib/models/user_model.dart']);
  if (fromJsonCheck.exitCode == 0 && fromJsonCheck.stdout.toString().contains('is_admin')) {
    print('✅ UserModel fromJson handles is_admin');
  } else {
    print('❌ UserModel fromJson missing is_admin handling');
  }
  
  // Test 4: Check AuthProvider exposes isAdmin
  print('\n👤 Test 4: AuthProvider isAdmin getter...');
  
  final authProviderCheck = await Process.run('grep', ['-n', 'get isAdmin', 'lib/providers/auth_provider.dart']);
  if (authProviderCheck.exitCode == 0) {
    print('✅ AuthProvider exposes isAdmin getter');
  } else {
    print('❌ AuthProvider missing isAdmin getter');
  }
  
  // Test 5: Check LocalDatabaseService includes isAdmin
  print('\n💾 Test 5: LocalDatabaseService UserModel creation...');
  
  final localDbCheck = await Process.run('grep', ['-A', '8', 'final defaultUser = UserModel(', 'lib/services/local_database_service.dart']);
  if (localDbCheck.exitCode == 0 && localDbCheck.stdout.toString().contains('isAdmin: false')) {
    print('✅ LocalDatabaseService creates UserModel with isAdmin');
  } else {
    print('❌ LocalDatabaseService missing isAdmin in UserModel creation');
  }
  
  // Test 6: Check login screen includes isAdmin
  print('\n🔐 Test 6: Login screen UserModel creation...');
  
  final loginCheck = await Process.run('grep', ['-A', '8', 'UserModel(', 'lib/screens/auth/login_screen.dart']);
  if (loginCheck.exitCode == 0 && loginCheck.stdout.toString().contains('isAdmin: false')) {
    print('✅ Login screen creates UserModel with isAdmin');
  } else {
    print('❌ Login screen missing isAdmin in UserModel creation');
  }
  
  // Test 7: Check Settings screen uses isAdmin
  print('\n⚙️  Test 7: Settings screen admin check...');
  
  final settingsCheck = await Process.run('grep', ['-n', 'authProvider.isAdmin', 'lib/screens/settings/settings_screen.dart']);
  if (settingsCheck.exitCode == 0) {
    print('✅ Settings screen checks authProvider.isAdmin');
  } else {
    print('❌ Settings screen not using authProvider.isAdmin');
  }
  
  // Test 8: Check support system files exist
  print('\n📧 Test 8: Support system files...');
  
  final supportServiceExists = await File('lib/services/support_service.dart').exists();
  final supportScreenExists = await File('lib/screens/support/support_screen.dart').exists();
  final analyticsServiceExists = await File('lib/services/analytics_service.dart').exists();
  final analyticsScreenExists = await File('lib/screens/admin/analytics_screen.dart').exists();
  
  if (supportServiceExists && supportScreenExists && analyticsServiceExists && analyticsScreenExists) {
    print('✅ All support and analytics files exist');
  } else {
    print('❌ Some support/analytics files missing');
    print('   Support service: $supportServiceExists');
    print('   Support screen: $supportScreenExists');
    print('   Analytics service: $analyticsServiceExists');
    print('   Analytics screen: $analyticsScreenExists');
  }
  
  // Test 9: Check SQL script exists
  print('\n🗄️  Test 9: SQL setup script...');
  
  final sqlScriptExists = await File('supabase_admin_setup.sql').exists();
  if (sqlScriptExists) {
    print('✅ Supabase admin setup SQL script exists');
  } else {
    print('❌ SQL setup script missing');
  }
  
  // Summary
  print('\n📋 Summary:');
  final allTests = [
    userModelCheck.exitCode == 0,
    constructorCheck.exitCode == 0 && constructorCheck.stdout.toString().contains('required this.isAdmin'),
    fromJsonCheck.exitCode == 0 && fromJsonCheck.stdout.toString().contains('is_admin'),
    authProviderCheck.exitCode == 0,
    localDbCheck.exitCode == 0 && localDbCheck.stdout.toString().contains('isAdmin: false'),
    loginCheck.exitCode == 0 && loginCheck.stdout.toString().contains('isAdmin: false'),
    settingsCheck.exitCode == 0,
    supportServiceExists && supportScreenExists && analyticsServiceExists && analyticsScreenExists,
    sqlScriptExists,
  ];
  
  final passedTests = allTests.where((test) => test).length;
  final totalTests = allTests.length;
  
  print('Tests passed: $passedTests/$totalTests');
  
  if (passedTests == totalTests) {
    print('\n🎉 SUCCESS: Admin system implementation complete!');
    print('\nNext steps:');
    print('1. Run: flutter pub get');
    print('2. Run: flutter analyze (check for any remaining issues)');
    print('3. Execute supabase_admin_setup.sql in your Supabase dashboard');
    print('4. Test the app with your admin email: pradhancode@gmail.com');
    exit(0);
  } else {
    print('\n⚠️  Some tests failed - check the implementation');
    exit(1);
  }
}