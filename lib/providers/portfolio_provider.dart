import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../models/portfolio_model.dart';
import '../models/transaction_model.dart';
import '../services/portfolio_service.dart';
import '../services/portfolio_cache_service.dart';
import '../services/ad_service.dart';
import '../services/leaderboard_service.dart';
import '../services/sync_service.dart';
import '../services/connection_manager.dart';
import '../services/optimized_cache_service.dart';
import '../services/enhanced_market_data_service.dart';
import 'achievement_provider.dart';

class PortfolioProvider with ChangeNotifier {
  final PortfolioService _portfolioService = PortfolioService();
  final LeaderboardService _leaderboardService = LeaderboardService();
  
  List<PortfolioModel> _portfolio = [];
  List<TransactionModel> _transactions = [];
  Map<String, dynamic> _summary = {};
  Map<String, dynamic> _stats = {};
  bool _isLoading = false;
  String? _error;

  List<PortfolioModel> get portfolio => _portfolio;
  List<TransactionModel> get transactions => _transactions;
  Map<String, dynamic> get summary => _summary;
  Map<String, dynamic> get stats => _stats;
  bool get isLoading => _isLoading;
  String? get error => _error;

  double get cashBalance => (_summary['cash_balance'] as num?)?.toDouble() ?? 0.0;
  double get holdingsValue => (_summary['holdings_value'] as num?)?.toDouble() ?? 0.0;
  double get netWorth => (_summary['net_worth'] as num?)?.toDouble() ?? 0.0;
  double get totalPnL => (_summary['total_pnl'] as num?)?.toDouble() ?? 0.0;
  double get totalPnLPercentage => (_summary['total_pnl_percentage'] as num?)?.toDouble() ?? 0.0;

  // Portfolio statistics
  int get totalTrades => (_stats['total_trades'] as int?) ?? 0;
  double get winRate => (_stats['win_rate'] as num?)?.toDouble() ?? 0.0;
  String? get bestPerformer => _stats['best_performer'] as String?;
  String? get worstPerformer => _stats['worst_performer'] as String?;
  String? get mostTraded => _stats['most_traded'] as String?;

  Future<void> loadPortfolio(String userId) async {
    print('📊 PortfolioProvider: Loading portfolio for user: $userId');
    
    // Validate user ID
    if (userId.isEmpty) {
      print('❌ PortfolioProvider: Empty user ID provided');
      _setError('Invalid user ID');
      return;
    }
    
    // Try to load from cache first
    final cachedData = await PortfolioCacheService.getCachedPortfolioData();
    if (cachedData != null) {
      print('📊 PortfolioProvider: Using cached portfolio data');
      _portfolio = cachedData['portfolio'] as List<PortfolioModel>;
      _transactions = cachedData['transactions'] as List<TransactionModel>;
      _summary = cachedData['summary'] as Map<String, dynamic>;
      _stats = cachedData['stats'] as Map<String, dynamic>;
      
      print('📊 PortfolioProvider: Cached data loaded - ${_portfolio.length} holdings');
      if (_portfolio.isNotEmpty) {
        for (final holding in _portfolio) {
          print('   📦 ${holding.symbol}: ${holding.quantity} shares @ \$${holding.avgPrice}');
        }
      }
      
      notifyListeners();
      return; // Use cached data and exit
    }
    
    _setLoading(true);
    _clearError();
    
    try {
      print('📊 PortfolioProvider: Loading fresh portfolio data from database...');
      final results = await Future.wait([
        _portfolioService.getUserPortfolio(userId),
        _portfolioService.getUserTransactions(userId, limit: 100),
        _portfolioService.getPortfolioSummary(userId),
        _portfolioService.getPortfolioStats(userId),
      ]);

      _portfolio = results[0] as List<PortfolioModel>;
      _transactions = results[1] as List<TransactionModel>;
      _summary = results[2] as Map<String, dynamic>;
      _stats = results[3] as Map<String, dynamic>;
      
      print('📊 PortfolioProvider: Fresh data loaded:');
      print('   📦 Holdings: ${_portfolio.length}');
      print('   📋 Transactions: ${_transactions.length}');
      print('   💰 Cash Balance: \$${cashBalance.toStringAsFixed(2)}');
      print('   📈 Net Worth: \$${netWorth.toStringAsFixed(2)}');
      
      if (_portfolio.isNotEmpty) {
        print('📊 PortfolioProvider: Holdings details:');
        for (final holding in _portfolio) {
          print('   📦 ${holding.symbol}: ${holding.quantity} shares @ \$${holding.avgPrice}');
        }
        
        // Pre-load market data for all portfolio symbols using MarketDataProvider singleton
        final symbols = _portfolio.map((h) => h.symbol).toList();
        print('📊 Pre-loading live market data for ${symbols.length} portfolio symbols...');
        
        // Force market data to be loaded for portfolio symbols
        for (final symbol in symbols) {
          try {
            print('🔄 Pre-loading market data for $symbol...');
            await EnhancedMarketDataService.getAsset(symbol);
          } catch (e) {
            print('❌ Failed to pre-load $symbol: $e');
          }
        }
        print('✅ Market data pre-loading attempted for all symbols');
      } else {
        print('⚠️ PortfolioProvider: No holdings found in database for user $userId');
      }
      
      // Cache the fresh data
      await PortfolioCacheService.cachePortfolioData(
        portfolio: _portfolio,
        transactions: _transactions,
        summary: _summary,
        stats: _stats,
      );
      
      print('✅ PortfolioProvider: Portfolio loaded and cached successfully');
      
      notifyListeners();
    } catch (e) {
      print('❌ PortfolioProvider: Failed to load portfolio: $e');
      print('❌ PortfolioProvider: Error type: ${e.runtimeType}');
      print('❌ PortfolioProvider: Stack trace: ${StackTrace.current}');
      
      // Provide default state for demo purposes
      _portfolio = [];
      _transactions = [];
      _summary = {
        'cash_balance': 10000.0,
        'holdings_value': 0.0,
        'net_worth': 10000.0,
        'total_pnl': 0.0,
        'total_pnl_percentage': 0.0,
      };
      _stats = {
        'total_trades': 0,
        'win_rate': 0.0,
        'best_performer': null,
        'worst_performer': null,
        'most_traded': null,
      };
      
      print('📊 PortfolioProvider: Using default state with \$10,000 cash balance');
      print('📊 PortfolioProvider: Default state - Cash: \$${cashBalance.toStringAsFixed(2)}, Net Worth: \$${netWorth.toStringAsFixed(2)}');
      notifyListeners();
    } finally {
      _setLoading(false);
    }
  }

  /// Force refresh portfolio data (invalidate cache and reload)
  Future<void> forceRefreshWithConnection(String userId) async {
    print('📊 Force refreshing portfolio data...');
    
    // Invalidate cache to force fresh data load
    await PortfolioCacheService.invalidateCache();
    
    // Load fresh data
    await loadPortfolio(userId);
  }

  Future<void> loadTransactions(String userId) async {
    print('📋 Loading transactions for user: $userId');
    
    try {
      _transactions = await _portfolioService.getUserTransactions(userId);
      print('✅ Transactions loaded: ${_transactions.length} transactions');
      notifyListeners();
    } catch (e) {
      print('❌ Failed to load transactions: $e');
      _setError('Failed to load transactions: $e');
    }
  }

  Future<bool> executeTrade({
    required String userId,
    required String symbol,
    required String type,
    required int quantity,
    required double price,
    AchievementProvider? achievementProvider,
  }) async {
    print('💱 Executing trade: $type $quantity $symbol at \$${price.toStringAsFixed(2)}');
    _setLoading(true);
    _clearError();
    
    try {
      final totalCost = quantity * price;
      
      // Pre-validate trade
      if (type == 'buy') {
        final canAfford = await _portfolioService.canAffordTrade(userId, totalCost);
        if (!canAfford) {
          _setError('Insufficient funds. Need \$${totalCost.toStringAsFixed(2)} but only have \$${cashBalance.toStringAsFixed(2)}');
          return false;
        }
      } else if (type == 'sell') {
        final sharesOwned = await _portfolioService.getSharesOwned(userId, symbol);
        if (sharesOwned < quantity) {
          _setError('Insufficient shares. Need $quantity but only have $sharesOwned');
          return false;
        }
      }

      // Execute the trade
      final success = await _portfolioService.executeTrade(
        userId: userId,
        symbol: symbol,
        type: type,
        quantity: quantity,
        price: price,
      );

      if (success) {
        print('✅ Trade executed successfully');
        
        // Record trade for achievements
        if (achievementProvider != null) {
          await achievementProvider.recordTrade();
          
          // Calculate profit/loss for this trade
          final currentValue = quantity * price;
          final previousHolding = getHoldingBySymbol(symbol);
          if (previousHolding != null && type == 'sell') {
            final profit = currentValue - (previousHolding.avgPrice * quantity);
            if (profit > 0) {
              await achievementProvider.recordProfit(profit);
            } else {
              await achievementProvider.recordLargeLoss(profit.abs());
            }
          }
          
          // Update net worth achievement
          await achievementProvider.recordNetWorth(netWorth);
          await achievementProvider.recordMultiMillionaire(netWorth);
          
          // Record sector-specific achievements
          if (type == 'buy') {
            await achievementProvider.recordTechStockPurchase(symbol);
            await achievementProvider.recordEnergyStockPurchase(symbol);
            await achievementProvider.recordHealthcareStockPurchase(symbol);
            await achievementProvider.recordFinancialStockPurchase(symbol);
            await achievementProvider.recordMemeStockPurchase(symbol);
            await achievementProvider.recordSP500StockPurchase(symbol);
            await achievementProvider.recordETFPurchase(symbol);
            await achievementProvider.recordDividendStockPurchase(symbol);
            await achievementProvider.recordSmallCapPurchase(symbol);
            await achievementProvider.recordInternationalPurchase(symbol);
            await achievementProvider.recordConsumerStockPurchase(symbol);
          }
          
          // Record high-value trade
          await achievementProvider.recordHighValueTrade(totalCost);
          
          // Record low-price high-volume trades
          await achievementProvider.recordLowPriceHighVolume(price, quantity);
          
          // Record time-based achievements
          await achievementProvider.recordTimeBasedTrade(DateTime.now());
          
          // Record portfolio concentration and cash percentage
          final portfolioValue = netWorth - cashBalance;
          if (portfolioValue > 0) {
            final concentration = (currentValue / portfolioValue) * 100;
            await achievementProvider.recordPortfolioConcentration(concentration);
          }
          
          final cashPercentage = (cashBalance / netWorth) * 100;
          await achievementProvider.recordCashPercentage(cashPercentage);
        }
        
        // Trigger ad after trade
        AdService.instance.onTradeCompleted();
        
        // Update leaderboard (don't block trade if this fails)
        try {
          await _leaderboardService.updateUserRank(userId);
        } catch (e) {
          print('⚠️ Failed to update leaderboard (non-blocking): $e');
        }
        
        // Invalidate cache and reload portfolio data to reflect changes
        try {
          await PortfolioCacheService.invalidateCache();
          await loadPortfolio(userId);
        } catch (e) {
          print('⚠️ Failed to reload portfolio data (non-blocking): $e');
        }
        
        return true;
      } else {
        _setError('Trade execution failed');
        return false;
      }
    } catch (e) {
      print('❌ Trade execution error: $e');
      _setError('Trade execution failed: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> canAffordTrade(String userId, double totalCost) async {
    try {
      return await _portfolioService.canAffordTrade(userId, totalCost);
    } catch (e) {
      print('❌ Error checking affordability: $e');
      return false;
    }
  }

  Future<int> getSharesOwned(String userId, String symbol) async {
    try {
      return await _portfolioService.getSharesOwned(userId, symbol);
    } catch (e) {
      print('❌ Error getting shares owned: $e');
      return 0;
    }
  }

  Future<double> calculatePortfolioValue(String userId) async {
    try {
      return await _portfolioService.calculatePortfolioValue(userId);
    } catch (e) {
      print('❌ Error calculating portfolio value: $e');
      return 0.0;
    }
  }

  Future<void> refreshPortfolio(String userId) async {
    print('🔄 Refreshing portfolio data...');
    await loadPortfolio(userId);
    await loadTransactions(userId);
  }

  Future<bool> syncPendingData(String userId) async {
    print('🔄 Syncing pending data...');
    _setLoading(true);
    _clearError();
    
    try {
      final syncSuccess = await SyncService.performFullSync(userId);
      
      if (syncSuccess) {
        // Reload portfolio data after successful sync
        await loadPortfolio(userId);
        await loadTransactions(userId);
        print('✅ Portfolio sync completed successfully');
        return true;
      } else {
        _setError('Failed to sync some data');
        return false;
      }
    } catch (e) {
      print('❌ Sync error: $e');
      _setError('Sync failed: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<Map<String, dynamic>> getSyncStatus(String userId) async {
    try {
      return await SyncService.getSyncStatus(userId);
    } catch (e) {
      print('❌ Error getting sync status: $e');
      return {
        'pending_trades': 0,
        'has_connection': false,
        'last_sync': null,
      };
    }
  }

  PortfolioModel? getHoldingBySymbol(String symbol) {
    try {
      return _portfolio.firstWhere((holding) => holding.symbol == symbol);
    } catch (e) {
      return null;
    }
  }

  double getHoldingValue(String symbol) {
    final holding = getHoldingBySymbol(symbol);
    if (holding == null) return 0.0;
    return holding.quantity * holding.avgPrice;
  }

  double getHoldingPnL(String symbol, double currentPrice) {
    final holding = getHoldingBySymbol(symbol);
    if (holding == null) return 0.0;
    return holding.quantity * (currentPrice - holding.avgPrice);
  }

  List<TransactionModel> getTransactionsForSymbol(String symbol) {
    return _transactions.where((tx) => tx.symbol == symbol).toList();
  }

  List<TransactionModel> getRecentTransactions({int limit = 10}) {
    final sorted = List<TransactionModel>.from(_transactions);
    sorted.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return sorted.take(limit).toList();
  }

  Map<String, int> getTopHoldingsByValue() {
    final holdings = Map<String, int>.fromIterable(
      _portfolio,
      key: (holding) => holding.symbol,
      value: (holding) => holding.quantity,
    );
    
    // Sort by value (would need current prices for accurate sorting)
    return holdings;
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String error) {
    _error = error;
    _isLoading = false;
    notifyListeners();
  }

  void _clearError() {
    _error = null;
  }

  void clearData() {
    _portfolio.clear();
    _transactions.clear();
    _summary.clear();
    _stats.clear();
    _error = null;
    _isLoading = false;
    notifyListeners();
  }

  bool get hasHoldings => _portfolio.isNotEmpty;
  bool get hasTransactions => _transactions.isNotEmpty;
  bool get isPortfolioEmpty => _portfolio.isEmpty;
  
  String get performanceLabel {
    if (totalPnL > 0) return 'Profit';
    if (totalPnL < 0) return 'Loss';
    return 'Break Even';
  }
  
  Color get performanceColor {
    if (totalPnL > 0) return const Color(0xFF4CAF50);
    if (totalPnL < 0) return const Color(0xFFf44336);
    return const Color(0xFF607D8B);
  }
}