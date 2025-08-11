import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import 'dart:convert';
import '../../providers/market_data_provider.dart';
import '../../providers/portfolio_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/achievement_provider.dart';
import '../../theme/modern_theme.dart';
import '../../models/market_asset_model.dart';
import '../../widgets/animations/animations.dart';
import '../../services/stock_descriptions_service.dart';
import '../../config/api_keys.dart';

class StockDetailScreen extends StatefulWidget {
  final MarketAssetModel asset;
  
  const StockDetailScreen({
    super.key,
    required this.asset,
  });

  @override
  State<StockDetailScreen> createState() => _StockDetailScreenState();
}

class _StockDetailScreenState extends State<StockDetailScreen>
    with TickerProviderStateMixin {
  String _selectedTimeframe = '1D';
  final List<String> _timeframes = ['1D', '1W', '1M', '3M', '1Y'];
  
  // Data
  String? _companyDescription;
  List<Map<String, dynamic>> _newsArticles = [];
  List<FlSpot> _chartData = [];
  bool _isLoadingData = true;
  
  // Local copy of asset data that can be updated
  late MarketAssetModel _currentAsset;
  
  // Animation controllers
  late AnimationController _slideController;
  late AnimationController _fadeController;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _currentAsset = widget.asset; // Initialize with the passed asset
    _initializeAnimations();
    _loadStockData();
  }

  void _initializeAnimations() {
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    ));

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    ));

    // Start animations
    _slideController.forward();
    _fadeController.forward();
  }

  @override
  void dispose() {
    _slideController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  Future<void> _loadStockData() async {
    // First refresh the market data for this symbol
    await _refreshMarketData();
    
    await Future.wait([
      _loadCompanyProfile(),
      _loadNews(),
      _generateChartData(),
    ]);
    
    if (mounted) {
      setState(() {
        _isLoadingData = false;
      });
    }
  }
  
  Future<void> _refreshMarketData() async {
    try {
      print('📊 StockDetailScreen: Refreshing market data for ${widget.asset.symbol}');
      
      // Fetch basic quote data
      final quoteResponse = await http.get(
        Uri.parse('https://finnhub.io/api/v1/quote?symbol=${widget.asset.symbol}&token=${ApiKeys.finnhubApiKey}'),
      );
      
      double? weekHigh52;
      double? weekLow52;
      
      // Fetch 52-week high/low from metrics endpoint
      try {
        final metricsResponse = await http.get(
          Uri.parse('https://finnhub.io/api/v1/stock/metric?symbol=${widget.asset.symbol}&metric=all&token=${ApiKeys.finnhubApiKey}'),
        );
        
        if (metricsResponse.statusCode == 200) {
          final metricsData = json.decode(metricsResponse.body);
          if (metricsData != null && metricsData['metric'] != null) {
            weekHigh52 = (metricsData['metric']['52WeekHigh'] as num?)?.toDouble();
            weekLow52 = (metricsData['metric']['52WeekLow'] as num?)?.toDouble();
            print('📊 StockDetailScreen: 52W High: ${weekHigh52?.toStringAsFixed(2)}, 52W Low: ${weekLow52?.toStringAsFixed(2)}');
          }
        }
      } catch (e) {
        print('⚠️ StockDetailScreen: Could not fetch 52-week data: $e');
      }
      
      if (quoteResponse.statusCode == 200) {
        final data = json.decode(quoteResponse.body);
        if (data != null && data['c'] != null) {
          final currentPrice = (data['c'] as num).toDouble();
          final change = (data['d'] as num?)?.toDouble() ?? 0.0;
          final changePercent = (data['dp'] as num?)?.toDouble() ?? 0.0;
          final high = (data['h'] as num?)?.toDouble() ?? currentPrice;
          final low = (data['l'] as num?)?.toDouble() ?? currentPrice;
          final open = (data['o'] as num?)?.toDouble() ?? currentPrice;
          final previousClose = (data['pc'] as num?)?.toDouble() ?? currentPrice;
          
          if (mounted) {
            setState(() {
              // Update the local asset copy with fresh values
              _currentAsset = _currentAsset.copyWith(
                price: currentPrice,
                change: change,
                changePercent: changePercent,
                dayHigh: high,
                dayLow: low,
                weekHigh52: weekHigh52,
                weekLow52: weekLow52,
                lastUpdated: DateTime.now(),
              );
            });
          }
          
          print('📊 StockDetailScreen: Updated ${widget.asset.symbol} - Price: \$${currentPrice.toStringAsFixed(2)}, Change: ${change >= 0 ? '+' : ''}${change.toStringAsFixed(2)} (${changePercent.toStringAsFixed(2)}%)');
        }
      } else {
        print('❌ StockDetailScreen: Failed to refresh market data for ${widget.asset.symbol}: ${quoteResponse.statusCode}');
      }
    } catch (e) {
      print('❌ StockDetailScreen: Error refreshing market data for ${widget.asset.symbol}: $e');
    }
  }

  Future<void> _loadCompanyProfile() async {
    try {
      // First try to get description from the local service
      final localDescription = StockDescriptionsService.getDescription(widget.asset.symbol);
      
      if (mounted) {
        setState(() {
          _companyDescription = localDescription;
        });
      }
      
      print('📋 StockDetailScreen: Loaded description for ${widget.asset.symbol}: ${localDescription.substring(0, 50)}...');
      
      // Optionally try Finnhub as well for additional data (but don't override if local description exists)
      if (_companyDescription == null || _companyDescription!.contains('A publicly traded company that operates')) {
        try {
          final response = await http.get(
            Uri.parse('https://finnhub.io/api/v1/stock/profile2?symbol=${widget.asset.symbol}&token=${ApiKeys.finnhubApiKey}'),
          );
          
          if (response.statusCode == 200) {
            final data = json.decode(response.body);
            if (mounted && data != null && data['description'] != null && data['description'].toString().trim().isNotEmpty) {
              setState(() {
                _companyDescription = data['description'];
              });
              print('📋 StockDetailScreen: Updated with Finnhub description for ${widget.asset.symbol}');
            }
          }
        } catch (e) {
          print('⚠️ Finnhub API call failed, using local description: $e');
        }
      }
    } catch (e) {
      print('Error loading company profile: $e');
      // Fallback to a generic description
      if (mounted) {
        setState(() {
          _companyDescription = 'Company information not available at this time.';
        });
      }
    }
  }

  Future<void> _loadNews() async {
    try {
      final toDate = DateTime.now();
      final fromDate = toDate.subtract(const Duration(days: 7));
      
      final response = await http.get(
        Uri.parse('https://finnhub.io/api/v1/company-news?symbol=${widget.asset.symbol}&from=${fromDate.toIso8601String().split('T')[0]}&to=${toDate.toIso8601String().split('T')[0]}&token=${ApiKeys.finnhubApiKey}'),
      );
      
      if (response.statusCode == 200) {
        final List<dynamic> articles = json.decode(response.body);
        if (mounted) {
          setState(() {
            _newsArticles = articles.take(5).map((article) => {
              'headline': article['headline'] ?? 'No headline',
              'summary': article['summary'] ?? 'No summary available',
              'url': article['url'] ?? '',
              'datetime': article['datetime'] ?? 0,
              'source': article['source'] ?? 'Unknown',
              'image': article['image'] ?? '',
            }).toList();
          });
        }
      }
    } catch (e) {
      print('Error loading news: \$e');
    }
  }

  Future<void> _generateChartData() async {
    await _loadHistoricalData();
  }

  Future<void> _loadHistoricalData() async {
    // Historical data not available - show message instead of chart
    if (mounted) {
      setState(() {
        _chartData = []; // Empty chart data
        _isLoadingData = false;
      });
    }
  }

  (DateTime, String) _getTimeframeParams(String timeframe) {
    final now = DateTime.now();
    switch (timeframe) {
      case '1D':
        return (now.subtract(const Duration(days: 1)), '5'); // 5-minute resolution
      case '1W':
        return (now.subtract(const Duration(days: 7)), '15'); // 15-minute resolution
      case '1M':
        return (now.subtract(const Duration(days: 30)), '60'); // 1-hour resolution
      case '3M':
        return (now.subtract(const Duration(days: 90)), 'D'); // daily resolution
      case '1Y':
        return (now.subtract(const Duration(days: 365)), 'D'); // daily resolution
      default:
        return (now.subtract(const Duration(days: 1)), '5');
    }
  }

  void _generateFallbackChartData() {
    final currentPrice = _currentAsset.price;
    final change = _currentAsset.change;
    
    final dataPoints = <FlSpot>[];
    final basePrice = currentPrice - change;
    final pointCount = _selectedTimeframe == '1D' ? 78 : _selectedTimeframe == '1W' ? 168 : 720; // More realistic data points
    
    // Create a more realistic price movement simulation
    double previousPrice = basePrice;
    final volatility = currentPrice * 0.02; // 2% volatility
    
    for (int i = 0; i < pointCount; i++) {
      // Add some random walk behavior
      final randomChange = (DateTime.now().millisecondsSinceEpoch + i) % 1000 / 1000.0 - 0.5;
      final priceChange = randomChange * volatility * 0.1;
      
      // Gradually trend towards the current price
      final progressTowardCurrent = change * (i / pointCount);
      final price = previousPrice + priceChange + (progressTowardCurrent * 0.1);
      
      dataPoints.add(FlSpot(i.toDouble(), price));
      previousPrice = price;
    }
    
    // Ensure the last point is close to the current price
    if (dataPoints.isNotEmpty) {
      dataPoints.last = FlSpot(dataPoints.last.x, currentPrice);
    }
    
    setState(() {
      _chartData = dataPoints;
      _isLoadingData = false;
    });
    
    print('📈 Generated realistic fallback chart data: ${dataPoints.length} points from \$${dataPoints.first.y.toStringAsFixed(2)} to \$${dataPoints.last.y.toStringAsFixed(2)}');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ModernTheme.backgroundPrimary,
      resizeToAvoidBottomInset: false,
      body: SlideTransition(
        position: _slideAnimation,
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: CustomScrollView(
            slivers: [
              _buildAnimatedAppBar(),
              _buildPriceSection(),
              _buildChartSection(),
              if (_companyDescription != null) _buildDescriptionSection(),
              _buildMarketDataSection(),
              _buildTradeButton(),
              if (_newsArticles.isNotEmpty) _buildNewsSection(),
              const SliverToBoxAdapter(child: SizedBox(height: 100)), // Bottom padding
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAnimatedAppBar() {
    return SliverAppBar(
      expandedHeight: 120,
      floating: true,
      pinned: true,
      backgroundColor: ModernTheme.backgroundPrimary,
      foregroundColor: ModernTheme.textPrimary,
      elevation: 0,
      surfaceTintColor: Colors.transparent,
      leading: Microinteractions.animatedButton(
        onPressed: () => Navigator.pop(context),
        child: Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: ModernTheme.backgroundCard,
            borderRadius: BorderRadius.circular(12),
            boxShadow: ModernTheme.shadowCard,
          ),
          child: const Icon(Icons.arrow_back, size: 20),
        ),
      ),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _currentAsset.symbol,
            style: ModernTheme.headlineMedium.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            _currentAsset.name,
            style: ModernTheme.bodySmall.copyWith(
              color: ModernTheme.textMuted,
            ),
          ),
        ],
      ),
      actions: [
        Consumer<PortfolioProvider>(
          builder: (context, portfolioProvider, child) {
            final isInWatchlist = portfolioProvider.isInWatchlist(widget.asset.symbol);
            
            return Microinteractions.animatedButton(
              onPressed: () => _toggleWatchlist(portfolioProvider, isInWatchlist),
              child: Container(
                margin: const EdgeInsets.only(right: 16),
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isInWatchlist ? ModernTheme.accentGreen : ModernTheme.backgroundCard,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: ModernTheme.shadowCard,
                ),
                child: Icon(
                  isInWatchlist ? Icons.favorite : Icons.favorite_border, 
                  size: 20,
                  color: isInWatchlist ? Colors.white : ModernTheme.textPrimary,
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildPriceSection() {
    return SliverToBoxAdapter(
      child: AnimatedPageWrapper(
        child: Container(
          padding: const EdgeInsets.all(ModernTheme.spaceL),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '\$${_currentAsset.price.toStringAsFixed(2)}',
                    style: ModernTheme.displayMedium.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: ModernTheme.spaceM),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: (_currentAsset.change >= 0 ? ModernTheme.accentGreen : ModernTheme.accentRed).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: _currentAsset.change >= 0 ? ModernTheme.accentGreen : ModernTheme.accentRed,
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _currentAsset.change >= 0 ? Icons.trending_up : Icons.trending_down,
                          size: 16,
                          color: _currentAsset.change >= 0 ? ModernTheme.accentGreen : ModernTheme.accentRed,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${_currentAsset.change >= 0 ? '+' : ''}\$${_currentAsset.change.toStringAsFixed(2)} (${_currentAsset.changePercent.toStringAsFixed(2)}%)',
                          style: ModernTheme.bodyMedium.copyWith(
                            color: _currentAsset.change >= 0 ? ModernTheme.accentGreen : ModernTheme.accentRed,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Last updated: ${DateTime.now().toString().substring(11, 16)}',
                style: ModernTheme.bodySmall.copyWith(
                  color: ModernTheme.textMuted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildChartSection() {
    return SliverToBoxAdapter(
      child: AnimatedPageWrapper(
        animationDelay: const Duration(milliseconds: 200),
        child: Container(
          margin: const EdgeInsets.all(ModernTheme.spaceL),
          padding: const EdgeInsets.all(ModernTheme.spaceL),
          decoration: BoxDecoration(
            color: ModernTheme.backgroundCard,
            borderRadius: BorderRadius.circular(ModernTheme.radiusL),
            boxShadow: ModernTheme.shadowCard,
          ),
          child: Column(
            children: [
              // Timeframe Selection
              Row(
                children: _timeframes.map((timeframe) {
                  final isSelected = _selectedTimeframe == timeframe;
                  return Expanded(
                    child: Microinteractions.animatedButton(
                      onPressed: () {
                        setState(() => _selectedTimeframe = timeframe);
                        _loadHistoricalData(); // Reload data for new timeframe
                      },
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        decoration: BoxDecoration(
                          color: isSelected ? ModernTheme.accentBlue : Colors.transparent,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          timeframe,
                          textAlign: TextAlign.center,
                          style: ModernTheme.bodyMedium.copyWith(
                            color: isSelected ? Colors.white : ModernTheme.textMuted,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              
              const SizedBox(height: ModernTheme.spaceL),
              
              // Chart
              SizedBox(
                height: 200,
                child: _isLoadingData ? _buildLoadingChart() : _buildLineChart(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingChart() {
    return CustomLoadingIndicators.shimmerCard(
      height: 200,
      borderRadius: BorderRadius.circular(ModernTheme.radiusL),
    );
  }

  Widget _buildLineChart() {
    if (_chartData.isEmpty) {
      return Container(
        decoration: BoxDecoration(
          color: ModernTheme.backgroundCard.withOpacity(0.3),
          borderRadius: BorderRadius.circular(ModernTheme.radiusM),
          border: Border.all(color: ModernTheme.textMuted.withOpacity(0.3)),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.info_outline, size: 40, color: ModernTheme.textMuted),
              const SizedBox(height: 12),
              Text(
                'Historical Data Not Available',
                style: ModernTheme.bodyLarge.copyWith(
                  fontWeight: FontWeight.w600,
                  color: ModernTheme.textMuted,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Current price: \$${_currentAsset.price.toStringAsFixed(2)}',
                style: ModernTheme.titleMedium.copyWith(
                  fontWeight: FontWeight.bold,
                  color: _currentAsset.change >= 0 ? ModernTheme.accentGreen : ModernTheme.accentRed,
                ),
              ),
            ],
          ),
        ),
      );
    }

    final isPositive = _currentAsset.change >= 0;
    final lineColor = isPositive ? ModernTheme.accentGreen : ModernTheme.accentRed;

    // Calculate min and max values for better scaling
    final minY = _chartData.map((e) => e.y).reduce((a, b) => a < b ? a : b);
    final maxY = _chartData.map((e) => e.y).reduce((a, b) => a > b ? a : b);
    final range = maxY - minY;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(ModernTheme.radiusM),
        color: const Color(0xFF1E1E1E), // Dark background for professional look
        border: Border.all(color: ModernTheme.textMuted.withOpacity(0.2), width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: LineChart(
          LineChartData(
            minX: 0,
            maxX: 23,
            minY: minY - (range * 0.02),
            maxY: maxY + (range * 0.02),
            gridData: FlGridData(
              show: true,
              drawVerticalLine: false, // Remove vertical lines for cleaner look
              drawHorizontalLine: true,
              horizontalInterval: (range / 4).clamp(0.01, double.infinity),
              getDrawingHorizontalLine: (value) => FlLine(
                color: ModernTheme.textMuted.withOpacity(0.2),
                strokeWidth: 0.5,
                dashArray: [5, 5], // Dashed lines like traditional charts
              ),
            ),
            titlesData: FlTitlesData(
              show: true,
              rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 45,
                  interval: (range / 2).clamp(0.01, double.infinity),
                  getTitlesWidget: (value, meta) => Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: Text(
                      '\$${value.toStringAsFixed(1)}',
                      style: ModernTheme.bodySmall.copyWith(
                        color: ModernTheme.textMuted,
                        fontSize: 10,
                      ),
                    ),
                  ),
                ),
              ),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 25,
                  interval: 6,
                  getTitlesWidget: (value, meta) {
                    final hour = value.toInt();
                    return Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Text(
                        '${hour.toString().padLeft(2, '0')}:00',
                        style: ModernTheme.bodySmall.copyWith(
                          color: ModernTheme.textMuted,
                          fontSize: 10,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
            borderData: FlBorderData(
              show: true,
              border: Border(
                left: BorderSide(
                  color: ModernTheme.textMuted.withOpacity(0.3),
                  width: 1,
                ),
                bottom: BorderSide(
                  color: ModernTheme.textMuted.withOpacity(0.3),
                  width: 1,
                ),
              ),
            ),
            lineBarsData: [
              LineChartBarData(
                spots: _chartData,
                isCurved: true,
                curveSmoothness: 0.15, // Slightly less smooth for more realistic look
                gradient: LinearGradient(
                  colors: [
                    lineColor,
                    lineColor.withOpacity(0.8),
                  ],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
                barWidth: 3.0, // Slightly thicker line
                isStrokeCapRound: true,
                dotData: FlDotData(show: false),
                belowBarData: BarAreaData(
                  show: true,
                  gradient: LinearGradient(
                    colors: [
                      lineColor.withOpacity(0.12),
                      lineColor.withOpacity(0.04),
                      Colors.transparent,
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
              ),
            ],
            lineTouchData: LineTouchData(
              enabled: true,
              touchTooltipData: LineTouchTooltipData(
                getTooltipColor: (touchedSpot) => const Color(0xFF2A2A2A),
                tooltipRoundedRadius: 6,
                tooltipPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                fitInsideHorizontally: true,
                fitInsideVertically: true,
                getTooltipItems: (touchedSpots) {
                  return touchedSpots.map((spot) {
                    final hour = spot.x.toInt();
                    return LineTooltipItem(
                      '\$${spot.y.toStringAsFixed(2)}',
                      TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                      children: [
                        TextSpan(
                          text: '\n${hour.toString().padLeft(2, '0')}:00',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.7),
                            fontWeight: FontWeight.normal,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    );
                  }).toList();
                },
              ),
              touchCallback: (FlTouchEvent event, LineTouchResponse? touchResponse) {
                if (event is FlTapUpEvent && touchResponse?.lineBarSpots?.isNotEmpty == true) {
                  HapticFeedback.lightImpact();
                }
              },
              getTouchedSpotIndicator: (LineChartBarData barData, List<int> spotIndexes) {
                return spotIndexes.map((spotIndex) {
                  return TouchedSpotIndicatorData(
                    FlLine(
                      color: Colors.white.withOpacity(0.6),
                      strokeWidth: 1.5,
                      dashArray: [4, 2],
                    ),
                    FlDotData(
                      show: true,
                      getDotPainter: (spot, percent, barData, index) {
                        return FlDotCirclePainter(
                          radius: 6,
                          color: const Color(0xFF2A2A2A),
                          strokeWidth: 2.5,
                          strokeColor: lineColor,
                        );
                      },
                    ),
                  );
                }).toList();
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDescriptionSection() {
    return SliverToBoxAdapter(
      child: AnimatedPageWrapper(
        animationDelay: const Duration(milliseconds: 400),
        child: Container(
          margin: const EdgeInsets.all(ModernTheme.spaceL),
          padding: const EdgeInsets.all(ModernTheme.spaceL),
          decoration: BoxDecoration(
            color: ModernTheme.backgroundCard,
            borderRadius: BorderRadius.circular(ModernTheme.radiusL),
            boxShadow: ModernTheme.shadowCard,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.info_outline, color: ModernTheme.accentBlue, size: 24),
                  const SizedBox(width: 12),
                  Text(
                    'About ${_currentAsset.name}',
                    style: ModernTheme.titleLarge.copyWith(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: ModernTheme.spaceS),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: ModernTheme.accentBlue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: ModernTheme.accentBlue.withOpacity(0.3),
                  ),
                ),
                child: Text(
                  StockDescriptionsService.getCompanyType(_currentAsset.symbol),
                  style: ModernTheme.bodySmall.copyWith(
                    color: ModernTheme.accentBlue,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(height: ModernTheme.spaceM),
              Text(
                _companyDescription!,
                style: ModernTheme.bodyMedium.copyWith(height: 1.6),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNewsSection() {
    return SliverToBoxAdapter(
      child: AnimatedPageWrapper(
        animationDelay: const Duration(milliseconds: 600),
        child: Container(
          margin: const EdgeInsets.all(ModernTheme.spaceL),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.article_outlined, color: ModernTheme.accentOrange, size: 24),
                  const SizedBox(width: 12),
                  Text(
                    'Latest News',
                    style: ModernTheme.titleLarge.copyWith(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: ModernTheme.spaceM),
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _newsArticles.length,
                separatorBuilder: (context, index) => const SizedBox(height: ModernTheme.spaceM),
                itemBuilder: (context, index) => _buildNewsCard(_newsArticles[index]),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNewsCard(Map<String, dynamic> article) {
    return Microinteractions.animatedButton(
      onPressed: () async {
        final String url = article['url'] as String;
        if (url.isNotEmpty) {
          try {
            final Uri uri = Uri.parse(url);
            if (await canLaunchUrl(uri)) {
              await launchUrl(
                uri,
                mode: LaunchMode.externalApplication,
              );
            } else {
              throw Exception('Could not launch URL');
            }
          } catch (e) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Row(
                    children: [
                      Icon(Icons.error_outline, color: Colors.white),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text('Could not open article: $e'),
                      ),
                    ],
                  ),
                  backgroundColor: ModernTheme.accentRed,
                  behavior: SnackBarBehavior.floating,
                ),
              );
            }
          }
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.white),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text('No URL available for this article'),
                    ),
                  ],
                ),
                backgroundColor: ModernTheme.accentOrange,
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        }
      },
      child: Container(
        padding: const EdgeInsets.all(ModernTheme.spaceM),
        decoration: BoxDecoration(
          color: ModernTheme.backgroundCard,
          borderRadius: BorderRadius.circular(ModernTheme.radiusL),
          boxShadow: ModernTheme.shadowCard,
          border: Border.all(color: ModernTheme.borderLight),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: ModernTheme.accentOrange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    article['source'],
                    style: ModernTheme.bodySmall.copyWith(
                      color: ModernTheme.accentOrange,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const Spacer(),
                Text(
                  _formatDate(article['datetime']),
                  style: ModernTheme.bodySmall.copyWith(color: ModernTheme.textMuted),
                ),
              ],
            ),
            const SizedBox(height: ModernTheme.spaceS),
            Text(
              article['headline'],
              style: ModernTheme.titleMedium.copyWith(fontWeight: FontWeight.bold),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: ModernTheme.spaceS),
            Text(
              article['summary'],
              style: ModernTheme.bodyMedium.copyWith(color: ModernTheme.textSecondary),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMarketDataSection() {
    return SliverToBoxAdapter(
      child: AnimatedPageWrapper(
        animationDelay: const Duration(milliseconds: 800),
        child: Container(
          margin: const EdgeInsets.all(ModernTheme.spaceL),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Market Data',
                style: ModernTheme.titleLarge.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: ModernTheme.spaceM),
              _buildMarketDataGrid(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMarketDataGrid() {
    // Debug log to check what data is available
    print('🔍 StockDetailScreen: Market data for ${widget.asset.symbol}:');
    print('   Current Price: \$${_currentAsset.price.toStringAsFixed(2)}');
    print('   Change: ${_currentAsset.change >= 0 ? '+' : ''}\$${_currentAsset.change.toStringAsFixed(2)}');
    print('   Change %: ${_currentAsset.changePercent >= 0 ? '+' : ''}${_currentAsset.changePercent.toStringAsFixed(2)}%');
    print('   Day High: ${_currentAsset.dayHigh != null ? '\$${_currentAsset.dayHigh!.toStringAsFixed(2)}' : 'NULL'}');
    print('   Day Low: ${_currentAsset.dayLow != null ? '\$${_currentAsset.dayLow!.toStringAsFixed(2)}' : 'NULL'}');
    print('   52W High: ${_currentAsset.weekHigh52 != null ? '\$${_currentAsset.weekHigh52!.toStringAsFixed(2)}' : 'NULL'}');
    print('   52W Low: ${_currentAsset.weekLow52 != null ? '\$${_currentAsset.weekLow52!.toStringAsFixed(2)}' : 'NULL'}');
    print('   Exchange: ${_currentAsset.exchange ?? 'NULL'}');
    
    final marketData = [
      {'label': 'Current Price', 'value': '\$${_currentAsset.price.toStringAsFixed(2)}'},
      {'label': 'Change', 'value': '${_currentAsset.change >= 0 ? '+' : ''}\$${_currentAsset.change.toStringAsFixed(2)}'},
      {'label': 'Change %', 'value': '${_currentAsset.changePercent >= 0 ? '+' : ''}${_currentAsset.changePercent.toStringAsFixed(2)}%'},
      {'label': 'Day High', 'value': _currentAsset.dayHigh != null ? '\$${_currentAsset.dayHigh!.toStringAsFixed(2)}' : 'Unavailable'},
      {'label': 'Day Low', 'value': _currentAsset.dayLow != null ? '\$${_currentAsset.dayLow!.toStringAsFixed(2)}' : 'Unavailable'},
      {'label': '52W High', 'value': _currentAsset.weekHigh52 != null ? '\$${_currentAsset.weekHigh52!.toStringAsFixed(2)}' : 'Unavailable'},
      {'label': '52W Low', 'value': _currentAsset.weekLow52 != null ? '\$${_currentAsset.weekLow52!.toStringAsFixed(2)}' : 'Unavailable'},
      {'label': 'Exchange', 'value': _currentAsset.exchange ?? 'NASDAQ'},
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 2.4, // Increased aspect ratio to prevent overflow
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
      ),
      itemCount: marketData.length,
      itemBuilder: (context, index) {
        final data = marketData[index];
        return HoverEffects.scaleOnHover(
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: ModernTheme.backgroundCard,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  data['label']!,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: ModernTheme.textMuted,
                    letterSpacing: 0.5,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  data['value']!,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: ModernTheme.textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildTradeButton() {
    return SliverToBoxAdapter(
      child: AnimatedPageWrapper(
        animationDelay: const Duration(milliseconds: 1000),
        child: Container(
          padding: const EdgeInsets.all(ModernTheme.spaceL),
          child: Microinteractions.animatedButton(
            onPressed: () => _showTradeDialog(context),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: ModernTheme.spaceL),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [ModernTheme.accentGreen, ModernTheme.accentGreen.withOpacity(0.8)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(ModernTheme.radiusL),
                boxShadow: [
                  BoxShadow(
                    color: ModernTheme.accentGreen.withOpacity(0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.trending_up, color: Colors.white, size: 24),
                  const SizedBox(width: 12),
                  Text(
                    'Trade ${widget.asset.symbol}',
                    style: ModernTheme.titleLarge.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _toggleWatchlist(PortfolioProvider portfolioProvider, bool isInWatchlist) async {
    if (isInWatchlist) {
      await portfolioProvider.removeFromWatchlist(widget.asset.symbol);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Removed ${widget.asset.symbol} from watchlist'),
            backgroundColor: ModernTheme.accentRed,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } else {
      await portfolioProvider.addToWatchlist(widget.asset.symbol);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Added ${widget.asset.symbol} to watchlist'),
            backgroundColor: ModernTheme.accentGreen,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _showTradeDialog(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    
    if (authProvider.user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please sign in to trade'),
          backgroundColor: ModernTheme.accentRed,
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => _buildTradeDialog(),
    );
  }

  Widget _buildTradeDialog() {
    return _TradeDialogWidget(asset: _currentAsset);
  }


  String _formatDate(int timestamp) {
    if (timestamp == 0) return 'Unknown';
    final date = DateTime.fromMillisecondsSinceEpoch(timestamp * 1000);
    final now = DateTime.now();
    final difference = now.difference(date).inHours;
    
    if (difference < 1) {
      return 'Just now';
    } else if (difference < 24) {
      return '${difference}h ago';
    } else {
      return '${difference ~/ 24}d ago';
    }
  }
}

// Add AnimatedPageWrapper extension
class AnimatedPageWrapper extends StatefulWidget {
  final Widget child;
  final Duration animationDelay;

  const AnimatedPageWrapper({
    super.key,
    required this.child,
    this.animationDelay = Duration.zero,
  });

  @override
  State<AnimatedPageWrapper> createState() => _AnimatedPageWrapperState();
}

class _AnimatedPageWrapperState extends State<AnimatedPageWrapper>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    ));

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    ));

    Future.delayed(widget.animationDelay, () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SlideTransition(
      position: _slideAnimation,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: widget.child,
      ),
    );
  }
}

class _TradeDialogWidget extends StatefulWidget {
  final MarketAssetModel asset;
  
  const _TradeDialogWidget({required this.asset});
  
  @override
  State<_TradeDialogWidget> createState() => _TradeDialogWidgetState();
}

class _TradeDialogWidgetState extends State<_TradeDialogWidget> {
  final TextEditingController quantityController = TextEditingController(text: '1');
  int currentQuantity = 1;
  
  @override
  void initState() {
    super.initState();
    quantityController.addListener(_updateQuantity);
  }
  
  @override
  void dispose() {
    quantityController.dispose();
    super.dispose();
  }
  
  void _updateQuantity() {
    final quantity = int.tryParse(quantityController.text) ?? 0;
    setState(() {
      currentQuantity = quantity;
    });
  }
  
  double get totalCost => widget.asset.price * currentQuantity;
  
  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: AnimatedPageWrapper(
        child: Container(
          padding: const EdgeInsets.all(ModernTheme.spaceL),
          decoration: BoxDecoration(
            color: ModernTheme.backgroundCard,
            borderRadius: BorderRadius.circular(ModernTheme.radiusXL),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [ModernTheme.accentBlue, ModernTheme.accentPurple],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(ModernTheme.radiusM),
                    ),
                    child: Center(
                      child: Text(
                        widget.asset.symbol.substring(0, 1),
                        style: ModernTheme.titleLarge.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: ModernTheme.spaceM),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.asset.symbol,
                          style: ModernTheme.titleLarge.copyWith(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          widget.asset.name,
                          style: ModernTheme.bodyMedium.copyWith(color: ModernTheme.textMuted),
                        ),
                      ],
                    ),
                  ),
                  Microinteractions.animatedButton(
                    onPressed: () => Navigator.pop(context),
                    child: Icon(Icons.close, color: ModernTheme.textMuted),
                  ),
                ],
              ),
              
              const SizedBox(height: ModernTheme.spaceXL),
              
              // Price Information Section
              Container(
                padding: const EdgeInsets.all(ModernTheme.spaceM),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      ModernTheme.accentBlue.withOpacity(0.1),
                      ModernTheme.accentPurple.withOpacity(0.1),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(ModernTheme.radiusM),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Price per share:', style: ModernTheme.bodyLarge),
                        Text(
                          '\$${widget.asset.price.toStringAsFixed(2)}',
                          style: ModernTheme.titleLarge.copyWith(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: ModernTheme.spaceS),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Quantity:', style: ModernTheme.bodyLarge),
                        Text(
                          '$currentQuantity shares',
                          style: ModernTheme.titleMedium.copyWith(fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                    const Divider(height: ModernTheme.spaceL),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Total Cost:',
                          style: ModernTheme.titleMedium.copyWith(
                            fontWeight: FontWeight.bold,
                            color: ModernTheme.accentGreen,
                          ),
                        ),
                        Text(
                          '\$${totalCost.toStringAsFixed(2)}',
                          style: ModernTheme.titleLarge.copyWith(
                            fontWeight: FontWeight.bold,
                            color: ModernTheme.accentGreen,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: ModernTheme.spaceL),
              
              TextField(
                controller: quantityController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Quantity',
                  hintText: 'Enter number of shares',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(ModernTheme.radiusM),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(ModernTheme.radiusM),
                    borderSide: BorderSide(color: ModernTheme.accentBlue, width: 2),
                  ),
                ),
              ),
              
              const SizedBox(height: ModernTheme.spaceXL),
              
              SizedBox(
                width: double.infinity,
                child: Microinteractions.animatedButton(
                  onPressed: currentQuantity > 0 ? () => _executeTrade(context, quantityController.text) : null,
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: ModernTheme.spaceM),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: currentQuantity > 0 
                          ? [ModernTheme.accentGreen, ModernTheme.accentGreen.withOpacity(0.8)]
                          : [Colors.grey, Colors.grey.withOpacity(0.8)],
                      ),
                      borderRadius: BorderRadius.circular(ModernTheme.radiusM),
                    ),
                    child: Center(
                      child: Text(
                        'BUY SHARES',
                        style: ModernTheme.titleMedium.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  void _executeTrade(BuildContext context, String quantityText) async {
    final quantity = int.tryParse(quantityText);
    if (quantity == null || quantity <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please enter a valid quantity'),
          backgroundColor: ModernTheme.accentRed,
        ),
      );
      return;
    }

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (authProvider.user?.id == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please sign in to trade'),
          backgroundColor: ModernTheme.accentRed,
        ),
      );
      return;
    }

    try {
      final portfolioProvider = Provider.of<PortfolioProvider>(context, listen: false);
      final achievementProvider = Provider.of<AchievementProvider>(context, listen: false);
      
      final success = await portfolioProvider.executeTrade(
        userId: authProvider.user!.id,
        symbol: widget.asset.symbol,
        type: 'buy',
        quantity: quantity,
        price: widget.asset.price,
        achievementProvider: achievementProvider,
      );

      if (context.mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              success 
                ? 'Successfully bought $quantity shares of ${widget.asset.symbol} for \$${totalCost.toStringAsFixed(2)}'
                : portfolioProvider.error ?? 'Trade failed',
            ),
            backgroundColor: success ? ModernTheme.accentGreen : ModernTheme.accentRed,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: ModernTheme.accentRed,
          ),
        );
      }
    }
  }
}