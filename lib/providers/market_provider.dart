import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/asset_model.dart';
import '../services/market_data_service.dart';
import '../services/storage_service.dart';

class MarketProvider with ChangeNotifier {
  final MarketDataService _marketDataService = MarketDataService();
  
  List<AssetModel> _assets = [];
  List<AssetModel> _filteredAssets = [];
  String _selectedType = 'all';
  String _searchQuery = '';
  bool _isLoading = false;
  String? _error;
  Timer? _priceUpdateTimer;

  List<AssetModel> get assets => _filteredAssets;
  String get selectedType => _selectedType;
  String get searchQuery => _searchQuery;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> initialize() async {
    _setLoading(true);
    
    try {
      // Load cached assets first
      final cachedAssets = StorageService.getCachedAssets();
      if (cachedAssets.isNotEmpty) {
        _assets = cachedAssets;
        _applyFilters();
      }
      
      // Then load fresh data
      await loadAssets();
      
      // Start periodic price updates
      _startPriceUpdates();
    } catch (e) {
      _setError('Failed to initialize market data: $e');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> loadAssets() async {
    try {
      _assets = await _marketDataService.getAllAssets();
      await StorageService.cacheAssets(_assets);
      _applyFilters();
      notifyListeners();
    } catch (e) {
      _setError('Failed to load assets: $e');
    }
  }

  Future<void> refreshAssets() async {
    _setLoading(true);
    _clearError();
    
    try {
      await _marketDataService.updateAllPrices();
      await loadAssets();
    } catch (e) {
      _setError('Failed to refresh assets: $e');
    } finally {
      _setLoading(false);
    }
  }

  void setAssetType(String type) {
    _selectedType = type;
    _applyFilters();
    notifyListeners();
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    _applyFilters();
    notifyListeners();
  }

  void _applyFilters() {
    List<AssetModel> filtered = _assets;
    
    // Filter by type
    if (_selectedType != 'all') {
      filtered = filtered.where((asset) => asset.type == _selectedType).toList();
    }
    
    // Filter by search query
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((asset) =>
          asset.symbol.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          asset.name.toLowerCase().contains(_searchQuery.toLowerCase())
      ).toList();
    }
    
    _filteredAssets = filtered;
  }

  Future<AssetModel?> getAssetBySymbol(String symbol) async {
    try {
      return await _marketDataService.getAssetBySymbol(symbol);
    } catch (e) {
      return null;
    }
  }

  Future<List<AssetModel>> searchAssets(String query) async {
    try {
      return await _marketDataService.searchAssets(query);
    } catch (e) {
      return [];
    }
  }

  void _startPriceUpdates() {
    _priceUpdateTimer?.cancel();
    _priceUpdateTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      _updatePrices();
    });
  }

  Future<void> _updatePrices() async {
    try {
      await _marketDataService.updateAllPrices();
      await loadAssets();
    } catch (e) {
      // Silently handle errors for background updates
    }
  }

  List<AssetModel> getTopMovers() {
    final sorted = List<AssetModel>.from(_assets);
    sorted.sort((a, b) => b.changePercent24h.compareTo(a.changePercent24h));
    return sorted.take(10).toList();
  }

  List<AssetModel> getTopLosers() {
    final sorted = List<AssetModel>.from(_assets);
    sorted.sort((a, b) => a.changePercent24h.compareTo(b.changePercent24h));
    return sorted.take(10).toList();
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

  @override
  void dispose() {
    _priceUpdateTimer?.cancel();
    super.dispose();
  }
}