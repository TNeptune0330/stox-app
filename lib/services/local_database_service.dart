import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/user_model.dart';
import '../models/portfolio_model.dart';
import '../models/transaction_model.dart';
import '../models/market_asset_model.dart';

class LocalDatabaseService {
  static const String _userBoxName = 'user_data';
  static const String _portfolioBoxName = 'portfolio_data';
  static const String _transactionBoxName = 'transaction_data';
  static const String _marketDataBoxName = 'market_data';
  static const String _settingsBoxName = 'settings_data';
  
  static late Box<Map> _userBox;
  static late Box<Map> _portfolioBox;
  static late Box<Map> _transactionBox;
  static late Box<Map> _marketDataBox;
  static late Box<Map> _settingsBox;
  
  static bool _isInitialized = false;
  
  static Future<void> initialize() async {
    if (_isInitialized) return;
    
    try {
      print('🗃️ Initializing Local Database...');
      
      // Initialize Hive
      await Hive.initFlutter();
      
      // Open boxes
      _userBox = await Hive.openBox<Map>(_userBoxName);
      _portfolioBox = await Hive.openBox<Map>(_portfolioBoxName);
      _transactionBox = await Hive.openBox<Map>(_transactionBoxName);
      _marketDataBox = await Hive.openBox<Map>(_marketDataBoxName);
      _settingsBox = await Hive.openBox<Map>(_settingsBoxName);
      
      _isInitialized = true;
      print('✅ Local Database initialized successfully');
      
      // Create default user if none exists
      await _createDefaultUserIfNeeded();
      
    } catch (e) {
      print('❌ Failed to initialize Local Database: $e');
      throw Exception('Database initialization failed: $e');
    }
  }
  
  static Future<void> _createDefaultUserIfNeeded() async {
    if (!_userBox.containsKey('current_user')) {
      print('📝 Creating default user...');
      
      final defaultUser = UserModel(
        id: 'default_user_${DateTime.now().millisecondsSinceEpoch}',
        email: 'demo@stox.app',
        username: 'Demo Trader',
        avatarUrl: null,
        colorTheme: 'dark',
        cashBalance: 10000.0,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      
      await saveUser(defaultUser);
      print('✅ Default user created with \$10,000 starting balance');
    }
  }
  
  // User Operations
  static Future<void> saveUser(UserModel user) async {
    await _userBox.put('current_user', user.toJson());
    print('💾 User saved: ${user.username} with \$${user.cashBalance.toStringAsFixed(2)}');
  }
  
  static UserModel? getCurrentUser() {
    final userData = _userBox.get('current_user');
    if (userData == null) return null;
    return UserModel.fromJson(Map<String, dynamic>.from(userData));
  }
  
  static Future<void> updateUserCashBalance(double newBalance) async {
    final user = getCurrentUser();
    if (user == null) return;
    
    final updatedUser = user.copyWith(
      cashBalance: newBalance,
      updatedAt: DateTime.now(),
    );
    
    await saveUser(updatedUser);
    print('💰 Cash balance updated to \$${newBalance.toStringAsFixed(2)}');
  }
  
  // Portfolio Operations
  static Future<void> savePortfolioHolding(PortfolioModel holding) async {
    await _portfolioBox.put(holding.symbol, holding.toJson());
    print('📊 Portfolio holding saved: ${holding.symbol} x${holding.quantity}');
  }
  
  static List<PortfolioModel> getPortfolioHoldings() {
    final holdings = <PortfolioModel>[];
    
    for (final key in _portfolioBox.keys) {
      final holdingData = _portfolioBox.get(key);
      if (holdingData != null) {
        holdings.add(PortfolioModel.fromJson(Map<String, dynamic>.from(holdingData)));
      }
    }
    
    return holdings;
  }
  
  static PortfolioModel? getPortfolioHolding(String symbol) {
    final holdingData = _portfolioBox.get(symbol);
    if (holdingData == null) return null;
    return PortfolioModel.fromJson(Map<String, dynamic>.from(holdingData));
  }
  
  static Future<void> removePortfolioHolding(String symbol) async {
    await _portfolioBox.delete(symbol);
    print('🗑️ Portfolio holding removed: $symbol');
  }
  
  // Transaction Operations
  static Future<void> saveTransaction(TransactionModel transaction) async {
    await _transactionBox.put(transaction.id, transaction.toJson());
    print('📝 Transaction saved: ${transaction.type} ${transaction.quantity} ${transaction.symbol}');
  }
  
  static List<TransactionModel> getTransactions({int? limit}) {
    final transactions = <TransactionModel>[];
    
    for (final key in _transactionBox.keys) {
      final transactionData = _transactionBox.get(key);
      if (transactionData != null) {
        transactions.add(TransactionModel.fromJson(Map<String, dynamic>.from(transactionData)));
      }
    }
    
    // Sort by timestamp (most recent first)
    transactions.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    
    if (limit != null && transactions.length > limit) {
      return transactions.take(limit).toList();
    }
    
    return transactions;
  }
  
  static List<TransactionModel> getTransactionsForSymbol(String symbol) {
    final transactions = getTransactions();
    return transactions.where((tx) => tx.symbol == symbol).toList();
  }
  
  // Market Data Operations
  static Future<void> saveMarketAsset(MarketAssetModel asset) async {
    await _marketDataBox.put(asset.symbol, asset.toJson());
  }
  
  static Future<void> saveMarketAssets(List<MarketAssetModel> assets) async {
    for (final asset in assets) {
      await saveMarketAsset(asset);
    }
    print('📈 Saved ${assets.length} market assets');
  }
  
  static List<MarketAssetModel> getMarketAssets() {
    final assets = <MarketAssetModel>[];
    
    for (final key in _marketDataBox.keys) {
      final assetData = _marketDataBox.get(key);
      if (assetData != null) {
        assets.add(MarketAssetModel.fromJson(Map<String, dynamic>.from(assetData)));
      }
    }
    
    return assets;
  }
  
  static MarketAssetModel? getMarketAsset(String symbol) {
    final assetData = _marketDataBox.get(symbol);
    if (assetData == null) return null;
    return MarketAssetModel.fromJson(Map<String, dynamic>.from(assetData));
  }
  
  static List<MarketAssetModel> getMarketAssetsByType(String type) {
    final assets = getMarketAssets();
    return assets.where((asset) => asset.type == type).toList();
  }
  
  // Settings Operations
  static Future<void> saveSetting(String key, dynamic value) async {
    await _settingsBox.put(key, {'value': value});
    print('⚙️ Setting saved: $key = $value');
  }
  
  static T? getSetting<T>(String key) {
    final settingData = _settingsBox.get(key);
    if (settingData == null) return null;
    return settingData['value'] as T?;
  }
  
  // Trading Operations
  static Future<bool> executeTrade({
    required String symbol,
    required String type,
    required int quantity,
    required double price,
  }) async {
    try {
      final user = getCurrentUser();
      if (user == null) {
        print('❌ No user found for trade execution');
        return false;
      }
      
      final totalValue = quantity * price;
      
      // Create transaction
      final transaction = TransactionModel(
        id: 'tx_${DateTime.now().millisecondsSinceEpoch}_${symbol}',
        userId: user.id,
        symbol: symbol,
        type: type,
        quantity: quantity,
        price: price,
        totalAmount: totalValue,
        timestamp: DateTime.now(),
      );
      
      if (type == 'buy') {
        // Check if user has enough cash
        if (user.cashBalance < totalValue) {
          print('❌ Insufficient funds for purchase');
          return false;
        }
        
        // Update cash balance
        await updateUserCashBalance(user.cashBalance - totalValue);
        
        // Update portfolio holding
        final existingHolding = getPortfolioHolding(symbol);
        if (existingHolding != null) {
          // Update existing holding
          final totalQuantity = existingHolding.quantity + quantity;
          final totalCost = (existingHolding.quantity * existingHolding.avgPrice) + totalValue;
          final newAvgPrice = totalCost / totalQuantity;
          
          final updatedHolding = existingHolding.copyWith(
            quantity: totalQuantity,
            avgPrice: newAvgPrice,
            updatedAt: DateTime.now(),
          );
          
          await savePortfolioHolding(updatedHolding);
        } else {
          // Create new holding
          final newHolding = PortfolioModel(
            id: 'holding_${symbol}_${user.id}',
            userId: user.id,
            symbol: symbol,
            quantity: quantity,
            avgPrice: price,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          );
          
          await savePortfolioHolding(newHolding);
        }
        
      } else if (type == 'sell') {
        // Check if user has enough shares
        final existingHolding = getPortfolioHolding(symbol);
        if (existingHolding == null || existingHolding.quantity < quantity) {
          print('❌ Insufficient shares for sale');
          return false;
        }
        
        // Update cash balance
        await updateUserCashBalance(user.cashBalance + totalValue);
        
        // Update portfolio holding
        final remainingQuantity = existingHolding.quantity - quantity;
        if (remainingQuantity > 0) {
          final updatedHolding = existingHolding.copyWith(
            quantity: remainingQuantity,
            updatedAt: DateTime.now(),
          );
          await savePortfolioHolding(updatedHolding);
        } else {
          // Remove holding if quantity is 0
          await removePortfolioHolding(symbol);
        }
      }
      
      // Save transaction
      await saveTransaction(transaction);
      
      print('✅ Trade executed successfully: $type $quantity $symbol at \$${price.toStringAsFixed(2)}');
      return true;
      
    } catch (e) {
      print('❌ Trade execution failed: $e');
      return false;
    }
  }
  
  // Analytics
  static Map<String, dynamic> getPortfolioSummary() {
    final user = getCurrentUser();
    final holdings = getPortfolioHoldings();
    
    if (user == null) {
      return {
        'cash_balance': 0.0,
        'holdings_value': 0.0,
        'net_worth': 0.0,
        'total_pnl': 0.0,
        'total_pnl_percentage': 0.0,
      };
    }
    
    double totalHoldingsValue = 0.0;
    double totalPnL = 0.0;
    
    for (final holding in holdings) {
      final currentAsset = getMarketAsset(holding.symbol);
      if (currentAsset != null) {
        final currentValue = holding.quantity * currentAsset.price;
        final purchaseValue = holding.quantity * holding.avgPrice;
        final holdingPnL = currentValue - purchaseValue;
        
        totalHoldingsValue += currentValue;
        totalPnL += holdingPnL;
      }
    }
    
    final netWorth = user.cashBalance + totalHoldingsValue;
    final totalPnLPercentage = totalHoldingsValue > 0 ? (totalPnL / (totalHoldingsValue - totalPnL)) * 100 : 0.0;
    
    return {
      'cash_balance': user.cashBalance,
      'holdings_value': totalHoldingsValue,
      'net_worth': netWorth,
      'total_pnl': totalPnL,
      'total_pnl_percentage': totalPnLPercentage,
    };
  }
  
  // Data Management
  static Future<void> clearAllData() async {
    await _userBox.clear();
    await _portfolioBox.clear();
    await _transactionBox.clear();
    await _marketDataBox.clear();
    await _settingsBox.clear();
    print('🗑️ All local data cleared');
  }
  
  static Future<void> exportData() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/stox_backup_${DateTime.now().millisecondsSinceEpoch}.json');
      
      final data = {
        'user': _userBox.toMap(),
        'portfolio': _portfolioBox.toMap(),
        'transactions': _transactionBox.toMap(),
        'market_data': _marketDataBox.toMap(),
        'settings': _settingsBox.toMap(),
        'exported_at': DateTime.now().toIso8601String(),
      };
      
      await file.writeAsString(jsonEncode(data));
      print('📤 Data exported to: ${file.path}');
    } catch (e) {
      print('❌ Export failed: $e');
    }
  }
  
  static Future<Map<String, dynamic>> getDatabaseStats() async {
    return {
      'users': _userBox.length,
      'portfolio_holdings': _portfolioBox.length,
      'transactions': _transactionBox.length,
      'market_assets': _marketDataBox.length,
      'settings': _settingsBox.length,
      'database_size_mb': await _getDatabaseSize(),
    };
  }
  
  static Future<double> _getDatabaseSize() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final hiveDir = Directory('${directory.path}');
      
      double totalSize = 0;
      await for (final file in hiveDir.list(recursive: true)) {
        if (file is File && file.path.contains('.hive')) {
          totalSize += await file.length();
        }
      }
      
      return totalSize / (1024 * 1024); // Convert to MB
    } catch (e) {
      return 0.0;
    }
  }
}