import 'dart:convert';
import '../models/market_asset_model.dart';
import 'storage_service.dart';

class WatchlistService {
  static const String _watchlistKey = 'user_watchlist';
  static const List<String> _defaultWatchlist = ['AAPL', 'GOOGL', 'MSFT', 'TSLA'];
  
  /// Get user's watchlist symbols
  static List<String> getWatchlistSymbols() {
    try {
      final watchlistData = StorageService.getString(_watchlistKey);
      if (watchlistData != null) {
        final List<dynamic> symbols = json.decode(watchlistData);
        return symbols.cast<String>();
      }
    } catch (e) {
      print('Error loading watchlist: $e');
    }
    
    // Return default watchlist if no saved data
    return _defaultWatchlist;
  }
  
  /// Save watchlist symbols
  static Future<void> saveWatchlistSymbols(List<String> symbols) async {
    try {
      final watchlistJson = json.encode(symbols);
      await StorageService.setString(_watchlistKey, watchlistJson);
      print('🔖 Watchlist saved: ${symbols.length} symbols');
    } catch (e) {
      print('Error saving watchlist: $e');
    }
  }
  
  /// Add symbol to watchlist
  static Future<void> addToWatchlist(String symbol) async {
    final currentSymbols = getWatchlistSymbols();
    if (!currentSymbols.contains(symbol.toUpperCase())) {
      currentSymbols.add(symbol.toUpperCase());
      await saveWatchlistSymbols(currentSymbols);
    }
  }
  
  /// Remove symbol from watchlist
  static Future<void> removeFromWatchlist(String symbol) async {
    final currentSymbols = getWatchlistSymbols();
    currentSymbols.remove(symbol.toUpperCase());
    await saveWatchlistSymbols(currentSymbols);
  }
  
  /// Check if symbol is in watchlist
  static bool isInWatchlist(String symbol) {
    final currentSymbols = getWatchlistSymbols();
    return currentSymbols.contains(symbol.toUpperCase());
  }
  
  /// Get default symbols for new users
  static List<String> getDefaultWatchlist() => _defaultWatchlist;
}