import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/theme_provider.dart';
import '../../services/storage_service.dart';
import '../main_navigation.dart';

class TutorialScreen extends StatefulWidget {
  const TutorialScreen({super.key});

  @override
  State<TutorialScreen> createState() => _TutorialScreenState();
}

class _TutorialScreenState extends State<TutorialScreen> with TickerProviderStateMixin {
  late PageController _pageController;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  
  int _currentPage = 0;
  bool _isLoading = false;

  final List<TutorialStep> _tutorialSteps = [
    TutorialStep(
      icon: Icons.trending_up,
      title: 'Welcome to Stox!',
      description: 'Learn stock trading without any financial risk. Practice with real market data in a safe environment.',
      buttonText: 'Learn Trading',
    ),
    TutorialStep(
      icon: Icons.attach_money,
      title: 'Understanding Stock Prices',
      description: 'Stock prices change based on supply and demand. When more people want to buy, prices go up. When more want to sell, prices go down.',
      buttonText: 'Next',
    ),
    TutorialStep(
      icon: Icons.shopping_cart,
      title: 'How to Buy Stocks',
      description: 'To buy a stock: 1) Search for it 2) Tap to view details 3) Hit "BUY" 4) Choose quantity 5) Confirm order. You now own shares!',
      buttonText: 'Next',
    ),
    TutorialStep(
      icon: Icons.sell,
      title: 'How to Sell Stocks',
      description: 'To sell: 1) Go to your Portfolio 2) Tap a stock you own 3) Hit "SELL" 4) Choose how many shares 5) Confirm. Cash is added to your balance!',
      buttonText: 'Next',
    ),
    TutorialStep(
      icon: Icons.bar_chart,
      title: 'Reading Stock Charts',
      description: 'Green means price went up, red means down. The chart shows price history. Look for trends - is it going up or down over time?',
      buttonText: 'Next',
    ),
    TutorialStep(
      icon: Icons.psychology,
      title: 'Trading Strategy Tips',
      description: 'Start small! Buy what you understand. Don\'t panic sell on red days. Diversify - don\'t put all money in one stock. Practice makes perfect!',
      buttonText: 'Next',
    ),
    TutorialStep(
      icon: Icons.search,
      title: 'Find Any Stock',
      description: 'Search for any company, ETF, or crypto. Try "Apple", "TSLA", "SPY", or "Bitcoin". Our system finds everything from global markets!',
      buttonText: 'Next',
    ),
    TutorialStep(
      icon: Icons.account_balance_wallet,
      title: 'Your Virtual Portfolio',
      description: 'Start with \$100,000 virtual cash. Track your performance, see profits/losses, and learn without risk. Perfect for beginners!',
      buttonText: 'Next',
    ),
    TutorialStep(
      icon: Icons.emoji_events,
      title: 'Earn Achievements',
      description: 'Complete challenges like "First Trade", "Profit Maker", "Diversified Portfolio". Unlock achievements as you master trading skills!',
      buttonText: 'Start Trading',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );
    _fadeController.forward();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  void _nextPage() {
    if (_currentPage < _tutorialSteps.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _completeTutorial();
    }
  }

  void _skipTutorial() {
    _completeTutorial();
  }

  Future<void> _completeTutorial() async {
    if (_isLoading) return;
    
    setState(() {
      _isLoading = true;
    });

    try {
      // Mark tutorial as completed
      await StorageService.setTutorialCompleted(true);
      
      // Navigate to main app
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => const MainNavigation(),
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

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return Scaffold(
          backgroundColor: themeProvider.background,
          body: SafeArea(
            child: Column(
              children: [
                // Skip button
                Align(
                  alignment: Alignment.topRight,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: TextButton(
                      onPressed: _isLoading ? null : _skipTutorial,
                      child: Text(
                        'Skip',
                        style: TextStyle(
                          color: themeProvider.theme,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
                
                // Tutorial content
                Expanded(
                  child: FadeTransition(
                    opacity: _fadeAnimation,
                    child: PageView.builder(
                      controller: _pageController,
                      onPageChanged: (page) {
                        setState(() {
                          _currentPage = page;
                        });
                      },
                      itemCount: _tutorialSteps.length,
                      itemBuilder: (context, index) {
                        final step = _tutorialSteps[index];
                        return _buildTutorialPage(step, themeProvider);
                      },
                    ),
                  ),
                ),
                
                // Page indicators
                _buildPageIndicators(themeProvider),
                
                // Next/Complete button
                Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _nextPage,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: themeProvider.theme,
                        foregroundColor: Colors.white,
                        elevation: 8,
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
                          : Text(
                              _tutorialSteps[_currentPage].buttonText,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildTutorialPage(TutorialStep step, ThemeProvider themeProvider) {
    return Padding(
      padding: const EdgeInsets.all(32.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Icon
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: themeProvider.theme.withOpacity(0.1),
              shape: BoxShape.circle,
              border: Border.all(
                color: themeProvider.theme.withOpacity(0.3),
                width: 3,
              ),
            ),
            child: Icon(
              step.icon,
              size: 80,
              color: themeProvider.theme,
            ),
          ),
          
          const SizedBox(height: 48),
          
          // Title
          Text(
            step.title,
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: themeProvider.contrast,
            ),
            textAlign: TextAlign.center,
          ),
          
          const SizedBox(height: 24),
          
          // Description
          Text(
            step.description,
            style: TextStyle(
              fontSize: 18,
              color: themeProvider.contrast.withOpacity(0.8),
              height: 1.6,
            ),
            textAlign: TextAlign.center,
          ),
          
          // Practice button for trading steps
          if (_currentPage >= 2 && _currentPage <= 4) ...[
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(
                    builder: (context) => const MainNavigation(),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: themeProvider.theme.withOpacity(0.1),
                foregroundColor: themeProvider.theme,
                side: BorderSide(color: themeProvider.theme),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              icon: const Icon(Icons.play_arrow),
              label: const Text(
                'Try Interactive Practice',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPageIndicators(ThemeProvider themeProvider) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(_tutorialSteps.length, (index) {
          return AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            margin: const EdgeInsets.symmetric(horizontal: 4),
            width: _currentPage == index ? 24 : 8,
            height: 8,
            decoration: BoxDecoration(
              color: _currentPage == index 
                  ? themeProvider.theme 
                  : themeProvider.theme.withOpacity(0.3),
              borderRadius: BorderRadius.circular(4),
            ),
          );
        }),
      ),
    );
  }
}

class TutorialStep {
  final IconData icon;
  final String title;
  final String description;
  final String buttonText;

  const TutorialStep({
    required this.icon,
    required this.title,
    required this.description,
    required this.buttonText,
  });
}