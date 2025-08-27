import 'dart:convert';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'storage_service.dart';

class WatchlistService {
  static const String _watchlistKey = 'user_watchlist';
  static final SupabaseClient _supabase = Supabase.instance.client;
  
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
    try {
      final currentSymbols = getWatchlistSymbols().toList(); // Ensure mutable list
      final upperSymbol = symbol.toUpperCase();
      
      if (!currentSymbols.contains(upperSymbol)) {
        // Save to local storage first
        currentSymbols.add(upperSymbol);
        await saveWatchlistSymbols(currentSymbols);
        
        // Also save to Supabase if user is authenticated
        final user = _supabase.auth.currentUser;
        if (user != null) {
          await _supabase
              .from('watchlist')
              .insert({
                'user_id': user.id,
                'symbol': upperSymbol,
                'added_at': DateTime.now().toIso8601String(),
              });
          print('🔖 Added $upperSymbol to Supabase watchlist');
        }
        
        print('🔖 Added $upperSymbol to watchlist');
      }
    } catch (e) {
      print('❌ Error adding to watchlist: $e');
      // Continue with local-only if Supabase fails
      final currentSymbols = getWatchlistSymbols().toList();
      final upperSymbol = symbol.toUpperCase();
      if (!currentSymbols.contains(upperSymbol)) {
        currentSymbols.add(upperSymbol);
        await saveWatchlistSymbols(currentSymbols);
        print('🔖 Added $upperSymbol to watchlist (local only)');
      }
    }
  }
  
  /// Remove symbol from watchlist
  static Future<void> removeFromWatchlist(String symbol) async {
    try {
      final currentSymbols = getWatchlistSymbols().toList(); // Ensure mutable list
      final upperSymbol = symbol.toUpperCase();
      
      if (currentSymbols.remove(upperSymbol)) {
        // Save to local storage first
        await saveWatchlistSymbols(currentSymbols);
        
        // Also remove from Supabase if user is authenticated
        final user = _supabase.auth.currentUser;
        if (user != null) {
          await _supabase
              .from('watchlist')
              .delete()
              .eq('user_id', user.id)
              .eq('symbol', upperSymbol);
          print('🔖 Removed $upperSymbol from Supabase watchlist');
        }
        
        print('🔖 Removed $upperSymbol from watchlist');
      }
    } catch (e) {
      print('❌ Error removing from watchlist: $e');
      // Continue with local-only if Supabase fails
      final currentSymbols = getWatchlistSymbols().toList();
      final upperSymbol = symbol.toUpperCase();
      if (currentSymbols.remove(upperSymbol)) {
        await saveWatchlistSymbols(currentSymbols);
        print('🔖 Removed $upperSymbol from watchlist (local only)');
      }
    }
  }
  
  /// Check if symbol is in watchlist
  static bool isInWatchlist(String symbol) {
    final currentSymbols = getWatchlistSymbols();
    return currentSymbols.contains(symbol.toUpperCase());
  }
  
  /// Get default symbols for new users (now returns empty list)
  static List<String> getDefaultWatchlist() => <String>[];
  
  /// Load watchlist from Supabase and sync with local storage
  static Future<List<String>> loadWatchlistFromSupabase() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        print('🔖 No authenticated user, using local watchlist');
        final localSymbols = getWatchlistSymbols();
        print('🔖 Local watchlist has ${localSymbols.length} symbols: ${localSymbols.join(", ")}');
        return localSymbols;
      }
      
      print('🔖 Loading watchlist from Supabase for user: ${user.id}');
      final response = await _supabase
          .from('watchlist')
          .select('symbol, added_at')
          .eq('user_id', user.id)
          .order('added_at', ascending: false);
      
      print('🔖 Supabase watchlist response: $response');
      
      final symbols = response.map<String>((item) => item['symbol'] as String).toList();
      print('🔖 Loaded ${symbols.length} symbols from Supabase watchlist: ${symbols.join(", ")}');
      
      // Sync with local storage
      await saveWatchlistSymbols(symbols);
      
      return symbols;
    } catch (e) {
      print('❌ Error loading watchlist from Supabase: $e');
      print('❌ Stack trace: ${StackTrace.current}');
      // Fallback to local storage
      final localSymbols = getWatchlistSymbols();
      print('🔖 Fallback to local watchlist: ${localSymbols.length} symbols');
      return localSymbols;
    }
  }
}