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
  late AnimationController _scaleController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<Offset> _slideAnimation;
  
  int _currentPage = 0;
  bool _isLoading = false;

  final List<TutorialStep> _tutorialSteps = [
    TutorialStep(
      icon: Icons.trending_up,
      title: 'Welcome to Stox!',
      subtitle: 'Learn. Trade. Profit.',
      description: 'Master stock trading with \$100K virtual cash\nZero risk, real market data',
      buttonText: 'Start Learning',
      primaryColor: Color(0xFF10B981),
      features: ['📈 Real market data', '💰 \$100K virtual cash', '🎯 Risk-free trading'],
    ),
    TutorialStep(
      icon: Icons.search,
      title: 'Discover Stocks',
      subtitle: 'Find your next investment',
      description: 'Search Apple, Tesla, Bitcoin & more\nGlobal markets at your fingertips',
      buttonText: 'Next',
      primaryColor: Color(0xFF3B82F6),
      features: ['🔍 Search any stock', '🌎 Global markets', '⚡ Instant results'],
    ),
    TutorialStep(
      icon: Icons.swap_horiz,
      title: 'Buy & Sell Simple',
      subtitle: 'Trade in 3 taps',
      description: 'Tap stock → Choose amount → Confirm\nThat\'s it! You\'re trading',
      buttonText: 'Next',
      primaryColor: Color(0xFFEA580C),
      features: ['📱 3-tap trading', '⚡ Instant orders', '💡 Smart suggestions'],
    ),
    TutorialStep(
      icon: Icons.account_balance_wallet,
      title: 'Track Performance',
      subtitle: 'Watch your wealth grow',
      description: 'Real-time portfolio tracking\nGreen profits, learn from losses',
      buttonText: 'Next',
      primaryColor: Color(0xFF8B5CF6),
      features: ['📊 Live tracking', '📈 Profit/loss charts', '🎯 Performance insights'],
    ),
    TutorialStep(
      icon: Icons.emoji_events,
      title: 'Ready to Trade!',
      subtitle: 'Your journey begins',
      description: 'Unlock achievements as you learn\nBecome a trading master',
      buttonText: 'Start Trading',
      primaryColor: Color(0xFFEAB308),
      features: ['🏆 Earn achievements', '📚 Learn by doing', '🚀 Build wealth'],
    ),
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    
    _fadeController = AnimationController(
      duration: Motion.slow,
      vsync: this,
    );
    _scaleController = AnimationController(
      duration: Motion.med,
      vsync: this,
    );
    _slideController = AnimationController(
      duration: Motion.med,
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Motion.easeOut),
    );
    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _scaleController, curve: Motion.spring),
    );
    _slideAnimation = Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(
      CurvedAnimation(parent: _slideController, curve: Motion.easeOut),
    );
    
    _startAnimations();
  }

  void _startAnimations() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) {
        _fadeController.forward();
      }
    });
    Future.delayed(const Duration(milliseconds: 200), () {
      if (mounted) {
        _scaleController.forward();
      }
    });
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) {
        _slideController.forward();
      }
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    _fadeController.dispose();
    _scaleController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  void _nextPage() {
    if (_currentPage < _tutorialSteps.length - 1) {
      // Reset animations for the next page
      _scaleController.reset();
      _slideController.reset();
      
      _pageController.nextPage(
        duration: Motion.med,
        curve: Motion.easeOut,
      ).then((_) {
        // Restart animations for the new page
        _startAnimations();
      });
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
                // Skip button with animation
                Align(
                  alignment: Alignment.topRight,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: FadeTransition(
                      opacity: _fadeAnimation,
                      child: TextButton.icon(
                        onPressed: _isLoading ? null : _skipTutorial,
                        icon: const Icon(Icons.close, size: 18),
                        label: const Text('Skip'),
                        style: TextButton.styleFrom(
                          foregroundColor: themeProvider.contrast.withOpacity(0.7),
                          backgroundColor: themeProvider.backgroundHigh,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
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
                
                // Next/Complete button with dynamic styling
                Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: SlideTransition(
                    position: Tween<Offset>(begin: const Offset(0, 0.5), end: Offset.zero).animate(
                      CurvedAnimation(parent: _slideController, curve: Motion.easeOut)
                    ),
                    child: FadeTransition(
                      opacity: _fadeAnimation,
                      child: SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _nextPage,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _tutorialSteps[_currentPage].primaryColor,
                            foregroundColor: Colors.white,
                            elevation: 12,
                            shadowColor: _tutorialSteps[_currentPage].primaryColor.withOpacity(0.4),
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
                              : AnimatedSwitcher(
                                  duration: Motion.med,
                                  child: Text(
                                    _tutorialSteps[_currentPage].buttonText,
                                    key: ValueKey(_currentPage),
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
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
    final bool _reducedMotion = MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        children: [
          const SizedBox(height: 40),
          
          // Animated icon with gradient background
          FadeTransition(
            opacity: _fadeAnimation,
            child: ScaleTransition(
              scale: _scaleAnimation,
              child: Container(
                width: 140,
                height: 140,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      step.primaryColor.withOpacity(0.1),
                      step.primaryColor.withOpacity(0.2),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: step.primaryColor.withOpacity(0.3),
                      blurRadius: 20,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: Icon(
                  step.icon,
                  size: 64,
                  color: step.primaryColor,
                ),
              ),
            ),
          ),
          
          const SizedBox(height: 32),
          
          // Title with slide animation
          SlideTransition(
            position: _slideAnimation,
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: Text(
                step.title,
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  color: themeProvider.contrast,
                  letterSpacing: -0.5,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
          
          const SizedBox(height: 8),
          
          // Subtitle
          SlideTransition(
            position: Tween<Offset>(begin: const Offset(0, 0.2), end: Offset.zero).animate(
              CurvedAnimation(parent: _slideController, curve: Motion.easeOut)
            ),
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: Text(
                step.subtitle,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: step.primaryColor,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Description
          SlideTransition(
            position: Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(
              CurvedAnimation(parent: _slideController, curve: Motion.easeOut)
            ),
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: Text(
                step.description,
                style: TextStyle(
                  fontSize: 16,
                  color: themeProvider.contrast.withOpacity(0.8),
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
          
          const SizedBox(height: 32),
          
          // Feature highlights
          Expanded(
            child: SlideTransition(
              position: Tween<Offset>(begin: const Offset(0, 0.4), end: Offset.zero).animate(
                CurvedAnimation(parent: _slideController, curve: Motion.easeOut)
              ),
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: step.features.asMap().entries.map((entry) {
                    final index = entry.key;
                    final feature = entry.value;
                    
                    return TweenAnimationBuilder<double>(
                      duration: Duration(milliseconds: _reducedMotion ? 0 : 600 + (index * 150)),
                      tween: Tween<double>(begin: 0.0, end: 1.0),
                      curve: Curves.easeOutBack,
                      builder: (context, value, child) {
                        return Transform.scale(
                          scale: value,
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 16),
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                            decoration: BoxDecoration(
                              color: step.primaryColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: step.primaryColor.withOpacity(0.2),
                                width: 1,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  feature.split(' ')[0], // Emoji part
                                  style: const TextStyle(fontSize: 16),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  feature.substring(feature.indexOf(' ') + 1),
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: themeProvider.contrast.withOpacity(0.9),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  }).toList(),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPageIndicators(ThemeProvider themeProvider) {
    final currentStep = _tutorialSteps[_currentPage];
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(_tutorialSteps.length, (index) {
          final isActive = _currentPage == index;
          return AnimatedContainer(
            duration: Motion.med,
            curve: Motion.spring,
            margin: const EdgeInsets.symmetric(horizontal: 6),
            width: isActive ? 32 : 8,
            height: 8,
            decoration: BoxDecoration(
              gradient: isActive ? LinearGradient(
                colors: [currentStep.primaryColor, currentStep.primaryColor.withOpacity(0.7)],
              ) : null,
              color: isActive ? null : currentStep.primaryColor.withOpacity(0.3),
              borderRadius: BorderRadius.circular(4),
              boxShadow: isActive ? [
                BoxShadow(
                  color: currentStep.primaryColor.withOpacity(0.4),
                  blurRadius: 8,
                  spreadRadius: 1,
                ),
              ] : null,
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
  final String subtitle;
  final String description;
  final String buttonText;
  final Color primaryColor;
  final List<String> features;

  const TutorialStep({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.description,
    required this.buttonText,
    required this.primaryColor,
    required this.features,
  });
}