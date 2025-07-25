import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/portfolio_model.dart';
import '../models/transaction_model.dart';
import '../services/storage_service.dart';
import '../services/local_database_service.dart';
import '../services/connection_manager.dart';
import '../services/local_trading_service.dart';
import '../utils/uuid_utils.dart';

class PortfolioService {
  final SupabaseClient _supabase = Supabase.instance.client;
  final ConnectionManager _connectionManager = ConnectionManager();

  Future<List<PortfolioModel>> getUserPortfolio(String userId) async {
    // Use the user ID directly (should be Supabase Auth user ID)
    return await _connectionManager.forceExecuteWithFallback<List<PortfolioModel>>(
      () async {
        print('🔄 Attempting to load portfolio from Supabase...');
        final response = await _supabase
            .from('portfolio')
            .select()
            .eq('user_id', userId)
            .order('created_at', ascending: false);

        print('✅ Portfolio loaded from Supabase: ${response.length} holdings');
        return response.map<PortfolioModel>((json) => PortfolioModel.fromJson(json)).toList();
      },
      () async {
        print('📱 Loading portfolio from local storage...');
        return await LocalTradingService.getLocalPortfolio(userId);
      },
    ) ?? [];
  }

  Future<List<TransactionModel>> getUserTransactions(String userId, {int limit = 50}) async {
    // Use the user ID directly (should be Supabase Auth user ID)
    return await _connectionManager.executeWithFallback<List<TransactionModel>>(
      () async {
        final response = await _supabase
            .from('transactions')
            .select()
            .eq('user_id', userId)
            .order('timestamp', ascending: false)
            .limit(limit);

        return response.map<TransactionModel>((json) => TransactionModel.fromJson(json)).toList();
      },
      () async => await LocalTradingService.getLocalTransactions(userId, limit: limit),
    ) ?? [];
  }

  Future<bool> executeTrade({
    required String userId,
    required String symbol,
    required String type,
    required int quantity,
    required double price,
  }) async {
    // Try Supabase first if connection allows
    if (_connectionManager.shouldRetry) {
      try {
        final totalValue = quantity * price;
        
        // Get asset info from market data for sector tracking
        final marketData = await _getMarketAssetInfo(symbol);
        
        // Use the user ID directly (should be Supabase Auth user ID)
        final result = await _supabase.rpc('execute_trade', params: {
          'user_id_param': userId,
          'symbol_param': symbol,
          'type_param': type,
          'quantity_param': quantity,
          'price_param': price,
          'total_value_param': totalValue,
          'sector_param': marketData['sector'],
          'asset_type_param': marketData['type'],
        });
        
        // Check if trade was successful
        if (result['success'] != true) {
          throw Exception(result['error'] ?? 'Trade execution failed');
        }
        
        _connectionManager.recordSuccess();
        print('✅ Trade executed successfully (Supabase): $type $quantity $symbol at \$${price.toStringAsFixed(2)}');
        return true;
      } catch (e) {
        _connectionManager.recordFailure();
        print('❌ Supabase trade failed: $e');
      }
    }
    
    // Fallback to local trading
    print('🔄 Executing trade locally...');
    // Use the user ID directly (should be Supabase Auth user ID)
    return await LocalTradingService.executeTrade(
      userId: userId,
      symbol: symbol,
      type: type,
      quantity: quantity,
      price: price,
    );
  }

  Future<double> calculatePortfolioValue(String userId) async {
    try {
      final portfolio = await getUserPortfolio(userId);
      double totalValue = 0.0;

      for (final holding in portfolio) {
        final currentPrice = await _getCurrentPrice(holding.symbol);
        totalValue += holding.quantity * currentPrice;
      }

      return totalValue;
    } catch (e) {
      print('❌ Error calculating portfolio value: $e');
      return 0.0;
    }
  }

  Future<double> _getCurrentPrice(String symbol) async {
    try {
      final response = await _supabase
          .from('market_prices')
          .select('price')
          .eq('symbol', symbol)
          .maybeSingle();

      if (response != null) {
        return (response['price'] as num).toDouble();
      }
      print('⚠️ No price data found for $symbol, using fallback');
      return 0.0;
    } catch (e) {
      print('❌ Error fetching current price for $symbol: $e');
      return 0.0;
    }
  }

  Future<Map<String, dynamic>> _getMarketAssetInfo(String symbol) async {
    try {
      final response = await _supabase
          .from('market_prices')
          .select('sector, type')
          .eq('symbol', symbol)
          .maybeSingle();

      if (response != null) {
        return {
          'sector': response['sector'] ?? 'Unknown',
          'type': response['type'] ?? 'stock',
        };
      }
    } catch (e) {
      print('❌ Error fetching asset info for $symbol: $e');
    }
    
    // Default fallback
    return {
      'sector': 'Unknown',
      'type': 'stock',
    };
  }

  Future<Map<String, dynamic>> getPortfolioSummary(String userId) async {
    // Use the user ID directly (should be Supabase Auth user ID)
    return await _connectionManager.forceExecuteWithFallback<Map<String, dynamic>>(
      () async {
        print('🔄 Attempting to load portfolio summary from Supabase...');
        final portfolio = await getUserPortfolio(userId);
        
        // Get user's cash balance from Supabase
        final user = await _supabase
            .from('users')
            .select('cash_balance')
            .eq('id', userId)
            .maybeSingle();
        
        if (user == null) {
          print('⚠️ User not found in Supabase for ID: $userId');
          throw Exception('User not found in database');
        }
        
        final cashBalance = (user['cash_balance'] as num).toDouble();
        
        print('✅ Portfolio summary loaded from Supabase: Cash \$${cashBalance.toStringAsFixed(2)}');

        double totalHoldingsValue = 0.0;
        double totalPnL = 0.0;

        for (final holding in portfolio) {
          final currentPrice = await _getCurrentPrice(holding.symbol);
          final holdingValue = holding.quantity * currentPrice;
          final holdingPnL = holding.calculatePnL(currentPrice);
          
          totalHoldingsValue += holdingValue;
          totalPnL += holdingPnL;
        }

        final netWorth = cashBalance + totalHoldingsValue;

        return {
          'cash_balance': cashBalance,
          'holdings_value': totalHoldingsValue,
          'net_worth': netWorth,
          'total_pnl': totalPnL,
          'total_pnl_percentage': totalHoldingsValue > 0 ? (totalPnL / (totalHoldingsValue - totalPnL)) * 100 : 0.0,
        };
      },
      () async => await LocalTradingService.getPortfolioSummary(userId),
    ) ?? {
      'cash_balance': 10000.0,
      'holdings_value': 0.0,
      'net_worth': 10000.0,
      'total_pnl': 0.0,
      'total_pnl_percentage': 0.0,
    };
  }

  Future<bool> canAffordTrade(String userId, double totalCost) async {
    final user = await StorageService.getCachedUser();
    if (user != null) {
      final canAfford = user.cashBalance >= totalCost;
      print('✅ Checking affordability: \$${user.cashBalance.toStringAsFixed(2)} vs \$${totalCost.toStringAsFixed(2)} = $canAfford');
      return canAfford;
    }
    
    // Fallback to default balance
    print('✅ Using default cash balance for trade: \$10000.00');
    return 10000.0 >= totalCost;
  }

  Future<int> getSharesOwned(String userId, String symbol) async {
    // Use the user ID directly (should be Supabase Auth user ID)
    return await _connectionManager.executeWithFallback<int>(
      () async {
        final response = await _supabase
            .from('portfolio')
            .select('quantity')
            .eq('user_id', userId)
            .eq('symbol', symbol)
            .maybeSingle();

        return response?['quantity'] ?? 0;
      },
      () async => await LocalTradingService.getSharesOwned(userId, symbol),
    ) ?? 0;
  }

  Future<double> getUserCashBalance(String userId) async {
    try {
      // Use the user ID directly (should be Supabase Auth user ID)
      final response = await _supabase
          .from('users')
          .select('cash_balance')
          .eq('id', userId)
          .maybeSingle();

      if (response != null) {
        return (response['cash_balance'] as num).toDouble();
      }
      print('⚠️ User not found in Supabase for cash balance: $userId');
      return 10000.0; // Default starting balance
    } catch (e) {
      print('❌ Error fetching cash balance: $e');
      return 10000.0; // Default starting balance
    }
  }

  Future<void> updateUserCashBalance(String userId, double newBalance) async {
    try {
      // Use the user ID directly (should be Supabase Auth user ID)
      await _supabase
          .from('users')
          .update({'cash_balance': newBalance})
          .eq('id', userId);
    } catch (e) {
      print('❌ Error updating cash balance: $e');
      throw Exception('Failed to update cash balance');
    }
  }

  Future<Map<String, dynamic>> getPortfolioStats(String userId) async {
    try {
      final portfolio = await getUserPortfolio(userId);
      final transactions = await getUserTransactions(userId);
      
      if (portfolio.isEmpty) {
        return {
          'total_trades': 0,
          'win_rate': 0.0,
          'best_performer': null,
          'worst_performer': null,
          'most_traded': null,
        };
      }

      // Calculate win rate from closed positions
      int totalTrades = transactions.length;
      int winningTrades = 0;
      
      // Group transactions by symbol to calculate P&L
      final Map<String, List<TransactionModel>> tradesBySymbol = {};
      for (final tx in transactions) {
        tradesBySymbol.putIfAbsent(tx.symbol, () => []).add(tx);
      }

      String? bestPerformer;
      String? worstPerformer;
      String? mostTraded;
      double bestPnL = double.negativeInfinity;
      double worstPnL = double.infinity;
      int maxTrades = 0;

      for (final entry in tradesBySymbol.entries) {
        final symbol = entry.key;
        final trades = entry.value;
        
        // Calculate P&L for this symbol
        double totalPnL = 0.0;
        for (final trade in trades) {
          if (trade.type == 'sell') {
            totalPnL += trade.quantity * trade.price;
          } else {
            totalPnL -= trade.quantity * trade.price;
          }
        }
        
        // Check if this position is profitable
        if (totalPnL > 0) winningTrades++;
        
        // Track best/worst performers
        if (totalPnL > bestPnL) {
          bestPnL = totalPnL;
          bestPerformer = symbol;
        }
        if (totalPnL < worstPnL) {
          worstPnL = totalPnL;
          worstPerformer = symbol;
        }
        
        // Track most traded
        if (trades.length > maxTrades) {
          maxTrades = trades.length;
          mostTraded = symbol;
        }
      }

      final winRate = totalTrades > 0 ? (winningTrades / tradesBySymbol.length) * 100 : 0.0;

      return {
        'total_trades': totalTrades,
        'win_rate': winRate,
        'best_performer': bestPerformer,
        'worst_performer': worstPerformer,
        'most_traded': mostTraded,
      };
    } catch (e) {
      print('❌ Error calculating portfolio stats: $e');
      return {
        'total_trades': 0,
        'win_rate': 0.0,
        'best_performer': null,
        'worst_performer': null,
        'most_traded': null,
      };
    }
  }
}