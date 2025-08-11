import 'package:flutter/material.dart';
import '../../theme/modern_theme.dart';

class TermsOfServiceScreen extends StatelessWidget {
  const TermsOfServiceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ModernTheme.backgroundPrimary,
      appBar: AppBar(
        title: const Text('Terms of Service'),
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
            Text(
              'Terms of Service',
              style: ModernTheme.displayMedium.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: ModernTheme.spaceM),
            Text(
              'Last updated: ${DateTime.now().toString().substring(0, 10)}',
              style: ModernTheme.bodyMedium.copyWith(
                color: ModernTheme.textMuted,
              ),
            ),
            const SizedBox(height: ModernTheme.spaceXL),
            
            _buildSection(
              '1. Acceptance of Terms',
              'By downloading, installing, or using the Stox Trading Simulator app ("Service"), you agree to be bound by these Terms of Service ("Terms"). If you disagree with any part of these terms, then you may not access the Service.',
            ),
            
            _buildSection(
              '2. Description of Service',
              'Stox is a stock trading simulation app that allows users to practice trading with virtual money using real market data. This is purely educational software designed to help users learn about stock trading without financial risk.',
            ),
            
            _buildSection(
              '3. Important Disclaimers',
              '• This is a SIMULATION only - no real money is involved\n'
              '• Past performance does not guarantee future results\n'
              '• Market data may be delayed and should not be used for actual trading decisions\n'
              '• This app is for educational purposes only and does not constitute financial advice\n'
              '• We are not a licensed financial advisor or broker',
            ),
            
            _buildSection(
              '4. User Accounts',
              'You may need to create an account to use certain features of the Service. You are responsible for safeguarding your account credentials and for all activities that occur under your account.',
            ),
            
            _buildSection(
              '5. Acceptable Use',
              'You agree not to:\n'
              '• Use the Service for any unlawful purpose\n'
              '• Attempt to gain unauthorized access to the Service\n'
              '• Interfere with or disrupt the Service\n'
              '• Upload malicious code or content\n'
              '• Impersonate others or provide false information',
            ),
            
            _buildSection(
              '6. Intellectual Property',
              'The Service and its original content, features, and functionality are owned by Stox and are protected by international copyright, trademark, patent, trade secret, and other intellectual property laws.',
            ),
            
            _buildSection(
              '7. Privacy Policy',
              'Your privacy is important to us. Please review our Privacy Policy, which also governs your use of the Service, to understand our practices.',
            ),
            
            _buildSection(
              '8. Data Sources',
              'Market data is provided by third-party sources including Finnhub and other financial data providers. We do not guarantee the accuracy, completeness, or timeliness of this data.',
            ),
            
            _buildSection(
              '9. Limitation of Liability',
              'In no event shall Stox, its directors, employees, partners, agents, suppliers, or affiliates be liable for any indirect, incidental, special, consequential, or punitive damages resulting from your use of the Service.',
            ),
            
            _buildSection(
              '10. Termination',
              'We may terminate or suspend your account and access to the Service immediately, without prior notice, for conduct that we believe violates these Terms or is harmful to other users of the Service, us, or third parties.',
            ),
            
            _buildSection(
              '11. Changes to Terms',
              'We reserve the right to modify or replace these Terms at any time. If a revision is material, we will provide at least 30 days notice prior to any new terms taking effect.',
            ),
            
            _buildSection(
              '12. Governing Law',
              'These Terms shall be interpreted and governed by the laws of the jurisdiction where the Service is provided, without regard to conflict of law provisions.',
            ),
            
            _buildSection(
              '13. Contact Information',
              'If you have any questions about these Terms of Service, please contact us at:\n\n'
              'Email: pradhancode@gmail.com\n'
              'Website: www.stoxapp.com',
            ),
            
            const SizedBox(height: ModernTheme.spaceXXL),
            
            Container(
              padding: const EdgeInsets.all(ModernTheme.spaceL),
              decoration: BoxDecoration(
                color: ModernTheme.accentBlue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(ModernTheme.radiusL),
                border: Border.all(
                  color: ModernTheme.accentBlue.withOpacity(0.3),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: ModernTheme.accentBlue,
                        size: 24,
                      ),
                      const SizedBox(width: ModernTheme.spaceM),
                      Text(
                        'Educational Purpose Only',
                        style: ModernTheme.titleMedium.copyWith(
                          color: ModernTheme.accentBlue,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: ModernTheme.spaceM),
                  Text(
                    'This app is designed purely for educational purposes to help users learn about stock trading. No real money is involved, and this should not be considered as financial advice.',
                    style: ModernTheme.bodyMedium.copyWith(
                      color: ModernTheme.textPrimary,
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

  Widget _buildSection(String title, String content) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: ModernTheme.titleLarge.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: ModernTheme.spaceM),
        Text(
          content,
          style: ModernTheme.bodyMedium.copyWith(
            height: 1.6,
          ),
        ),
        const SizedBox(height: ModernTheme.spaceXL),
      ],
    );
  }
}