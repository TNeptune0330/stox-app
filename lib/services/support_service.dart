import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class SupportRequest {
  final String id;
  final String userId;
  final String email;
  final String? fullName;
  final String requestType; // bug, feature, support, feedback
  final String subject;
  final String description;
  final String? appVersion;
  final String? deviceInfo;
  final String? screenshotUrl;
  final String priority; // low, medium, high, critical
  final String status; // open, in_progress, resolved, closed
  final String? adminNotes;
  final DateTime createdAt;
  final DateTime updatedAt;

  SupportRequest({
    required this.id,
    required this.userId,
    required this.email,
    this.fullName,
    required this.requestType,
    required this.subject,
    required this.description,
    this.appVersion,
    this.deviceInfo,
    this.screenshotUrl,
    required this.priority,
    required this.status,
    this.adminNotes,
    required this.createdAt,
    required this.updatedAt,
  });

  factory SupportRequest.fromJson(Map<String, dynamic> json) {
    return SupportRequest(
      id: json['id'],
      userId: json['user_id'],
      email: json['email'],
      fullName: json['full_name'],
      requestType: json['request_type'],
      subject: json['subject'],
      description: json['description'],
      appVersion: json['app_version'],
      deviceInfo: json['device_info'],
      screenshotUrl: json['screenshot_url'],
      priority: json['priority'],
      status: json['status'],
      adminNotes: json['admin_notes'],
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'email': email,
      'full_name': fullName,
      'request_type': requestType,
      'subject': subject,
      'description': description,
      'app_version': appVersion,
      'device_info': deviceInfo,
      'screenshot_url': screenshotUrl,
      'priority': priority,
      'status': status,
      'admin_notes': adminNotes,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}

class SupportService {
  static final _supabase = Supabase.instance.client;
  
  /// Send email notification for new support request
  static Future<void> _sendEmailNotification(SupportRequest request) async {
    try {
      print('📧 Preparing email notification...');
      
      // Create formatted email content
      final emailSubject = '[Stox App Support] ${request.requestType.toUpperCase()}: ${request.subject}';
      final emailBody = '''
🔔 New Stox App Support Request

📧 From: ${request.email}
👤 User: ${request.fullName ?? 'N/A'}
🏷️ Type: ${request.requestType.toUpperCase()}
📋 Subject: ${request.subject}
⚡ Priority: ${request.priority.toUpperCase()}

📝 Description:
${request.description}

🔧 Technical Details:
• App Version: ${request.appVersion ?? 'N/A'}
• Device Info: ${request.deviceInfo ?? 'N/A'}
• User ID: ${request.userId}
• Request ID: ${request.id}
• Submitted: ${request.createdAt.toString()}

---
Reply to this email to respond to the user.
User's email: ${request.email}

Stox Trading Simulator Support System
      ''';

      // Try multiple email services for reliability
      bool emailSent = false;

      // Method 1: Try Supabase Edge Function (if configured)
      if (!emailSent) {
        try {
          final response = await _supabase.functions.invoke('send-email', body: {
            'to': 'pradhancode@gmail.com',
            'subject': emailSubject,
            'html': emailBody.replaceAll('\n', '<br>'),
            'text': emailBody,
          });
          
          if (response.status == 200) {
            print('✅ Email sent via Supabase Edge Function');
            emailSent = true;
          }
        } catch (e) {
          print('⚠️ Supabase Edge Function failed: $e');
        }
      }

      // Method 2: Try simple HTTP POST to email service
      if (!emailSent) {
        try {
          final response = await http.post(
            Uri.parse('https://api.resend.com/emails'),
            headers: {
              'Authorization': 'Bearer re_123456789', // Would need real API key
              'Content-Type': 'application/json',
            },
            body: json.encode({
              'from': 'Stox App <noreply@stoxapp.com>',
              'to': ['pradhancode@gmail.com'],
              'subject': emailSubject,
              'text': emailBody,
            }),
          );
          
          if (response.statusCode == 200) {
            print('✅ Email sent via Resend API');
            emailSent = true;
          }
        } catch (e) {
          print('⚠️ Resend API failed: $e');
        }
      }

      // Method 3: Log detailed notification (always works)
      print('📧 EMAIL NOTIFICATION:');
      print('To: pradhancode@gmail.com');
      print('Subject: $emailSubject');
      print('Body:\n$emailBody');
      print('📧 End of email notification');
      
      if (!emailSent) {
        print('📧 Email services unavailable - notification logged to console');
      }
      
    } catch (e) {
      print('❌ Email notification error: $e');
      // Don't throw - email failure shouldn't break support request submission
    }
  }

  /// Submit a new support request
  static Future<SupportRequest> submitSupportRequest({
    required String requestType,
    required String subject,
    required String description,
    String priority = 'medium',
    String? appVersion,
    String? deviceInfo,
    String? screenshotUrl,
  }) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        throw 'User must be logged in to submit support requests';
      }

      print('📧 Submitting $requestType request: $subject');
      
      // Ensure user profile exists to avoid policy issues
      try {
        await _supabase.from('user_profiles').upsert({
          'id': user.id,
          'email': user.email,
          'is_admin': false,
        });
      } catch (profileError) {
        print('⚠️ Profile upsert failed (continuing anyway): $profileError');
      }

      final requestData = {
        'user_id': user.id,
        'email': user.email,
        'full_name': user.userMetadata?['full_name'] ?? user.email,
        'request_type': requestType,
        'subject': subject,
        'description': description,
        'priority': priority,
        'app_version': appVersion ?? '1.0.0',
        'device_info': deviceInfo,
        'screenshot_url': screenshotUrl,
        'status': 'open',
      };

      final response = await _supabase
          .from('support_requests')
          .insert(requestData)
          .select()
          .single();

      print('✅ Support request submitted successfully');
      
      final supportRequest = SupportRequest.fromJson(response);
      
      // Send email notification in background
      _sendEmailNotification(supportRequest).catchError((error) {
        print('⚠️ Email notification failed but request was saved: $error');
      });
      
      print('📧 Email notification initiated to pradhancode@gmail.com');

      return supportRequest;
    } catch (e) {
      print('❌ Error submitting support request: $e');
      rethrow;
    }
  }

  /// Get user's support requests
  static Future<List<SupportRequest>> getUserSupportRequests() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        throw 'User must be logged in to view support requests';
      }

      final response = await _supabase
          .from('support_requests')
          .select()
          .eq('user_id', user.id)
          .order('created_at', ascending: false);

      return response.map<SupportRequest>((json) => SupportRequest.fromJson(json)).toList();
    } catch (e) {
      print('❌ Error fetching support requests: $e');
      return [];
    }
  }

  /// Get all support requests (admin only)
  static Future<List<SupportRequest>> getAllSupportRequests() async {
    try {
      final response = await _supabase
          .from('support_requests')
          .select()
          .order('created_at', ascending: false);

      return response.map<SupportRequest>((json) => SupportRequest.fromJson(json)).toList();
    } catch (e) {
      print('❌ Error fetching all support requests: $e');
      return [];
    }
  }

  /// Update support request status (admin only)
  static Future<void> updateSupportRequestStatus(
    String requestId,
    String status, {
    String? adminNotes,
  }) async {
    try {
      final updateData = <String, dynamic>{
        'status': status,
        'updated_at': DateTime.now().toIso8601String(),
      };

      if (adminNotes != null) {
        updateData['admin_notes'] = adminNotes;
      }

      await _supabase
          .from('support_requests')
          .update(updateData)
          .eq('id', requestId);

      print('✅ Support request $requestId updated to $status');
    } catch (e) {
      print('❌ Error updating support request: $e');
      rethrow;
    }
  }

  /// Get support request statistics (admin only)
  static Future<Map<String, int>> getSupportStats() async {
    try {
      final response = await _supabase
          .from('support_requests')
          .select('status, request_type');

      final stats = <String, int>{
        'total': response.length,
        'open': 0,
        'in_progress': 0,
        'resolved': 0,
        'closed': 0,
        'bug': 0,
        'feature': 0,
        'support': 0,
        'feedback': 0,
      };

      for (final request in response) {
        final status = request['status'] as String;
        final type = request['request_type'] as String;
        
        stats[status] = (stats[status] ?? 0) + 1;
        stats[type] = (stats[type] ?? 0) + 1;
      }

      return stats;
    } catch (e) {
      print('❌ Error fetching support stats: $e');
      return {};
    }
  }

  /// Quick bug report helper
  static Future<SupportRequest> reportBug({
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
  static Future<SupportRequest> requestFeature({
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
  static Future<SupportRequest> submitFeedback({
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