import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/theme_provider.dart';
import '../../services/performance_monitor_service.dart';
import '../../services/optimized_cache_service.dart';
import '../../services/optimized_network_service.dart';
import '../../mixins/performance_optimized_mixin.dart';

class PerformanceDebugScreen extends StatefulWidget {
  const PerformanceDebugScreen({super.key});

  @override
  State<PerformanceDebugScreen> createState() => _PerformanceDebugScreenState();
}

class _PerformanceDebugScreenState extends State<PerformanceDebugScreen> 
    with PerformanceOptimizedMixin, TickerProviderStateMixin {
  
  Map<String, dynamic>? _performanceReport;
  bool _isLoading = false;
  
  @override
  void initState() {
    super.initState();
    _loadPerformanceData();
  }
  
  Future<void> _loadPerformanceData() async {
    safeSetState(() => _isLoading = true);
    
    await Future.delayed(const Duration(milliseconds: 500)); // Allow UI to update
    
    final report = PerformanceMonitorService.getPerformanceReport();
    
    safeSetState(() {
      _performanceReport = report;
      _isLoading = false;
    });
  }
  
  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return Scaffold(
          backgroundColor: themeProvider.background,
          appBar: AppBar(
            title: const Text('Performance Debug'),
            backgroundColor: themeProvider.backgroundHigh,
            foregroundColor: themeProvider.contrast,
            actions: [
              IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: _loadPerformanceData,
              ),
              IconButton(
                icon: const Icon(Icons.clear_all),
                onPressed: _clearAllData,
              ),
            ],
          ),
          body: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _buildPerformanceReport(themeProvider),
        );
      },
    );
  }
  
  Widget _buildPerformanceReport(ThemeProvider themeProvider) {
    if (_performanceReport == null) {
      return const Center(child: Text('No performance data available'));
    }
    
    return buildOptimizedList(
      items: _buildReportSections(),
      itemBuilder: (context, section, index) => section,
      padding: const EdgeInsets.all(16),
    );
  }
  
  List<Widget> _buildReportSections() {
    final report = _performanceReport!;
    final sections = <Widget>[];
    
    // App Info Section
    sections.add(_buildSectionCard(
      'App Information',
      Icons.info,
      _buildAppInfoContent(report['app_info']),
    ));
    
    // Performance Metrics Section
    final metrics = report['metrics'] as Map<String, dynamic>;
    if (metrics.isNotEmpty) {
      sections.add(_buildSectionCard(
        'Performance Metrics',
        Icons.speed,
        _buildMetricsContent(metrics),
      ));
    }
    
    // Cache Statistics Section
    sections.add(_buildSectionCard(
      'Cache Performance',
      Icons.storage,
      _buildCacheStatsContent(report['cache_stats']),
    ));
    
    // Network Statistics Section
    sections.add(_buildSectionCard(
      'Network Performance',
      Icons.network_check,
      _buildNetworkStatsContent(report['network_stats']),
    ));
    
    // Slow Operations Section
    final slowOps = PerformanceMonitorService.getSlowOperations(limit: 5);
    if (slowOps.isNotEmpty) {
      sections.add(_buildSectionCard(
        'Slow Operations',
        Icons.warning,
        _buildSlowOpsContent(slowOps),
      ));
    }
    
    // Recent Events Section
    final events = report['recent_events'] as List;
    if (events.isNotEmpty) {
      sections.add(_buildSectionCard(
        'Recent Events',
        Icons.event,
        _buildEventsContent(events.take(5).toList()),
      ));
    }
    
    return sections;
  }
  
  Widget _buildSectionCard(String title, IconData icon, Widget content) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          color: themeProvider.backgroundHigh,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(icon, color: themeProvider.theme, size: 24),
                    const SizedBox(width: 12),
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: themeProvider.contrast,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                content,
              ],
            ),
          ),
        );
      },
    );
  }
  
  Widget _buildAppInfoContent(Map<String, dynamic> appInfo) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildInfoRow('Version', appInfo['version'] ?? 'Unknown', themeProvider),
            _buildInfoRow('Build', appInfo['build_number'] ?? 'Unknown', themeProvider),
            _buildInfoRow('Package', appInfo['package_name'] ?? 'Unknown', themeProvider),
          ],
        );
      },
    );
  }
  
  Widget _buildMetricsContent(Map<String, dynamic> metrics) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: metrics.entries.map((entry) {
            final stats = entry.value as Map<String, dynamic>;
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: themeProvider.background,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: themeProvider.theme.withOpacity(0.2)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    entry.key.replaceAll('_', ' ').toUpperCase(),
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: themeProvider.contrast,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildStatChip('Avg', '${stats['avg']}ms', themeProvider),
                      _buildStatChip('P95', '${stats['p95']}ms', themeProvider),
                      _buildStatChip('Max', '${stats['max']}ms', themeProvider),
                      _buildStatChip('Count', '${stats['count']}', themeProvider),
                    ],
                  ),
                ],
              ),
            );
          }).toList(),
        );
      },
    );
  }
  
  Widget _buildCacheStatsContent(Map<String, dynamic> cacheStats) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return Column(
          children: [
            _buildInfoRow('Hit Rate', '${cacheStats['hit_rate_percent']}%', themeProvider),
            _buildInfoRow('Cache Hits', '${cacheStats['cache_hits']}', themeProvider),
            _buildInfoRow('Cache Misses', '${cacheStats['cache_misses']}', themeProvider),
            _buildInfoRow('Memory Cache Size', '${cacheStats['memory_cache_size']}/${cacheStats['memory_cache_max']}', themeProvider),
            if (cacheStats['cache_evictions'] > 0)
              _buildInfoRow('Evictions', '${cacheStats['cache_evictions']}', themeProvider),
          ],
        );
      },
    );
  }
  
  Widget _buildNetworkStatsContent(Map<String, dynamic> networkStats) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return Column(
          children: [
            _buildInfoRow('Total Requests', '${networkStats['total_requests']}', themeProvider),
            _buildInfoRow('Cached Responses', '${networkStats['cached_responses']}', themeProvider),
            _buildInfoRow('Failed Requests', '${networkStats['failed_requests']}', themeProvider),
            _buildInfoRow('Avg Latency', '${networkStats['average_latency_ms']}ms', themeProvider),
            _buildInfoRow('Connectivity', '${networkStats['connectivity']}', themeProvider),
            if (networkStats['queued_requests'] > 0)
              _buildInfoRow('Queued Requests', '${networkStats['queued_requests']}', themeProvider),
          ],
        );
      },
    );
  }
  
  Widget _buildSlowOpsContent(List<Map<String, dynamic>> slowOps) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return Column(
          children: slowOps.map((op) {
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: themeProvider.background,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Icon(Icons.slow_motion_video, color: Colors.orange, size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          op['operation'],
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: themeProvider.contrast,
                          ),
                        ),
                        Text(
                          'Avg: ${op['avg_time_ms']}ms • Max: ${op['max_time_ms']}ms • Count: ${op['count']}',
                          style: TextStyle(
                            fontSize: 12,
                            color: themeProvider.contrast.withOpacity(0.7),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        );
      },
    );
  }
  
  Widget _buildEventsContent(List events) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return Column(
          children: events.map<Widget>((event) {
            final eventMap = event as Map<String, dynamic>;
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: themeProvider.background,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: themeProvider.theme.withOpacity(0.2)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    eventMap['name'],
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: themeProvider.contrast,
                    ),
                  ),
                  Text(
                    eventMap['timestamp'],
                    style: TextStyle(
                      fontSize: 12,
                      color: themeProvider.contrast.withOpacity(0.7),
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        );
      },
    );
  }
  
  Widget _buildInfoRow(String label, String value, ThemeProvider themeProvider) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(color: themeProvider.contrast.withOpacity(0.8)),
          ),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: themeProvider.contrast,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildStatChip(String label, String value, ThemeProvider themeProvider) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: themeProvider.theme.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: themeProvider.contrast.withOpacity(0.7),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: themeProvider.contrast,
            ),
          ),
        ],
      ),
    );
  }
  
  Future<void> _clearAllData() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear Performance Data'),
        content: const Text('This will clear all performance metrics, cache, and network statistics. Continue?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Clear'),
          ),
        ],
      ),
    );
    
    if (confirmed == true) {
      await OptimizedCacheService.clearAll();
      await OptimizedNetworkService.reset();
      PerformanceMonitorService.reset();
      
      _loadPerformanceData();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Performance data cleared')),
        );
      }
    }
  }
}