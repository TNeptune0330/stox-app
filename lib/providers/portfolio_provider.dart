import 'package:flutter/foundation.dart';
import '../models/portfolio_model.dart';
import '../models/transaction_model.dart';
import '../services/portfolio_service.dart';
import '../services/ad_service.dart';

class PortfolioProvider with ChangeNotifier {
  final PortfolioService _portfolioService = PortfolioService();
  
  List<PortfolioModel> _portfolio = [];
  List<TransactionModel> _transactions = [];
  Map<String, dynamic> _summary = {};
  bool _isLoading = false;
  String? _error;

  List<PortfolioModel> get portfolio => _portfolio;
  List<TransactionModel> get transactions => _transactions;
  Map<String, dynamic> get summary => _summary;
  bool get isLoading => _isLoading;
  String? get error => _error;

  double get cashBalance => (_summary['cash_balance'] as num?)?.toDouble() ?? 0.0;
  double get holdingsValue => (_summary['holdings_value'] as num?)?.toDouble() ?? 0.0;
  double get netWorth => (_summary['net_worth'] as num?)?.toDouble() ?? 0.0;
  double get totalPnL => (_summary['total_pnl'] as num?)?.toDouble() ?? 0.0;
  double get totalPnLPercentage => (_summary['total_pnl_percentage'] as num?)?.toDouble() ?? 0.0;

  Future<void> loadPortfolio(String userId) async {
    _setLoading(true);
    _clearError();
    
    try {
      final results = await Future.wait([
        _portfolioService.getUserPortfolio(userId),
        _portfolioService.getPortfolioSummary(userId),
      ]);

      _portfolio = results[0] as List<PortfolioModel>;
      _summary = results[1] as Map<String, dynamic>;
      
      notifyListeners();
    } catch (e) {
      _setError('Failed to load portfolio: $e');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> loadTransactions(String userId) async {
    try {
      _transactions = await _portfolioService.getUserTransactions(userId);
      notifyListeners();
    } catch (e) {
      _setError('Failed to load transactions: $e');
    }
  }

  Future<bool> executeTrade({
    required String userId,
    required String symbol,
    required String type,
    required int quantity,
    required double price,
  }) async {
    _setLoading(true);
    _clearError();
    
    try {
      final totalCost = quantity * price;
      
      if (type == 'buy') {
        final canAfford = await _portfolioService.canAffordTrade(userId, totalCost);
        if (!canAfford) {
          _setError('Insufficient funds');
          return false;
        }
      } else if (type == 'sell') {
        final sharesOwned = await _portfolioService.getSharesOwned(userId, symbol);
        if (sharesOwned < quantity) {
          _setError('Insufficient shares');
          return false;
        }
      }

      final success = await _portfolioService.executeTrade(
        userId: userId,
        symbol: symbol,
        type: type,
        quantity: quantity,
        price: price,
      );

      if (success) {
        // Trigger ad after trade
        AdService.instance.onTradeCompleted();
        
        // Reload portfolio data
        await loadPortfolio(userId);
        await loadTransactions(userId);
        
        return true;
      }
      
      return false;
    } catch (e) {
      _setError('Failed to execute trade: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<int> getSharesOwned(String userId, String symbol) async {
    try {
      return await _portfolioService.getSharesOwned(userId, symbol);
    } catch (e) {
      return 0;
    }
  }

  PortfolioModel? getHolding(String symbol) {
    try {
      return _portfolio.firstWhere((holding) => holding.symbol == symbol);
    } catch (e) {
      return null;
    }
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String error) {
    _error = error;
    notifyListeners();
  }

  void _clearError() {
    _error = null;
  }
}