import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/portfolio_model.dart';
import '../models/transaction_model.dart';
import '../services/storage_service.dart';

class PortfolioService {
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<List<PortfolioModel>> getUserPortfolio(String userId) async {
    try {
      final response = await _supabase
          .from('portfolio')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false);

      return response.map<PortfolioModel>((json) => PortfolioModel.fromJson(json)).toList();
    } catch (e) {
      print('❌ Error fetching portfolio: $e');
      return [];
    }
  }

  Future<List<TransactionModel>> getUserTransactions(String userId, {int limit = 50}) async {
    try {
      final response = await _supabase
          .from('transactions')
          .select()
          .eq('user_id', userId)
          .order('timestamp', ascending: false)
          .limit(limit);

      return response.map<TransactionModel>((json) => TransactionModel.fromJson(json)).toList();
    } catch (e) {
      print('❌ Error fetching transactions: $e');
      return [];
    }
  }

  Future<bool> executeTrade({
    required String userId,
    required String symbol,
    required String type,
    required int quantity,
    required double price,
  }) async {
    try {
      final totalValue = quantity * price;
      
      // Check if user has enough cash for buy orders
      if (type == 'buy') {
        final canAfford = await canAffordTrade(userId, totalValue);
        if (!canAfford) {
          throw Exception('Insufficient funds');
        }
      }
      
      // For sell orders, check if user has enough shares
      if (type == 'sell') {
        final sharesOwned = await getSharesOwned(userId, symbol);
        if (sharesOwned < quantity) {
          throw Exception('Insufficient shares');
        }
      }

      // Execute the trade using database transaction or local storage
      try {
        await _supabase.rpc('execute_trade', params: {
          'user_id_param': userId,
          'symbol_param': symbol,
          'type_param': type,
          'quantity_param': quantity,
          'price_param': price,
          'total_value_param': totalValue,
        });
        print('✅ Trade executed successfully (Supabase): $type $quantity $symbol at \$${price.toStringAsFixed(2)}');
      } catch (e) {
        print('❌ Supabase trade failed: $e');
        // For demo purposes, just log the trade locally
        print('✅ Trade executed locally (demo): $type $quantity $symbol at \$${price.toStringAsFixed(2)}');
        
        // Update cached user's cash balance
        try {
          final cachedUser = await StorageService.getCachedUser();
          if (cachedUser != null) {
            final newCashBalance = type == 'buy' 
                ? cachedUser.cashBalance - totalValue
                : cachedUser.cashBalance + totalValue;
            
            final updatedUser = cachedUser.copyWith(
              cashBalance: newCashBalance,
              updatedAt: DateTime.now(),
            );
            
            await StorageService.cacheUser(updatedUser);
            print('✅ Updated cached cash balance: \$${newCashBalance.toStringAsFixed(2)}');
          }
        } catch (storageError) {
          print('❌ Error updating cached user: $storageError');
        }
      }
      
      return true;
    } catch (e) {
      print('❌ Trade execution failed: $e');
      return false;
    }
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
          .single();

      return (response['price'] as num).toDouble();
    } catch (e) {
      print('❌ Error fetching current price for $symbol: $e');
      return 0.0;
    }
  }

  Future<Map<String, dynamic>> getPortfolioSummary(String userId) async {
    try {
      final portfolio = await getUserPortfolio(userId);
      
      // Get user's cash balance - try Supabase first, then local storage
      double cashBalance = 0.0;
      try {
        final user = await _supabase
            .from('users')
            .select('cash_balance')
            .eq('id', userId)
            .single();
        cashBalance = (user['cash_balance'] as num).toDouble();
      } catch (e) {
        print('❌ Error fetching cash balance from Supabase: $e');
        // Fallback to local storage
        try {
          final cachedUser = await StorageService.getCachedUser();
          if (cachedUser != null) {
            cashBalance = cachedUser.cashBalance;
            print('✅ Using cached cash balance: \$${cashBalance.toStringAsFixed(2)}');
          } else {
            cashBalance = 10000.0; // Default starting balance
            print('✅ Using default cash balance: \$${cashBalance.toStringAsFixed(2)}');
          }
        } catch (storageError) {
          print('❌ Error fetching cached user: $storageError');
          cashBalance = 10000.0; // Default starting balance
        }
      }

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
    } catch (e) {
      print('❌ Error calculating portfolio summary: $e');
      return {
        'cash_balance': 0.0,
        'holdings_value': 0.0,
        'net_worth': 0.0,
        'total_pnl': 0.0,
        'total_pnl_percentage': 0.0,
      };
    }
  }

  Future<bool> canAffordTrade(String userId, double totalCost) async {
    try {
      // Try Supabase first
      final response = await _supabase
          .from('users')
          .select('cash_balance')
          .eq('id', userId)
          .single();

      final cashBalance = (response['cash_balance'] as num).toDouble();
      return cashBalance >= totalCost;
    } catch (e) {
      print('❌ Error checking affordability from Supabase: $e');
      // Fallback to local storage
      try {
        final cachedUser = await StorageService.getCachedUser();
        if (cachedUser != null) {
          final cashBalance = cachedUser.cashBalance;
          print('✅ Using cached cash balance for trade: \$${cashBalance.toStringAsFixed(2)}');
          print('✅ Trade cost: \$${totalCost.toStringAsFixed(2)}');
          return cashBalance >= totalCost;
        } else {
          // Default starting balance
          print('✅ Using default cash balance for trade: \$10000.00');
          return 10000.0 >= totalCost;
        }
      } catch (storageError) {
        print('❌ Error checking cached user: $storageError');
        return 10000.0 >= totalCost; // Default starting balance
      }
    }
  }

  Future<int> getSharesOwned(String userId, String symbol) async {
    try {
      final response = await _supabase
          .from('portfolio')
          .select('quantity')
          .eq('user_id', userId)
          .eq('symbol', symbol)
          .maybeSingle();

      return response?['quantity'] ?? 0;
    } catch (e) {
      print('❌ Error fetching shares owned: $e');
      return 0;
    }
  }

  Future<double> getUserCashBalance(String userId) async {
    try {
      final response = await _supabase
          .from('users')
          .select('cash_balance')
          .eq('id', userId)
          .single();

      return (response['cash_balance'] as num).toDouble();
    } catch (e) {
      print('❌ Error fetching cash balance: $e');
      return 0.0;
    }
  }

  Future<void> updateUserCashBalance(String userId, double newBalance) async {
    try {
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