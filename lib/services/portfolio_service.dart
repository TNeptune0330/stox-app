import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/portfolio_model.dart';
import '../models/transaction_model.dart';

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
      throw Exception('Failed to fetch portfolio: $e');
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
      throw Exception('Failed to fetch transactions: $e');
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
      await _supabase.rpc('execute_trade', params: {
        'user_id_param': userId,
        'symbol_param': symbol,
        'type_param': type,
        'quantity_param': quantity,
        'price_param': price,
      });

      return true;
    } catch (e) {
      throw Exception('Failed to execute trade: $e');
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
      throw Exception('Failed to calculate portfolio value: $e');
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
      return 0.0;
    }
  }

  Future<Map<String, dynamic>> getPortfolioSummary(String userId) async {
    try {
      final portfolio = await getUserPortfolio(userId);
      final user = await _supabase
          .from('users')
          .select('cash_balance')
          .eq('id', userId)
          .single();

      double totalHoldingsValue = 0.0;
      double totalPnL = 0.0;

      for (final holding in portfolio) {
        final currentPrice = await _getCurrentPrice(holding.symbol);
        final holdingValue = holding.quantity * currentPrice;
        final holdingPnL = holding.calculatePnL(currentPrice);
        
        totalHoldingsValue += holdingValue;
        totalPnL += holdingPnL;
      }

      final cashBalance = (user['cash_balance'] as num).toDouble();
      final netWorth = cashBalance + totalHoldingsValue;

      return {
        'cash_balance': cashBalance,
        'holdings_value': totalHoldingsValue,
        'net_worth': netWorth,
        'total_pnl': totalPnL,
        'total_pnl_percentage': totalHoldingsValue > 0 ? (totalPnL / (totalHoldingsValue - totalPnL)) * 100 : 0.0,
      };
    } catch (e) {
      throw Exception('Failed to get portfolio summary: $e');
    }
  }

  Future<bool> canAffordTrade(String userId, double totalCost) async {
    try {
      final response = await _supabase
          .from('users')
          .select('cash_balance')
          .eq('id', userId)
          .single();

      final cashBalance = (response['cash_balance'] as num).toDouble();
      return cashBalance >= totalCost;
    } catch (e) {
      return false;
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
      return 0;
    }
  }
}