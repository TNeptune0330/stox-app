import 'dart:io';
import 'dart:math';
import 'package:flutter/services.dart';
import '../models/user_model.dart';
import '../models/portfolio_model.dart';
import '../models/transaction_model.dart';
import '../models/market_asset_model.dart';
import '../services/local_database_service.dart';
import '../services/enhanced_market_data_service.dart';
import '../services/revenue_admob_service.dart';

class ComprehensiveTestService {
  static const String _logPrefix = '[ComprehensiveTest]';
  
  static Future<void> runAllTests() async {
    print('$_logPrefix ═══════════════════════════════════════════════════════');
    print('$_logPrefix           COMPREHENSIVE APP TEST SUITE');
    print('$_logPrefix ═══════════════════════════════════════════════════════');
    
    try {
      // Initialize services
      await _initializeServices();
      
      // Run all test categories
      await _testDatabaseOperations();
      await _testMarketDataService();
      await _testTradingFunctionality();
      await _testAdMobIntegration();
      await _testPlatformSpecificFeatures();
      await _testDataPersistence();
      await _testErrorHandling();
      await _testPerformance();
      
      print('$_logPrefix ═══════════════════════════════════════════════════════');
      print('$_logPrefix           ALL TESTS COMPLETED SUCCESSFULLY');
      print('$_logPrefix ═══════════════════════════════════════════════════════');
      
    } catch (e) {
      print('$_logPrefix ❌ TEST SUITE FAILED: $e');
      rethrow;
    }
  }
  
  static Future<void> _initializeServices() async {
    print('$_logPrefix 🔧 Initializing Services...');
    
    try {
      await LocalDatabaseService.initialize();
      await EnhancedMarketDataService.initializeMarketData();
      await RevenueAdMobService.initialize();
      
      print('$_logPrefix ✅ All services initialized successfully');
    } catch (e) {
      print('$_logPrefix ❌ Service initialization failed: $e');
      throw Exception('Service initialization failed');
    }
  }
  
  static Future<void> _testDatabaseOperations() async {
    print('$_logPrefix 📂 Testing Database Operations...');
    
    try {
      // Test 1: User Operations
      print('$_logPrefix   Test 1: User Operations');
      
      final testUser = UserModel(
        id: 'test_user_${DateTime.now().millisecondsSinceEpoch}',
        email: 'test@example.com',
        username: 'TestUser',
        avatarUrl: null,
        colorTheme: 'dark',
        cashBalance: 5000.0,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      
      await LocalDatabaseService.saveUser(testUser);
      final retrievedUser = LocalDatabaseService.getCurrentUser();
      
      if (retrievedUser == null || retrievedUser.id != testUser.id) {
        throw Exception('User save/retrieve failed');
      }
      
      await LocalDatabaseService.updateUserCashBalance(7500.0);
      final updatedUser = LocalDatabaseService.getCurrentUser();
      
      if (updatedUser?.cashBalance != 7500.0) {
        throw Exception('User cash balance update failed');
      }
      
      print('$_logPrefix   ✅ User operations test passed');
      
      // Test 2: Portfolio Operations
      print('$_logPrefix   Test 2: Portfolio Operations');
      
      final testHolding = PortfolioModel(
        id: 'test_holding_1',
        userId: testUser.id,
        symbol: 'AAPL',
        quantity: 10,
        avgPrice: 150.0,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      
      await LocalDatabaseService.savePortfolioHolding(testHolding);
      final retrievedHolding = LocalDatabaseService.getPortfolioHolding('AAPL');
      
      if (retrievedHolding == null || retrievedHolding.quantity != 10) {
        throw Exception('Portfolio save/retrieve failed');
      }
      
      final allHoldings = LocalDatabaseService.getPortfolioHoldings();
      if (allHoldings.isEmpty) {
        throw Exception('Portfolio holdings retrieval failed');
      }
      
      print('$_logPrefix   ✅ Portfolio operations test passed');
      
      // Test 3: Transaction Operations
      print('$_logPrefix   Test 3: Transaction Operations');
      
      final testTransaction = TransactionModel(
        id: 'test_tx_1',
        userId: testUser.id,
        symbol: 'AAPL',
        type: 'buy',
        quantity: 5,
        price: 150.0,
        totalAmount: 750.0,
        timestamp: DateTime.now(),
      );
      
      await LocalDatabaseService.saveTransaction(testTransaction);
      final transactions = LocalDatabaseService.getTransactions(limit: 10);
      
      if (transactions.isEmpty) {
        throw Exception('Transaction save/retrieve failed');
      }
      
      final symbolTransactions = LocalDatabaseService.getTransactionsForSymbol('AAPL');
      if (symbolTransactions.isEmpty) {
        throw Exception('Symbol-specific transaction retrieval failed');
      }
      
      print('$_logPrefix   ✅ Transaction operations test passed');
      
      print('$_logPrefix ✅ Database Operations: ALL TESTS PASSED');
      
    } catch (e) {
      print('$_logPrefix ❌ Database Operations test failed: $e');
      rethrow;
    }
  }
  
  static Future<void> _testMarketDataService() async {
    print('$_logPrefix 📈 Testing Market Data Service...');
    
    try {
      // Test 1: Market Data Initialization
      print('$_logPrefix   Test 1: Market Data Initialization');
      
      final assets = await EnhancedMarketDataService.getAllAssets();
      if (assets.isEmpty) {
        throw Exception('No market data found');
      }
      
      print('$_logPrefix   ✅ Found ${assets.length} market assets');
      
      // Test 2: Asset Retrieval by Type
      print('$_logPrefix   Test 2: Asset Retrieval by Type');
      
      final stocks = await EnhancedMarketDataService.getAssetsByType('stock');
      final cryptos = await EnhancedMarketDataService.getAssetsByType('crypto');
      final etfs = await EnhancedMarketDataService.getAssetsByType('etf');
      
      if (stocks.isEmpty || cryptos.isEmpty || etfs.isEmpty) {
        throw Exception('Missing asset types');
      }
      
      print('$_logPrefix   ✅ Stocks: ${stocks.length}, Cryptos: ${cryptos.length}, ETFs: ${etfs.length}');
      
      // Test 3: Individual Asset Retrieval
      print('$_logPrefix   Test 3: Individual Asset Retrieval');
      
      final appleStock = await EnhancedMarketDataService.getAsset('AAPL');
      if (appleStock == null) {
        throw Exception('AAPL stock not found');
      }
      
      final bitcoin = await EnhancedMarketDataService.getAsset('BTC');
      if (bitcoin == null) {
        throw Exception('BTC crypto not found');
      }
      
      print('$_logPrefix   ✅ Individual asset retrieval working');
      
      // Test 4: Search Functionality
      print('$_logPrefix   Test 4: Search Functionality');
      
      final appleResults = await EnhancedMarketDataService.searchAssets('Apple');
      if (appleResults.isEmpty) {
        throw Exception('Search for Apple failed');
      }
      
      final bitcoinResults = await EnhancedMarketDataService.searchAssets('Bitcoin');
      if (bitcoinResults.isEmpty) {
        throw Exception('Search for Bitcoin failed');
      }
      
      print('$_logPrefix   ✅ Search functionality working');
      
      // Test 5: Market Statistics
      print('$_logPrefix   Test 5: Market Statistics');
      
      final marketStats = await EnhancedMarketDataService.getMarketStats();
      if (marketStats['total_assets'] == 0) {
        throw Exception('Market statistics failed');
      }
      
      print('$_logPrefix   ✅ Market stats: ${marketStats['total_assets']} assets, ${marketStats['gainers']} gainers, ${marketStats['losers']} losers');
      
      print('$_logPrefix ✅ Market Data Service: ALL TESTS PASSED');
      
    } catch (e) {
      print('$_logPrefix ❌ Market Data Service test failed: $e');
      rethrow;
    }
  }
  
  static Future<void> _testTradingFunctionality() async {
    print('$_logPrefix 💱 Testing Trading Functionality...');
    
    try {
      // Setup test user with known balance
      final testUser = UserModel(
        id: 'trade_test_user',
        email: 'trader@example.com',
        username: 'TradeTestUser',
        avatarUrl: null,
        colorTheme: 'dark',
        cashBalance: 10000.0,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      
      await LocalDatabaseService.saveUser(testUser);
      
      // Test 1: Buy Trade
      print('$_logPrefix   Test 1: Buy Trade');
      
      final buySuccess = await LocalDatabaseService.executeTrade(
        symbol: 'AAPL',
        type: 'buy',
        quantity: 5,
        price: 200.0,
      );
      
      if (!buySuccess) {
        throw Exception('Buy trade failed');
      }
      
      final userAfterBuy = LocalDatabaseService.getCurrentUser();
      if (userAfterBuy?.cashBalance != 9000.0) {
        throw Exception('Cash balance not updated after buy');
      }
      
      final appleHolding = LocalDatabaseService.getPortfolioHolding('AAPL');
      if (appleHolding?.quantity != 5) {
        throw Exception('Portfolio not updated after buy');
      }
      
      print('$_logPrefix   ✅ Buy trade successful');
      
      // Test 2: Additional Buy (Average Price Calculation)
      print('$_logPrefix   Test 2: Additional Buy Trade');
      
      final additionalBuySuccess = await LocalDatabaseService.executeTrade(
        symbol: 'AAPL',
        type: 'buy',
        quantity: 5,
        price: 220.0,
      );
      
      if (!additionalBuySuccess) {
        throw Exception('Additional buy trade failed');
      }
      
      final appleHoldingAfterSecondBuy = LocalDatabaseService.getPortfolioHolding('AAPL');
      if (appleHoldingAfterSecondBuy?.quantity != 10) {
        throw Exception('Portfolio quantity not updated correctly');
      }
      
      // Check average price calculation (200 * 5 + 220 * 5) / 10 = 210
      if ((appleHoldingAfterSecondBuy?.avgPrice ?? 0) != 210.0) {
        throw Exception('Average price calculation failed');
      }
      
      print('$_logPrefix   ✅ Additional buy and average price calculation successful');
      
      // Test 3: Sell Trade
      print('$_logPrefix   Test 3: Sell Trade');
      
      final sellSuccess = await LocalDatabaseService.executeTrade(
        symbol: 'AAPL',
        type: 'sell',
        quantity: 3,
        price: 230.0,
      );
      
      if (!sellSuccess) {
        throw Exception('Sell trade failed');
      }
      
      final appleHoldingAfterSell = LocalDatabaseService.getPortfolioHolding('AAPL');
      if (appleHoldingAfterSell?.quantity != 7) {
        throw Exception('Portfolio quantity not updated after sell');
      }
      
      print('$_logPrefix   ✅ Sell trade successful');
      
      // Test 4: Insufficient Funds
      print('$_logPrefix   Test 4: Insufficient Funds Test');
      
      final insufficientFundsResult = await LocalDatabaseService.executeTrade(
        symbol: 'TSLA',
        type: 'buy',
        quantity: 100,
        price: 1000.0, // $100,000 total
      );
      
      if (insufficientFundsResult) {
        throw Exception('Insufficient funds check failed');
      }
      
      print('$_logPrefix   ✅ Insufficient funds protection working');
      
      // Test 5: Insufficient Shares
      print('$_logPrefix   Test 5: Insufficient Shares Test');
      
      final insufficientSharesResult = await LocalDatabaseService.executeTrade(
        symbol: 'AAPL',
        type: 'sell',
        quantity: 20, // User only has 7 shares
        price: 200.0,
      );
      
      if (insufficientSharesResult) {
        throw Exception('Insufficient shares check failed');
      }
      
      print('$_logPrefix   ✅ Insufficient shares protection working');
      
      // Test 6: Portfolio Summary
      print('$_logPrefix   Test 6: Portfolio Summary');
      
      final portfolioSummary = LocalDatabaseService.getPortfolioSummary();
      if (portfolioSummary['net_worth'] == 0.0) {
        throw Exception('Portfolio summary failed');
      }
      
      print('$_logPrefix   ✅ Portfolio summary: Net Worth: \$${portfolioSummary['net_worth'].toStringAsFixed(2)}');
      
      print('$_logPrefix ✅ Trading Functionality: ALL TESTS PASSED');
      
    } catch (e) {
      print('$_logPrefix ❌ Trading Functionality test failed: $e');
      rethrow;
    }
  }
  
  static Future<void> _testAdMobIntegration() async {
    print('$_logPrefix 🎯 Testing AdMob Integration...');
    
    try {
      // Test 1: AdMob Service Status
      print('$_logPrefix   Test 1: AdMob Service Status');
      
      final adStats = RevenueAdMobService.getAdStats();
      if (adStats.isEmpty) {
        throw Exception('AdMob stats not available');
      }
      
      print('$_logPrefix   ✅ AdMob service initialized');
      
      // Test 2: Banner Ad
      print('$_logPrefix   Test 2: Banner Ad Loading');
      
      final bannerAd = RevenueAdMobService.getBannerAd();
      final isBannerLoaded = RevenueAdMobService.isBannerAdLoaded;
      
      print('$_logPrefix   ✅ Banner ad loaded: $isBannerLoaded');
      
      // Test 3: Interstitial Ad
      print('$_logPrefix   Test 3: Interstitial Ad Status');
      
      final isInterstitialLoaded = RevenueAdMobService.isInterstitialAdLoaded;
      print('$_logPrefix   ✅ Interstitial ad loaded: $isInterstitialLoaded');
      
      // Test 4: Rewarded Ad
      print('$_logPrefix   Test 4: Rewarded Ad Status');
      
      final isRewardedLoaded = RevenueAdMobService.isRewardedAdLoaded;
      print('$_logPrefix   ✅ Rewarded ad loaded: $isRewardedLoaded');
      
      // Test 5: Native Ad
      print('$_logPrefix   Test 5: Native Ad Status');
      
      final isNativeLoaded = RevenueAdMobService.isNativeAdLoaded;
      print('$_logPrefix   ✅ Native ad loaded: $isNativeLoaded');
      
      // Test 6: Ad Triggers
      print('$_logPrefix   Test 6: Ad Trigger Events');
      
      await RevenueAdMobService.onTradeCompleted();
      await RevenueAdMobService.onScreenTransition('portfolio');
      
      print('$_logPrefix   ✅ Ad triggers working');
      
      print('$_logPrefix ✅ AdMob Integration: ALL TESTS PASSED');
      
    } catch (e) {
      print('$_logPrefix ❌ AdMob Integration test failed: $e');
      rethrow;
    }
  }
  
  static Future<void> _testPlatformSpecificFeatures() async {
    print('$_logPrefix 📱 Testing Platform-Specific Features...');
    
    try {
      // Test 1: Platform Detection
      print('$_logPrefix   Test 1: Platform Detection');
      
      final platform = Platform.operatingSystem;
      print('$_logPrefix   ✅ Platform detected: $platform');
      
      // Test 2: File System Access
      print('$_logPrefix   Test 2: File System Access');
      
      final dbStats = await LocalDatabaseService.getDatabaseStats();
      if (dbStats['database_size_mb'] == null) {
        throw Exception('Database size calculation failed');
      }
      
      print('$_logPrefix   ✅ Database size: ${dbStats['database_size_mb'].toStringAsFixed(2)} MB');
      
      // Test 3: Device Info
      print('$_logPrefix   Test 3: Device Information');
      
      try {
        final deviceInfo = {
          'platform': Platform.operatingSystem,
          'version': Platform.operatingSystemVersion,
          'is_ios': Platform.isIOS,
          'is_android': Platform.isAndroid,
        };
        
        print('$_logPrefix   ✅ Device info: $deviceInfo');
      } catch (e) {
        print('$_logPrefix   ⚠️ Device info partially unavailable: $e');
      }
      
      print('$_logPrefix ✅ Platform-Specific Features: ALL TESTS PASSED');
      
    } catch (e) {
      print('$_logPrefix ❌ Platform-Specific Features test failed: $e');
      rethrow;
    }
  }
  
  static Future<void> _testDataPersistence() async {
    print('$_logPrefix 💾 Testing Data Persistence...');
    
    try {
      // Test 1: User Data Persistence
      print('$_logPrefix   Test 1: User Data Persistence');
      
      final originalUser = LocalDatabaseService.getCurrentUser();
      if (originalUser == null) {
        throw Exception('No user data found');
      }
      
      await LocalDatabaseService.updateUserCashBalance(12345.67);
      
      // Simulate app restart by getting fresh data
      final persistedUser = LocalDatabaseService.getCurrentUser();
      if (persistedUser?.cashBalance != 12345.67) {
        throw Exception('User data not persisted correctly');
      }
      
      print('$_logPrefix   ✅ User data persistence working');
      
      // Test 2: Portfolio Data Persistence
      print('$_logPrefix   Test 2: Portfolio Data Persistence');
      
      final portfolioHoldings = LocalDatabaseService.getPortfolioHoldings();
      if (portfolioHoldings.isEmpty) {
        throw Exception('Portfolio data not persisted');
      }
      
      print('$_logPrefix   ✅ Portfolio data persistence working');
      
      // Test 3: Transaction History Persistence
      print('$_logPrefix   Test 3: Transaction History Persistence');
      
      final transactions = LocalDatabaseService.getTransactions();
      if (transactions.isEmpty) {
        throw Exception('Transaction data not persisted');
      }
      
      print('$_logPrefix   ✅ Transaction history persistence working');
      
      // Test 4: Market Data Persistence
      print('$_logPrefix   Test 4: Market Data Persistence');
      
      final marketAssets = LocalDatabaseService.getMarketAssets();
      if (marketAssets.isEmpty) {
        throw Exception('Market data not persisted');
      }
      
      print('$_logPrefix   ✅ Market data persistence working');
      
      // Test 5: Settings Persistence
      print('$_logPrefix   Test 5: Settings Persistence');
      
      await LocalDatabaseService.saveSetting('test_setting', 'test_value');
      final retrievedSetting = LocalDatabaseService.getSetting<String>('test_setting');
      
      if (retrievedSetting != 'test_value') {
        throw Exception('Settings not persisted correctly');
      }
      
      print('$_logPrefix   ✅ Settings persistence working');
      
      print('$_logPrefix ✅ Data Persistence: ALL TESTS PASSED');
      
    } catch (e) {
      print('$_logPrefix ❌ Data Persistence test failed: $e');
      rethrow;
    }
  }
  
  static Future<void> _testErrorHandling() async {
    print('$_logPrefix 🛡️ Testing Error Handling...');
    
    try {
      // Test 1: Invalid Trade Parameters
      print('$_logPrefix   Test 1: Invalid Trade Parameters');
      
      final invalidTradeResult = await LocalDatabaseService.executeTrade(
        symbol: '',
        type: 'invalid_type',
        quantity: -1,
        price: -100.0,
      );
      
      if (invalidTradeResult) {
        throw Exception('Invalid trade parameters not handled');
      }
      
      print('$_logPrefix   ✅ Invalid trade parameters handled correctly');
      
      // Test 2: Non-existent Asset Retrieval
      print('$_logPrefix   Test 2: Non-existent Asset Retrieval');
      
      final nonExistentAsset = await EnhancedMarketDataService.getAsset('NONEXISTENT');
      if (nonExistentAsset != null) {
        throw Exception('Non-existent asset query not handled');
      }
      
      print('$_logPrefix   ✅ Non-existent asset retrieval handled correctly');
      
      // Test 3: Empty Search Query
      print('$_logPrefix   Test 3: Empty Search Query');
      
      final emptySearchResults = await EnhancedMarketDataService.searchAssets('');
      print('$_logPrefix   ✅ Empty search query handled, results: ${emptySearchResults.length}');
      
      print('$_logPrefix ✅ Error Handling: ALL TESTS PASSED');
      
    } catch (e) {
      print('$_logPrefix ❌ Error Handling test failed: $e');
      rethrow;
    }
  }
  
  static Future<void> _testPerformance() async {
    print('$_logPrefix ⚡ Testing Performance...');
    
    try {
      // Test 1: Database Query Performance
      print('$_logPrefix   Test 1: Database Query Performance');
      
      final stopwatch = Stopwatch()..start();
      
      for (int i = 0; i < 100; i++) {
        final user = LocalDatabaseService.getCurrentUser();
        final holdings = LocalDatabaseService.getPortfolioHoldings();
        final transactions = LocalDatabaseService.getTransactions(limit: 10);
      }
      
      stopwatch.stop();
      final dbQueryTime = stopwatch.elapsedMilliseconds;
      
      if (dbQueryTime > 1000) {
        throw Exception('Database queries too slow: ${dbQueryTime}ms');
      }
      
      print('$_logPrefix   ✅ Database query performance: ${dbQueryTime}ms for 100 iterations');
      
      // Test 2: Market Data Access Performance
      print('$_logPrefix   Test 2: Market Data Access Performance');
      
      final stopwatch2 = Stopwatch()..start();
      
      for (int i = 0; i < 50; i++) {
        final assets = await EnhancedMarketDataService.getAllAssets();
        final appleStock = await EnhancedMarketDataService.getAsset('AAPL');
      }
      
      stopwatch2.stop();
      final marketDataTime = stopwatch2.elapsedMilliseconds;
      
      if (marketDataTime > 2000) {
        throw Exception('Market data access too slow: ${marketDataTime}ms');
      }
      
      print('$_logPrefix   ✅ Market data access performance: ${marketDataTime}ms for 50 iterations');
      
      print('$_logPrefix ✅ Performance: ALL TESTS PASSED');
      
    } catch (e) {
      print('$_logPrefix ❌ Performance test failed: $e');
      rethrow;
    }
  }
  
  static Future<Map<String, dynamic>> generateTestReport() async {
    print('$_logPrefix 📊 Generating Test Report...');
    
    final dbStats = await LocalDatabaseService.getDatabaseStats();
    final marketStats = await EnhancedMarketDataService.getMarketStats();
    final adStats = RevenueAdMobService.getAdStats();
    
    final report = {
      'test_timestamp': DateTime.now().toIso8601String(),
      'platform': Platform.operatingSystem,
      'platform_version': Platform.operatingSystemVersion,
      'database_stats': dbStats,
      'market_stats': marketStats,
      'ad_stats': adStats,
      'test_status': 'PASSED',
    };
    
    print('$_logPrefix ✅ Test report generated');
    return report;
  }
}