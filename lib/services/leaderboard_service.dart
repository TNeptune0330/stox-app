import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user_model.dart';

class LeaderboardService {
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<List<Map<String, dynamic>>> getLeaderboard({int limit = 100}) async {
    try {
      print('📊 Fetching leaderboard...');
      
      // Get all users with their portfolio values and trade counts
      final response = await _supabase
          .from('leaderboard')
          .select('*, users!inner(username, avatar_url, total_trades)')
          .order('rank', ascending: true)
          .limit(limit);

      print('✅ Loaded ${response.length} leaderboard entries');
      return response;
    } catch (e) {
      print('❌ Error fetching leaderboard: $e');
      return [];
    }
  }

  Future<Map<String, dynamic>?> getUserRank(String userId) async {
    try {
      final response = await _supabase
          .from('leaderboard')
          .select('*, users!inner(username, avatar_url)')
          .eq('user_id', userId)
          .maybeSingle();

      return response;
    } catch (e) {
      print('❌ Error fetching user rank: $e');
      return null;
    }
  }

  Future<void> updateUserRank(String userId) async {
    try {
      print('🔄 Updating user rank for $userId...');
      
      // Skip leaderboard update if Supabase is unavailable
      if (!await _isSupabaseAvailable()) {
        print('⚠️ Supabase unavailable, skipping leaderboard update');
        return;
      }
      
      // Get user's current portfolio and cash balance
      final user = await _supabase
          .from('users')
          .select('cash_balance, username')
          .eq('id', userId)
          .single();

      // Calculate portfolio value
      final portfolioResponse = await _supabase
          .from('portfolio')
          .select('symbol, quantity, avg_price')
          .eq('user_id', userId);

      double totalPortfolioValue = 0.0;
      double totalPnL = 0.0;

      for (final holding in portfolioResponse) {
        final symbol = holding['symbol'];
        final quantity = holding['quantity'];
        final avgPrice = holding['avg_price'];

        // Get current price
        final priceResponse = await _supabase
            .from('market_prices')
            .select('price')
            .eq('symbol', symbol)
            .maybeSingle();

        if (priceResponse != null) {
          final currentPrice = priceResponse['price'].toDouble();
          final holdingValue = quantity * currentPrice;
          final holdingPnL = quantity * (currentPrice - avgPrice);
          
          totalPortfolioValue += holdingValue;
          totalPnL += holdingPnL;
        }
      }

      final cashBalance = user['cash_balance'].toDouble();
      final netWorth = cashBalance + totalPortfolioValue;
      final totalPnLPercentage = totalPortfolioValue > 0 ? (totalPnL / totalPortfolioValue) * 100 : 0.0;

      // Update or insert leaderboard entry
      await _supabase.from('leaderboard').upsert({
        'user_id': userId,
        'username': user['username'],
        'net_worth': netWorth,
        'total_pnl': totalPnL,
        'total_pnl_percentage': totalPnLPercentage,
        'updated_at': DateTime.now().toIso8601String(),
      });

      print('✅ User rank updated successfully');
    } catch (e) {
      print('❌ Error updating user rank: $e');
      throw Exception('Failed to update user rank: $e');
    }
  }

  Future<bool> _isSupabaseAvailable() async {
    try {
      await _supabase.from('users').select('id').limit(1);
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<void> updateAllRanks() async {
    try {
      print('🔄 Updating all user ranks...');
      
      // Call the stored procedure to update leaderboard
      await _supabase.rpc('update_leaderboard');
      
      print('✅ All user ranks updated successfully');
    } catch (e) {
      print('❌ Error updating all ranks: $e');
      throw Exception('Failed to update all ranks: $e');
    }
  }

  Future<Map<String, dynamic>> getLeaderboardStats() async {
    try {
      final response = await _supabase
          .from('leaderboard')
          .select('net_worth, total_pnl')
          .order('rank', ascending: true);

      if (response.isEmpty) {
        return {
          'total_players': 0,
          'top_net_worth': 0.0,
          'average_net_worth': 0.0,
          'total_profits': 0.0,
          'total_losses': 0.0,
        };
      }

      final totalPlayers = response.length;
      final topNetWorth = response.first['net_worth'].toDouble();
      final averageNetWorth = response.map((e) => e['net_worth'].toDouble()).reduce((a, b) => a + b) / totalPlayers;
      
      double totalProfits = 0.0;
      double totalLosses = 0.0;
      
      for (final entry in response) {
        final pnl = entry['total_pnl'].toDouble();
        if (pnl > 0) {
          totalProfits += pnl;
        } else {
          totalLosses += pnl.abs();
        }
      }

      return {
        'total_players': totalPlayers,
        'top_net_worth': topNetWorth,
        'average_net_worth': averageNetWorth,
        'total_profits': totalProfits,
        'total_losses': totalLosses,
      };
    } catch (e) {
      print('❌ Error getting leaderboard stats: $e');
      return {
        'total_players': 0,
        'top_net_worth': 0.0,
        'average_net_worth': 0.0,
        'total_profits': 0.0,
        'total_losses': 0.0,
      };
    }
  }

  Future<List<Map<String, dynamic>>> getTopPerformers({int limit = 10}) async {
    try {
      final response = await _supabase
          .from('leaderboard')
          .select('*, users!inner(username, avatar_url)')
          .order('total_pnl_percentage', ascending: false)
          .limit(limit);

      return response;
    } catch (e) {
      print('❌ Error fetching top performers: $e');
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> getRecentJoiners({int limit = 10}) async {
    try {
      final response = await _supabase
          .from('users')
          .select('id, username, avatar_url, created_at, cash_balance')
          .order('created_at', ascending: false)
          .limit(limit);

      return response;
    } catch (e) {
      print('❌ Error fetching recent joiners: $e');
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> searchUsers(String query, {int limit = 20}) async {
    try {
      final response = await _supabase
          .from('leaderboard')
          .select('*, users!inner(username, avatar_url)')
          .or('username.ilike.%$query%,users.email.ilike.%$query%')
          .order('net_worth', ascending: false)
          .limit(limit);

      return response;
    } catch (e) {
      print('❌ Error searching users: $e');
      return [];
    }
  }
}