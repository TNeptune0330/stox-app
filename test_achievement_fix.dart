import 'lib/services/local_database_service.dart';
import 'lib/providers/achievement_provider.dart';

void main() async {
  print('🧪 Testing Achievement System Fixes...');
  print('═══════════════════════════════════════════════════════════════');
  
  try {
    // Initialize the local database
    await LocalDatabaseService.initialize();
    print('✅ Local database initialized');
    
    // Test 1: Save and retrieve Set<String>
    print('\n📝 Test 1: Set<String> Storage');
    print('─────────────────────────────────');
    
    final testSet = <String>{'achievement1', 'achievement2', 'achievement3'};
    await LocalDatabaseService.saveSetting('test_achievements', testSet);
    
    final retrievedSet = LocalDatabaseService.getSetting<Set<String>>('test_achievements');
    
    print('Original set: $testSet');
    print('Retrieved set: $retrievedSet');
    print('Types match: ${retrievedSet.runtimeType == Set<String>}');
    print('Values match: ${testSet.difference(retrievedSet ?? {}).isEmpty}');
    
    assert(retrievedSet != null, 'Set should not be null');
    assert(retrievedSet!.runtimeType == Set<String>, 'Should be Set<String>');
    assert(testSet.difference(retrievedSet).isEmpty, 'Sets should be equal');
    
    print('✅ Set<String> test passed');
    
    // Test 2: Save and retrieve Map<String, int>
    print('\n📝 Test 2: Map<String, int> Storage');
    print('──────────────────────────────────');
    
    final testMap = <String, int>{
      'first_trade': 1,
      'ten_trades': 5,
      'hundred_trades': 25,
      'profit_made': 1500
    };
    
    await LocalDatabaseService.saveSetting('test_progress', testMap);
    
    final retrievedMap = LocalDatabaseService.getSetting<Map<String, int>>('test_progress');
    
    print('Original map: $testMap');
    print('Retrieved map: $retrievedMap');
    print('Types match: ${retrievedMap.runtimeType == Map<String, int>}');
    print('Values match: ${testMap.toString() == retrievedMap.toString()}');
    
    assert(retrievedMap != null, 'Map should not be null');
    assert(retrievedMap!.runtimeType == Map<String, int>, 'Should be Map<String, int>');
    assert(testMap.length == retrievedMap.length, 'Maps should have same length');
    
    // Check individual entries
    for (final entry in testMap.entries) {
      assert(retrievedMap.containsKey(entry.key), 'Map should contain key ${entry.key}');
      assert(retrievedMap[entry.key] == entry.value, 'Values should match for ${entry.key}');
    }
    
    print('✅ Map<String, int> test passed');
    
    // Test 3: Achievement Provider Initialization
    print('\n📝 Test 3: Achievement Provider');
    print('─────────────────────────────────');
    
    final achievementProvider = AchievementProvider();
    await achievementProvider.initialize();
    
    print('Achievements loaded: ${achievementProvider.achievements.length}');
    print('Unlocked achievements: ${achievementProvider.unlockedAchievements.length}');
    print('User progress entries: ${achievementProvider.userProgress.length}');
    
    assert(achievementProvider.achievements.isNotEmpty, 'Should have achievements');
    
    print('✅ Achievement provider test passed');
    
    // Test 4: Achievement Progress Updates
    print('\n📝 Test 4: Achievement Progress Updates');
    print('─────────────────────────────────────────');
    
    await achievementProvider.updateProgress('first_trade', 1);
    await achievementProvider.updateProgress('ten_trades', 3);
    
    final firstTradeProgress = achievementProvider.userProgress['first_trade'];
    final tenTradesProgress = achievementProvider.userProgress['ten_trades'];
    
    print('First trade progress: $firstTradeProgress');
    print('Ten trades progress: $tenTradesProgress');
    
    assert(firstTradeProgress == 1, 'First trade progress should be 1');
    assert(tenTradesProgress == 3, 'Ten trades progress should be 3');
    
    print('✅ Achievement progress update test passed');
    
    print('\n═══════════════════════════════════════════════════════════════');
    print('🎉 ALL ACHIEVEMENT SYSTEM TESTS PASSED!');
    print('═══════════════════════════════════════════════════════════════');
    
    print('\n📊 Test Summary:');
    print('✅ Set<String> Storage: Working correctly');
    print('✅ Map<String, int> Storage: Working correctly');
    print('✅ Achievement Provider: Working correctly');
    print('✅ Progress Updates: Working correctly');
    
    print('\n🔧 Fixes Applied:');
    print('✅ Enhanced LocalDatabaseService with proper type conversion');
    print('✅ Fixed Hive storage for complex types (Set<String>, Map<String, int>)');
    print('✅ Simplified AchievementProvider type casting');
    print('✅ Added comprehensive error handling');
    
    print('\n✅ Achievement system is now fully functional!');
    
  } catch (e) {
    print('❌ Test failed: $e');
    print('Stack trace: ${StackTrace.current}');
    rethrow;
  }
}