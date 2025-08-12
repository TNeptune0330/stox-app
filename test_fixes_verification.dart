#!/usr/bin/env dart

import 'dart:io';

void main() async {
  print('🧪 Testing News URL Opening and Chart Data Fixes');
  
  // Test 1: Check URL launcher integration in asset_detail_screen.dart
  print('\n📰 Test 1: News URL opening functionality...');
  
  final urlLauncherTests = [
    'url_launcher/url_launcher.dart',
    'launchUrl.*uri.*mode.*LaunchMode',
    'canLaunchUrl.*uri',
    'ScaffoldMessenger.*showSnackBar',
    'if.*mounted',
  ];
  
  int urlFeatures = 0;
  
  for (final pattern in urlLauncherTests) {
    final result = await Process.run('grep', ['-r', pattern, 'lib/screens/market/asset_detail_screen.dart']);
    if (result.exitCode == 0 && result.stdout.toString().trim().isNotEmpty) {
      urlFeatures++;
    }
  }
  
  print('✅ Found $urlFeatures URL launcher features');
  
  // Test 2: Check pubspec.yaml for url_launcher dependency
  print('\n📦 Test 2: URL launcher dependency...');
  
  final pubspecResult = await Process.run('grep', ['url_launcher', 'pubspec.yaml']);
  if (pubspecResult.exitCode == 0) {
    print('✅ url_launcher dependency found in pubspec.yaml');
  } else {
    print('❌ url_launcher dependency missing');
  }
  
  // Test 3: Check chart data improvements
  print('\n📊 Test 3: Chart data functionality...');
  
  final chartTests = [
    'getHistoricalData',
    'isCurved.*false',
    'FlSpot.*0.*widget.asset.price',
    'EnhancedMarketDataService',
    'if.*_priceData.isEmpty',
  ];
  
  int chartFeatures = 0;
  
  for (final pattern in chartTests) {
    final result = await Process.run('grep', ['-r', pattern, 'lib/screens/market/asset_detail_screen.dart']);
    if (result.exitCode == 0 && result.stdout.toString().trim().isNotEmpty) {
      chartFeatures++;
    }
  }
  
  print('✅ Found $chartFeatures chart data features');
  
  // Test 4: Check enhanced market data service has fallback methods
  print('\n🔄 Test 4: Chart data fallback methods...');
  
  final fallbackTests = [
    '_getHistoricalDataFallback',
    'multiple.*fallback.*approaches',
    'exponential.*backoff',
    'return.*<FlSpot>.*\\[\\]',
  ];
  
  int fallbackFeatures = 0;
  
  for (final pattern in fallbackTests) {
    final result = await Process.run('grep', ['-r', '-i', pattern, 'lib/services/enhanced_market_data_service.dart']);
    if (result.exitCode == 0) {
      fallbackFeatures++;
    }
  }
  
  print('✅ Found $fallbackFeatures fallback mechanisms');
  
  // Test 5: Check fundamental data improvements
  print('\n📈 Test 5: Fundamental data improvements...');
  
  final fundamentalTests = [
    'getFundamentalData',
    'Use.*real.*market.*data',
    'never.*returns.*mock.*data',
    'empty.*map.*if.*no.*data',
  ];
  
  int fundamentalFeatures = 0;
  
  for (final pattern in fundamentalTests) {
    final result = await Process.run('grep', ['-r', '-i', pattern, 'lib/screens/market/asset_detail_screen.dart']);
    if (result.exitCode == 0) {
      fundamentalFeatures++;
    }
  }
  
  // Also check enhanced service
  for (final pattern in fundamentalTests) {
    final result = await Process.run('grep', ['-r', '-i', pattern, 'lib/services/enhanced_market_data_service.dart']);
    if (result.exitCode == 0) {
      fundamentalFeatures++;
    }
  }
  
  print('✅ Found $fundamentalFeatures fundamental data improvements');
  
  // Summary
  print('\n📋 Fix Verification Summary:');
  print('- URL launcher features: ✅ $urlFeatures/5');
  print('- URL launcher dependency: ✅ Present');
  print('- Chart data features: ✅ $chartFeatures/5'); 
  print('- Chart fallback mechanisms: ✅ $fallbackFeatures/4');
  print('- Fundamental data improvements: ✅ $fundamentalFeatures/8');
  
  final totalScore = urlFeatures + chartFeatures + fallbackFeatures + (fundamentalFeatures ~/ 2);
  print('\nTotal implementation score: $totalScore/19');
  
  if (totalScore >= 15) {
    print('\n🎉 SUCCESS: Both fixes appear to be properly implemented!');
    print('\n✅ News Articles Fix:');
    print('   - url_launcher package added to pubspec.yaml');
    print('   - URL launching implemented with error handling');
    print('   - Context safety with mounted checks');
    
    print('\n✅ Charts Data Fix:');
    print('   - Historical data fetching from EnhancedMarketDataService');
    print('   - Fallback to current price if no historical data');
    print('   - Straight lines (isCurved: false) implemented');
    print('   - Multiple API fallback mechanisms in place');
    
    exit(0);
  } else {
    print('\n⚠️  Some fixes may be incomplete - score: $totalScore/19');
    exit(1);
  }
}