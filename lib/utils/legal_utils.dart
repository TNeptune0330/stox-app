import 'package:shared_preferences/shared_preferences.dart';

class LegalUtils {
  static const String _termsAcceptedKey = 'terms_accepted';
  static const String _privacyAcceptedKey = 'privacy_accepted';
  static const String _acceptanceDateKey = 'terms_acceptance_date';

  /// Check if user has accepted both terms and privacy policy
  static Future<bool> hasAcceptedTerms() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final termsAccepted = prefs.getBool(_termsAcceptedKey) ?? false;
      final privacyAccepted = prefs.getBool(_privacyAcceptedKey) ?? false;
      
      return termsAccepted && privacyAccepted;
    } catch (e) {
      print('Error checking terms acceptance: $e');
      return false;
    }
  }

  /// Accept both terms and privacy policy
  static Future<void> acceptTerms() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_termsAcceptedKey, true);
      await prefs.setBool(_privacyAcceptedKey, true);
      await prefs.setString(_acceptanceDateKey, DateTime.now().toIso8601String());
    } catch (e) {
      print('Error saving terms acceptance: $e');
      rethrow;
    }
  }

  /// Clear terms acceptance (for testing or reset)
  static Future<void> clearAcceptance() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_termsAcceptedKey);
      await prefs.remove(_privacyAcceptedKey);
      await prefs.remove(_acceptanceDateKey);
    } catch (e) {
      print('Error clearing terms acceptance: $e');
    }
  }

  /// Get the date when terms were accepted
  static Future<DateTime?> getAcceptanceDate() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final dateString = prefs.getString(_acceptanceDateKey);
      if (dateString != null) {
        return DateTime.parse(dateString);
      }
    } catch (e) {
      print('Error getting acceptance date: $e');
    }
    return null;
  }

  /// Check if terms need to be re-accepted (if older than 1 year)
  static Future<bool> needsReAcceptance() async {
    try {
      final acceptanceDate = await getAcceptanceDate();
      if (acceptanceDate == null) return true;
      
      final oneYearAgo = DateTime.now().subtract(const Duration(days: 365));
      return acceptanceDate.isBefore(oneYearAgo);
    } catch (e) {
      print('Error checking if re-acceptance needed: $e');
      return true;
    }
  }
}