import 'dart:io';

/// Test Runner Script
/// 
/// Comprehensive test execution script that runs all test suites
/// and generates detailed reports.
/// 
/// Usage:
/// dart test_scripts/test_runner.dart [test_type]
/// 
/// Test types:
/// - mvp: MVP feature tests only
/// - stress: Stress tests only  
/// - integration: Integration tests only
/// - all: All test suites (default)
/// 
void main(List<String> arguments) async {
  final testType = arguments.isNotEmpty ? arguments[0] : 'all';
  
  print('🧪 STOX APP TEST RUNNER');
  print('========================');
  print('Test Type: ${testType.toUpperCase()}');
  print('Started at: ${DateTime.now()}');
  print('');
  
  final stopwatch = Stopwatch()..start();
  bool allPassed = true;
  
  try {
    switch (testType.toLowerCase()) {
      case 'mvp':
        allPassed = await _runMVPTests();
        break;
      case 'stress':
        allPassed = await _runStressTests();
        break;
      case 'integration':
        allPassed = await _runIntegrationTests();
        break;
      case 'all':
      default:
        allPassed = await _runAllTests();
        break;
    }
  } catch (e) {
    print('❌ Test execution failed: $e');
    allPassed = false;
  }
  
  stopwatch.stop();
  
  print('');
  print('🏁 TEST EXECUTION COMPLETED');
  print('===========================');
  print('Duration: ${_formatDuration(stopwatch.elapsed)}');
  print('Status: ${allPassed ? '✅ ALL TESTS PASSED' : '❌ SOME TESTS FAILED'}');
  print('Completed at: ${DateTime.now()}');
  
  // Generate test report
  await _generateTestReport(testType, stopwatch.elapsed, allPassed);
  
  exit(allPassed ? 0 : 1);
}

/// Run MVP feature tests
Future<bool> _runMVPTests() async {
  print('🚀 Running MVP Feature Tests...');
  print('-------------------------------');
  
  final result = await Process.run('flutter', [
    'test',
    'test_scripts/mvp_feature_tests.dart',
    '--reporter=expanded'
  ]);
  
  print(result.stdout);
  if (result.stderr.isNotEmpty) {
    print('stderr: ${result.stderr}');
  }
  
  final passed = result.exitCode == 0;
  print(passed ? '✅ MVP Tests: PASSED' : '❌ MVP Tests: FAILED');
  
  return passed;
}

/// Run stress tests
Future<bool> _runStressTests() async {
  print('🔥 Running Stress Tests...');
  print('---------------------------');
  
  final result = await Process.run('flutter', [
    'test',
    'test_scripts/stress_tests.dart',
    '--reporter=expanded'
  ]);
  
  print(result.stdout);
  if (result.stderr.isNotEmpty) {
    print('stderr: ${result.stderr}');
  }
  
  final passed = result.exitCode == 0;
  print(passed ? '✅ Stress Tests: PASSED' : '❌ Stress Tests: FAILED');
  
  return passed;
}

/// Run integration tests
Future<bool> _runIntegrationTests() async {
  print('🔄 Running Integration Tests...');
  print('--------------------------------');
  
  final result = await Process.run('flutter', [
    'test',
    'test_scripts/integration_tests.dart',
    '--reporter=expanded'
  ]);
  
  print(result.stdout);
  if (result.stderr.isNotEmpty) {
    print('stderr: ${result.stderr}');
  }
  
  final passed = result.exitCode == 0;
  print(passed ? '✅ Integration Tests: PASSED' : '❌ Integration Tests: FAILED');
  
  return passed;
}

/// Run all test suites
Future<bool> _runAllTests() async {
  print('🎯 Running All Test Suites...');
  print('==============================');
  print('');
  
  final mvpPassed = await _runMVPTests();
  print('');
  
  final stressPassed = await _runStressTests();
  print('');
  
  final integrationPassed = await _runIntegrationTests();
  print('');
  
  // Run standard Flutter tests as well
  print('🧪 Running Standard Flutter Tests...');
  print('------------------------------------');
  
  final flutterResult = await Process.run('flutter', [
    'test',
    '--reporter=expanded',
    '--coverage'
  ]);
  
  print(flutterResult.stdout);
  if (flutterResult.stderr.isNotEmpty) {
    print('stderr: ${flutterResult.stderr}');
  }
  
  final flutterPassed = flutterResult.exitCode == 0;
  print(flutterPassed ? '✅ Flutter Tests: PASSED' : '❌ Flutter Tests: FAILED');
  
  return mvpPassed && stressPassed && integrationPassed && flutterPassed;
}

/// Generate detailed test report
Future<void> _generateTestReport(String testType, Duration duration, bool allPassed) async {
  final timestamp = DateTime.now().toIso8601String().replaceAll(':', '-');
  final reportFile = File('test_reports/test_report_$timestamp.md');
  
  // Create reports directory if it doesn't exist
  await reportFile.parent.create(recursive: true);
  
  final report = StringBuffer();
  report.writeln('# Stox App Test Report');
  report.writeln('');
  report.writeln('**Generated:** ${DateTime.now()}');
  report.writeln('**Test Type:** ${testType.toUpperCase()}');
  report.writeln('**Duration:** ${_formatDuration(duration)}');
  report.writeln('**Status:** ${allPassed ? '✅ PASSED' : '❌ FAILED'}');
  report.writeln('');
  
  // System information
  report.writeln('## System Information');
  report.writeln('- OS: ${Platform.operatingSystem}');
  report.writeln('- Dart Version: ${Platform.version}');
  report.writeln('- Architecture: ${Platform.localeName}');
  report.writeln('');
  
  // Test suite breakdown
  report.writeln('## Test Suites');
  report.writeln('');
  
  switch (testType.toLowerCase()) {
    case 'mvp':
      report.writeln('### MVP Feature Tests');
      report.writeln('- User Authentication & Management');
      report.writeln('- Market Data & Search');
      report.writeln('- Portfolio Management & Trading');
      report.writeln('- Achievement System');
      report.writeln('- Offline Functionality');
      report.writeln('- Data Persistence & Sync');
      report.writeln('- Error Handling & Recovery');
      break;
      
    case 'stress':
      report.writeln('### Stress Tests');
      report.writeln('- Cache Performance (1000+ operations)');
      report.writeln('- Database Performance (500+ transactions)');
      report.writeln('- Concurrent User Simulation (10 users)');
      report.writeln('- Memory Management');
      report.writeln('- Network Stress Tests');
      report.writeln('- Burst Traffic Handling');
      break;
      
    case 'integration':
      report.writeln('### Integration Tests');
      report.writeln('- End-to-End User Journeys');
      report.writeln('- Cross-Screen Data Consistency');
      report.writeln('- Real-time Data Updates');
      report.writeln('- Offline/Online Transitions');
      report.writeln('- Error Recovery Workflows');
      break;
      
    default:
      report.writeln('### All Test Suites');
      report.writeln('- MVP Feature Tests');
      report.writeln('- Stress Tests');
      report.writeln('- Integration Tests');
      report.writeln('- Standard Flutter Tests');
      break;
  }
  
  report.writeln('');
  
  // Performance metrics (if available)
  report.writeln('## Performance Metrics');
  report.writeln('- Test Execution Time: ${_formatDuration(duration)}');
  report.writeln('- Average Test Time: ${_formatDuration(Duration(milliseconds: duration.inMilliseconds ~/ _getExpectedTestCount(testType)))}');
  report.writeln('');
  
  // Recommendations
  report.writeln('## Recommendations');
  if (allPassed) {
    report.writeln('✅ All tests passed successfully. The app is ready for deployment.');
    report.writeln('');
    report.writeln('**Next Steps:**');
    report.writeln('- Run tests on different devices/platforms');
    report.writeln('- Perform manual testing of critical user flows');
    report.writeln('- Monitor performance metrics in production');
  } else {
    report.writeln('❌ Some tests failed. Please review the following:');
    report.writeln('');
    report.writeln('**Action Items:**');
    report.writeln('- Fix failing tests before deployment');
    report.writeln('- Review error logs for root causes');
    report.writeln('- Run targeted test suites after fixes');
    report.writeln('- Consider rolling back recent changes if needed');
  }
  
  await reportFile.writeAsString(report.toString());
  
  print('');
  print('📄 Test report generated: ${reportFile.path}');
}

/// Format duration for human reading
String _formatDuration(Duration duration) {
  if (duration.inHours > 0) {
    return '${duration.inHours}h ${duration.inMinutes % 60}m ${duration.inSeconds % 60}s';
  } else if (duration.inMinutes > 0) {
    return '${duration.inMinutes}m ${duration.inSeconds % 60}s';
  } else {
    return '${duration.inSeconds}s ${duration.inMilliseconds % 1000}ms';
  }
}

/// Get expected test count for performance calculations
int _getExpectedTestCount(String testType) {
  switch (testType.toLowerCase()) {
    case 'mvp':
      return 15; // Approximate number of MVP tests
    case 'stress':
      return 8;  // Approximate number of stress tests
    case 'integration':
      return 6;  // Approximate number of integration tests
    default:
      return 30; // Total approximate test count
  }
}