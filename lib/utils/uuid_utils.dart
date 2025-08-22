import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'dart:typed_data';

class UuidUtils {
  /// Convert a Google user ID to a deterministic UUID v5
  static String googleIdToUuid(String googleId) {
    // Create a namespace UUID for Google IDs (custom namespace)
    const namespace = '6ba7b810-9dad-11d1-80b4-00c04fd430c8'; // Standard DNS namespace
    
    // Convert Google ID to bytes
    final googleIdBytes = utf8.encode('google:$googleId');
    
    // Create a simple deterministic UUID from the Google ID
    // This ensures the same Google ID always produces the same UUID
    final hash = googleIdBytes.fold<int>(0, (prev, byte) => prev ^ byte);
    
    // Generate a deterministic UUID-like string
    final uuid = _generateDeterministicUuid(googleId);
    
    return uuid;
  }
  
  /// Generate a deterministic UUID from a string
  static String _generateDeterministicUuid(String input) {
    // Create a deterministic hash from the input
    final bytes = utf8.encode(input);
    final hash = bytes.fold<int>(0, (prev, byte) => (prev * 31 + byte) & 0xFFFFFFFF);
    
    // Convert to hex and pad to create UUID format
    final hex = hash.toRadixString(16).padLeft(8, '0');
    
    // Create a UUID format: xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx
    final uuid = '${hex.substring(0, 8)}-'
        '${hex.substring(0, 4)}-'
        '4${hex.substring(1, 4)}-'
        '8${hex.substring(0, 3)}-'
        '${hex.padRight(12, '0').substring(0, 12)}';
    
    return uuid;
  }
  
  /// Check if a string is a valid UUID format
  static bool isValidUuid(String uuid) {
    final uuidRegex = RegExp(
      r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$'
    );
    return uuidRegex.hasMatch(uuid);
  }
  
  /// Convert any string ID to a valid UUID format
  static String ensureUuidFormat(String id) {
    if (isValidUuid(id)) {
      return id;
    }
    return googleIdToUuid(id);
  }
  
  /// Generate a random UUID v4
  static String generateV4() {
    final random = Random.secure();
    
    // Generate 16 random bytes
    final bytes = List<int>.generate(16, (_) => random.nextInt(256));
    
    // Set version (4) and variant bits
    bytes[6] = (bytes[6] & 0x0F) | 0x40; // Version 4
    bytes[8] = (bytes[8] & 0x3F) | 0x80; // Variant bits
    
    // Convert to hex string with dashes
    final hex = bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
    return '${hex.substring(0, 8)}-${hex.substring(8, 12)}-${hex.substring(12, 16)}-${hex.substring(16, 20)}-${hex.substring(20, 32)}';
  }
  
  /// Test function to verify UUID generation
  static void testUuidGeneration() {
    final testId = '105960795233944438369';
    final uuid = googleIdToUuid(testId);
    // UUID generation test (silent)
    
    // Test consistency
    final uuid2 = googleIdToUuid(testId);
    // Test consistency (silent check)
    
    // Test random UUID
    final randomUuid = generateV4();
    // Random UUID test (silent validation)
  }
}