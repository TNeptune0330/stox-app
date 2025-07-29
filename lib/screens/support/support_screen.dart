import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/theme_provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/support_service.dart';
import 'dart:io' show Platform;

class SupportScreen extends StatefulWidget {
  const SupportScreen({super.key});

  @override
  State<SupportScreen> createState() => _SupportScreenState();
}

class _SupportScreenState extends State<SupportScreen> {
  final _formKey = GlobalKey<FormState>();
  final _subjectController = TextEditingController();
  final _descriptionController = TextEditingController();
  
  String _selectedType = 'support';
  String _selectedPriority = 'medium';
  bool _isSubmitting = false;

  final Map<String, String> _requestTypes = {
    'bug': '🐛 Bug Report',
    'feature': '💡 Feature Request', 
    'support': '❓ Support Question',
    'feedback': '💬 General Feedback',
  };

  final Map<String, String> _priorities = {
    'low': '🟢 Low',
    'medium': '🟡 Medium',
    'high': '🟠 High',
    'critical': '🔴 Critical',
  };

  @override
  void dispose() {
    _subjectController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _submitRequest() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    try {
      final deviceInfo = _getDeviceInfo();
      
      await SupportService.submitSupportRequest(
        requestType: _selectedType,
        subject: _subjectController.text.trim(),
        description: _descriptionController.text.trim(),
        priority: _selectedPriority,
        appVersion: '1.0.0',
        deviceInfo: deviceInfo,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Support request submitted successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        
        // Clear form
        _subjectController.clear();
        _descriptionController.clear();
        setState(() {
          _selectedType = 'support';
          _selectedPriority = 'medium';
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  String _getDeviceInfo() {
    try {
      return 'Platform: ${Platform.operatingSystem}, '
             'Version: ${Platform.operatingSystemVersion}';
    } catch (e) {
      return 'Platform: Unknown';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return Scaffold(
          backgroundColor: themeProvider.background,
          appBar: AppBar(
            title: const Text('Support & Feedback'),
            backgroundColor: themeProvider.background,
            foregroundColor: themeProvider.contrast,
            elevation: 0,
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: themeProvider.backgroundHigh,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: themeProvider.theme.withOpacity(0.3),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: themeProvider.theme.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              Icons.support_agent,
                              color: themeProvider.theme,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'We\'re Here to Help',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: themeProvider.contrast,
                                  ),
                                ),
                                Text(
                                  'Report bugs, request features, or get support',
                                  style: TextStyle(
                                    color: themeProvider.contrast.withOpacity(0.7),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.blue.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: Colors.blue.withOpacity(0.3),
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.email,
                              color: Colors.blue,
                              size: 16,
                            ),
                            const SizedBox(width: 8),
                            Flexible(
                              child: Text(
                                'Responses sent to: pradhancode@gmail.com',
                                style: TextStyle(
                                  color: Colors.blue[700],
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Form
                Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Request Type
                      Text(
                        'Request Type',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: themeProvider.contrast,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        decoration: BoxDecoration(
                          color: themeProvider.backgroundHigh,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: themeProvider.theme.withOpacity(0.3),
                          ),
                        ),
                        child: DropdownButton<String>(
                          value: _selectedType,
                          isExpanded: true,
                          underline: const SizedBox(),
                          dropdownColor: themeProvider.backgroundHigh,
                          style: TextStyle(color: themeProvider.contrast),
                          onChanged: (value) {
                            setState(() => _selectedType = value!);
                          },
                          items: _requestTypes.entries.map((entry) {
                            return DropdownMenuItem(
                              value: entry.key,
                              child: Text(entry.value),
                            );
                          }).toList(),
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Priority (only for bugs and high priority items)
                      if (_selectedType == 'bug' || _selectedType == 'support') ...[
                        Text(
                          'Priority',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: themeProvider.contrast,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          decoration: BoxDecoration(
                            color: themeProvider.backgroundHigh,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: themeProvider.theme.withOpacity(0.3),
                            ),
                          ),
                          child: DropdownButton<String>(
                            value: _selectedPriority,
                            isExpanded: true,
                            underline: const SizedBox(),
                            dropdownColor: themeProvider.backgroundHigh,
                            style: TextStyle(color: themeProvider.contrast),
                            onChanged: (value) {
                              setState(() => _selectedPriority = value!);
                            },
                            items: _priorities.entries.map((entry) {
                              return DropdownMenuItem(
                                value: entry.key,
                                child: Text(entry.value),
                              );
                            }).toList(),
                          ),
                        ),
                        const SizedBox(height: 20),
                      ],

                      // Subject
                      Text(
                        'Subject',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: themeProvider.contrast,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _subjectController,
                        decoration: InputDecoration(
                          hintText: 'Brief description of your ${_selectedType}...',
                          hintStyle: TextStyle(
                            color: themeProvider.contrast.withOpacity(0.5),
                          ),
                          filled: true,
                          fillColor: themeProvider.backgroundHigh,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: themeProvider.theme.withOpacity(0.3),
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: themeProvider.theme.withOpacity(0.3),
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: themeProvider.theme,
                              width: 2,
                            ),
                          ),
                        ),
                        style: TextStyle(color: themeProvider.contrast),
                        validator: (value) {
                          if (value?.trim().isEmpty ?? true) {
                            return 'Please enter a subject';
                          }
                          return null;
                        },
                      ),

                      const SizedBox(height: 20),

                      // Description
                      Text(
                        'Description',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: themeProvider.contrast,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _descriptionController,
                        maxLines: 6,
                        decoration: InputDecoration(
                          hintText: _getDescriptionHint(),
                          hintStyle: TextStyle(
                            color: themeProvider.contrast.withOpacity(0.5),
                          ),
                          filled: true,
                          fillColor: themeProvider.backgroundHigh,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: themeProvider.theme.withOpacity(0.3),
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: themeProvider.theme.withOpacity(0.3),
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: themeProvider.theme,
                              width: 2,
                            ),
                          ),
                        ),
                        style: TextStyle(color: themeProvider.contrast),
                        validator: (value) {
                          if (value?.trim().isEmpty ?? true) {
                            return 'Please provide a detailed description';
                          }
                          if (value!.trim().length < 10) {
                            return 'Please provide more details (at least 10 characters)';
                          }
                          return null;
                        },
                      ),

                      const SizedBox(height: 32),

                      // Submit Button
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _isSubmitting ? null : _submitRequest,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: themeProvider.theme,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 0,
                          ),
                          child: _isSubmitting
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                              : Text(
                                  'Submit ${_requestTypes[_selectedType]?.split(' ').last ?? 'Request'}',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Contact Info
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: themeProvider.theme.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: themeProvider.theme.withOpacity(0.2),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '📧 Direct Contact',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: themeProvider.contrast,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'For urgent issues, email directly: pradhancode@gmail.com',
                              style: TextStyle(
                                fontSize: 12,
                                color: themeProvider.contrast.withOpacity(0.7),
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
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
      },
    );
  }

  String _getDescriptionHint() {
    switch (_selectedType) {
      case 'bug':
        return 'Describe the bug in detail:\n• What were you doing when it happened?\n• What did you expect to happen?\n• What actually happened?\n• Can you reproduce it?';
      case 'feature':
        return 'Describe your feature idea:\n• What would this feature do?\n• How would it improve the app?\n• Any specific requirements?';
      case 'support':
        return 'Describe your question or issue:\n• What are you trying to accomplish?\n• What specific help do you need?\n• Have you tried anything already?';
      case 'feedback':
        return 'Share your thoughts about the app:\n• What do you like?\n• What could be improved?\n• Any suggestions for new features?';
      default:
        return 'Please provide as much detail as possible...';
    }
  }
}