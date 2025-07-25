import 'package:flutter/material.dart';
import 'lib/services/local_database_service.dart';
import 'lib/services/local_trading_service.dart';
import 'lib/models/user_model.dart';
import 'lib/services/storage_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  print('🧪 Testing Trading Flow...');
  
  // Initialize services
  await LocalDatabaseService.initialize();
  await StorageService.initialize();
  
  // Create test user
  final testUser = UserModel(
    id: 'test_user_123',
    email: 'test@example.com',
    username: 'TestUser',
    cashBalance: 10000.0,
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
  );
  
  // Cache the user
  await StorageService.cacheUser(testUser);
  print('✅ Test user cached: ${testUser.username} with \$${testUser.cashBalance}');
  
  // Test buying shares
  print('\n🔄 Testing buy trade...');
  final buyResult = await LocalTradingService.executeTrade(
    userId: testUser.id,
    symbol: 'AAPL',
    type: 'buy',
    quantity: 5,
    price: 150.0,
  );
  
  print('Buy trade result: $buyResult');
  
  // Check portfolio
  print('\n📊 Checking portfolio...');
  final portfolio = await LocalTradingService.getLocalPortfolio(testUser.id);
  print('Portfolio holdings: ${portfolio.length}');
  for (final holding in portfolio) {
    print('  - ${holding.symbol}: ${holding.quantity} shares @ \$${holding.avgPrice}');
  }
  
  // Check transactions
  print('\n📋 Checking transactions...');
  final transactions = await LocalTradingService.getLocalTransactions(testUser.id);
  print('Transactions: ${transactions.length}');
  for (final tx in transactions) {
    print('  - ${tx.type.toUpperCase()} ${tx.quantity} ${tx.symbol} @ \$${tx.price}');
  }
  
  // Check cash balance
  final updatedUser = await StorageService.getCachedUser();
  print('\n💰 Updated cash balance: \$${updatedUser?.cashBalance ?? 0}');
  
  // Test selling shares
  print('\n🔄 Testing sell trade...');
  final sellResult = await LocalTradingService.executeTrade(
    userId: testUser.id,
    symbol: 'AAPL',
    type: 'sell',
    quantity: 2,
    price: 155.0,
  );
  
  print('Sell trade result: $sellResult');
  
  // Check portfolio after sell
  print('\n📊 Checking portfolio after sell...');
  final portfolioAfterSell = await LocalTradingService.getLocalPortfolio(testUser.id);
  print('Portfolio holdings: ${portfolioAfterSell.length}');
  for (final holding in portfolioAfterSell) {
    print('  - ${holding.symbol}: ${holding.quantity} shares @ \$${holding.avgPrice}');
  }
  
  // Check final cash balance
  final finalUser = await StorageService.getCachedUser();
  print('\n💰 Final cash balance: \$${finalUser?.cashBalance ?? 0}');
  
  print('\n✅ Trading flow test completed!');
}