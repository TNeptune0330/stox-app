import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/portfolio_provider.dart';
import '../providers/market_data_provider.dart';
import '../providers/theme_provider.dart';
import '../providers/achievement_provider.dart';
import '../utils/responsive_utils.dart';
import '../widgets/banner_ad_widget.dart';
import 'market/market_screen.dart';
import 'portfolio/portfolio_screen.dart';
import 'achievements/achievements_screen.dart';
import 'settings/settings_screen.dart';

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _currentIndex = 1; // Default to Portfolio screen
  
  final List<Widget> _screens = [
    const MarketScreen(),
    const PortfolioScreen(),
    const AchievementsScreen(),
    const SettingsScreen(),
  ];

  @override
  void initState() {
    super.initState();
    // Delay initialization to avoid calling during build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeData();
    });
  }

  Future<void> _initializeData() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final portfolioProvider = Provider.of<PortfolioProvider>(context, listen: false);
    final marketProvider = Provider.of<MarketDataProvider>(context, listen: false);
    final achievementProvider = Provider.of<AchievementProvider>(context, listen: false);
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);

    if (authProvider.user != null) {
      // Set user ID for data syncing
      achievementProvider.setUserId(authProvider.user!.id);
      themeProvider.setUserId(authProvider.user!.id);
      
      await Future.wait([
        portfolioProvider.loadPortfolio(authProvider.user!.id),
        marketProvider.initialize(),
        achievementProvider.initialize(authProvider.user!.id),
        themeProvider.initialize(authProvider.user!.id),
      ]);
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
                child: IndexedStack(
                  index: _currentIndex,
                  children: _screens,
                ),
              ),
              // Banner Ad
              const BannerAdWidget(), // Temporarily disabled for iOS build (returns empty container)
            ],
          ),
          bottomNavigationBar: BottomNavigationBar(
            currentIndex: _currentIndex,
            onTap: (index) {
              setState(() {
                _currentIndex = index;
              });
            },
            type: BottomNavigationBarType.fixed,
            selectedItemColor: themeProvider.theme,
            unselectedItemColor: Colors.grey,
            iconSize: ResponsiveUtils.getIconSize(context, 20),
            selectedFontSize: ResponsiveUtils.getFontSize(context, 10),
            unselectedFontSize: ResponsiveUtils.getFontSize(context, 9),
            items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.trending_up),
            label: 'Market',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.account_balance_wallet),
            label: 'Portfolio',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.emoji_events),
            label: 'Achievements',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'Settings',
          ),
            ],
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