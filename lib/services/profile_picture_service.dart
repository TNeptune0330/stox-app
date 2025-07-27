import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ProfilePictureService {
  static final SupabaseClient _supabase = Supabase.instance.client;
  static const String _bucketName = 'profile-pictures';
  
  /// Pick an image from gallery or camera
  static Future<XFile?> pickImage({ImageSource source = ImageSource.gallery}) async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: source,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 80,
      );
      return image;
    } catch (e) {
      print('Error picking image: $e');
      return null;
    }
  }
  
  /// Upload profile picture to Supabase storage
  static Future<String?> uploadProfilePicture({
    required String userId,
    required XFile imageFile,
  }) async {
    try {
      // Ensure bucket exists first
      await ensureBucketExists();
      
      // Create unique filename
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = '$userId/profile_${timestamp}.jpg';
      
      Uint8List imageBytes;
      if (kIsWeb) {
        imageBytes = await imageFile.readAsBytes();
      } else {
        imageBytes = await File(imageFile.path).readAsBytes();
      }
      
      // Upload to Supabase storage
      final String path = await _supabase.storage
          .from(_bucketName)
          .uploadBinary(fileName, imageBytes, fileOptions: const FileOptions(
            cacheControl: '3600',
            upsert: true,
          ));
      
      // Get public URL
      final String publicUrl = _supabase.storage
          .from(_bucketName)
          .getPublicUrl(fileName);
      
      print('✅ Profile picture uploaded: $publicUrl');
      return publicUrl;
      
    } catch (e) {
      print('❌ Error uploading profile picture: $e');
      // For production, disable profile picture uploads if storage is not configured
      print('⚠️ Profile picture upload disabled - storage bucket not configured');
      return null;
    }
  }
  
  /// Delete old profile picture
  static Future<bool> deleteProfilePicture(String url) async {
    try {
      // Extract file path from URL
      final uri = Uri.parse(url);
      final pathSegments = uri.pathSegments;
      
      if (pathSegments.length >= 3) {
        final fileName = pathSegments.sublist(2).join('/');
        
        await _supabase.storage
            .from(_bucketName)
            .remove([fileName]);
        
        print('✅ Old profile picture deleted: $fileName');
        return true;
      }
      
      return false;
    } catch (e) {
      print('❌ Error deleting profile picture: $e');
      return false;
    }
  }
  
  /// Update user profile with new avatar URL
  static Future<bool> updateUserAvatar({
    required String userId,
    required String avatarUrl,
  }) async {
    try {
      await _supabase
          .from('users')
          .update({'avatar_url': avatarUrl})
          .eq('id', userId);
      
      print('✅ User avatar URL updated in database');
      return true;
    } catch (e) {
      print('❌ Error updating user avatar URL: $e');
      return false;
    }
  }
  
  /// Complete profile picture update flow
  static Future<String?> updateProfilePicture({
    required String userId,
    required XFile imageFile,
    String? oldAvatarUrl,
  }) async {
    try {
      // Upload new profile picture
      final newAvatarUrl = await uploadProfilePicture(
        userId: userId,
        imageFile: imageFile,
      );
      
      if (newAvatarUrl == null) {
        print('❌ Failed to upload new profile picture');
        return null;
      }
      
      // Update user profile in database
      final updateSuccess = await updateUserAvatar(
        userId: userId,
        avatarUrl: newAvatarUrl,
      );
      
      if (!updateSuccess) {
        print('❌ Failed to update user avatar in database');
        return null;
      }
      
      // Delete old profile picture if it exists
      if (oldAvatarUrl != null && oldAvatarUrl.isNotEmpty) {
        await deleteProfilePicture(oldAvatarUrl);
      }
      
      return newAvatarUrl;
    } catch (e) {
      print('❌ Error in complete profile picture update: $e');
      return null;
    }
  }
  
  /// Create storage bucket if it doesn't exist
  static Future<void> ensureBucketExists() async {
    try {
      // Check if bucket exists
      final buckets = await _supabase.storage.listBuckets();
      final bucketExists = buckets.any((bucket) => bucket.name == _bucketName);
      
      if (!bucketExists) {
        // Create bucket
        await _supabase.storage.createBucket(_bucketName, const BucketOptions(
          public: true,
          allowedMimeTypes: ['image/jpeg', 'image/png', 'image/webp'],
          fileSizeLimit: '2MB',
        ));
        print('✅ Profile pictures bucket created');
      }
    } catch (e) {
      print('❌ Error ensuring bucket exists: $e');
    }
  }
}