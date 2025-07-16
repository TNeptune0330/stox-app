import 'package:flutter/foundation.dart';
import '../models/market_asset_model.dart';
import '../services/enhanced_market_data_service.dart';

class MarketDataProvider with ChangeNotifier {
  List<MarketAssetModel> _allAssets = [];
  List<MarketAssetModel> _filteredAssets = [];
  String _currentFilter = 'all';
  String _searchQuery = '';
  bool _isLoading = false;
  String? _error;
  Map<String, dynamic> _marketStats = {};
  
  // Getters
  List<MarketAssetModel> get allAssets => _allAssets;
  List<MarketAssetModel> get filteredAssets => _filteredAssets;
  String get currentFilter => _currentFilter;
  String get searchQuery => _searchQuery;
  bool get isLoading => _isLoading;
  String? get error => _error;
  Map<String, dynamic> get marketStats => _marketStats;
  
  // Asset type getters
  List<MarketAssetModel> get stocks => _allAssets.where((asset) => asset.type == 'stock').toList();
  List<MarketAssetModel> get cryptos => _allAssets.where((asset) => asset.type == 'crypto').toList();
  List<MarketAssetModel> get etfs => _allAssets.where((asset) => asset.type == 'etf').toList();
  
  // Market performance getters
  List<MarketAssetModel> get topGainers => _allAssets
      .where((asset) => asset.changePercent > 0)
      .toList()
      ..sort((a, b) => b.changePercent.compareTo(a.changePercent));
  
  List<MarketAssetModel> get topLosers => _allAssets
      .where((asset) => asset.changePercent < 0)
      .toList()
      ..sort((a, b) => a.changePercent.compareTo(b.changePercent));
  
  Future<void> initialize() async {
    _setLoading(true);
    _clearError();
    
    try {
      print('📊 MarketDataProvider: Initializing...');
      
      // Load initial market data
      await refreshMarketData();
      
      print('✅ MarketDataProvider: Initialized successfully');
    } catch (e) {
      print('❌ MarketDataProvider: Initialization failed: $e');
      _setError('Failed to initialize market data: $e');
    } finally {
      _setLoading(false);
    }
  }
  
  Future<void> refreshMarketData() async {
    try {
      print('🔄 MarketDataProvider: Refreshing market data...');
      
      // Get all assets
      _allAssets = await EnhancedMarketDataService.getAllAssets();
      
      // Get market statistics
      _marketStats = await EnhancedMarketDataService.getMarketStats();
      
      // Apply current filter
      _applyFilter();
      
      print('✅ MarketDataProvider: Data refreshed - ${_allAssets.length} assets loaded');
      notifyListeners();
    } catch (e) {
      print('❌ MarketDataProvider: Refresh failed: $e');
      _setError('Failed to refresh market data: $e');
    }
  }
  
  void setFilter(String filter) {
    if (_currentFilter != filter) {
      _currentFilter = filter;
      _applyFilter();
      print('🔍 MarketDataProvider: Filter changed to $filter');
    }
  }
  
  void setSearchQuery(String query) {
    if (_searchQuery != query) {
      _searchQuery = query;
      _applyFilter();
      print('🔍 MarketDataProvider: Search query changed to "$query"');
    }
  }
  
  void _applyFilter() {
    List<MarketAssetModel> assets = _allAssets;
    
    // Apply type filter
    if (_currentFilter != 'all') {
      assets = assets.where((asset) => asset.type == _currentFilter).toList();
    }
    
    // Apply search filter
    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      assets = assets.where((asset) =>
          asset.symbol.toLowerCase().contains(query) ||
          asset.name.toLowerCase().contains(query)
      ).toList();
    }
    
    _filteredAssets = assets;
    notifyListeners();
  }
  
  MarketAssetModel? getAsset(String symbol) {
    try {
      return _allAssets.firstWhere((asset) => asset.symbol == symbol);
    } catch (e) {
      return null;
    }
  }
  
  Future<MarketAssetModel?> getAssetAsync(String symbol) async {
    try {
      return await EnhancedMarketDataService.getAsset(symbol);
    } catch (e) {
      print('❌ MarketDataProvider: Error getting asset $symbol: $e');
      return null;
    }
  }
  
  double getAssetPrice(String symbol) {
    final asset = getAsset(symbol);
    return asset?.price ?? 0.0;
  }
  
  double getAssetChange(String symbol) {
    final asset = getAsset(symbol);
    return asset?.change ?? 0.0;
  }
  
  double getAssetChangePercent(String symbol) {
    final asset = getAsset(symbol);
    return asset?.changePercent ?? 0.0;
  }
  
  bool isAssetGainer(String symbol) {
    final asset = getAsset(symbol);
    return (asset?.changePercent ?? 0.0) > 0;
  }
  
  bool isAssetLoser(String symbol) {
    final asset = getAsset(symbol);
    return (asset?.changePercent ?? 0.0) < 0;
  }
  
  List<MarketAssetModel> getSimilarAssets(String symbol, {int limit = 5}) {
    final asset = getAsset(symbol);
    if (asset == null) return [];
    
    return _allAssets
        .where((a) => a.symbol != symbol && a.type == asset.type)
        .take(limit)
        .toList();
  }
  
  List<MarketAssetModel> getWatchlist() {
    // For now, return top performers
    // In a real app, this would be user-specific
    return [...topGainers.take(5), ...topLosers.take(5)];
  }
  
  Map<String, dynamic> getAssetStats(String symbol) {
    final asset = getAsset(symbol);
    if (asset == null) return {};
    
    return {
      'symbol': asset.symbol,
      'name': asset.name,
      'type': asset.type,
      'price': asset.price,
      'change': asset.change,
      'change_percent': asset.changePercent,
      'last_updated': asset.lastUpdated,
    };
  }
  
  Map<String, dynamic> getMarketOverview() {
    if (_allAssets.isEmpty) return {};
    
    final gainers = _allAssets.where((asset) => asset.changePercent > 0).length;
    final losers = _allAssets.where((asset) => asset.changePercent < 0).length;
    final unchanged = _allAssets.length - gainers - losers;
    
    final avgChange = _allAssets.isNotEmpty
        ? _allAssets.map((asset) => asset.changePercent).reduce((a, b) => a + b) / _allAssets.length
        : 0.0;
    
    return {
      'total_assets': _allAssets.length,
      'gainers': gainers,
      'losers': losers,
      'unchanged': unchanged,
      'avg_change': avgChange,
      'market_sentiment': avgChange > 0 ? 'bullish' : avgChange < 0 ? 'bearish' : 'neutral',
      'last_updated': _allAssets.isNotEmpty
          ? _allAssets.map((asset) => asset.lastUpdated).reduce((a, b) => a.isAfter(b) ? a : b)
          : null,
    };
  }
  
  List<MarketAssetModel> getAssetsByPerformance({
    required String performance, // 'gainers', 'losers', 'most_active'
    int limit = 10,
  }) {
    switch (performance) {
      case 'gainers':
        return topGainers.take(limit).toList();
      case 'losers':
        return topLosers.take(limit).toList();
      case 'most_active':
        // For now, return assets with highest absolute change
        return _allAssets
            .where((asset) => asset.change.abs() > 0)
            .toList()
            ..sort((a, b) => b.change.abs().compareTo(a.change.abs()))
            ..take(limit);
      default:
        return [];
    }
  }
  
  Future<void> updateAssetPrice(String symbol, double newPrice) async {
    final assetIndex = _allAssets.indexWhere((asset) => asset.symbol == symbol);
    if (assetIndex != -1) {
      final asset = _allAssets[assetIndex];
      final change = newPrice - asset.price;
      final changePercent = (change / asset.price) * 100;
      
      final updatedAsset = MarketAssetModel(
        symbol: asset.symbol,
        name: asset.name,
        price: newPrice,
        change: change,
        changePercent: changePercent,
        type: asset.type,
        lastUpdated: DateTime.now(),
      );
      
      _allAssets[assetIndex] = updatedAsset;
      _applyFilter();
      
      print('📈 MarketDataProvider: Updated $symbol price to \$${newPrice.toStringAsFixed(2)}');
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
  
  void clearData() {
    _allAssets.clear();
    _filteredAssets.clear();
    _marketStats.clear();
    _currentFilter = 'all';
    _searchQuery = '';
    _error = null;
    _isLoading = false;
    notifyListeners();
  }
}