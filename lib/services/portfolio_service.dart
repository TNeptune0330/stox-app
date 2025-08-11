import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/portfolio_model.dart';
import '../models/transaction_model.dart';
import '../services/storage_service.dart';
import '../services/local_database_service.dart';
import '../services/connection_manager.dart';
import '../services/enhanced_market_data_service.dart';
import '../services/finnhub_limiter_service.dart';
import '../services/portfolio_cache_service.dart';
import '../utils/uuid_utils.dart';

class PortfolioService {
  final SupabaseClient _supabase = Supabase.instance.client;
  final ConnectionManager _connectionManager = ConnectionManager();

  Future<List<PortfolioModel>> getUserPortfolio(String userId) async {
    print('🏦 PortfolioService.getUserPortfolio: Starting for user $userId');
    
    // Debug: Check what portfolio data exists in the database
    await _debugPortfolioData(userId);
    
    // Use the user ID directly (should be Supabase Auth user ID)
    final result = await _connectionManager.forceExecuteWithFallback<List<PortfolioModel>>(
      () async {
        print('🔄 PortfolioService: Attempting to load portfolio from Supabase...');
        print('🔄 PortfolioService: User ID: "$userId" (type: ${userId.runtimeType})');
        print('🔄 PortfolioService: User ID length: ${userId.length}');
        print('🔄 PortfolioService: Query: SELECT * FROM portfolio WHERE user_id = \'$userId\'');
        
        final response = await _supabase
            .from('portfolio')
            .select()
            .eq('user_id', userId)
            .order('created_at', ascending: false);

        print('✅ PortfolioService: Raw Supabase response type: ${response.runtimeType}');
        print('✅ PortfolioService: Raw Supabase response: $response');
        print('✅ PortfolioService: Portfolio query successful: ${response.length} holdings');
        
        if (response.isEmpty) {
          print('⚠️ PortfolioService: No portfolio data found in Supabase for user $userId');
          return <PortfolioModel>[];
        }
        
        print('🔄 PortfolioService: Converting ${response.length} JSON objects to PortfolioModel...');
        final portfolioList = <PortfolioModel>[];
        
        for (int i = 0; i < response.length; i++) {
          try {
            final json = response[i];
            print('🔄 PortfolioService: Converting item $i: $json');
            
            // Validate required fields before conversion
            final requiredFields = ['id', 'user_id', 'symbol', 'quantity', 'avg_price', 'created_at', 'updated_at'];
            for (final field in requiredFields) {
              if (!json.containsKey(field) || json[field] == null) {
                print('❌ PortfolioService: Missing required field "$field" in JSON: $json');
                throw Exception('Missing required field: $field');
              }
            }
            
            final portfolioItem = PortfolioModel.fromJson(json);
            portfolioList.add(portfolioItem);
            print('✅ PortfolioService: Successfully converted ${portfolioItem.symbol}: ${portfolioItem.quantity} shares @ \$${portfolioItem.avgPrice}');
            
          } catch (e) {
            print('❌ PortfolioService: Failed to convert JSON item $i: $e');
            print('❌ PortfolioService: Problematic JSON: ${response[i]}');
            // Continue processing other items instead of failing completely
            continue;
          }
        }
        
        print('✅ PortfolioService: Successfully converted ${portfolioList.length}/${response.length} portfolio items');
        return portfolioList;
      },
      () async {
        print('📱 PortfolioService: Loading portfolio from local storage...');
        // Temporarily return empty portfolio for local database
        final localPortfolio = <PortfolioModel>[];
        print('📱 PortfolioService: Local portfolio loaded: ${localPortfolio.length} holdings');
        return localPortfolio;
      },
    );
    
    final finalResult = result ?? <PortfolioModel>[];
    print('🏦 PortfolioService.getUserPortfolio: Returning ${finalResult.length} holdings');
    return finalResult;
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
      () async => <TransactionModel>[],
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
        print('🔍 PortfolioService: execute_trade result: $result');
        if (result['success'] != true) {
          print('❌ PortfolioService: Trade failed with error: ${result['error']}');
          throw Exception(result['error'] ?? 'Trade execution failed');
        }
        
        _connectionManager.recordSuccess();
        print('✅ Trade executed successfully (Supabase): $type $quantity $symbol at \$${price.toStringAsFixed(2)}');
        print('✅ PortfolioService: Trade result details: $result');
        
        // Clear all cache immediately after successful database update
        await _clearAllCaches();
        print('🗑️ PortfolioService: All caches cleared after successful trade');
        
        return true;
      } catch (e) {
        _connectionManager.recordFailure();
        print('❌ Supabase trade failed: $e');
      }
    }
    
    // Fallback to local trading
    print('🔄 Executing trade locally...');
    // Use the user ID directly (should be Supabase Auth user ID)
    return await LocalDatabaseService.executeTrade(
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
      int validHoldings = 0;

      for (final holding in portfolio) {
        final currentPrice = await _getCurrentPrice(holding.symbol);
        if (currentPrice > 0) {
          // Only include holdings with REAL market data
          final holdingValue = holding.quantity * currentPrice;
          totalValue += holdingValue;
          validHoldings++;
          print('📊 Adding ${holding.symbol}: ${holding.quantity} × \$${currentPrice.toStringAsFixed(2)} = \$${holdingValue.toStringAsFixed(2)}');
        } else {
          print('⚠️ Skipping ${holding.symbol}: No live market data available');
        }
      }

      print('✅ Portfolio value calculated: \$${totalValue.toStringAsFixed(2)} from $validHoldings holdings with live data');
      return totalValue;
    } catch (e) {
      print('❌ Error calculating portfolio value: $e');
      return 0.0;
    }
  }

  Future<double> _getCurrentPrice(String symbol) async {
    try {
      // ONLY use live Finnhub API data - NO FALLBACKS
      final finnhubAsset = await FinnhubLimiterService.getStockQuote(symbol);
      if (finnhubAsset != null && finnhubAsset.price > 0) {
        print('✅ Using LIVE Finnhub price for $symbol: \$${finnhubAsset.price.toStringAsFixed(2)}');
        return finnhubAsset.price;
      }
      
      // If Finnhub fails, try enhanced market data service (live data only)
      final assetData = await EnhancedMarketDataService.getAsset(symbol);
      if (assetData != null && assetData.price > 0) {
        print('✅ Using LIVE market data for $symbol: \$${assetData.price.toStringAsFixed(2)}');
        return assetData.price;
      }
      
      // NO FALLBACKS - if we can't get live data, return 0
      print('❌ No live market data available for $symbol - returning 0.0');
      return 0.0;
    } catch (e) {
      print('❌ Error fetching current price for $symbol: $e');
      return 0.0;
    }
  }

  Future<String> _getCurrentUserId() async {
    final user = StorageService.getCachedUser();
    return user?.id ?? '';
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
        
        // Try to get user's cash balance from users table first, then user_profiles as fallback
        double cashBalance = 10000.0; // Default balance
        
        try {
          final user = await _supabase
              .from('users')
              .select('cash_balance')
              .eq('id', userId)
              .maybeSingle();
          
          if (user != null) {
            cashBalance = (user['cash_balance'] as num).toDouble();
            print('✅ Got cash balance from users table: \$${cashBalance.toStringAsFixed(2)}');
          } else {
            print('⚠️ User not found in users table, trying user_profiles...');
            
            // Fallback to user_profiles table
            final userProfile = await _supabase
                .from('user_profiles')
                .select('cash_balance')
                .eq('id', userId)
                .maybeSingle();
            
            if (userProfile != null && userProfile['cash_balance'] != null) {
              cashBalance = (userProfile['cash_balance'] as num).toDouble();
              print('✅ Got cash balance from user_profiles: \$${cashBalance.toStringAsFixed(2)}');
            } else {
              print('⚠️ No cash balance found, using default: \$${cashBalance.toStringAsFixed(2)}');
            }
          }
        } catch (e) {
          print('❌ Error fetching cash balance: $e - using default: \$${cashBalance.toStringAsFixed(2)}');
        }
        
        print('✅ Portfolio summary loaded from Supabase: Cash \$${cashBalance.toStringAsFixed(2)}');

        double totalHoldingsValue = 0.0;
        double totalPnL = 0.0;

        double totalCostBasis = 0.0; // Track original investment amount
        
        print('📊 Processing ${portfolio.length} holdings for portfolio summary');
        
        for (final holding in portfolio) {
          print('📊 Processing holding: ${holding.symbol} - Qty: ${holding.quantity}, Avg Price: \$${holding.avgPrice.toStringAsFixed(2)}');
          
          final currentPrice = await _getCurrentPrice(holding.symbol);
          final holdingValue = holding.quantity * currentPrice;
          final holdingPnL = holding.calculatePnL(currentPrice);
          final holdingCostBasis = holding.quantity * holding.avgPrice;
          
          totalHoldingsValue += holdingValue;
          totalPnL += holdingPnL;
          totalCostBasis += holdingCostBasis;
          
          print('📊 ${holding.symbol}: Current \$${currentPrice.toStringAsFixed(2)}, Value \$${holdingValue.toStringAsFixed(2)}, P&L \$${holdingPnL.toStringAsFixed(2)}');
        }

        final netWorth = cashBalance + totalHoldingsValue;
        
        // Calculate P&L percentage based on cost basis (original investment)
        final totalPnLPercentage = totalCostBasis > 0 ? (totalPnL / totalCostBasis) * 100 : 0.0;

        return {
          'cash_balance': cashBalance,
          'holdings_value': totalHoldingsValue,
          'net_worth': netWorth,
          'total_pnl': totalPnL,
          'total_pnl_percentage': totalPnLPercentage,
        };
      },
      () async => LocalDatabaseService.getPortfolioSummary(),
    ) ?? {
      'cash_balance': 10000.0,
      'holdings_value': 0.0,
      'net_worth': 10000.0,
      'total_pnl': 0.0,
      'total_pnl_percentage': 0.0,
    };
  }

  Future<bool> canAffordTrade(String userId, double totalCost) async {
    final user = StorageService.getCachedUser();
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
      () async => 0,
    ) ?? 0;
  }

  Future<double> getUserCashBalance(String userId) async {
    try {
      // Try users table first
      final userResponse = await _supabase
          .from('users')
          .select('cash_balance')
          .eq('id', userId)
          .maybeSingle();

      if (userResponse != null && userResponse['cash_balance'] != null) {
        return (userResponse['cash_balance'] as num).toDouble();
      }
      
      // Fallback to user_profiles table
      final profileResponse = await _supabase
          .from('user_profiles')
          .select('cash_balance')
          .eq('id', userId)
          .maybeSingle();

      if (profileResponse != null && profileResponse['cash_balance'] != null) {
        return (profileResponse['cash_balance'] as num).toDouble();
      }
      
      print('⚠️ User not found in either users or user_profiles table: $userId');
      return 10000.0; // Default starting balance
    } catch (e) {
      print('❌ Error fetching cash balance: $e');
      return 10000.0; // Default starting balance
    }
  }

  Future<void> updateUserCashBalance(String userId, double newBalance) async {
    try {
      // Try to update users table first
      final userUpdateResult = await _supabase
          .from('users')
          .update({'cash_balance': newBalance})
          .eq('id', userId);
      
      print('✅ Updated cash balance in users table: \$${newBalance.toStringAsFixed(2)}');
      
      // Also update user_profiles as backup
      try {
        await _supabase
            .from('user_profiles')
            .update({'cash_balance': newBalance})
            .eq('id', userId);
        print('✅ Updated cash balance in user_profiles table: \$${newBalance.toStringAsFixed(2)}');
      } catch (e) {
        print('⚠️ Could not update user_profiles cash balance (non-critical): $e');
      }
      
    } catch (e) {
      print('❌ Error updating cash balance in users table: $e');
      
      // Fallback to updating user_profiles only
      try {
        await _supabase
            .from('user_profiles')
            .update({'cash_balance': newBalance})
            .eq('id', userId);
        print('✅ Updated cash balance in user_profiles table (fallback): \$${newBalance.toStringAsFixed(2)}');
      } catch (fallbackError) {
        print('❌ Error updating cash balance in user_profiles: $fallbackError');
        throw Exception('Failed to update cash balance in any table');
      }
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

  /// Debug method to inspect portfolio data in the database
  Future<void> _debugPortfolioData(String userId) async {
    try {
      print('🔍 DEBUG: ==========================================');
      print('🔍 DEBUG: COMPREHENSIVE PORTFOLIO INSPECTION');
      print('🔍 DEBUG: User ID: $userId');
      print('🔍 DEBUG: ==========================================');
      
      // Check if user exists in users table
      try {
        final userCheck = await _supabase
            .from('users')
            .select('id, email, cash_balance, created_at')
            .eq('id', userId)
            .maybeSingle();
        
        if (userCheck != null) {
          print('✅ DEBUG: User found in users table:');
          print('   📧 Email: ${userCheck['email']}');
          print('   💰 Cash: \$${userCheck['cash_balance']}');
          print('   📅 Created: ${userCheck['created_at']}');
        } else {
          print('❌ DEBUG: User NOT found in users table with ID: $userId');
          return; // No point continuing if user doesn't exist
        }
      } catch (e) {
        print('❌ DEBUG: Error checking user table: $e');
      }
      
      // Get total count of portfolio entries for this user
      try {
        final portfolioCountResponse = await _supabase
            .from('portfolio')
            .select('*')
            .eq('user_id', userId);
        
        print('📊 DEBUG: Portfolio entries count: ${portfolioCountResponse.length}');
        
        if (portfolioCountResponse.isNotEmpty) {
          // We already have all the entries from the query above
          final allEntries = portfolioCountResponse;
          
          print('📦 DEBUG: All portfolio entries (${allEntries.length}):');
          for (int i = 0; i < allEntries.length; i++) {
            final entry = allEntries[i];
            print('   [$i] ${entry['symbol']}: ${entry['quantity']} shares @ \$${entry['avg_price']}');
            print('       ID: ${entry['id']}');
            print('       User ID: ${entry['user_id']}');
            print('       Created: ${entry['created_at']}');
            print('       Updated: ${entry['updated_at']}');
            print('       Raw JSON: $entry');
            print('');
          }
        } else {
          print('📦 DEBUG: No portfolio entries found - user truly has 0 holdings');
        }
      } catch (e) {
        print('❌ DEBUG: Error checking portfolio table: $e');
      }
      
      // Check recent transactions for this user
      try {
        final recentTransactions = await _supabase
            .from('transactions')
            .select('*')
            .eq('user_id', userId)
            .order('timestamp', ascending: false)
            .limit(10);
        
        if (recentTransactions.isNotEmpty) {
          print('📋 DEBUG: Recent transactions (${recentTransactions.length}):');
          for (int i = 0; i < recentTransactions.length; i++) {
            final tx = recentTransactions[i];
            print('   [$i] ${tx['type'].toString().toUpperCase()} ${tx['quantity']} ${tx['symbol']} @ \$${tx['price']}');
            print('       Timestamp: ${tx['timestamp']}');
            print('       Total Value: \$${(tx['quantity'] * tx['price']).toStringAsFixed(2)}');
          }
        } else {
          print('📋 DEBUG: No transactions found for this user');
        }
      } catch (e) {
        print('❌ DEBUG: Error checking transactions table: $e');
      }
      
      // Try a direct raw query to see what's in the portfolio table
      try {
        print('🔍 DEBUG: Raw portfolio table query...');
        final rawQuery = await _supabase
            .rpc('get_user_portfolio_debug', params: {'target_user_id': userId});
        print('📊 DEBUG: Raw query result: $rawQuery');
      } catch (e) {
        print('⚠️ DEBUG: Raw query function not available (expected): $e');
      }
      
      print('🔍 DEBUG: ==========================================');
      print('🔍 DEBUG: INSPECTION COMPLETE');
      print('🔍 DEBUG: ==========================================');
      
    } catch (e) {
      print('❌ DEBUG: Critical error in debug inspection: $e');
      print('❌ DEBUG: Error type: ${e.runtimeType}');
    }
  }

  /// Clear all caches after database updates
  Future<void> _clearAllCaches() async {
    try {
      // Clear portfolio cache
      await PortfolioCacheService.clearCache();
      
      // Clear other relevant caches
      await StorageService.clearCache();
      
      print('🗑️ PortfolioService: All caches cleared successfully');
    } catch (e) {
      print('❌ PortfolioService: Error clearing caches: $e');
    }
  }
}