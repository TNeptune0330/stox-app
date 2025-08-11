import 'package:flutter/material.dart';
import '../../theme/modern_theme.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ModernTheme.backgroundPrimary,
      appBar: AppBar(
        title: const Text('Privacy Policy'),
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
              'Privacy Policy',
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
              'Introduction',
              'This Privacy Policy describes how Stox Trading Simulator ("we", "our", or "us") collects, uses, and shares information about you when you use our mobile application and related services (collectively, the "Service").',
            ),
            
            _buildSection(
              'Information We Collect',
              'We collect information you provide directly to us, such as:\n\n'
              '• Account Information: Email address, username, and profile information when you create an account\n'
              '• Usage Data: Information about how you use the app, including trading activity, preferences, and interactions\n'
              '• Device Information: Device type, operating system, unique device identifiers, and mobile network information\n'
              '• Location Information: Approximate location based on IP address (not precise location)',
            ),
            
            _buildSection(
              'How We Use Your Information',
              'We use the information we collect to:\n\n'
              '• Provide, maintain, and improve the Service\n'
              '• Process transactions and maintain your trading simulation portfolio\n'
              '• Send you technical notices, updates, and support messages\n'
              '• Respond to your comments, questions, and customer service requests\n'
              '• Monitor and analyze trends, usage, and activities in connection with the Service\n'
              '• Personalize and improve your experience',
            ),
            
            _buildSection(
              'Information Sharing',
              'We do not sell, rent, or trade your personal information to third parties. We may share your information in the following circumstances:\n\n'
              '• With service providers who perform services on our behalf\n'
              '• To comply with legal obligations or respond to legal requests\n'
              '• To protect our rights, property, or safety, or that of others\n'
              '• In connection with a business transaction such as a merger or acquisition',
            ),
            
            _buildSection(
              'Data Security',
              'We implement appropriate technical and organizational measures to protect your personal information against unauthorized access, alteration, disclosure, or destruction. However, no method of transmission over the internet is 100% secure.',
            ),
            
            _buildSection(
              'Third-Party Services',
              'Our Service integrates with third-party services:\n\n'
              '• Market Data Providers: We use Finnhub and other financial data providers for real-time market information\n'
              '• Authentication: Google Sign-In for secure account creation and login\n'
              '• Analytics: Usage analytics to improve app performance\n'
              '• Cloud Storage: Supabase for secure data storage and synchronization',
            ),
            
            _buildSection(
              'Data Retention',
              'We retain your information for as long as your account is active or as needed to provide you services. You may delete your account at any time, and we will delete your personal information within 30 days of account deletion.',
            ),
            
            _buildSection(
              'Children\'s Privacy',
              'Our Service is not intended for children under the age of 13. We do not knowingly collect personal information from children under 13. If you are a parent and believe your child has provided us with personal information, please contact us.',
            ),
            
            _buildSection(
              'Your Rights',
              'Depending on your location, you may have certain rights regarding your personal information:\n\n'
              '• Access: Request access to your personal information\n'
              '• Correction: Request correction of inaccurate information\n'
              '• Deletion: Request deletion of your personal information\n'
              '• Portability: Request a copy of your information in a portable format\n'
              '• Opt-out: Opt out of certain data processing activities',
            ),
            
            _buildSection(
              'Cookies and Similar Technologies',
              'We use cookies and similar tracking technologies to collect information about your browsing activities and to distinguish you from other users. This helps us provide you with a better experience and improve the Service.',
            ),
            
            _buildSection(
              'International Data Transfers',
              'Your information may be transferred to and processed in countries other than your own. We ensure appropriate safeguards are in place to protect your information in accordance with applicable data protection laws.',
            ),
            
            _buildSection(
              'Changes to This Privacy Policy',
              'We may update this Privacy Policy from time to time. We will notify you of any changes by posting the new Privacy Policy within the app and updating the "Last updated" date.',
            ),
            
            _buildSection(
              'Contact Us',
              'If you have any questions about this Privacy Policy, please contact us at:\n\n'
              'Email: pradhancode@gmail.com\n'
              'Address: [Your Company Address]\n'
              'Website: www.stoxapp.com',
            ),
            
            const SizedBox(height: ModernTheme.spaceXXL),
            
            Container(
              padding: const EdgeInsets.all(ModernTheme.spaceL),
              decoration: BoxDecoration(
                color: ModernTheme.accentGreen.withOpacity(0.1),
                borderRadius: BorderRadius.circular(ModernTheme.radiusL),
                border: Border.all(
                  color: ModernTheme.accentGreen.withOpacity(0.3),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.security,
                        color: ModernTheme.accentGreen,
                        size: 24,
                      ),
                      const SizedBox(width: ModernTheme.spaceM),
                      Text(
                        'Your Privacy Matters',
                        style: ModernTheme.titleMedium.copyWith(
                          color: ModernTheme.accentGreen,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: ModernTheme.spaceM),
                  Text(
                    'We are committed to protecting your privacy and being transparent about how we use your data. All trading data is simulated and does not involve real financial transactions.',
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