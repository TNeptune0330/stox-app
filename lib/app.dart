import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/auth_provider.dart';
import 'providers/portfolio_provider.dart';
import 'providers/market_data_provider.dart';
import 'providers/theme_provider.dart';
import 'providers/achievement_provider.dart';
import 'screens/auth/modern_sign_in_screen.dart';
import 'screens/main_navigation.dart';
import 'services/storage_service.dart';
import 'services/ad_service.dart';
import 'theme/modern_theme.dart';
import 'widgets/modern_loading.dart';

class StoxApp extends StatelessWidget {
  const StoxApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => PortfolioProvider()),
        ChangeNotifierProvider(create: (_) => MarketDataProvider()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => AchievementProvider()),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          return MaterialApp(
            title: 'Stox',
            theme: ModernTheme.darkTheme,
            home: const AppInitializer(),
            debugShowCheckedModeBanner: false,
          );
        },
      ),
    );
  }
}

class AppInitializer extends StatefulWidget {
  const AppInitializer({super.key});

  @override
  State<AppInitializer> createState() => _AppInitializerState();
}

class _AppInitializerState extends State<AppInitializer> {
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    try {
      // Initialize services
      await StorageService.initialize();
      await AdService.instance.initialize();
      
      // Periodic price updates disabled - using search-driven approach
      print('✅ Price updates: Disabled - search-driven approach only');
      
      // Initialize providers
      if (mounted) {
        final authProvider = Provider.of<AuthProvider>(context, listen: false);
        final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
        final achievementProvider = Provider.of<AchievementProvider>(context, listen: false);
        final marketDataProvider = Provider.of<MarketDataProvider>(context, listen: false);
        
        await Future.wait([
          authProvider.initialize(),
          themeProvider.initialize(),
          achievementProvider.initialize(),
          marketDataProvider.initialize(),
        ]);
      }
      
      if (mounted) {
        setState(() {
          _isInitialized = true;
        });
      }
    } catch (e) {
      // Handle initialization errors
      debugPrint('Initialization error: $e');
      if (mounted) {
        setState(() {
          _isInitialized = true;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      return Scaffold(
        backgroundColor: ModernTheme.backgroundPrimary,
        body: const Center(
          child: ModernLoading(
            size: 80,
            message: 'Initializing Stox...',
            showMessage: true,
          ),
        ),
      );
    }

    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        if (authProvider.isAuthenticated) {
          return const MainNavigation();
        } else {
          return const ModernSignInScreen();
        }
      },
    );
  }
}