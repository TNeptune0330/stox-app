import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/portfolio_provider.dart';
import '../providers/market_data_provider.dart';
import '../providers/theme_provider.dart';
import '../providers/achievement_provider.dart';
import '../utils/responsive_utils.dart';
import '../widgets/banner_ad_widget.dart';
import '../widgets/animated_screen.dart';
import '../widgets/staggered_dialog_content.dart';
import 'market/market_screen.dart';
import 'portfolio/portfolio_screen.dart';
import 'achievements/achievements_screen.dart';
import 'settings/settings_screen.dart';

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> with TickerProviderStateMixin {
  int _currentIndex = 1; // Default to Portfolio screen
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late PageController _pageController;
  
  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _currentIndex);
    _animationController = AnimationController(
      duration: Motion.med,
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 0.92,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Motion.spring,
    ));
    
    // Delay initialization to avoid calling during build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeData();
    });
  }
  
  @override
  void dispose() {
    _animationController.dispose();
    _pageController.dispose();
    super.dispose();
  }
  
  final List<Widget> _screens = [
    const MarketScreen(),
    const PortfolioScreen(),
    const AchievementsScreen(),
    const SettingsScreen(),
  ];
  
  final List<Map<String, dynamic>> _navItems = [
    {'icon': Icons.public, 'label': 'Markets'},
    {'icon': Icons.work, 'label': 'Portfolio'},
    {'icon': Icons.military_tech, 'label': 'Achievements'},
    {'icon': Icons.settings, 'label': 'Settings'},
  ];

  Future<void> _initializeData() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final portfolioProvider = Provider.of<PortfolioProvider>(context, listen: false);
    final marketProvider = Provider.of<MarketDataProvider>(context, listen: false);
    final achievementProvider = Provider.of<AchievementProvider>(context, listen: false);
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);

    if (authProvider.user != null) {
      print('🏠 MainNavigation: Initializing data for user ${authProvider.user!.id}');
      
      // Set user ID for data syncing
      achievementProvider.setUserId(authProvider.user!.id);
      themeProvider.setUserId(authProvider.user!.id);
      
      await Future.wait([
        portfolioProvider.loadPortfolio(authProvider.user!.id),
        marketProvider.initialize(),
        achievementProvider.initialize(authProvider.user!.id),
        themeProvider.initialize(authProvider.user!.id),
      ]);
      
      print('🏠 MainNavigation: All providers initialized successfully');
    } else {
      print('🏠 MainNavigation: No authenticated user - skipping full initialization');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return Scaffold(
          backgroundColor: themeProvider.background,
          body: Column(
            children: [
              Expanded(
                child: PageView(
                  controller: _pageController,
                  physics: const NeverScrollableScrollPhysics(), // Disable swipe
                  children: _screens.map((screen) => AnimatedScreen(child: screen)).toList(),
                ),
              ),
              // Banner Ad
              const BannerAdWidget(), // Temporarily disabled for iOS build (returns empty container)
            ],
          ),
          bottomNavigationBar: Container(
            margin: const EdgeInsets.all(16),
            height: 64,
            decoration: BoxDecoration(
              color: themeProvider.backgroundHigh,
              borderRadius: BorderRadius.circular(32),
              border: Border.all(
                color: themeProvider.contrast.withOpacity(0.1),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.24),
                  blurRadius: 24,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: List.generate(_navItems.length, (index) {
                final isSelected = _currentIndex == index;
                return _buildNavItem(
                  themeProvider,
                  index,
                  _navItems[index]['icon'],
                  _navItems[index]['label'],
                  isSelected,
                );
              }),
            ),
          ),
        );
      },
    );
  }
  
  bool get _reducedMotion => MediaQuery.maybeOf(context)?.disableAnimations ?? false;

  // Enhanced page route transitions
  static Route<T> createSlideRoute<T>(Widget page, {SlideDirection direction = SlideDirection.fromRight}) {
    Offset getOffset() {
      switch (direction) {
        case SlideDirection.fromRight:
          return const Offset(1.0, 0.0);
        case SlideDirection.fromLeft:
          return const Offset(-1.0, 0.0);
        case SlideDirection.fromTop:
          return const Offset(0.0, -1.0);
        case SlideDirection.fromBottom:
          return const Offset(0.0, 1.0);
      }
    }

    return PageRouteBuilder<T>(
      pageBuilder: (context, animation, _) => page,
      transitionDuration: Motion.med,
      reverseTransitionDuration: Motion.med,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        final reducedMotion = MediaQuery.maybeOf(context)?.disableAnimations ?? false;
        final curve = CurvedAnimation(parent: animation, curve: Motion.easeOut);
        final reverseCurve = CurvedAnimation(parent: secondaryAnimation, curve: Motion.easeOut);
        
        if (reducedMotion) {
          return FadeTransition(opacity: curve, child: child);
        }
        
        final slideOffset = Tween(begin: getOffset(), end: Offset.zero).animate(curve);
        final reverseSlideOffset = Tween(begin: Offset.zero, end: getOffset() * -0.3).animate(reverseCurve);
        
        return SlideTransition(
          position: slideOffset,
          child: SlideTransition(
            position: reverseSlideOffset,
            child: FadeTransition(
              opacity: Tween(begin: 0.0, end: 1.0).animate(curve),
              child: child,
            ),
          ),
        );
      },
    );
  }

  // Enhanced animated dialog helper with staggered content
  static Future<T?> showAnimatedDialog<T>(BuildContext context, Widget child) {
    final reducedMotion = MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    
    return showGeneralDialog<T>(
      context: context,
      barrierLabel: 'Dialog',
      barrierDismissible: true,
      barrierColor: Colors.black.withOpacity(0.4),
      transitionDuration: reducedMotion ? Motion.fast : Motion.slow,
      pageBuilder: (_, __, ___) => SafeArea(child: StaggeredDialogContent(child: child)),
      transitionBuilder: (_, a, __, c) {
        final t = CurvedAnimation(parent: a, curve: Motion.easeOut);
        final scale = Tween(begin: 0.94, end: 1.0).animate(t);
        final slide = Tween(begin: const Offset(0, 0.1), end: Offset.zero).animate(t);
        
        if (reducedMotion) {
          return FadeTransition(opacity: t, child: c);
        }
        
        return FadeTransition(
          opacity: t,
          child: SlideTransition(
            position: slide,
            child: ScaleTransition(scale: scale, child: c),
          ),
        );
      },
    );
  }

  Widget _buildNavItem(ThemeProvider themeProvider, int index, IconData icon, String label, bool isSelected) {
    // Define accent colors for each tab
    final accentColors = [
      const Color(0xFFEC4899), // Pink for Markets
      const Color(0xFFEAB308), // Yellow for Portfolio  
      const Color(0xFF3B82F6), // Blue for Achievements
      const Color(0xFFEA580C), // Orange for Settings
    ];
    final accentColor = accentColors[index % accentColors.length];
    
    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) {
        return GestureDetector(
          onTap: () {
            if (_currentIndex != index) {
              _animationController.forward().then((_) {
                _animationController.reverse();
              });
              
              final reducedMotion = MediaQuery.maybeOf(context)?.disableAnimations ?? false;
              _pageController.animateToPage(
                index,
                duration: reducedMotion ? Motion.fast : Motion.med,
                curve: Motion.easeOut,
              );
              
              setState(() {
                _currentIndex = index;
              });
            }
          },
          child: AnimatedContainer(
            duration: Motion.med,
            curve: Motion.easeOut,
            height: 48,
            padding: const EdgeInsets.symmetric(horizontal: 4),
            decoration: BoxDecoration(
              color: isSelected ? accentColor.withOpacity(0.15) : Colors.transparent,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Circular button with colored accent
                AnimatedScale(
                  scale: isSelected ? (_reducedMotion ? 1.0 : _scaleAnimation.value) : 0.95,
                  duration: _reducedMotion ? Motion.fast : Motion.med,
                  curve: Motion.spring,
                  child: Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: isSelected 
                          ? accentColor
                          : themeProvider.backgroundHigh.withOpacity(0.3),
                      shape: BoxShape.circle,
                      border: isSelected ? null : Border.all(
                        color: themeProvider.contrast.withOpacity(0.1),
                        width: 1,
                      ),
                      boxShadow: isSelected ? [
                        BoxShadow(
                          color: accentColor.withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ] : null,
                    ),
                    child: Icon(
                      icon,
                      color: isSelected 
                          ? Colors.white 
                          : themeProvider.contrast.withOpacity(0.6),
                      size: 24,
                    ),
                  ),
                ),
                // Label pill with colored accent (only for selected item)
                if (isSelected) ...[
                  const SizedBox(width: 8),
                  AnimatedOpacity(
                    duration: _reducedMotion ? Motion.fast : Motion.med,
                    opacity: isSelected ? 1.0 : 0.0,
                    child: Container(
                      height: 36,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: themeProvider.backgroundHigh,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: accentColor.withOpacity(0.3),
                          width: 1.5,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          label,
                          style: TextStyle(
                            color: accentColor,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}

class AppBarTitle extends StatelessWidget {
  final String title;
  final List<Widget>? actions;
  
  const AppBarTitle({
    super.key,
    required this.title,
    this.actions,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return SliverAppBar(
          title: Text(
            title,
            style: TextStyle(
              color: themeProvider.contrast,
              fontWeight: FontWeight.bold,
            ),
          ),
          actions: actions,
          pinned: true,
          expandedHeight: 60,
          backgroundColor: themeProvider.backgroundHigh,
          foregroundColor: themeProvider.contrast,
          elevation: 0,
          shadowColor: themeProvider.contrast.withOpacity(0.1),
          flexibleSpace: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  themeProvider.backgroundHigh,
                  themeProvider.backgroundHigh.withOpacity(0.8),
                ],
              ),
              border: Border(
                bottom: BorderSide(
                  color: themeProvider.theme.withOpacity(0.2),
                  width: 1,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class LoadingWidget extends StatelessWidget {
  const LoadingWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(themeProvider.themeHigh),
                backgroundColor: themeProvider.theme.withOpacity(0.2),
              ),
              const SizedBox(height: 16),
              Text(
                'Loading...',
                style: TextStyle(
                  color: themeProvider.themeHigh,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class ErrorStateWidget extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;
  
  const ErrorStateWidget({
    super.key,
    required this.message,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return Center(
          child: Container(
            margin: const EdgeInsets.all(24),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: themeProvider.theme.withOpacity(0.05),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: themeProvider.themeHigh.withOpacity(0.4),
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: themeProvider.themeHigh.withOpacity(0.2),
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.error_outline,
                  size: 64,
                  color: themeProvider.contrast,
                ),
                const SizedBox(height: 16),
                Text(
                  'Error',
                  style: TextStyle(
                    color: themeProvider.contrast,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: themeProvider.contrast.withOpacity(0.8),
                    fontSize: 16,
                  ),
                ),
                if (onRetry != null) ...[
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: onRetry,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: themeProvider.theme,
                      foregroundColor: themeProvider.contrast,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    ),
                    child: const Text('Retry'),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}

class EmptyStateWidget extends StatelessWidget {
  final String title;
  final String message;
  final IconData icon;
  final Widget? action;
  
  const EmptyStateWidget({
    super.key,
    required this.title,
    required this.message,
    required this.icon,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return Center(
          child: Container(
            margin: const EdgeInsets.all(24),
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: themeProvider.theme.withOpacity(0.05),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: themeProvider.themeHigh.withOpacity(0.5),
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: themeProvider.themeHigh.withOpacity(0.3),
                  blurRadius: 16,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: themeProvider.themeHigh.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    icon,
                    size: 48,
                    color: themeProvider.themeHigh,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: themeProvider.contrast,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: themeProvider.contrast.withOpacity(0.7),
                    fontSize: 16,
                  ),
                ),
                if (action != null) ...[
                  const SizedBox(height: 24),
                  action!,
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}