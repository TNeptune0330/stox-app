import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
// import 'package:google_mobile_ads/google_mobile_ads.dart';

// Services
import 'services/local_database_service.dart';
import 'services/revenue_admob_service.dart';
import 'services/storage_service.dart';
import 'services/connection_manager.dart';
import 'services/financial_news_service.dart';
import 'services/optimized_cache_service.dart';
import 'services/optimized_network_service.dart';
import 'services/performance_monitor_service.dart';

// Providers
import 'providers/auth_provider.dart';
import 'providers/portfolio_provider.dart';
import 'providers/market_data_provider.dart';
import 'providers/theme_provider.dart';
import 'providers/achievement_provider.dart';

// Screens
import 'screens/splash_screen.dart';
import 'screens/auth/login_screen.dart';
import 'screens/main_navigation.dart';
import 'screens/onboarding/onboarding_screen.dart';
import 'screens/tutorial/tutorial_screen.dart';

// Config
import 'config/supabase_config.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Start performance monitoring immediately
  PerformanceMonitorService.startAppStartup();
  await PerformanceMonitorService.initialize();
  
  print('🚀 Stox Trading Simulator - Production Launch');
  
  try {
    // Initialize core services
    await _initializeCoreServices();
    
    // Run comprehensive tests in debug mode
    if (kDebugMode) {
      // Skip comprehensive tests for faster startup
      print('🚀 Production mode - optimized startup (tests disabled)');
    }
    
    // Complete startup measurement
    PerformanceMonitorService.completeAppStartup();
    
    // Launch app
    runApp(const StoxApp());
    
  } catch (e) {
    print('❌ App initialization failed: $e');
    // Show user-friendly error screen
    runApp(MaterialApp(
      home: const ProductionErrorScreen(),
      debugShowCheckedModeBanner: false,
    ));
  }
}

Future<void> _initializeCoreServices() async {
  print('🔧 Initializing core services...');
  
  try {
    // Initialize Supabase
    await Supabase.initialize(
      url: SupabaseConfig.url,
      anonKey: SupabaseConfig.anonKey,
    );
    print('✅ Supabase initialized');
    
    // Reset connection manager state (in case URL was changed)
    ConnectionManager().resetConnectionState();
    
    // Initialize performance services first
    await Future.wait([
      OptimizedCacheService.initialize(),
      OptimizedNetworkService.initialize(),
    ]);
    print('✅ Performance services initialized');
    
    // Initialize critical services in parallel for faster startup
    await Future.wait([
      StorageService.initialize(),
      LocalDatabaseService.initialize(),
    ]);
    print('✅ Critical services initialized');
    
    // Market data service disabled - using search-driven Google Finance approach
    print('✅ Market Data Service: Using search-driven approach only');
    
    // Defer non-critical services to not block app startup
    _initializeNonCriticalServices();
    
    // Set system UI overlay style
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        systemNavigationBarColor: Color(0xFF0f1419),
        systemNavigationBarIconBrightness: Brightness.light,
      ),
    );
    
    // Set preferred orientations
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    
    print('✅ All core services initialized successfully');
    
  } catch (e) {
    print('❌ Core service initialization failed: $e');
    rethrow;
  }
}

/// Initialize non-critical services in background to not block app startup
void _initializeNonCriticalServices() async {
  try {
    // Initialize AdMob in background
    await RevenueAdMobService.initialize();
    print('✅ AdMob Service initialized (background)');
    
    // Initialize daily news cache in background
    FinancialNewsService.updateDailyNews();
    print('✅ Daily news update initiated (background)');
    
    // Periodic market data updates disabled - using search-driven approach
    print('✅ Market data: No periodic updates - search-driven only');
  } catch (e) {
    print('⚠️ Non-critical service initialization failed: $e');
    // Don't crash app for non-critical services
  }
}

/// Production-ready error screen that doesn't expose technical details
class ProductionErrorScreen extends StatelessWidget {
  const ProductionErrorScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B1426),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline,
                size: 64,
                color: Color(0xFF48CAE4),
              ),
              const SizedBox(height: 24),
              const Text(
                'Oops! Something went wrong',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              const Text(
                'We\'re having trouble starting the app. Please try restarting the application.',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.white70,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: () {
                  // In a real app, this might trigger a restart or retry
                  exit(0);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF48CAE4),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                ),
                child: const Text('Restart App'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class StoxApp extends StatefulWidget {
  const StoxApp({super.key});

  @override
  State<StoxApp> createState() => _StoxAppState();
}

class _StoxAppState extends State<StoxApp> {
  late ThemeProvider _themeProvider;
  late AuthProvider _authProvider;
  
  @override
  void initState() {
    super.initState();
    _themeProvider = ThemeProvider();
    _authProvider = AuthProvider();
    // Initialize providers after the services are ready
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _themeProvider.initialize();
      _authProvider.initialize();
    });
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: _authProvider),
        ChangeNotifierProvider(create: (_) => PortfolioProvider()),
        ChangeNotifierProvider(create: (_) => MarketDataProvider()),
        ChangeNotifierProvider.value(value: _themeProvider),
        ChangeNotifierProvider(create: (_) => AchievementProvider()),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          return MaterialApp(
            title: 'Stox Trading Simulator',
            debugShowCheckedModeBanner: false,
            theme: themeProvider.themeData,
            home: const SplashScreen(),
            routes: {
              '/login': (context) => const LoginScreen(),
              '/main': (context) => const MainNavigation(),
              '/onboarding': (context) => const OnboardingScreen(),
              '/tutorial': (context) => const TutorialScreen(),
            },
            builder: (context, child) {
              // Ensure consistent text scaling on all devices
              return MediaQuery(
                data: MediaQuery.of(context).copyWith(
                  textScaler: const TextScaler.linear(1.0),
                ),
                child: child!,
              );
            },
          );
        },
      ),
    );
  }
}

class ErrorScreen extends StatelessWidget {
  final String error;
  
  const ErrorScreen({super.key, required this.error});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0f1419),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline,
                size: 64,
                color: Colors.red,
              ),
              const SizedBox(height: 16),
              const Text(
                'App Initialization Failed',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                error,
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.white70,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  // Restart app
                  SystemNavigator.pop();
                },
                child: const Text('Restart App'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}