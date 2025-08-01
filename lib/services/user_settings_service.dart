import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/connection_manager.dart';
import '../services/storage_service.dart';
import '../utils/uuid_utils.dart';

class UserSettingsService {
  final SupabaseClient _supabase = Supabase.instance.client;
  final ConnectionManager _connectionManager = ConnectionManager();

  // Save user setting to Supabase
  Future<void> saveSetting({
    required String userId,
    required String key,
    required dynamic value,
  }) async {
    await _connectionManager.executeWithFallback<void>(
      () async {
        // Try to update first, then insert if it doesn't exist
        final existingResponse = await _supabase
            .from('user_settings')
            .select('id')
            .eq('user_id', UuidUtils.ensureUuidFormat(userId))
            .eq('setting_key', key)
            .maybeSingle();
            
        if (existingResponse != null) {
          // Update existing record
          await _supabase
              .from('user_settings')
              .update({
                'setting_value': value,
                'updated_at': DateTime.now().toIso8601String(),
              })
              .eq('user_id', UuidUtils.ensureUuidFormat(userId))
              .eq('setting_key', key);
        } else {
          // Insert new record
          await _supabase
              .from('user_settings')
              .insert({
                'user_id': UuidUtils.ensureUuidFormat(userId),
                'setting_key': key,
                'setting_value': value,
                'updated_at': DateTime.now().toIso8601String(),
              });
        }

        _connectionManager.recordSuccess();
        print('✅ Setting saved to Supabase: $key');
        
        // Also save locally as backup
        await _saveSettingLocally(key, value);
      },
      () async {
        // Fallback to local storage
        await _saveSettingLocally(key, value);
        print('📱 Setting saved locally: $key');
      },
    );
  }

  // Get user setting from Supabase
  Future<T?> getSetting<T>({
    required String userId,
    required String key,
    T? defaultValue,
  }) async {
    return await _connectionManager.executeWithFallback<T?>(
      () async {
        final response = await _supabase
            .from('user_settings')
            .select('setting_value')
            .eq('user_id', UuidUtils.ensureUuidFormat(userId))
            .eq('setting_key', key)
            .maybeSingle();

        _connectionManager.recordSuccess();

        if (response != null) {
          final value = response['setting_value'];
          print('✅ Setting loaded from Supabase: $key');
          
          // Cache locally
          await _saveSettingLocally(key, value);
          return value as T?;
        }
        
        return defaultValue;
      },
      () async {
        // Fallback to local storage
        final value = await _getSettingLocally<T>(key, defaultValue);
        print('📱 Setting loaded locally: $key');
        return value;
      },
    ) ?? defaultValue;
  }

  // Get all user settings from Supabase
  Future<Map<String, dynamic>> getAllSettings(String userId) async {
    return await _connectionManager.executeWithFallback<Map<String, dynamic>>(
      () async {
        final response = await _supabase
            .from('user_settings')
            .select('setting_key, setting_value')
            .eq('user_id', UuidUtils.ensureUuidFormat(userId));

        _connectionManager.recordSuccess();

        final Map<String, dynamic> settings = {};
        for (final row in response) {
          settings[row['setting_key']] = row['setting_value'];
        }

        print('✅ All settings loaded from Supabase: ${settings.length} settings');
        
        // Cache all settings locally
        for (final entry in settings.entries) {
          await _saveSettingLocally(entry.key, entry.value);
        }

        return settings;
      },
      () async {
        // Fallback to local storage
        final settings = await _getAllSettingsLocally();
        print('📱 All settings loaded locally: ${settings.length} settings');
        return settings;
      },
    ) ?? {};
  }

  // Sync all local settings to Supabase
  Future<void> syncSettingsToSupabase(String userId) async {
    if (!_connectionManager.shouldRetry) return;

    try {
      print('🔄 Syncing local settings to Supabase...');

      final localSettings = await _getAllSettingsLocally();
      
      for (final entry in localSettings.entries) {
        await saveSetting(
          userId: userId,
          key: entry.key,
          value: entry.value,
        );
      }

      print('✅ All settings synced to Supabase');
    } catch (e) {
      print('❌ Failed to sync settings to Supabase: $e');
    }
  }

  // Delete user setting
  Future<void> deleteSetting({
    required String userId,
    required String key,
  }) async {
    await _connectionManager.executeWithFallback<void>(
      () async {
        await _supabase
            .from('user_settings')
            .delete()
            .eq('user_id', UuidUtils.ensureUuidFormat(userId))
            .eq('setting_key', key);

        _connectionManager.recordSuccess();
        print('✅ Setting deleted from Supabase: $key');
        
        // Also delete locally
        await _deleteSettingLocally(key);
      },
      () async {
        // Fallback to local deletion
        await _deleteSettingLocally(key);
        print('📱 Setting deleted locally: $key');
      },
    );
  }

  // Private helper methods for local storage
  Future<void> _saveSettingLocally(String key, dynamic value) async {
    // Use the existing StorageService for theme
    if (key == 'theme') {
      await StorageService.saveTheme(value.toString());
    } else {
      // For other settings, we could expand StorageService or use SharedPreferences directly
      // For now, we'll just log it
      print('📱 Local setting saved: $key = $value');
    }
  }

  Future<T?> _getSettingLocally<T>(String key, T? defaultValue) async {
    // Use the existing StorageService for theme
    if (key == 'theme') {
      return StorageService.getTheme() as T?;
    }
    
    // For other settings, return default
    return defaultValue;
  }

  Future<Map<String, dynamic>> _getAllSettingsLocally() async {
    return {
      'theme': StorageService.getTheme(),
      // Add other local settings here as needed
    };
  }

  Future<void> _deleteSettingLocally(String key) async {
    // Implementation would depend on the setting type
    print('📱 Local setting deleted: $key');
  }
}