import 'dart:convert';
import '../models/transaction_model.dart';
import '../models/portfolio_model.dart';
import '../models/user_model.dart';
import 'storage_service.dart';
import 'local_database_service.dart';

class LocalTradingService {
  static const String _portfolioKey = 'local_portfolio';
  static const String _transactionsKey = 'local_transactions';
  static const String _pendingTradesKey = 'pending_trades';

  // Execute a trade locally
  static Future<bool> executeTrade({
    required String userId,
    required String symbol,
    required String type,
    required int quantity,
    required double price,
  }) async {
    print('💰 LocalTradingService.executeTrade: Starting $type $quantity $symbol at \$${price.toStringAsFixed(2)}');
    try {
      final totalValue = quantity * price;
      print('💱 Total trade value: \$${totalValue.toStringAsFixed(2)}');
      
      // Get current user and validate
      final user = await StorageService.getCachedUser();
      if (user == null) {
        print('❌ No cached user found');
        return false;
      }
      
      print('💰 Current user cash balance: \$${user.cashBalance.toStringAsFixed(2)}');

      // Validate trade
      if (type == 'buy' && user.cashBalance < totalValue) {
        print('❌ Insufficient funds: need \$${totalValue.toStringAsFixed(2)}, have \$${user.cashBalance.toStringAsFixed(2)}');
        return false;
      }

      if (type == 'sell') {
        final currentShares = await getSharesOwned(userId, symbol);
        if (currentShares < quantity) {
          print('❌ Insufficient shares: need $quantity, have $currentShares');
          return false;
        }
      }

      // Update cash balance
      final newCashBalance = type == 'buy' 
          ? user.cashBalance - totalValue
          : user.cashBalance + totalValue;
      
      print('💰 Updating cash balance: \${user.cashBalance.toStringAsFixed(2)} → \${newCashBalance.toStringAsFixed(2)}');
      
      final updatedUser = user.copyWith(
        cashBalance: newCashBalance,
        updatedAt: DateTime.now(),
      );
      
      await StorageService.cacheUser(updatedUser);
      print('💾 Cached updated user with new balance: \${newCashBalance.toStringAsFixed(2)}');

      // Create transaction record
      final transaction = TransactionModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        userId: userId,
        symbol: symbol,
        type: type,
        quantity: quantity,
        price: price,
        totalAmount: totalValue,
        timestamp: DateTime.now(),
      );

      // Save transaction locally
      await saveTransaction(transaction);
      print('💾 Transaction saved locally: ${transaction.type} ${transaction.quantity} ${transaction.symbol}');

      // Update portfolio
      await updatePortfolio(userId, symbol, type, quantity, price);
      print('📊 Portfolio updated for ${symbol}');

      // Save as pending trade for sync later
      await savePendingTrade(transaction);
      print('📤 Trade saved as pending for sync');

      print('✅ Local trade executed: $type $quantity $symbol at \$${price.toStringAsFixed(2)}');
      print('✅ New cash balance: \$${newCashBalance.toStringAsFixed(2)}');
      
      return true;
    } catch (e) {
      print('❌ Local trade execution failed: $e');
      return false;
    }
  }

  // Get local portfolio
  static Future<List<PortfolioModel>> getLocalPortfolio(String userId) async {
    try {
      final portfolioData = await LocalDatabaseService.getSetting<List<dynamic>>(_portfolioKey);
      if (portfolioData == null) return [];

      return portfolioData
          .map((json) => PortfolioModel.fromJson(Map<String, dynamic>.from(json)))
          .where((p) => p.userId == userId)
          .toList();
    } catch (e) {
      print('❌ Error getting local portfolio: $e');
      return [];
    }
  }

  // Get local transactions
  static Future<List<TransactionModel>> getLocalTransactions(String userId, {int limit = 50}) async {
    try {
      final transactionsData = await LocalDatabaseService.getSetting<List<dynamic>>(_transactionsKey);
      if (transactionsData == null) return [];

      final transactions = transactionsData
          .map((json) => TransactionModel.fromJson(Map<String, dynamic>.from(json)))
          .where((t) => t.userId == userId)
          .toList();

      transactions.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      return transactions.take(limit).toList();
    } catch (e) {
      print('❌ Error getting local transactions: $e');
      return [];
    }
  }

  // Save transaction locally
  static Future<void> saveTransaction(TransactionModel transaction) async {
    try {
      final transactions = await LocalDatabaseService.getSetting<List<dynamic>>(_transactionsKey) ?? [];
      transactions.add(transaction.toJson());
      await LocalDatabaseService.saveSetting(_transactionsKey, transactions);
    } catch (e) {
      print('❌ Error saving transaction: $e');
    }
  }

  // Update portfolio after trade
  static Future<void> updatePortfolio(String userId, String symbol, String type, int quantity, double price) async {
    try {
      final portfolio = await getLocalPortfolio(userId);
      final existingHolding = portfolio.firstWhere(
        (p) => p.symbol == symbol,
        orElse: () => PortfolioModel(
          id: symbol,
          userId: userId,
          symbol: symbol,
          quantity: 0,
          avgPrice: 0.0,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      );

      int newQuantity;
      double newAvgPrice;

      if (type == 'buy') {
        newQuantity = existingHolding.quantity + quantity;
        newAvgPrice = ((existingHolding.quantity * existingHolding.avgPrice) + (quantity * price)) / newQuantity;
      } else {
        newQuantity = existingHolding.quantity - quantity;
        newAvgPrice = existingHolding.avgPrice; // Keep same avg price for sells
      }

      if (newQuantity <= 0) {
        // Remove from portfolio if no shares left
        portfolio.removeWhere((p) => p.symbol == symbol);
      } else {
        // Update existing holding
        final updatedHolding = existingHolding.copyWith(
          quantity: newQuantity,
          avgPrice: newAvgPrice,
          updatedAt: DateTime.now(),
        );

        final index = portfolio.indexWhere((p) => p.symbol == symbol);
        if (index >= 0) {
          portfolio[index] = updatedHolding;
        } else {
          portfolio.add(updatedHolding);
        }
      }

      // Save updated portfolio
      await LocalDatabaseService.saveSetting(_portfolioKey, portfolio.map((p) => p.toJson()).toList());
    } catch (e) {
      print('❌ Error updating portfolio: $e');
    }
  }

  // Get shares owned locally
  static Future<int> getSharesOwned(String userId, String symbol) async {
    try {
      final portfolio = await getLocalPortfolio(userId);
      final holding = portfolio.firstWhere(
        (p) => p.symbol == symbol,
        orElse: () => PortfolioModel(
          id: symbol,
          userId: userId,
          symbol: symbol,
          quantity: 0,
          avgPrice: 0.0,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      );
      return holding.quantity;
    } catch (e) {
      print('❌ Error getting shares owned: $e');
      return 0;
    }
  }

  // Save pending trade for sync
  static Future<void> savePendingTrade(TransactionModel transaction) async {
    try {
      final pendingTrades = await LocalDatabaseService.getSetting<List<dynamic>>(_pendingTradesKey) ?? [];
      pendingTrades.add(transaction.toJson());
      await LocalDatabaseService.saveSetting(_pendingTradesKey, pendingTrades);
    } catch (e) {
      print('❌ Error saving pending trade: $e');
    }
  }

  // Get pending trades
  static Future<List<TransactionModel>> getPendingTrades(String userId) async {
    try {
      final pendingTrades = await LocalDatabaseService.getSetting<List<dynamic>>(_pendingTradesKey) ?? [];
      return pendingTrades
          .map((json) => TransactionModel.fromJson(Map<String, dynamic>.from(json)))
          .where((trade) => trade.userId == userId)
          .toList();
    } catch (e) {
      print('❌ Error getting pending trades: $e');
      return [];
    }
  }

  // Clear pending trades after sync
  static Future<void> clearPendingTrades() async {
    try {
      await LocalDatabaseService.saveSetting(_pendingTradesKey, []);
    } catch (e) {
      print('❌ Error clearing pending trades: $e');
    }
  }

  // Calculate portfolio summary
  static Future<Map<String, dynamic>> getPortfolioSummary(String userId) async {
    try {
      final user = await StorageService.getCachedUser();
      final portfolio = await getLocalPortfolio(userId);
      
      double cashBalance = user?.cashBalance ?? 10000.0;
      double totalHoldingsValue = 0.0;
      double totalPnL = 0.0;

      for (final holding in portfolio) {
        totalHoldingsValue += holding.totalValue;
        // Note: Would need current prices for accurate P&L calculation
        // For now, using purchase value as placeholder
      }

      final netWorth = cashBalance + totalHoldingsValue;

      return {
        'cash_balance': cashBalance,
        'holdings_value': totalHoldingsValue,
        'net_worth': netWorth,
        'total_pnl': totalPnL,
        'total_pnl_percentage': totalHoldingsValue > 0 ? (totalPnL / totalHoldingsValue) * 100 : 0.0,
      };
    } catch (e) {
      print('❌ Error calculating portfolio summary: $e');
      return {
        'cash_balance': 10000.0,
        'holdings_value': 0.0,
        'net_worth': 10000.0,
        'total_pnl': 0.0,
        'total_pnl_percentage': 0.0,
      };
    }
  }

  // Clear synced trades after successful sync
  static Future<void> clearSyncedTrades(String userId, int syncedCount) async {
    try {
      final pendingTrades = await LocalDatabaseService.getSetting<List<dynamic>>(_pendingTradesKey) ?? [];
      
      // Convert to TransactionModel list for filtering
      final allTrades = pendingTrades
          .map((json) => TransactionModel.fromJson(Map<String, dynamic>.from(json)))
          .toList();
      
      // Remove the first syncedCount trades for this user
      final userTrades = allTrades.where((trade) => trade.userId == userId).toList();
      final tradesToRemove = userTrades.take(syncedCount).toList();
      
      // Filter out the synced trades
      final remainingTrades = allTrades
          .where((trade) => !tradesToRemove.contains(trade))
          .map((trade) => trade.toJson())
          .toList();
      
      await LocalDatabaseService.saveSetting(_pendingTradesKey, remainingTrades);
      print('🧹 Cleared $syncedCount synced trades for user $userId');
    } catch (e) {
      print('❌ Error clearing synced trades: $e');
    }
  }

  // Get local user data
  static Future<UserModel?> getLocalUserData(String userId) async {
    try {
      final user = await StorageService.getCachedUser();
      if (user?.id == userId) {
        return user;
      }
      return null;
    } catch (e) {
      print('❌ Error getting local user data: $e');
      return null;
    }
  }
}