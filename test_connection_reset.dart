import 'dart:io';
import 'lib/services/connection_manager.dart';
import 'lib/config/supabase_config.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() async {
  print('🧪 Testing Connection Manager Reset...');
  
  try {
    // Initialize Supabase
    await Supabase.initialize(
      url: SupabaseConfig.url,
      anonKey: SupabaseConfig.anonKey,
    );
    
    final connectionManager = ConnectionManager();
    final supabase = Supabase.instance.client;
    
    print('1. Testing connection manager reset...');
    connectionManager.resetConnectionState();
    
    print('2. Testing force execute...');
    final result = await connectionManager.forceExecuteWithFallback<List<dynamic>>(
      () async {
        print('🔄 Making network call to market_prices...');
        final response = await supabase
            .from('market_prices')
            .select('symbol, name, price')
            .limit(3);
        print('✅ Network call successful: ${response.length} records');
        return response;
      },
      () async {
        print('📱 Using fallback...');
        return [];
      },
    );
    
    if (result != null && result.isNotEmpty) {
      print('✅ Connection manager reset successful!');
      print('📊 Retrieved data: ${result.first['symbol']} - \$${result.first['price']}');
    } else {
      print('❌ Connection test failed - no data retrieved');
    }
    
    print('\n🎯 Test completed!');
    print('The app should now make successful network calls to Supabase.');
    
  } catch (e) {
    print('❌ Connection test failed: $e');
    exit(1);
  }
}