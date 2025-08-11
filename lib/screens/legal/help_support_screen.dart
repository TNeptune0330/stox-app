import 'package:flutter/material.dart';
import '../../theme/modern_theme.dart';
import 'contact_form_screen.dart';

class HelpSupportScreen extends StatelessWidget {
  const HelpSupportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ModernTheme.backgroundPrimary,
      appBar: AppBar(
        title: const Text('Help & Support'),
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
                    ModernTheme.accentGreen,
                    ModernTheme.accentBlue,
                  ],
                ),
                borderRadius: BorderRadius.circular(ModernTheme.radiusL),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.help_outline,
                    color: Colors.white,
                    size: 32,
                  ),
                  const SizedBox(width: ModernTheme.spaceM),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Need Help?',
                          style: ModernTheme.headlineMedium.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'We\'re here to help you get the most out of Stox',
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
            
            // FAQ Section
            Text(
              'Frequently Asked Questions',
              style: ModernTheme.titleLarge.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: ModernTheme.spaceL),
            
            _buildFAQItem(
              'What is Stox?',
              'Stox is a stock trading simulator that lets you practice trading with virtual money using real market data. It\'s designed to help you learn about investing without any financial risk.',
              Icons.info_outline,
              ModernTheme.accentBlue,
            ),
            
            _buildFAQItem(
              'Is real money involved?',
              'No! Stox uses only virtual money for trading. All transactions are simulated, so you can learn and practice without any financial risk. This is purely educational.',
              Icons.security,
              ModernTheme.accentGreen,
            ),
            
            _buildFAQItem(
              'How accurate is the market data?',
              'We use real market data from reliable financial data providers like Finnhub. However, data may be slightly delayed and should not be used for actual trading decisions.',
              Icons.trending_up,
              ModernTheme.accentOrange,
            ),
            
            _buildFAQItem(
              'How do I reset my portfolio?',
              'Currently, you can start fresh by creating a new account. In future updates, we\'ll add a portfolio reset feature in the settings.',
              Icons.refresh,
              ModernTheme.accentPurple,
            ),
            
            _buildFAQItem(
              'Can I compete with friends?',
              'While the app doesn\'t currently have direct multiplayer features, you can compare your performance with friends by sharing your portfolio stats and achievements.',
              Icons.people,
              ModernTheme.accentPink,
            ),
            
            _buildFAQItem(
              'What are achievements for?',
              'Achievements help gamify your learning experience. They track your trading milestones and help you stay motivated as you learn about investing.',
              Icons.emoji_events,
              ModernTheme.accentTeal,
            ),
            
            const SizedBox(height: ModernTheme.spaceXL),
            
            // Contact Section
            Text(
              'Still Need Help?',
              style: ModernTheme.titleLarge.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: ModernTheme.spaceL),
            
            // Single Contact Button
            Container(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const ContactFormScreen(),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: ModernTheme.accentBlue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.all(ModernTheme.spaceL),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(ModernTheme.radiusL),
                  ),
                  elevation: 4,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.support_agent, size: 24),
                    const SizedBox(width: ModernTheme.spaceM),
                    Text(
                      'Contact Support',
                      style: ModernTheme.titleMedium.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFAQItem(String question, String answer, IconData icon, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: ModernTheme.spaceM),
      decoration: BoxDecoration(
        color: ModernTheme.backgroundCard,
        borderRadius: BorderRadius.circular(ModernTheme.radiusL),
        boxShadow: ModernTheme.shadowCard,
      ),
      child: ExpansionTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            color: color,
            size: 20,
          ),
        ),
        title: Text(
          question,
          style: ModernTheme.titleMedium.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(ModernTheme.spaceL),
            child: Text(
              answer,
              style: ModernTheme.bodyMedium.copyWith(
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

}