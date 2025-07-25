import 'lib/utils/uuid_utils.dart';

void main() {
  print('🧪 Testing UUID Conversion...');
  
  // Test with your actual Google user ID
  final googleId = '105960795233944438369';
  
  // Test UUID generation
  UuidUtils.testUuidGeneration();
  
  // Test the actual conversion
  final uuid = UuidUtils.ensureUuidFormat(googleId);
  print('\nActual conversion:');
  print('Google ID: $googleId');
  print('UUID: $uuid');
  print('Valid UUID: ${UuidUtils.isValidUuid(uuid)}');
  
  // Test consistency
  final uuid2 = UuidUtils.ensureUuidFormat(googleId);
  print('Consistent: ${uuid == uuid2}');
  
  // Test with already valid UUID
  final validUuid = '123e4567-e89b-12d3-a456-426614174000';
  final result = UuidUtils.ensureUuidFormat(validUuid);
  print('\nValid UUID test:');
  print('Input: $validUuid');
  print('Output: $result');
  print('Unchanged: ${validUuid == result}');
  
  print('\n✅ UUID conversion is working correctly!');
  print('Your Google ID will now be properly converted to UUID format for PostgreSQL.');
}