import 'package:url_launcher/url_launcher.dart';
import 'dart:io' show Platform;

class SupportService {
  /// Open native Mail app with pre-filled email
  static Future<void> submitSupportRequest({
    required String requestType,
    required String subject,
    required String description,
    String priority = 'medium',
    String? appVersion,
    String? deviceInfo,
    String? screenshotUrl,
  }) async {
    try {
      // Format the email subject
      final emailSubject = '[Stox App ${requestType.toUpperCase()}] $subject';
      
      // Create the email body with all the details
      final emailBody = '''Hello Stox Support Team,

Request Type: ${requestType.toUpperCase()}
Priority: ${priority.toUpperCase()}

Description:
$description

---
Technical Information:
• App Version: ${appVersion ?? '1.0.0'}
• Device: ${deviceInfo ?? '${Platform.operatingSystem} ${Platform.operatingSystemVersion}'}
${screenshotUrl != null ? '• Screenshot: $screenshotUrl' : ''}

Please help me with this ${requestType == 'bug' ? 'bug report' : requestType == 'feature' ? 'feature request' : requestType == 'support' ? 'support question' : 'feedback'}.

Thank you!''';

      // Create mailto URL with pre-filled content
      final String encodedSubject = Uri.encodeComponent(emailSubject);
      final String encodedBody = Uri.encodeComponent(emailBody);
      final String mailtoUrl = 'mailto:pradhancode@gmail.com?subject=$encodedSubject&body=$encodedBody';
      
      final Uri uri = Uri.parse(mailtoUrl);
      
      print('📧 Opening Mail app with pre-filled email...');
      print('📧 To: pradhancode@gmail.com');
      print('📧 Subject: $emailSubject');
      
      // Launch the Mail app
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
        print('✅ Mail app opened successfully');
      } else {
        throw Exception('Could not open Mail app. Please make sure you have Mail configured on your device.');
      }
    } catch (e) {
      print('❌ Error opening Mail app: $e');
      throw Exception('Failed to open Mail app: $e');
    }
  }
  
  /// Quick bug report helper
  static Future<void> reportBug({
    required String title,
    required String description,
    String priority = 'medium',
    String? deviceInfo,
  }) async {
    return await submitSupportRequest(
      requestType: 'bug',
      subject: 'Bug Report: $title',
      description: description,
      priority: priority,
      deviceInfo: deviceInfo,
    );
  }

  /// Quick feature request helper
  static Future<void> requestFeature({
    required String title,
    required String description,
    String priority = 'low',
  }) async {
    return await submitSupportRequest(
      requestType: 'feature',
      subject: 'Feature Request: $title',
      description: description,
      priority: priority,
    );
  }

  /// Quick feedback helper
  static Future<void> submitFeedback({
    required String title,
    required String feedback,
  }) async {
    return await submitSupportRequest(
      requestType: 'feedback',
      subject: 'App Feedback: $title',
      description: feedback,
      priority: 'low',
    );
  }
}