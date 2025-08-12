import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'legal_document_screen.dart';
import '../main_navigation.dart';

class TermsAcceptanceScreen extends StatefulWidget {
  const TermsAcceptanceScreen({super.key});

  @override
  State<TermsAcceptanceScreen> createState() => _TermsAcceptanceScreenState();
}

class _TermsAcceptanceScreenState extends State<TermsAcceptanceScreen> {
  bool _termsAccepted = false;
  bool _privacyAccepted = false;
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0a0a0a),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF0a0a0a),
              Color(0xFF1a1a1a),
              Color(0xFF1565c0),
            ],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 40),
                        
                        // Header
                        Center(
                          child: Column(
                            children: [
                              Container(
                                width: 80,
                                height: 80,
                                decoration: BoxDecoration(
                                  color: const Color(0xFF1565c0),
                                  borderRadius: BorderRadius.circular(20),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0xFF1565c0).withOpacity(0.3),
                                      blurRadius: 20,
                                      offset: const Offset(0, 10),
                                    ),
                                  ],
                                ),
                                child: const Icon(
                                  Icons.gavel,
                                  color: Colors.white,
                                  size: 40,
                                ),
                              ),
                              const SizedBox(height: 24),
                              const Text(
                                'Legal Agreement',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'Please review and accept our terms to continue',
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.7),
                                  fontSize: 16,
                                  height: 1.4,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                        
                        const SizedBox(height: 48),
                        
                        // Terms of Service Card
                        _buildDocumentCard(
                          title: 'Terms of Service',
                          description: 'Rules and guidelines for using Stox Trading Simulator',
                          icon: Icons.description,
                          isAccepted: _termsAccepted,
                          onTap: () => _viewDocument(
                            'Terms of Service',
                            'assets/legal/terms_of_service.md',
                            (accepted) => setState(() => _termsAccepted = accepted),
                          ),
                          onToggle: (value) => setState(() => _termsAccepted = value!),
                        ),
                        
                        const SizedBox(height: 24),
                        
                        // Privacy Policy Card
                        _buildDocumentCard(
                          title: 'Privacy Policy',
                          description: 'How we collect, use, and protect your information',
                          icon: Icons.privacy_tip,
                          isAccepted: _privacyAccepted,
                          onTap: () => _viewDocument(
                            'Privacy Policy',
                            'assets/legal/privacy_policy.md',
                            (accepted) => setState(() => _privacyAccepted = accepted),
                          ),
                          onToggle: (value) => setState(() => _privacyAccepted = value!),
                        ),
                        
                        const SizedBox(height: 32),
                        
                        // Important Notice
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1565c0).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: const Color(0xFF1565c0).withOpacity(0.3),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Row(
                                children: [
                                  Icon(
                                    Icons.info_outline,
                                    color: Color(0xFF1565c0),
                                    size: 20,
                                  ),
                                  SizedBox(width: 8),
                                  Text(
                                    'Important Notice',
                                    style: TextStyle(
                                      color: Color(0xFF1565c0),
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'This app is for educational purposes only. No real money is involved in trading. Virtual performance does not guarantee real-world trading success.',
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.8),
                                  fontSize: 14,
                                  height: 1.4,
                                ),
                              ),
                            ],
                          ),
                        ),
                        
                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
                ),
                
                // Continue Button
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: (_termsAccepted && _privacyAccepted) ? _acceptTerms : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: (_termsAccepted && _privacyAccepted)
                          ? const Color(0xFF1565c0)
                          : Colors.grey.shade700,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : Text(
                            (_termsAccepted && _privacyAccepted)
                                ? 'Continue to App'
                                : 'Please Accept Both Documents',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDocumentCard({
    required String title,
    required String description,
    required IconData icon,
    required bool isAccepted,
    required VoidCallback onTap,
    required Function(bool?) onToggle,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1a1a1a),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isAccepted
              ? const Color(0xFF1565c0)
              : Colors.grey.withOpacity(0.3),
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: isAccepted
                      ? const Color(0xFF1565c0).withOpacity(0.2)
                      : Colors.grey.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  color: isAccepted ? const Color(0xFF1565c0) : Colors.grey,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.7),
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Checkbox(
                value: isAccepted,
                onChanged: onToggle,
                activeColor: const Color(0xFF1565c0),
                checkColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _viewDocument(String title, String assetPath, Function(bool) onAccept) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => LegalDocumentScreen(
          title: title,
          assetPath: assetPath,
          showAcceptButton: true,
          onAccept: () {
            Navigator.of(context).pop();
            onAccept(true);
          },
        ),
      ),
    );
  }

  Future<void> _acceptTerms() async {
    setState(() => _isLoading = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('terms_accepted', true);
      await prefs.setBool('privacy_accepted', true);
      await prefs.setString('terms_acceptance_date', DateTime.now().toIso8601String());

      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => const MainNavigation(),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving acceptance: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }
}