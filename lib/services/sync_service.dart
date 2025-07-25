import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/local_trading_service.dart';
import '../services/connection_manager.dart';
import '../models/transaction_model.dart';

class SyncService {
  static final SupabaseClient _supabase = Supabase.instance.client;
  static final ConnectionManager _connectionManager = ConnectionManager();

  /// Sync all pending trades to Supabase when connection is restored
  static Future<bool> syncPendingTrades(String userId) async {
    try {
      print('🔄 Starting sync for pending trades...');
      
      // Get all pending trades
      final pendingTrades = await LocalTradingService.getPendingTrades(userId);
      
      if (pendingTrades.isEmpty) {
        print('✅ No pending trades to sync');
        return true;
      }
      
      print('📊 Found ${pendingTrades.length} pending trades to sync');
      
      int syncedCount = 0;
      List<String> failedTrades = [];
      
      // Process each pending trade
      for (final trade in pendingTrades) {
        try {
          // Execute trade on Supabase using the stored procedure
          final result = await _supabase.rpc('execute_trade', params: {
            'user_id_param': userId,
            'symbol_param': trade.symbol,
            'type_param': trade.type,
            'quantity_param': trade.quantity,
            'price_param': trade.price,
            'total_value_param': trade.totalAmount,
            'sector_param': null, // Trade model doesn't have sector
            'asset_type_param': 'stock', // Default to stock
          });
          
          if (result != null && result['success'] == true) {
            syncedCount++;
            print('✅ Synced trade: ${trade.symbol} ${trade.type} ${trade.quantity}');
          } else {
            failedTrades.add('${trade.symbol} ${trade.type}');
            print('❌ Failed to sync trade: ${trade.symbol} - ${result?['error']}');
          }
          
        } catch (e) {
          failedTrades.add('${trade.symbol} ${trade.type}');
          print('❌ Error syncing trade ${trade.symbol}: $e');
        }
      }
      
      // Clear successfully synced trades
      if (syncedCount > 0) {
        await LocalTradingService.clearSyncedTrades(userId, syncedCount);
        print('🧹 Cleared $syncedCount synced trades from local storage');
      }
      
      if (failedTrades.isNotEmpty) {
        print('⚠️ Failed to sync ${failedTrades.length} trades: ${failedTrades.join(', ')}');
        return false;
      }
      
      print('✅ Successfully synced all $syncedCount pending trades');
      return true;
      
    } catch (e) {
      print('❌ Error during sync process: $e');
      return false;
    }
  }

  /// Sync user data (cash balance, profile) to Supabase
  static Future<bool> syncUserData(String userId) async {
    try {
      print('🔄 Syncing user data...');
      
      // Get local user data
      final userData = await LocalTradingService.getLocalUserData(userId);
      if (userData == null) {
        print('❌ No local user data found');
        return false;
      }
      
      // Update user data in Supabase
      await _supabase
          .from('users')
          .update({
            'cash_balance': userData.cashBalance,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', userId);
      
      print('✅ User data synced successfully');
      return true;
      
    } catch (e) {
      print('❌ Error syncing user data: $e');
      return false;
    }
  }

  /// Sync portfolio holdings to Supabase
  static Future<bool> syncPortfolio(String userId) async {
    try {
      print('🔄 Syncing portfolio holdings...');
      
      // Get local portfolio
      final portfolio = await LocalTradingService.getLocalPortfolio(userId);
      
      if (portfolio.isEmpty) {
        print('✅ No portfolio to sync');
        return true;
      }
      
      // Upsert each holding
      for (final holding in portfolio) {
        await _supabase
            .from('portfolio')
            .upsert({
              'user_id': userId,
              'symbol': holding.symbol,
              'quantity': holding.quantity,
              'avg_price': holding.avgPrice,
              'total_invested': holding.totalValue,
              'updated_at': DateTime.now().toIso8601String(),
            });
      }
      
      print('✅ Portfolio synced successfully (${portfolio.length} holdings)');
      return true;
      
    } catch (e) {
      print('❌ Error syncing portfolio: $e');
      return false;
    }
  }

  /// Perform complete sync of all user data
  static Future<bool> performFullSync(String userId) async {
    try {
      print('🔄 Starting full sync for user: $userId');
      
      // Check if we have connection
      if (!await _connectionManager.hasConnection()) {
        print('❌ No connection available for sync');
        return false;
      }
      
      // Sync in order of importance
      bool tradesSuccess = await syncPendingTrades(userId);
      bool userSuccess = await syncUserData(userId);
      bool portfolioSuccess = await syncPortfolio(userId);
      
      final overallSuccess = tradesSuccess && userSuccess && portfolioSuccess;
      
      if (overallSuccess) {
        print('✅ Full sync completed successfully');
      } else {
        print('⚠️ Full sync completed with some failures');
      }
      
      return overallSuccess;
      
    } catch (e) {
      print('❌ Error during full sync: $e');
      return false;
    }
  }

  /// Auto-sync when connection is restored
  static Future<void> autoSyncOnConnection(String userId) async {
    try {
      // Listen for connection changes
      _connectionManager.onConnectionRestored = () async {
        print('🌐 Connection restored, starting auto-sync...');
        await performFullSync(userId);
      };
      
    } catch (e) {
      print('❌ Error setting up auto-sync: $e');
    }
  }

  /// Get sync status for UI
  static Future<Map<String, dynamic>> getSyncStatus(String userId) async {
    try {
      final pendingTrades = await LocalTradingService.getPendingTrades(userId);
      final hasConnection = await _connectionManager.hasConnection();
      
      return {
        'pending_trades': pendingTrades.length,
        'has_connection': hasConnection,
        'last_sync': DateTime.now().toIso8601String(),
      };
      
    } catch (e) {
      print('❌ Error getting sync status: $e');
      return {
        'pending_trades': 0,
        'has_connection': false,
        'last_sync': null,
      };
    }
  }
}