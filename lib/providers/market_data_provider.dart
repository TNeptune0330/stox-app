import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/market_asset_model.dart';
import '../services/enhanced_market_data_service.dart';
import '../services/google_stock_search_service.dart';

class MarketDataProvider with ChangeNotifier {
  List<MarketAssetModel> _filteredAssets = [];
  List<MarketAssetModel> _nasdaq100Movers = [];
  List<MarketAssetModel> _sp500Movers = [];
  List<MarketAssetModel> _dowJonesMovers = [];
  String _searchQuery = '';
  bool _isLoading = false;
  String? _error;
  Timer? _searchTimer;
  
  // NASDAQ 100 top symbols for market movers
  static const List<String> _nasdaq100Symbols = [
    'AAPL', 'MSFT', 'AMZN', 'NVDA', 'GOOGL', 'META', 'TSLA', 'AVGO', 'ORCL', 'COST',
    'NFLX', 'AMD', 'PEP', 'ADBE', 'CSCO', 'TXN', 'QCOM', 'TMUS', 'AMAT', 'INTU'
  ];
  
  // S&P 500 top symbols for market movers 
  static const List<String> _sp500Symbols = [
    'AAPL', 'MSFT', 'AMZN', 'NVDA', 'GOOGL', 'BRK.B', 'META', 'TSLA', 'UNH', 'JNJ',
    'XOM', 'JPM', 'V', 'PG', 'MA', 'CVX', 'HD', 'PFE', 'ABBV', 'KO'
  ];
  
  // DOW Jones symbols for market movers
  static const List<String> _dowJonesSymbols = [
    'UNH', 'GS', 'HD', 'MSFT', 'AMGN', 'CAT', 'CRM', 'V', 'AXP', 'BA',
    'HON', 'AAPL', 'IBM', 'JNJ', 'JPM', 'MCD', 'MMM', 'MRK', 'NKE', 'PG',
    'TRV', 'DIS', 'VZ', 'CVX', 'WBA', 'WMT', 'DOW', 'CSCO', 'KO', 'INTC'
  ];
  
  // Getters
  List<MarketAssetModel> get filteredAssets => _filteredAssets;
  List<MarketAssetModel> get nasdaq100Movers => _nasdaq100Movers;
  List<MarketAssetModel> get sp500Movers => _sp500Movers;
  List<MarketAssetModel> get dowJonesMovers => _dowJonesMovers;
  String get searchQuery => _searchQuery;
  bool get isLoading => _isLoading;
  String? get error => _error;
  
  // For backward compatibility
  List<MarketAssetModel> get allAssets => [];
  
  Future<void> initialize() async {
    _setLoading(true);
    _clearError();
    
    try {
      print('📊 MarketDataProvider: Initializing with market movers only...');
      
      // Load only market movers from major indices
      await _loadMarketMovers();
      
      print('✅ MarketDataProvider: Initialized successfully');
    } catch (e) {
      print('❌ MarketDataProvider: Initialization failed: $e');
      _setError('Failed to initialize market data: $e');
    } finally {
      _setLoading(false);
    }
  }
  
  Future<void> _loadMarketMovers() async {
    try {
      print('🔄 Loading market movers from major indices...');
      
      // Load NASDAQ 100 movers
      final nasdaq100Assets = <MarketAssetModel>[];
      for (final symbol in _nasdaq100Symbols.take(10)) { // Get more to find top movers
        try {
          final asset = await EnhancedMarketDataService.getAsset(symbol);
          if (asset != null) {
            nasdaq100Assets.add(asset);
          }
        } catch (e) {
          print('Error loading NASDAQ 100 symbol $symbol: $e');
        }
      }
      nasdaq100Assets.sort((a, b) => b.changePercent.abs().compareTo(a.changePercent.abs()));
      _nasdaq100Movers = nasdaq100Assets.take(3).toList();
      
      // Load S&P 500 movers
      final sp500Assets = <MarketAssetModel>[];
      for (final symbol in _sp500Symbols.take(10)) { // Get more to find top movers
        try {
          final asset = await EnhancedMarketDataService.getAsset(symbol);
          if (asset != null) {
            sp500Assets.add(asset);
          }
        } catch (e) {
          print('Error loading S&P 500 symbol $symbol: $e');
        }
      }
      sp500Assets.sort((a, b) => b.changePercent.abs().compareTo(a.changePercent.abs()));
      _sp500Movers = sp500Assets.take(3).toList();
      
      // Load DOW Jones movers
      final dowJonesAssets = <MarketAssetModel>[];
      for (final symbol in _dowJonesSymbols.take(10)) { // Get more to find top movers
        try {
          final asset = await EnhancedMarketDataService.getAsset(symbol);
          if (asset != null) {
            dowJonesAssets.add(asset);
          }
        } catch (e) {
          print('Error loading DOW Jones symbol $symbol: $e');
        }
      }
      dowJonesAssets.sort((a, b) => b.changePercent.abs().compareTo(a.changePercent.abs()));
      _dowJonesMovers = dowJonesAssets.take(3).toList();
      
      print('✅ Market movers loaded: NASDAQ(${_nasdaq100Movers.length}), S&P500(${_sp500Movers.length}), DOW(${_dowJonesMovers.length})');
      notifyListeners();
    } catch (e) {
      print('❌ Failed to load market movers: $e');
      throw e;
    }
  }
  
  Future<void> refreshMarketData() async {
    await _loadMarketMovers();
  }
  
  Future<void> setSearchQuery(String query) async {
    if (_searchQuery == query) return;
    
    _searchQuery = query;
    notifyListeners();
    
    // Cancel previous search timer
    _searchTimer?.cancel();
    
    if (query.isEmpty) {
      _filteredAssets = [];
      notifyListeners();
      return;
    }
    
    // Don't auto-search, wait for user to hit enter
    // Search will be triggered by performSearch() method
  }
  
  /// Perform search when user hits enter
  Future<void> performSearch() async {
    if (_searchQuery.isEmpty) return;
    await _performGoogleSearch(_searchQuery);
  }
  
  Future<void> _performGoogleSearch(String query) async {
    if (query.isEmpty) return;
    
    _setLoading(true);
    _clearError();
    
    try {
      print('🔍 Performing Google-powered search for: "$query"');
      
      // Use Google Stock Search Service
      final searchResults = await GoogleStockSearchService.searchStocks(query);
      
      _filteredAssets = searchResults;
      print('✅ Search completed: ${searchResults.length} results found');
      
    } catch (e) {
      print('❌ Search failed: $e');
      _setError('Search failed: $e');
      _filteredAssets = [];
    } finally {
      _setLoading(false);
      notifyListeners();
    }
  }
  
  // Remove old methods that are no longer needed
  void setFilter(String filter) {
    // No longer needed - we don't pre-load all assets
  }
  
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }
  
  void _setError(String? error) {
    _error = error;
    notifyListeners();
  }
  
  void _clearError() {
    _error = null;
  }
  
  @override
  void dispose() {
    _searchTimer?.cancel();
    super.dispose();
  }
}