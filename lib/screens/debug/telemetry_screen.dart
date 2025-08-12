import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/theme_provider.dart';
import '../../services/telemetry_service.dart';

class TelemetryScreen extends StatefulWidget {
  const TelemetryScreen({super.key});

  @override
  State<TelemetryScreen> createState() => _TelemetryScreenState();
}

class _TelemetryScreenState extends State<TelemetryScreen> {
  String _selectedCategory = 'All';
  final List<String> _categories = [
    'All', 'MarketData', 'Auth', 'Database', 'News', 'Trading', 'Errors'
  ];

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return Scaffold(
          backgroundColor: themeProvider.background,
          appBar: AppBar(
            title: const Text('App Telemetry'),
            backgroundColor: themeProvider.background,
            foregroundColor: themeProvider.contrast,
            actions: [
              IconButton(
                icon: const Icon(Icons.clear_all),
                onPressed: () {
                  TelemetryService.clearLogs();
                  setState(() {});
                },
                tooltip: 'Clear Logs',
              ),
              IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: () => setState(() {}),
                tooltip: 'Refresh',
              ),
            ],
          ),
          body: Column(
            children: [
              // Category Filter
              Container(
                height: 50,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _categories.length,
                  itemBuilder: (context, index) {
                    final category = _categories[index];
                    final isSelected = _selectedCategory == category;
                    
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: FilterChip(
                        label: Text(category),
                        selected: isSelected,
                        onSelected: (selected) {
                          setState(() {
                            _selectedCategory = category;
                          });
                        },
                        selectedColor: themeProvider.theme.withOpacity(0.3),
                        checkmarkColor: themeProvider.theme,
                      ),
                    );
                  },
                ),
              ),
              
              // Logs Display
              Expanded(
                child: Container(
                  margin: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.black87,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: themeProvider.theme.withOpacity(0.3),
                    ),
                  ),
                  child: _buildLogsList(themeProvider),
                ),
              ),
              
              // Stats Bar
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: themeProvider.backgroundHigh,
                  border: Border(
                    top: BorderSide(
                      color: themeProvider.theme.withOpacity(0.2),
                    ),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildStatItem('Total Logs', '${TelemetryService.getTotalLogCount()}', themeProvider),
                    _buildStatItem('Errors', '${TelemetryService.getErrorCount()}', themeProvider),
                    _buildStatItem('API Calls', '${TelemetryService.getApiCallCount()}', themeProvider),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildLogsList(ThemeProvider themeProvider) {
    final logs = TelemetryService.getFilteredLogs(_selectedCategory);
    
    if (logs.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.analytics_outlined,
              size: 48,
              color: Colors.grey[600],
            ),
            const SizedBox(height: 16),
            Text(
              'No logs available',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 16,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: logs.length,
      itemBuilder: (context, index) {
        final log = logs[logs.length - 1 - index]; // Show newest first
        return _buildLogItem(log, themeProvider);
      },
    );
  }

  Widget _buildLogItem(TelemetryLog log, ThemeProvider themeProvider) {
    Color logColor = Colors.white;
    IconData logIcon = Icons.info;
    
    switch (log.level) {
      case 'ERROR':
        logColor = Colors.red[300]!;
        logIcon = Icons.error;
        break;
      case 'WARNING':
        logColor = Colors.orange[300]!;
        logIcon = Icons.warning;
        break;
      case 'SUCCESS':
        logColor = Colors.green[300]!;
        logIcon = Icons.check_circle;
        break;
      case 'INFO':
        logColor = Colors.blue[300]!;
        logIcon = Icons.info;
        break;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: logColor.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            logIcon,
            color: logColor,
            size: 16,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  log.message,
                  style: TextStyle(
                    color: logColor,
                    fontSize: 12,
                    fontFamily: 'monospace',
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${log.category} • ${log.timestamp.toString().substring(11, 19)}',
                  style: TextStyle(
                    color: Colors.grey[500],
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, ThemeProvider themeProvider) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: themeProvider.theme,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: themeProvider.contrast.withOpacity(0.7),
          ),
        ),
      ],
    );
  }
}