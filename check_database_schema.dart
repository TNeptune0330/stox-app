import 'dart:io';
import 'lib/config/supabase_config.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() async {
  print('🔍 Checking Supabase Database Schema...');
  print('📡 URL: ${SupabaseConfig.url}');
  print('');
  
  try {
    // Initialize Supabase
    await Supabase.initialize(
      url: SupabaseConfig.url,
      anonKey: SupabaseConfig.anonKey,
    );
    
    final supabase = Supabase.instance.client;
    print('✅ Supabase connection established');
    
    // Required tables for the app
    final requiredTables = [
      'users',
      'portfolio', 
      'transactions',
      'market_prices',
      'achievement_progress',
      'user_achievements',
      'user_settings',
      'leaderboard'
    ];
    
    print('\n📋 Checking Required Tables:');
    print('=' * 50);
    
    for (final table in requiredTables) {
      try {
        final response = await supabase.from(table).select('*').limit(1);
        print('✅ $table - EXISTS');
      } catch (e) {
        print('❌ $table - MISSING');
        print('   Error: ${e.toString().split('\n')[0]}');
      }
    }
    
    print('\n🔧 Checking Required Functions:');
    print('=' * 50);
    
    // Check if execute_trade function exists
    try {
      await supabase.rpc('execute_trade', params: {
        'user_id_param': '00000000-0000-0000-0000-000000000000',
        'symbol_param': 'TEST',
        'type_param': 'buy',
        'quantity_param': 1,
        'price_param': 100.0,
        'total_value_param': 100.0
      });
      print('✅ execute_trade function - EXISTS');
    } catch (e) {
      if (e.toString().contains('function') && e.toString().contains('does not exist')) {
        print('❌ execute_trade function - MISSING');
      } else {
        print('✅ execute_trade function - EXISTS (test call failed as expected)');
      }
    }
    
    print('\n📊 Checking Market Data:');
    print('=' * 50);
    
    try {
      final response = await supabase.from('market_prices').select('count').single();
      final count = response['count'] as int;
      print('✅ Market prices table has $count records');
      
      if (count == 0) {
        print('⚠️  Market prices table is empty - needs initial data');
      }
    } catch (e) {
      print('❌ Cannot check market prices count: $e');
    }
    
    print('\n🎯 Database Schema Check Complete!');
    print('');
    
    // Provide recommendations
    print('📝 Recommendations:');
    print('=' * 50);
    print('1. If tables are missing, run the SQL from supabase_complete_schema.sql');
    print('2. Go to: https://supabase.com/dashboard/project/dskcftkbfdkynjbxnwak/editor/20701');
    print('3. Copy and paste the schema SQL and execute it');
    print('4. Make sure Row Level Security (RLS) is enabled');
    print('5. Verify that the market_prices table has initial stock data');
    
  } catch (e) {
    print('❌ Database schema check failed: $e');
    print('');
    print('🔧 Troubleshooting:');
    print('1. Check if your Supabase project is active');
    print('2. Verify the anon key is correct');
    print('3. Make sure the database schema is set up');
    exit(1);
  }
}