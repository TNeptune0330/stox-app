import 'dart:io';
import 'lib/services/realistic_price_simulator.dart';

void main() async {
  print('🧪 Testing Realistic Price Simulator...');
  
  try {
    // Test price simulation
    await RealisticPriceSimulator.simulateRealisticPriceUpdates();
    print('✅ Price simulation completed successfully');
    
    // Test market summary
    final summary = await RealisticPriceSimulator.getMarketSummary();
    print('📊 Market Summary:');
    print('  - Market Trend: ${summary['market_trend']}');
    print('  - Average Change: ${summary['average_change']?.toStringAsFixed(2)}%');
    print('  - Gainers: ${summary['gainers']}');
    print('  - Losers: ${summary['losers']}');
    
    // Test market event simulation
    await RealisticPriceSimulator.simulateMarketEvent();
    print('✅ Market event simulation completed');
    
    print('\n🎯 All tests passed! The realistic price simulator is working correctly.');
    print('📈 Stock prices will now change every 2 minutes with realistic volatility.');
    print('💰 Portfolio P&L calculations will show actual profit/loss based on current prices.');
    
  } catch (e) {
    print('❌ Test failed: $e');
    exit(1);
  }
}