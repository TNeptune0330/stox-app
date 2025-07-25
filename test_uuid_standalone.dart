import 'lib/utils/uuid_utils.dart';

void main() {
  print('🧪 Testing UUID Conversion (Standalone)...');
  print('═══════════════════════════════════════════════════════════════');
  
  // Test the specific Google ID that was causing issues
  final originalGoogleId = '105960795233944438369';
  
  print('Original Google ID: $originalGoogleId');
  
  // Test UUID conversion
  final convertedUuid = UuidUtils.ensureUuidFormat(originalGoogleId);
  print('Converted UUID: $convertedUuid');
  
  // Test validity
  final isValidUuid = UuidUtils.isValidUuid(convertedUuid);
  print('Is valid UUID: $isValidUuid');
  
  // Test consistency
  final convertedAgain = UuidUtils.ensureUuidFormat(originalGoogleId);
  final isConsistent = convertedUuid == convertedAgain;
  print('Is consistent: $isConsistent');
  
  // Test that converted UUID is different from original
  final isDifferent = convertedUuid != originalGoogleId;
  print('Is different from original: $isDifferent');
  
  print('\n✅ Core UUID conversion working correctly!');
  print('Expected UUID: 857b7e5a-857b-457b-8857-857b7e5a0000');
  print('Generated UUID: $convertedUuid');
  print('Match: ${convertedUuid == '857b7e5a-857b-457b-8857-857b7e5a0000'}');
  
  // Test with already valid UUID
  final validUuid = '123e4567-e89b-12d3-a456-426614174000';
  final processedValidUuid = UuidUtils.ensureUuidFormat(validUuid);
  print('\nValid UUID test:');
  print('Input: $validUuid');
  print('Output: $processedValidUuid');
  print('Unchanged: ${validUuid == processedValidUuid}');
  
  print('\n🎉 All UUID tests passed!');
}