import 'dart:async';
import 'package:flutter/foundation.dart';
import 'market_data_service.dart';
import 'realistic_price_simulator.dart';

class PriceUpdateService {
  static PriceUpdateService? _instance;
  static PriceUpdateService get instance => _instance ??= PriceUpdateService._();
  
  PriceUpdateService._();

  Timer? _updateTimer;
  final MarketDataService _marketDataService = MarketDataService();
  bool _isUpdating = false;

  void startPeriodicUpdates() {
    print('Starting realistic price updates every 2 minutes...');
    
    // Update immediately on start
    _updatePrices();
    
    // Set up periodic updates every 2 minutes for more dynamic trading
    _updateTimer = Timer.periodic(const Duration(minutes: 2), (_) {
      _updatePrices();
    });
  }

  void stopPeriodicUpdates() {
    print('Stopping periodic price updates...');
    _updateTimer?.cancel();
    _updateTimer = null;
  }

  Future<void> _updatePrices() async {
    if (_isUpdating) {
      print('Price update already in progress, skipping...');
      return;
    }

    _isUpdating = true;
    
    try {
      print('🔄 Updating market prices at ${DateTime.now().toIso8601String()}');
      
      // Try realistic price simulation first
      await RealisticPriceSimulator.simulateRealisticPriceUpdates();
      
      // Occasionally simulate market events (10% chance)
      if (DateTime.now().second % 10 == 0) {
        await RealisticPriceSimulator.simulateMarketEvent();
      }
      
      print('✅ Market prices updated successfully');
    } catch (e) {
      print('❌ Failed to update market prices: $e');
      // Fallback to original method if simulation fails
      try {
        await _marketDataService.updateAllPrices();
      } catch (fallbackError) {
        print('❌ Fallback price update also failed: $fallbackError');
      }
    } finally {
      _isUpdating = false;
    }
  }

  Future<void> forceUpdate() async {
    print('🔄 Force updating market prices...');
    await _updatePrices();
  }

  void dispose() {
    stopPeriodicUpdates();
  }
}