import 'dart:convert';
import 'dart:math';
import '../models/user_model.dart';
import '../utils/uuid_utils.dart';
import 'storage_service.dart';

class AuthTestService {
  static const List<String> _testEmails = [
    'test.user@example.com',
    'john.doe@testmail.com',
    'jane.smith@demo.com',
    'trader.pro@testing.com',
    'market.wizard@fake.com',
  ];

  static const List<String> _testNames = [
    'Test User',
    'John Doe',
    'Jane Smith',
    'Trader Pro',
    'Market Wizard',
  ];

  /// Creates a fake user for testing authentication
  static UserModel createFakeUser() {
    final random = Random();
    final index = random.nextInt(_testEmails.length);
    
    // Generate a fake Google ID (similar to real ones)
    final fakeGoogleId = _generateFakeGoogleId();
    
    // Convert to proper UUID format
    final uuid = UuidUtils.ensureUuidFormat(fakeGoogleId);
    
    final user = UserModel(
      id: uuid,
      email: _testEmails[index],
      username: _testNames[index],
      avatarUrl: 'https://ui-avatars.com/api/?name=${_testNames[index].replaceAll(' ', '+')}&background=random',
      colorTheme: 'darkBlue',
      cashBalance: 10000.0,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    
    print('🧪 Created fake user for testing:');
    print('  Name: ${user.username}');
    print('  Email: ${user.email}');
    print('  Original Google ID: $fakeGoogleId');
    print('  Converted UUID: ${user.id}');
    print('  Cash Balance: \$${user.cashBalance.toStringAsFixed(2)}');
    
    return user;
  }

  /// Generate a fake Google ID that looks like a real one
  static String _generateFakeGoogleId() {
    final random = Random();
    final length = 21; // Real Google IDs are typically 21 digits
    
    String googleId = '';
    for (int i = 0; i < length; i++) {
      googleId += random.nextInt(10).toString();
    }
    
    return googleId;
  }

  /// Simulate a fake Google Sign In process
  static Future<UserModel> simulateGoogleSignIn() async {
    print('🔑 Simulating Google Sign In...');
    
    // Add some delay to simulate network call
    await Future.delayed(const Duration(milliseconds: 1500));
    
    final user = createFakeUser();
    
    // Cache the user (this should trigger UUID conversion if needed)
    await StorageService.cacheUser(user);
    
    print('✅ Fake Google Sign In completed successfully');
    return user;
  }

  /// Test UUID conversion with various Google ID formats
  static void testUuidConversion() {
    print('🧪 Testing UUID conversion with various Google ID formats:');
    
    final testIds = [
      '105960795233944438369',
      '123456789012345678901',
      '987654321098765432109',
      '111111111111111111111',
      '999999999999999999999',
    ];
    
    for (final id in testIds) {
      final uuid = UuidUtils.ensureUuidFormat(id);
      final isValid = UuidUtils.isValidUuid(uuid);
      
      print('  Google ID: $id');
      print('  UUID: $uuid');
      print('  Valid: $isValid');
      print('  ---');
    }
  }

  /// Clear all test data
  static Future<void> clearTestData() async {
    await StorageService.clearUserData();
    print('🧹 Test data cleared');
  }

  /// Get a list of test users for manual testing
  static List<Map<String, String>> getTestUsers() {
    return List.generate(_testEmails.length, (index) => {
      'email': _testEmails[index],
      'name': _testNames[index],
      'googleId': _generateFakeGoogleId(),
    });
  }
}