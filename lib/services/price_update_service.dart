import 'dart:async';
import 'package:flutter/foundation.dart';
import 'market_data_service.dart';

class PriceUpdateService {
  static PriceUpdateService? _instance;
  static PriceUpdateService get instance => _instance ??= PriceUpdateService._();
  
  PriceUpdateService._();

  Timer? _updateTimer;
  final MarketDataService _marketDataService = MarketDataService();
  bool _isUpdating = false;

  void startPeriodicUpdates() {
    print('Starting periodic price updates every 5 minutes...');
    
    // Update immediately on start
    _updatePrices();
    
    // Set up periodic updates every 5 minutes
    _updateTimer = Timer.periodic(const Duration(minutes: 5), (_) {
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
      
      // Update all prices
      await _marketDataService.updateAllPrices();
      
      print('✅ Market prices updated successfully');
    } catch (e) {
      print('❌ Failed to update market prices: $e');
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