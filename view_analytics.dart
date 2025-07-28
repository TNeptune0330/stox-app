#!/usr/bin/env dart

import 'dart:io';

void main(List<String> args) async {
  print('📊 STOX APP - USER ANALYTICS VIEWER');
  print('===================================');
  
  print('\n🎯 How to View Your App Analytics:\n');
  
  // Method 1: In-App Analytics
  print('1️⃣  IN-APP ANALYTICS DASHBOARD');
  print('   • Open your Stox app');
  print('   • Go to Settings (bottom navigation)');
  print('   • Tap "User Analytics" (visible in debug mode)');
  print('   • View real-time metrics:');
  print('     - Total Users');
  print('     - Active Users Today');
  print('     - New Users This Week');
  print('     - Trading Activity');
  print('     - App Usage Stats');
  
  print('\n2️⃣  SUPABASE DASHBOARD (Recommended)');
  print('   • Visit: https://supabase.com/dashboard');
  print('   • Select your Stox project');
  print('   • Navigate to:');
  print('     📈 Authentication → User stats & sign-ups');
  print('     🗃️  Database → Query user tables directly');
  print('     📊 Analytics → Usage patterns & metrics');
  
  print('\n3️⃣  MANUAL DATABASE QUERIES');
  print('   You can run these SQL queries in Supabase:');
  print('');
  print('   -- Total Users');
  print('   SELECT COUNT(*) as total_users FROM auth.users;');
  print('');
  print('   -- Users Created Today');
  print('   SELECT COUNT(*) as new_today FROM auth.users');
  print('   WHERE DATE(created_at) = CURRENT_DATE;');
  print('');
  print('   -- Active Users (traded in last 7 days)');
  print('   SELECT COUNT(DISTINCT user_id) as active_users');
  print('   FROM user_trades');
  print(r"   WHERE created_at >= NOW() - INTERVAL '7 days';");
  print('');
  print('   -- Total Trades');
  print('   SELECT COUNT(*) as total_trades FROM user_trades;');
  print('');
  print('   -- Most Popular Stocks');
  print('   SELECT symbol, COUNT(*) as trade_count');
  print('   FROM user_trades');
  print('   GROUP BY symbol');
  print('   ORDER BY trade_count DESC');
  print('   LIMIT 10;');
  
  print('\n4️⃣  QUICK STATS COMMAND');
  print('   Run this command to get basic stats:');
  print('   \$ dart view_analytics.dart --quick');
  
  // Quick stats if requested
  if (args.isNotEmpty && args[0] == '--quick') {
    print('\n🔍 QUICK STATS (Simulated - Connect to your database for real data)');
    print('════════════════════════════════════════════════════════════════');
    
    // These would be real database queries in production
    final stats = {
      'Total Users': '1,247',
      'Active Today': '89',
      'New This Week': '34',
      'Total Trades': '5,678',
      'Most Traded': 'AAPL (247 trades)',
      'Avg Session': '8.5 minutes',
    };
    
    stats.forEach((key, value) {
      print('   $key: $value');
    });
    
    print('\n   💡 For real-time data, use the Supabase dashboard or in-app analytics.');
  }
  
  print('\n📱 ACCESSING IN-APP ANALYTICS:');
  print('   Current setup shows analytics for:');
  print('   ✅ Admin users (email contains "admin")');
  print('   ✅ Debug mode (always visible during development)');
  print('   ❌ Regular users (hidden in production)');
  
  print('\n🔐 ANALYTICS PERMISSIONS:');
  print('   To show analytics to specific users, modify:');
  print('   lib/screens/settings/settings_screen.dart:625');
  print(r"   Change: final isAdmin = authProvider.user?.email?.contains('admin') ?? false;");
  
  print('\n📊 METRICS AVAILABLE:');
  final metrics = [
    'User Registration & Growth',
    'Daily/Weekly/Monthly Active Users',
    'Trading Volume & Activity',
    'Most Popular Stocks/Cryptos',
    'Session Duration & Retention',
    'Portfolio Values & Performance',
    'News Article Views',
    'Market Data Requests',
    'Error Rates & App Stability',
  ];
  
  for (final metric in metrics) {
    print('   • $metric');
  }
  
  print('\n🚀 NEXT STEPS:');
  print('   1. Run your app: flutter run');
  print('   2. Go to Settings → User Analytics');
  print('   3. Or visit your Supabase dashboard');
  print('   4. Set up automated reports if needed');
  
  print('\n✨ Your analytics are ready to view!');
}