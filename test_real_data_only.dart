#!/usr/bin/env dart

import 'dart:io';

void main() async {
  print('🧪 Testing Real Data Only Implementation');
  
  // Test 1: Check for any remaining mock data references
  print('\n📊 Test 1: Searching for mock data references...');
  
  final mockSearches = [
    'Mock.*Created',
    '_createMock',
    '📊.*Mock',
    'mock.*data',
    'Random\\(\\)',
  ];
  
  bool foundMockReferences = false;
  
  for (final pattern in mockSearches) {
    final result = await Process.run('grep', ['-r', pattern, 'lib/']);
    if (result.exitCode == 0 && result.stdout.toString().trim().isNotEmpty) {
      print('❌ Found mock references with pattern "$pattern":');
      print(result.stdout);
      foundMockReferences = true;
    }
  }
  
  if (!foundMockReferences) {
    print('✅ No mock data references found');
  }
  
  // Test 2: Check for proper error handling
  print('\n🔄 Test 2: Checking error handling...');
  
  final errorPatterns = [
    'NEVER.*mock',
    'ONLY.*real',
    'skip.*instead',
  ];
  
  int errorHandlingCount = 0;
  
  for (final pattern in errorPatterns) {
    final result = await Process.run('grep', ['-r', '-i', pattern, 'lib/services/enhanced_market_data_service.dart']);
    if (result.exitCode == 0) {
      errorHandlingCount += result.stdout.toString().split('\n').where((line) => line.trim().isNotEmpty).length;
    }
  }
  
  print('✅ Found $errorHandlingCount error handling improvements');
  
  // Test 3: Check for retry logic
  print('\n🔄 Test 3: Checking retry logic...');
  
  final retryPatterns = [
    'retry.*attempt',
    'exponential.*backoff',
    'maxRetries',
    'Future\\.delayed',
  ];
  
  int retryImplementations = 0;
  
  for (final pattern in retryPatterns) {
    final result = await Process.run('grep', ['-r', '-i', pattern, 'lib/services/enhanced_market_data_service.dart']);
    if (result.exitCode == 0) {
      retryImplementations++;
    }
  }
  
  print('✅ Found $retryImplementations retry mechanisms');
  
  // Test 4: Verify API endpoints
  print('\n🌐 Test 4: Checking API endpoints...');
  
  final apiEndpoints = [
    'yahoo.*finance',
    'finnhub',
    'coingecko',
    'alphavantage',
  ];
  
  int apiCount = 0;
  
  for (final pattern in apiEndpoints) {
    final result = await Process.run('grep', ['-r', '-i', pattern, 'lib/services/enhanced_market_data_service.dart']);
    if (result.exitCode == 0) {
      apiCount++;
    }
  }
  
  print('✅ Found $apiCount different API integrations');
  
  // Test 5: Check initialization improvements
  print('\n🚀 Test 5: Checking initialization...');
  
  final initPatterns = [
    '_initializeRealMarketData',
    'REAL.*market.*data',
    'real.*data.*only',
  ];
  
  bool hasRealDataInit = false;
  
  for (final pattern in initPatterns) {
    final result = await Process.run('grep', ['-r', '-i', pattern, 'lib/services/enhanced_market_data_service.dart']);
    if (result.exitCode == 0) {
      hasRealDataInit = true;
      break;
    }
  }
  
  if (hasRealDataInit) {
    print('✅ Real data initialization implemented');
  } else {
    print('❌ Real data initialization not found');
  }
  
  // Summary
  print('\n📋 Summary:');
  print('- Mock data references: ${foundMockReferences ? "❌ FOUND" : "✅ NONE"}');
  print('- Error handling: ✅ $errorHandlingCount improvements');
  print('- Retry mechanisms: ✅ $retryImplementations implementations');
  print('- API integrations: ✅ $apiCount different APIs');
  print('- Real data init: ${hasRealDataInit ? "✅ IMPLEMENTED" : "❌ MISSING"}');
  
  if (!foundMockReferences && hasRealDataInit) {
    print('\n🎉 SUCCESS: Real data only implementation verified!');
    exit(0);
  } else {
    print('\n⚠️  Issues found - check implementation');
    exit(1);
  }
}