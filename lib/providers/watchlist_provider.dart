import 'package:flutter/foundation.dart';
import '../models/market_asset_model.dart';
import '../services/watchlist_service.dart';
import '../services/enhanced_market_data_service.dart';

class WatchlistProvider with ChangeNotifier {
  List<String> _watchlistSymbols = [];
  List<MarketAssetModel> _watchlistAssets = [];
  bool _isLoading = false;
  String? _error;

  List<String> get watchlistSymbols => _watchlistSymbols;
  List<MarketAssetModel> get watchlistAssets => _watchlistAssets;
  bool get isLoading => _isLoading;
  String? get error => _error;

  /// Initialize watchlist
  Future<void> initialize() async {
    print('🔖 WatchlistProvider: Starting initialization...');
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      // Load watchlist symbols from Supabase (with local fallback)
      _watchlistSymbols = await WatchlistService.loadWatchlistFromSupabase();
      print('🔖 WatchlistProvider: Loaded ${_watchlistSymbols.length} symbols: ${_watchlistSymbols.join(", ")}');

      // Load market data for watchlist symbols
      if (_watchlistSymbols.isNotEmpty) {
        await _loadWatchlistData();
      } else {
        print('🔖 WatchlistProvider: No symbols in watchlist');
      }

      _isLoading = false;
      notifyListeners();
      print('🔖 WatchlistProvider: Initialization complete - ${_watchlistAssets.length} assets ready');
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      print('❌ WatchlistProvider error: $e');
    }
  }

  /// Load market data for watchlist symbols
  Future<void> _loadWatchlistData() async {
    _watchlistAssets.clear();

    print('🔖 Loading market data for ${_watchlistSymbols.length} watchlist symbols...');

    for (final symbol in _watchlistSymbols) {
      try {
        // Use findSymbol which will fetch from APIs if not cached locally
        final marketData = await EnhancedMarketDataService.findSymbol(symbol);
        if (marketData != null) {
          _watchlistAssets.add(marketData);
          print('🔖 Loaded ${symbol}: \$${marketData.price.toStringAsFixed(2)} (${marketData.changePercent >= 0 ? '+' : ''}${marketData.changePercent.toStringAsFixed(2)}%)');
        } else {
          print('⚠️ No market data found for $symbol, creating placeholder');
          // Create a fallback asset with basic info
          _watchlistAssets.add(MarketAssetModel(
            symbol: symbol,
            name: symbol,
            price: 0.0,
            change: 0.0,
            changePercent: 0.0,
            type: 'stock',
            lastUpdated: DateTime.now(),
          ));
        }
      } catch (e) {
        print('❌ Failed to load data for $symbol: $e');
        // Create a fallback asset with basic info
        _watchlistAssets.add(MarketAssetModel(
          symbol: symbol,
          name: symbol,
          price: 0.0,
          change: 0.0,
          changePercent: 0.0,
          type: 'stock',
          lastUpdated: DateTime.now(),
        ));
      }
    }

    print('🔖 Finished loading watchlist data: ${_watchlistAssets.length} assets loaded');
  }

  /// Add symbol to watchlist
  Future<void> addToWatchlist(String symbol) async {
    try {
      await WatchlistService.addToWatchlist(symbol);
      _watchlistSymbols = WatchlistService.getWatchlistSymbols();
      
      // Load market data for the new symbol using findSymbol to fetch from APIs if needed
      final marketData = await EnhancedMarketDataService.findSymbol(symbol);
      if (marketData != null) {
        _watchlistAssets.add(marketData);
        print('🔖 Market data loaded for new watchlist symbol: $symbol');
      } else {
        // Add placeholder if no market data found
        _watchlistAssets.add(MarketAssetModel(
          symbol: symbol.toUpperCase(),
          name: symbol.toUpperCase(),
          price: 0.0,
          change: 0.0,
          changePercent: 0.0,
          type: 'stock',
          lastUpdated: DateTime.now(),
        ));
        print('⚠️ Added placeholder for $symbol (no market data found)');
      }
      
      notifyListeners();
      print('🔖 Added $symbol to watchlist');
    } catch (e) {
      print('❌ Failed to add $symbol to watchlist: $e');
    }
  }

  /// Remove symbol from watchlist
  Future<void> removeFromWatchlist(String symbol) async {
    try {
      await WatchlistService.removeFromWatchlist(symbol);
      _watchlistSymbols = WatchlistService.getWatchlistSymbols();
      _watchlistAssets.removeWhere((asset) => asset.symbol.toUpperCase() == symbol.toUpperCase());
      
      notifyListeners();
      print('🔖 Removed $symbol from watchlist');
    } catch (e) {
      print('❌ Failed to remove $symbol from watchlist: $e');
    }
  }

  /// Check if symbol is in watchlist
  bool isInWatchlist(String symbol) {
    return WatchlistService.isInWatchlist(symbol);
  }

  /// Refresh watchlist data
  Future<void> refresh() async {
    await _loadWatchlistData();
    notifyListeners();
  }
}