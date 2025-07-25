import 'dart:io';
import 'lib/config/supabase_config.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() async {
  print('🧪 Testing Supabase Connection...');
  
  try {
    // Initialize Supabase
    await Supabase.initialize(
      url: SupabaseConfig.url,
      anonKey: SupabaseConfig.anonKey,
    );
    
    print('✅ Supabase initialized successfully');
    print('📡 URL: ${SupabaseConfig.url}');
    
    final supabase = Supabase.instance.client;
    
    // Test basic connectivity
    print('🔍 Testing basic connectivity...');
    
    try {
      // Try to query a table (this will fail if schema isn't set up yet)
      final response = await supabase.from('users').select('count').limit(1);
      print('✅ Database connection successful');
      print('📊 Users table accessible');
    } catch (e) {
      print('⚠️ Database tables not found - you need to run the schema setup');
      print('   Go to: https://supabase.com/dashboard/project/dskcftkbfdkynjbxnwak/editor/20701');
      print('   Run the SQL from: supabase_complete_schema.sql');
    }
    
    // Test market_prices table
    try {
      final response = await supabase.from('market_prices').select('count').limit(1);
      print('✅ Market prices table accessible');
    } catch (e) {
      print('⚠️ Market prices table not found - schema setup needed');
    }
    
    print('\n🎯 Connection test completed!');
    
  } catch (e) {
    print('❌ Connection test failed: $e');
    exit(1);
  }
}