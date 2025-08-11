import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../theme/modern_theme.dart';

class ContactFormScreen extends StatefulWidget {
  const ContactFormScreen({super.key});

  @override
  State<ContactFormScreen> createState() => _ContactFormScreenState();
}

class _ContactFormScreenState extends State<ContactFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _messageController = TextEditingController();
  String _selectedType = 'Bug Report';
  bool _isSubmitting = false;

  final List<String> _contactTypes = ['Bug Report', 'Feature Request'];

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSubmitting = true;
    });

    try {
      // Create mailto URL with pre-filled content
      final String subject = Uri.encodeComponent('Stox App: $_selectedType');
      final String body = Uri.encodeComponent(
        'Contact Type: $_selectedType\n\n'
        'Message:\n${_messageController.text}\n\n'
        '---\n'
        'Sent from Stox Trading Simulator App'
      );
      
      final Uri emailUri = Uri(
        scheme: 'mailto',
        path: 'pradhancode@gmail.com',
        query: 'subject=$subject&body=$body',
      );

      // Try to launch email client
      try {
        final bool launched = await launchUrl(
          emailUri,
          mode: LaunchMode.externalApplication,
        );
        
        if (launched && mounted) {
          // Show success message
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.white),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text('Email client opened successfully! Your message is ready to send.'),
                  ),
                ],
              ),
              backgroundColor: ModernTheme.accentGreen,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(ModernTheme.radiusM),
              ),
              duration: const Duration(seconds: 4),
            ),
          );
          
          // Clear form after successful submission
          _messageController.clear();
          setState(() {
            _selectedType = 'Bug Report';
          });
        } else if (mounted) {
          throw Exception('Unable to launch email client');
        }
      } catch (e) {
        // Handle cases where no email client is available or launch fails
        // Fallback: show email information if no email client available
        if (mounted) {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              backgroundColor: ModernTheme.backgroundCard,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(ModernTheme.radiusL),
              ),
              title: Row(
                children: [
                  Icon(Icons.email, color: ModernTheme.accentBlue),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Email Details',
                      style: ModernTheme.titleLarge.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'No email client found. Please send manually to:',
                    style: ModernTheme.bodyMedium,
                  ),
                  const SizedBox(height: ModernTheme.spaceM),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(ModernTheme.spaceM),
                    decoration: BoxDecoration(
                      color: ModernTheme.accentBlue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(ModernTheme.radiusM),
                      border: Border.all(color: ModernTheme.accentBlue.withOpacity(0.3)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'To: pradhancode@gmail.com',
                          style: ModernTheme.bodyMedium.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Subject: Stox App: $_selectedType',
                          style: ModernTheme.bodyMedium.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Message:',
                          style: ModernTheme.bodyMedium.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _messageController.text,
                          style: ModernTheme.bodySmall.copyWith(
                            color: ModernTheme.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    // Clear form
                    _messageController.clear();
                    setState(() {
                      _selectedType = 'Bug Report';
                    });
                  },
                  child: Text(
                    'Got it',
                    style: TextStyle(
                      color: ModernTheme.accentBlue,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          );
        }
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ModernTheme.backgroundPrimary,
      appBar: AppBar(
        title: const Text('Contact Us'),
        backgroundColor: ModernTheme.backgroundPrimary,
        foregroundColor: ModernTheme.textPrimary,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(ModernTheme.spaceL),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(ModernTheme.spaceL),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    ModernTheme.accentBlue,
                    ModernTheme.accentPurple,
                  ],
                ),
                borderRadius: BorderRadius.circular(ModernTheme.radiusL),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.support_agent,
                    color: Colors.white,
                    size: 32,
                  ),
                  const SizedBox(width: ModernTheme.spaceM),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Get in Touch',
                          style: ModernTheme.headlineMedium.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Report bugs or suggest new features',
                          style: ModernTheme.bodyMedium.copyWith(
                            color: Colors.white.withOpacity(0.9),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: ModernTheme.spaceXL),
            
            // Contact Form
            Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Contact Type',
                    style: ModernTheme.titleMedium.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: ModernTheme.spaceM),
                  
                  // Type Selection
                  Container(
                    decoration: BoxDecoration(
                      color: ModernTheme.backgroundCard,
                      borderRadius: BorderRadius.circular(ModernTheme.radiusL),
                      boxShadow: ModernTheme.shadowCard,
                    ),
                    child: Column(
                      children: _contactTypes.map((type) {
                        final isSelected = _selectedType == type;
                        final color = type == 'Bug Report' ? ModernTheme.accentRed : ModernTheme.accentGreen;
                        final icon = type == 'Bug Report' ? Icons.bug_report : Icons.lightbulb_outline;
                        
                        return InkWell(
                          onTap: () {
                            setState(() {
                              _selectedType = type;
                            });
                          },
                          borderRadius: BorderRadius.circular(ModernTheme.radiusL),
                          child: Container(
                            padding: const EdgeInsets.all(ModernTheme.spaceM),
                            decoration: BoxDecoration(
                              color: isSelected ? color.withOpacity(0.1) : Colors.transparent,
                              borderRadius: BorderRadius.circular(ModernTheme.radiusL),
                              border: isSelected ? Border.all(color: color.withOpacity(0.5)) : null,
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: color.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Icon(
                                    icon,
                                    color: color,
                                    size: 24,
                                  ),
                                ),
                                const SizedBox(width: ModernTheme.spaceM),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        type,
                                        style: ModernTheme.titleMedium.copyWith(
                                          fontWeight: FontWeight.bold,
                                          color: isSelected ? color : ModernTheme.textPrimary,
                                        ),
                                      ),
                                      Text(
                                        type == 'Bug Report' 
                                            ? 'Report issues or problems'
                                            : 'Suggest new features or improvements',
                                        style: ModernTheme.bodySmall.copyWith(
                                          color: ModernTheme.textMuted,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Radio<String>(
                                  value: type,
                                  groupValue: _selectedType,
                                  activeColor: color,
                                  onChanged: (value) {
                                    if (value != null) {
                                      setState(() {
                                        _selectedType = value;
                                      });
                                    }
                                  },
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  
                  const SizedBox(height: ModernTheme.spaceXL),
                  
                  Text(
                    'Your Message',
                    style: ModernTheme.titleMedium.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: ModernTheme.spaceM),
                  
                  // Message Field
                  Container(
                    decoration: BoxDecoration(
                      color: ModernTheme.backgroundCard,
                      borderRadius: BorderRadius.circular(ModernTheme.radiusL),
                      boxShadow: ModernTheme.shadowCard,
                    ),
                    child: TextFormField(
                      controller: _messageController,
                      maxLines: 8,
                      decoration: InputDecoration(
                        hintText: _selectedType == 'Bug Report'
                            ? 'Please describe the bug you encountered, including steps to reproduce it...'
                            : 'Please describe your feature idea and how it would improve the app...',
                        hintStyle: ModernTheme.bodyMedium.copyWith(
                          color: ModernTheme.textMuted,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(ModernTheme.radiusL),
                          borderSide: BorderSide.none,
                        ),
                        filled: true,
                        fillColor: Colors.transparent,
                        contentPadding: const EdgeInsets.all(ModernTheme.spaceM),
                      ),
                      style: ModernTheme.bodyMedium,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter your message';
                        }
                        if (value.trim().length < 10) {
                          return 'Please provide more details (at least 10 characters)';
                        }
                        return null;
                      },
                    ),
                  ),
                  
                  const SizedBox(height: ModernTheme.spaceXL),
                  
                  // Submit Button
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _isSubmitting ? null : _submitForm,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _selectedType == 'Bug Report' 
                            ? ModernTheme.accentRed 
                            : ModernTheme.accentGreen,
                        foregroundColor: Colors.white,
                        elevation: 8,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(ModernTheme.radiusL),
                        ),
                        disabledBackgroundColor: ModernTheme.textMuted,
                      ),
                      child: _isSubmitting
                          ? Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                const Text('Sending...'),
                              ],
                            )
                          : Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.send,
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                const Text(
                                  'Submit',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ),
                  
                  const SizedBox(height: ModernTheme.spaceL),
                  
                  // Info Text
                  Container(
                    padding: const EdgeInsets.all(ModernTheme.spaceM),
                    decoration: BoxDecoration(
                      color: ModernTheme.accentBlue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(ModernTheme.radiusL),
                      border: Border.all(
                        color: ModernTheme.accentBlue.withOpacity(0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          color: ModernTheme.accentBlue,
                          size: 20,
                        ),
                        const SizedBox(width: ModernTheme.spaceM),
                        Expanded(
                          child: Text(
                            'Your message will be sent to pradhancode@gmail.com. We typically respond within 24 hours.',
                            style: ModernTheme.bodySmall.copyWith(
                              color: ModernTheme.accentBlue,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}