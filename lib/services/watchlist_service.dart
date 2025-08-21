import 'dart:convert';
import 'storage_service.dart';

class WatchlistService {
  static const String _watchlistKey = 'user_watchlist';
  
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
    
    // Return empty watchlist if no saved data
    return <String>[];
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
    final currentSymbols = getWatchlistSymbols().toList(); // Ensure mutable list
    final upperSymbol = symbol.toUpperCase();
    if (!currentSymbols.contains(upperSymbol)) {
      currentSymbols.add(upperSymbol);
      await saveWatchlistSymbols(currentSymbols);
      print('🔖 Added $upperSymbol to watchlist');
    }
  }
  
  /// Remove symbol from watchlist
  static Future<void> removeFromWatchlist(String symbol) async {
    final currentSymbols = getWatchlistSymbols().toList(); // Ensure mutable list
    final upperSymbol = symbol.toUpperCase();
    if (currentSymbols.remove(upperSymbol)) {
      await saveWatchlistSymbols(currentSymbols);
      print('🔖 Removed $upperSymbol from watchlist');
    }
  }
  
  /// Check if symbol is in watchlist
  static bool isInWatchlist(String symbol) {
    final currentSymbols = getWatchlistSymbols();
    return currentSymbols.contains(symbol.toUpperCase());
  }
  
  /// Get default symbols for new users (now returns empty list)
  static List<String> getDefaultWatchlist() => <String>[];
}