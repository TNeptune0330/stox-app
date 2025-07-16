import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

// Services
import 'services/local_database_service.dart';
import 'services/enhanced_market_data_service.dart';
import 'services/revenue_admob_service.dart';
import 'services/comprehensive_test_service.dart';

// Providers
import 'providers/auth_provider.dart';
import 'providers/portfolio_provider.dart';
import 'providers/market_data_provider.dart';

// Screens
import 'screens/splash_screen.dart';
import 'screens/auth/login_screen.dart';
import 'screens/main_navigation.dart';

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
    
    // Initialize Local Database
    await LocalDatabaseService.initialize();
    print('✅ Local Database initialized');
    
    // Initialize Market Data Service
    await EnhancedMarketDataService.initializeMarketData();
    print('✅ Market Data Service initialized');
    
    // Initialize AdMob
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

class StoxApp extends StatelessWidget {
  const StoxApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => PortfolioProvider()),
        ChangeNotifierProvider(create: (_) => MarketDataProvider()),
      ],
      child: MaterialApp(
        title: 'Stox Trading Simulator',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          primarySwatch: Colors.purple,
          scaffoldBackgroundColor: const Color(0xFF0f1419),
          appBarTheme: const AppBarTheme(
            backgroundColor: Color(0xFF1a1a2e),
            foregroundColor: Colors.white,
            elevation: 0,
          ),
          textTheme: const TextTheme(
            bodyLarge: TextStyle(color: Colors.white),
            bodyMedium: TextStyle(color: Colors.white),
            headlineLarge: TextStyle(color: Colors.white),
            headlineMedium: TextStyle(color: Colors.white),
            headlineSmall: TextStyle(color: Colors.white),
          ),
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF7209b7),
              foregroundColor: Colors.white,
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          inputDecorationTheme: InputDecorationTheme(
            filled: true,
            fillColor: const Color(0xFF1a1a2e),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            hintStyle: const TextStyle(color: Colors.white70),
          ),
        ),
        home: const SplashScreen(),
        routes: {
          '/login': (context) => const LoginScreen(),
          '/main': (context) => const MainNavigation(),
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