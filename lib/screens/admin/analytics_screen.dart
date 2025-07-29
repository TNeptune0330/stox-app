import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/theme_provider.dart';
import '../../services/analytics_service.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  Map<String, dynamic> _analytics = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAnalytics();
  }

  Future<void> _loadAnalytics() async {
    setState(() => _isLoading = true);
    
    try {
      final analytics = await AnalyticsService.getFullAnalytics();
      setState(() {
        _analytics = analytics;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading analytics: $e');
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return Scaffold(
          backgroundColor: themeProvider.background,
          appBar: AppBar(
            title: const Text('User Analytics'),
            backgroundColor: themeProvider.background,
            foregroundColor: themeProvider.contrast,
            actions: [
              IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: _loadAnalytics,
                tooltip: 'Refresh Data',
              ),
            ],
          ),
          body: _isLoading
              ? Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(themeProvider.theme),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadAnalytics,
                  color: themeProvider.theme,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Overview Cards
                        _buildOverviewSection(themeProvider),
                        const SizedBox(height: 24),
                        
                        // User Stats
                        _buildUserStatsSection(themeProvider),
                        const SizedBox(height: 24),
                        
                        // Trading Activity
                        _buildTradingStatsSection(themeProvider),
                        const SizedBox(height: 24),
                        
                        // App Usage
                        _buildAppUsageSection(themeProvider),
                      ],
                    ),
                  ),
                ),
        );
      },
    );
  }

  Widget _buildOverviewSection(ThemeProvider themeProvider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Overview',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: themeProvider.contrast,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildMetricCard(
                'Total Users',
                '${_analytics['totalUsers'] ?? 0}',
                Icons.people,
                Colors.blue,
                themeProvider,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildMetricCard(
                'Active Today',
                '${_analytics['activeToday'] ?? 0}',
                Icons.person_pin,
                Colors.green,
                themeProvider,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildMetricCard(
                'New This Week',
                '${_analytics['newThisWeek'] ?? 0}',
                Icons.person_add,
                Colors.orange,
                themeProvider,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildMetricCard(
                'Total Trades',
                '${_analytics['totalTrades'] ?? 0}',
                Icons.trending_up,
                Colors.purple,
                themeProvider,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildUserStatsSection(ThemeProvider themeProvider) {
    final userGrowth = _analytics['userGrowth'] as List<dynamic>? ?? [];
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'User Statistics',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: themeProvider.contrast,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: themeProvider.backgroundHigh,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: themeProvider.theme.withOpacity(0.3),
            ),
          ),
          child: Column(
            children: [
              _buildStatRow('Daily Active Users', '${_analytics['dailyActiveUsers'] ?? 0}', themeProvider),
              _buildStatRow('Weekly Active Users', '${_analytics['weeklyActiveUsers'] ?? 0}', themeProvider),
              _buildStatRow('Monthly Active Users', '${_analytics['monthlyActiveUsers'] ?? 0}', themeProvider),
              _buildStatRow('Average Session Duration', '${_analytics['avgSessionDuration'] ?? 0}m', themeProvider),
              _buildStatRow('User Retention (7d)', '${_analytics['retention7d'] ?? 0}%', themeProvider),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTradingStatsSection(ThemeProvider themeProvider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Trading Activity',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: themeProvider.contrast,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: themeProvider.backgroundHigh,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: themeProvider.theme.withOpacity(0.3),
            ),
          ),
          child: Column(
            children: [
              _buildStatRow('Trades Today', '${_analytics['tradesToday'] ?? 0}', themeProvider),
              _buildStatRow('Total Portfolio Value', '\$${_formatNumber(_analytics['totalPortfolioValue'] ?? 0)}', themeProvider),
              _buildStatRow('Most Traded Stock', '${_analytics['mostTradedStock'] ?? 'N/A'}', themeProvider),
              _buildStatRow('Average Trade Size', '\$${_formatNumber(_analytics['avgTradeSize'] ?? 0)}', themeProvider),
              _buildStatRow('Active Traders', '${_analytics['activeTraders'] ?? 0}', themeProvider),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAppUsageSection(ThemeProvider themeProvider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'App Usage',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: themeProvider.contrast,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: themeProvider.backgroundHigh,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: themeProvider.theme.withOpacity(0.3),
            ),
          ),
          child: Column(
            children: [
              _buildStatRow('App Opens Today', '${_analytics['appOpensToday'] ?? 0}', themeProvider),
              _buildStatRow('Screen Views', '${_analytics['screenViews'] ?? 0}', themeProvider),
              _buildStatRow('Market Data Requests', '${_analytics['marketDataRequests'] ?? 0}', themeProvider),
              _buildStatRow('News Articles Viewed', '${_analytics['newsViews'] ?? 0}', themeProvider),
              _buildStatRow('Average User Rating', '${_analytics['avgRating'] ?? 0}/5 ⭐', themeProvider),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMetricCard(String title, String value, IconData icon, Color color, ThemeProvider themeProvider) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: themeProvider.backgroundHigh,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withOpacity(0.3),
        ),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: color,
              size: 24,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: themeProvider.contrast,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: themeProvider.contrast.withOpacity(0.7),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildStatRow(String label, String value, ThemeProvider themeProvider) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: themeProvider.contrast.withOpacity(0.8),
            ),
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

  String _formatNumber(dynamic number) {
    if (number == null) return '0';
    final num = double.tryParse(number.toString()) ?? 0;
    
    if (num >= 1000000) {
      return '${(num / 1000000).toStringAsFixed(1)}M';
    } else if (num >= 1000) {
      return '${(num / 1000).toStringAsFixed(1)}K';
    } else {
      return num.toStringAsFixed(0);
    }
  }
}