import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
// import 'package:google_mobile_ads/google_mobile_ads.dart';

// Services
import 'services/local_database_service.dart';
import 'services/enhanced_market_data_service.dart';
import 'services/revenue_admob_service.dart';
import 'services/comprehensive_test_service.dart';
import 'services/storage_service.dart';
import 'services/connection_manager.dart';

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
import 'screens/auth_test_screen.dart';
import 'screens/auth_flow_test_screen.dart';

// Config
import 'config/supabase_config.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  print('🚀 Stox Trading Simulator - Production Launch');
  
  try {
    // Initialize core services
    await _initializeCoreServices();
    
    // Run comprehensive tests in debug mode
    if (kDebugMode) {
      await _runProductionTests();
    }
    
    // Launch app
    runApp(const StoxApp());
    
  } catch (e) {
    print('❌ App initialization failed: $e');
    // Show error screen
    runApp(MaterialApp(
      home: ErrorScreen(error: e.toString()),
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
    
    // Initialize Storage Service
    await StorageService.initialize();
    print('✅ Storage Service initialized');
    
    // Initialize Local Database
    await LocalDatabaseService.initialize();
    print('✅ Local Database initialized');
    
    // Initialize Market Data Service
    await EnhancedMarketDataService.initializeMarketData();
    print('✅ Market Data Service initialized');
    
    // Initialize AdMob - Temporarily disabled for iOS build
    await RevenueAdMobService.initialize();
    print('✅ AdMob Service initialized');
    
    // Start periodic market data updates
    await EnhancedMarketDataService.startPeriodicUpdates();
    print('✅ Market data updates started');
    
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

Future<void> _runProductionTests() async {
  print('🧪 Running production tests...');
  
  try {
    await ComprehensiveTestService.runAllTests();
    
    final testReport = await ComprehensiveTestService.generateTestReport();
    print('📊 Test Report Generated:');
    print('   - Platform: ${testReport['platform']}');
    print('   - Database Assets: ${testReport['database_stats']['market_assets']}');
    print('   - Portfolio Holdings: ${testReport['database_stats']['portfolio_holdings']}');
    print('   - Test Status: ${testReport['test_status']}');
    
  } catch (e) {
    print('❌ Production tests failed: $e');
    // Don't crash the app, just log the error
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
              '/auth-test': (context) => const AuthTestScreen(),
              '/auth-flow-test': (context) => const AuthFlowTestScreen(),
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