import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/market_asset_model.dart';
import '../services/google_stock_search_service.dart';
import '../services/finnhub_limiter_service.dart';
import '../services/optimized_cache_service.dart';

class MarketDataProvider with ChangeNotifier {
  List<MarketAssetModel> _filteredAssets = [];
  List<MarketAssetModel> _nasdaq100Movers = [];
  List<MarketAssetModel> _sp500Movers = [];
  List<MarketAssetModel> _dowJonesMovers = [];
  String _searchQuery = '';
  bool _isLoading = false;
  String? _error;
  Timer? _searchTimer;
  bool _hasSearchBeenPerformed = false;
  
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
  bool get hasSearchBeenPerformed => _hasSearchBeenPerformed;
  
  // Cache for individual asset lookups
  final Map<String, MarketAssetModel> _assetCache = {};
  
  // For backward compatibility - return cached assets plus market movers
  List<MarketAssetModel> get allAssets {
    final Set<MarketAssetModel> allAssets = {};
    allAssets.addAll(_nasdaq100Movers);
    allAssets.addAll(_sp500Movers);
    allAssets.addAll(_dowJonesMovers);
    allAssets.addAll(_assetCache.values);
    return allAssets.toList();
  }
  
  Future<void> initialize() async {
    _setLoading(false); // Don't show loading on startup
    _clearError();
    
    try {
      print('📊 MarketDataProvider: Initializing with market movers...');
      
      // Load market movers on startup (this is useful info for users)
      await _loadMarketMovers();
      
      // Clear search-specific data
      _filteredAssets = [];
      
      print('✅ MarketDataProvider: Ready with market movers loaded');
    } catch (e) {
      print('❌ MarketDataProvider: Initialization failed: $e');
      _setError('Failed to initialize market data: $e');
    } finally {
      notifyListeners();
    }
  }
  
  Future<void> _loadMarketMovers() async {
    try {
      print('🔄 Loading market movers using Google Finance scraping...');
      
      // Use only Google scraping for market movers to save API calls
      // Load top 3 movers from each index using Google Finance
      _nasdaq100Movers = await _loadMoversFromGoogle(_nasdaq100Symbols.take(6).toList(), 'NASDAQ');
      _sp500Movers = await _loadMoversFromGoogle(_sp500Symbols.take(6).toList(), 'S&P 500');
      _dowJonesMovers = await _loadMoversFromGoogle(_dowJonesSymbols.take(6).toList(), 'DOW');
      
      print('✅ Market movers loaded via Google scraping: NASDAQ(${_nasdaq100Movers.length}), S&P500(${_sp500Movers.length}), DOW(${_dowJonesMovers.length})');
      notifyListeners();
    } catch (e) {
      print('❌ Failed to load market movers: $e');
      // Set empty lists if loading fails
      _nasdaq100Movers = [];
      _sp500Movers = [];
      _dowJonesMovers = [];
      notifyListeners();
    }
  }
  
  /// Load market movers using Finnhub API (primary) with Google Finance fallback
  Future<List<MarketAssetModel>> _loadMoversFromGoogle(List<String> symbols, String indexName) async {
    final movers = <MarketAssetModel>[];
    
    for (final symbol in symbols) {
      try {
        // Primary: Always use Finnhub API (UNLIMITED) for most accurate data
        print('🎯 PRIMARY: Using Finnhub API for $symbol in $indexName (UNLIMITED)');
        final finnhubAsset = await FinnhubLimiterService.getStockQuote(symbol);
        if (finnhubAsset != null) {
          movers.add(finnhubAsset);
          print('✅ FINNHUB: [$indexName] $symbol = \$${finnhubAsset.price.toStringAsFixed(2)} (${finnhubAsset.changePercent >= 0 ? '+' : ''}${finnhubAsset.changePercent.toStringAsFixed(2)}%)');
          continue;
        } else {
          print('⚠️ Finnhub returned null for $symbol (rate limited or invalid), trying fallback');
        }
        
        // Fallback: Use Google Finance scraping (less accurate but available)
        final results = await GoogleStockSearchService.searchStocks(symbol);
        if (results.isNotEmpty) {
          movers.add(results.first);
          print('✅ FALLBACK: [$indexName] $symbol loaded via Google scraping');
        } else {
          print('❌ [$indexName] No data found for $symbol via any method');
        }
      } catch (e) {
        print('❌ [$indexName] Failed to load $symbol: $e');
      }
    }
    
    // Sort by absolute change percent and take top 3
    movers.sort((a, b) => b.changePercent.abs().compareTo(a.changePercent.abs()));
    return movers.take(3).toList();
  }
  
  Future<void> refreshMarketData() async {
    print('📊 Manual refresh requested - no auto-loading enabled');
    print('📊 Use search function to load specific stocks');
    // No automatic data loading - user must search for specific stocks
  }
  
  Future<void> setSearchQuery(String query) async {
    if (_searchQuery == query) return;
    
    _searchQuery = query;
    
    // Cancel previous search timer
    _searchTimer?.cancel();
    
    if (query.isEmpty) {
      _filteredAssets = [];
      _hasSearchBeenPerformed = false;
      _clearError();
      notifyListeners();
      return;
    }
    
    notifyListeners();
    
    // Don't auto-search, wait for user to hit enter
    // Search will be triggered by performSearch() method
  }
  
  /// Perform search when user hits enter
  Future<void> performSearch() async {
    if (_searchQuery.isEmpty) return;
    _hasSearchBeenPerformed = true;
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
  
  /// Fetch current price for a specific symbol with optimized caching
  Future<MarketAssetModel?> fetchSymbolPrice(String symbol) async {
    try {
      print('📊 Fetching current price for $symbol...');
      
      // Check optimized cache first (2 minute TTL for market data)
      final cachedAsset = await OptimizedCacheService.getMarketAsset(symbol);
      if (cachedAsset != null) {
        _assetCache[symbol.toUpperCase()] = cachedAsset;
        print('📊 Using optimized cache for $symbol: \$${cachedAsset.price}');
        return cachedAsset;
      }
      
      // Fetch fresh data with rate limiting protection
      final searchResults = await GoogleStockSearchService.searchStocks(symbol);
      if (searchResults.isNotEmpty) {
        final asset = searchResults.first;
        
        // Cache in both memory and persistent cache
        _assetCache[symbol.toUpperCase()] = asset;
        await OptimizedCacheService.setMarketAsset(asset);
        
        notifyListeners(); // Update UI with new data
        print('📊 Fetched and cached fresh price for $symbol: \$${asset.price}');
        return asset;
      }
      
      return null;
    } catch (e) {
      print('❌ Failed to fetch price for $symbol: $e');
      return null;
    }
  }
  
  /// Pre-fetch prices for a list of symbols (optimized batch processing)
  Future<void> preloadSymbolPrices(List<String> symbols) async {
    print('📊 Pre-loading prices for ${symbols.length} holdings...');
    
    // Check cache first for all symbols
    final cacheKeys = symbols.map((s) => s.toUpperCase()).toList();
    final cachedAssets = <String, MarketAssetModel>{};
    
    for (final symbol in cacheKeys) {
      final cached = await OptimizedCacheService.getMarketAsset(symbol);
      if (cached != null) {
        cachedAssets[symbol] = cached;
        _assetCache[symbol] = cached;
      }
    }
    
    print('📊 Found ${cachedAssets.length}/${symbols.length} symbols in cache');
    
    // Only fetch symbols not in cache
    final symbolsToFetch = symbols.where((s) => 
      !cachedAssets.containsKey(s.toUpperCase())
    ).toList();
    
    if (symbolsToFetch.isEmpty) {
      print('✅ All symbols loaded from cache');
      notifyListeners();
      return;
    }
    
    // Batch fetch missing symbols with controlled concurrency
    print('📊 Fetching ${symbolsToFetch.length} symbols from API...');
    
    const batchSize = 3; // Process 3 symbols at a time to avoid API limits
    final batches = <List<String>>[];
    
    for (int i = 0; i < symbolsToFetch.length; i += batchSize) {
      final end = (i + batchSize < symbolsToFetch.length) ? i + batchSize : symbolsToFetch.length;
      batches.add(symbolsToFetch.sublist(i, end));
    }
    
    for (final batch in batches) {
      final futures = batch.map((symbol) => fetchSymbolPrice(symbol));
      await Future.wait(futures);
      
      // Small delay between batches
      if (batch != batches.last) {
        await Future.delayed(const Duration(milliseconds: 500));
      }
    }
    
    print('✅ Pre-loading complete for portfolio holdings');
    notifyListeners();
  }
  
  @override
  void dispose() {
    _searchTimer?.cancel();
    super.dispose();
  }
}