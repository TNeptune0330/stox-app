import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/theme_provider.dart';
import '../../services/storage_service.dart';
import '../legal/legal_document_screen.dart';
import '../auth/login_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  bool _termsAccepted = false;
  bool _privacyAccepted = false;
  bool _isLoading = false;

  bool get _canProceed => _termsAccepted && _privacyAccepted;

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return Scaffold(
          backgroundColor: themeProvider.background,
          body: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                children: [
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // App Logo and Welcome
                        Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: themeProvider.theme.withOpacity(0.1),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: themeProvider.theme.withOpacity(0.3),
                              width: 2,
                            ),
                          ),
                          child: Icon(
                            Icons.trending_up,
                            size: 64,
                            color: themeProvider.theme,
                          ),
                        ),
                        
                        const SizedBox(height: 32),
                        
                        Text(
                          'Welcome to Stox',
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: themeProvider.contrast,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        
                        const SizedBox(height: 16),
                        
                        Text(
                          'Learn stock trading without financial risk!\n\nPractice with real market data in a safe, educational environment.',
                          style: TextStyle(
                            fontSize: 16,
                            color: themeProvider.contrast.withOpacity(0.8),
                            height: 1.5,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        
                        const SizedBox(height: 48),
                        
                        // Legal Agreements Section
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: themeProvider.backgroundHigh,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: themeProvider.theme.withOpacity(0.2),
                              width: 1,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Before we begin',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: themeProvider.contrast,
                                ),
                              ),
                              
                              const SizedBox(height: 16),
                              
                              // Terms of Service
                              _buildLegalCheckbox(
                                isChecked: _termsAccepted,
                                onChanged: (value) {
                                  setState(() {
                                    _termsAccepted = value ?? false;
                                  });
                                },
                                text: 'I agree to the ',
                                linkText: 'Terms of Service',
                                onLinkTap: () => _showLegalDocument(
                                  title: 'Terms of Service',
                                  assetPath: 'assets/legal/terms_of_service.md',
                                ),
                                themeProvider: themeProvider,
                              ),
                              
                              const SizedBox(height: 12),
                              
                              // Privacy Policy
                              _buildLegalCheckbox(
                                isChecked: _privacyAccepted,
                                onChanged: (value) {
                                  setState(() {
                                    _privacyAccepted = value ?? false;
                                  });
                                },
                                text: 'I agree to the ',
                                linkText: 'Privacy Policy',
                                onLinkTap: () => _showLegalDocument(
                                  title: 'Privacy Policy',
                                  assetPath: 'assets/legal/privacy_policy.md',
                                ),
                                themeProvider: themeProvider,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  // Continue Button
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _canProceed ? _continueToApp : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _canProceed 
                            ? themeProvider.theme
                            : themeProvider.theme.withOpacity(0.3),
                        foregroundColor: Colors.white,
                        elevation: _canProceed ? 8 : 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : const Text(
                              'Continue to App',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Educational Disclaimer
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: themeProvider.themeHigh.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: themeProvider.themeHigh.withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          color: themeProvider.themeHigh,
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'This is a simulation app. No real money is involved.',
                            style: TextStyle(
                              fontSize: 14,
                              color: themeProvider.contrast.withOpacity(0.8),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildLegalCheckbox({
    required bool isChecked,
    required ValueChanged<bool?> onChanged,
    required String text,
    required String linkText,
    required VoidCallback onLinkTap,
    required ThemeProvider themeProvider,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Checkbox(
          value: isChecked,
          onChanged: onChanged,
          activeColor: themeProvider.theme,
          checkColor: Colors.white,
          side: BorderSide(
            color: themeProvider.theme.withOpacity(0.5),
            width: 2,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: GestureDetector(
            onTap: () => onChanged(!isChecked),
            child: RichText(
              text: TextSpan(
                text: text,
                style: TextStyle(
                  fontSize: 16,
                  color: themeProvider.contrast.withOpacity(0.9),
                ),
                children: [
                  WidgetSpan(
                    child: GestureDetector(
                      onTap: onLinkTap,
                      child: Text(
                        linkText,
                        style: TextStyle(
                          fontSize: 16,
                          color: themeProvider.theme,
                          fontWeight: FontWeight.bold,
                          decoration: TextDecoration.underline,
                          decorationColor: themeProvider.theme,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _showLegalDocument({
    required String title,
    required String assetPath,
  }) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => LegalDocumentScreen(
          title: title,
          assetPath: assetPath,
          showAcceptButton: false,
        ),
      ),
    );
  }

  Future<void> _continueToApp() async {
    if (!_canProceed) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // Save onboarding completion status
      await StorageService.setOnboardingCompleted(true);
      
      // Navigate to login screen
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => const LoginScreen(),
          ),
        );
      }
    } catch (e) {
      // Handle error
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
}