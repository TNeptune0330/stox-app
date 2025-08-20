import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/market_asset_model.dart';
import '../../models/portfolio_model.dart';
import '../../providers/theme_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/portfolio_provider.dart';
import '../../services/enhanced_market_data_service.dart';
import '../../services/stock_descriptions_service.dart';
import '../../services/financial_news_service.dart';
import 'trade_dialog.dart';

class AssetDetailScreen extends StatefulWidget {
  final MarketAssetModel asset;
  final bool isHolding;
  final PortfolioModel? holdingDetails;

  const AssetDetailScreen({
    super.key,
    required this.asset,
    this.isHolding = false,
    this.holdingDetails,
  });

  @override
  State<AssetDetailScreen> createState() => _AssetDetailScreenState();
}

class _AssetDetailScreenState extends State<AssetDetailScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = false;
  String _selectedTimeframe = '1D';
  List<FlSpot> _priceData = [];
  Map<String, dynamic>? _fundamentals;
  bool _isLoadingFundamentals = true;
  List<NewsArticle> _newsArticles = [];
  bool _isLoadingNews = false;

  final List<String> _timeframes = ['1D', '1W', '1M', '3M', '1Y'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadChartData();
    _loadFundamentals();
    _loadNews();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadChartData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final chartData = await EnhancedMarketDataService.getHistoricalData(
        widget.asset.symbol,
        _selectedTimeframe,
      );

      setState(() {
        _priceData = chartData.asMap().entries.map((entry) {
          return FlSpot(entry.key.toDouble(), entry.value.close);
        }).toList();
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading chart data: $e');
      setState(() {
        _priceData = [];
        _isLoading = false;
      });
    }
  }

  Future<void> _loadFundamentals() async {
    try {
      final fundamentalData = await EnhancedMarketDataService.getFundamentalData(widget.asset.symbol);
      
      if (mounted) {
        setState(() {
          _fundamentals = fundamentalData;
          _isLoadingFundamentals = false;
        });
      }
    } catch (e) {
      print('Error loading fundamentals for ${widget.asset.symbol}: $e');
      setState(() {
        _fundamentals = null;
        _isLoadingFundamentals = false;
      });
    }
  }

  Future<void> _loadNews() async {
    setState(() {
      _isLoadingNews = true;
    });

    try {
      _newsArticles = await FinancialNewsService.getNews(
        symbol: widget.asset.symbol,
        limit: 10,
      );
    } catch (e) {
      print('Error loading news: $e');
      _newsArticles = [];
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingNews = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        final isPositive = widget.asset.changePercent >= 0;
        final changeColor = isPositive ? const Color(0xFF22C55E) : const Color(0xFFEF4444);
        
        return Scaffold(
          backgroundColor: themeProvider.background,
          body: SingleChildScrollView(
            child: Column(
              children: [
                // Header with back button and notifications
                Container(
                  padding: EdgeInsets.only(
                    top: MediaQuery.of(context).padding.top + 8,
                    left: 16,
                    right: 16,
                    bottom: 16,
                  ),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.of(context).pop(),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: themeProvider.backgroundHigh,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            Icons.arrow_back_ios,
                            color: themeProvider.contrast,
                            size: 20,
                          ),
                        ),
                      ),
                      const Spacer(),
                      Text(
                        'Detail',
                        style: TextStyle(
                          color: themeProvider.contrast,
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: themeProvider.backgroundHigh,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          Icons.notifications_outlined,
                          color: themeProvider.contrast,
                          size: 20,
                        ),
                      ),
                    ],
                  ),
                ),

                // Stock header with logo
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    children: [
                      // Company logo placeholder
                      Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          color: const Color(0xFF1ED760), // Spotify green
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Center(
                          child: Text(
                            widget.asset.symbol.substring(0, 2),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.asset.symbol,
                              style: TextStyle(
                                color: themeProvider.contrast,
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            Text(
                              widget.asset.name,
                              style: TextStyle(
                                color: themeProvider.contrast.withOpacity(0.7),
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // Price display
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  child: Row(
                    children: [
                      Text(
                        '\$${widget.asset.price.toStringAsFixed(2)}',
                        style: TextStyle(
                          color: themeProvider.contrast,
                          fontSize: 32,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: changeColor,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              isPositive ? Icons.arrow_upward : Icons.arrow_downward,
                              color: Colors.white,
                              size: 16,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${widget.asset.changePercent >= 0 ? '+' : ''}${widget.asset.changePercent.toStringAsFixed(2)}%',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // Chart with purple gradient background
                Container(
                  margin: const EdgeInsets.all(16),
                  padding: const EdgeInsets.all(16),
                  height: 200,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Color(0xFF9333EA), // Purple
                        Color(0xFF6366F1), // Indigo
                      ],
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: _buildSpotifyStyleChart(themeProvider),
                ),

                // Time period selector
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: ['1D', '1W', '1M', '3M', '6M', '1Y', 'All'].map((period) {
                      final isSelected = _selectedTimeframe == period;
                      return Expanded(
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              _selectedTimeframe = period;
                            });
                            _loadChartData();
                          },
                          child: Container(
                            margin: const EdgeInsets.symmetric(horizontal: 2),
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            decoration: BoxDecoration(
                              color: isSelected ? themeProvider.theme : Colors.transparent,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              period,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: isSelected ? Colors.white : themeProvider.contrast.withOpacity(0.7),
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),

                const SizedBox(height: 24),

                // Holdings section (only show if this is a holding)
                if (widget.isHolding && widget.holdingDetails != null)
                  _buildHoldingsSection(themeProvider),

                // Stats section (conditionally show based on holding status)
                _buildStatsSection(themeProvider),

                // About section
                _buildAboutSection(themeProvider),

                const SizedBox(height: 100), // Space for trade buttons
              ],
            ),
          ),
          bottomNavigationBar: _buildTradeButtons(themeProvider),
        );
      },
    );
  }

  Widget _buildSpotifyStyleChart(ThemeProvider themeProvider) {
    return _isLoading
        ? const Center(
            child: CircularProgressIndicator(
              color: Colors.white,
              strokeWidth: 2,
            ),
          )
        : _priceData.isEmpty
            ? const Center(
                child: Text(
                  'No chart data available',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                ),
              )
            : LineChart(
                LineChartData(
                  gridData: const FlGridData(show: false),
                  titlesData: const FlTitlesData(show: false),
                  borderData: FlBorderData(show: false),
                  lineBarsData: [
                    LineChartBarData(
                      spots: _priceData,
                      isCurved: true,
                      gradient: const LinearGradient(
                        colors: [Colors.white, Colors.white70],
                      ),
                      barWidth: 3,
                      isStrokeCapRound: true,
                      dotData: const FlDotData(show: false),
                      belowBarData: BarAreaData(
                        show: true,
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.white.withOpacity(0.3),
                            Colors.white.withOpacity(0.0),
                          ],
                        ),
                      ),
                    ),
                  ],
                  minX: 0,
                  maxX: _priceData.isNotEmpty ? _priceData.length.toDouble() - 1 : 0,
                  minY: _priceData.isNotEmpty 
                    ? _priceData.map((e) => e.y).reduce((a, b) => a < b ? a : b) * 0.95
                    : 0,
                  maxY: _priceData.isNotEmpty 
                    ? _priceData.map((e) => e.y).reduce((a, b) => a > b ? a : b) * 1.05
                    : 1,
                ),
              );
  }

  Widget _buildHoldingsSection(ThemeProvider themeProvider) {
    final holding = widget.holdingDetails!;
    final currentPrice = widget.asset.price;
    final pnlDollar = currentPrice - holding.avgPrice;
    final pnlPercent = holding.avgPrice > 0 ? (pnlDollar / holding.avgPrice) * 100 : 0.0;
    final isPositive = pnlDollar >= 0;
    final pnlColor = isPositive ? const Color(0xFF22C55E) : const Color(0xFFEF4444);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: themeProvider.backgroundHigh,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: themeProvider.theme.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Holdings header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: themeProvider.theme.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.account_balance_wallet,
                  color: themeProvider.theme,
                  size: 16,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Your Investment',
                style: TextStyle(
                  color: themeProvider.contrast,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Investment stats
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Total Investment',
                      style: TextStyle(
                        color: themeProvider.contrast.withOpacity(0.7),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '\$${(holding.avgPrice * holding.quantity).toStringAsFixed(2)}',
                      style: TextStyle(
                        color: themeProvider.contrast,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      'Profit',
                      style: TextStyle(
                        color: themeProvider.contrast.withOpacity(0.7),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${isPositive ? '+' : ''}\$${(pnlDollar * holding.quantity).toStringAsFixed(2)}',
                      style: TextStyle(
                        color: pnlColor,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Additional stats
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'AVG FILL',
                      style: TextStyle(
                        color: themeProvider.contrast.withOpacity(0.7),
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '\$${holding.avgPrice.toStringAsFixed(2)}',
                      style: TextStyle(
                        color: themeProvider.contrast,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'BUY ZONE',
                      style: TextStyle(
                        color: themeProvider.contrast.withOpacity(0.7),
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '\$${(holding.avgPrice * 0.95).toStringAsFixed(2)} - \$${(holding.avgPrice * 1.05).toStringAsFixed(2)}',
                      style: TextStyle(
                        color: themeProvider.contrast,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'PROFIT ZONE',
                      style: TextStyle(
                        color: themeProvider.contrast.withOpacity(0.7),
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '\$${(holding.avgPrice * 1.1).toStringAsFixed(2)}+',
                      style: TextStyle(
                        color: themeProvider.contrast,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'STOP LOSS',
                      style: TextStyle(
                        color: themeProvider.contrast.withOpacity(0.7),
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '\$${(holding.avgPrice * 0.9).toStringAsFixed(2)}',
                      style: TextStyle(
                        color: themeProvider.contrast,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatsSection(ThemeProvider themeProvider) {
    // Show different stats based on whether this is a holding or not
    if (widget.isHolding) {
      // For holdings, show performance-focused stats
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Column(
          children: [
            // Performance stats row
            Row(
              children: [
                _buildStatCard(
                  themeProvider,
                  'Market Cap',
                  _fundamentals?['marketCap']?.toString() ?? 'N/A',
                  Icons.public,
                  const Color(0xFF3B82F6),
                ),
                const SizedBox(width: 12),
                _buildStatCard(
                  themeProvider,
                  'P/E Ratio',
                  _fundamentals?['peRatio']?.toString() ?? 'N/A',
                  Icons.trending_up,
                  const Color(0xFFEC4899),
                ),
              ],
            ),
          ],
        ),
      );
    } else {
      // For non-holdings, show general market stats
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Column(
          children: [
            Row(
              children: [
                _buildStatCard(
                  themeProvider,
                  'Volume',
                  _fundamentals?['volume']?.toString() ?? 'N/A',
                  Icons.bar_chart,
                  const Color(0xFF22C55E),
                ),
                const SizedBox(width: 12),
                _buildStatCard(
                  themeProvider,
                  '52W High',
                  _fundamentals?['weekHigh52']?.toString() ?? 'N/A',
                  Icons.north,
                  const Color(0xFFEAB308),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _buildStatCard(
                  themeProvider,
                  '52W Low',
                  _fundamentals?['weekLow52']?.toString() ?? 'N/A',
                  Icons.south,
                  const Color(0xFFEA580C),
                ),
                const SizedBox(width: 12),
                _buildStatCard(
                  themeProvider,
                  'P/E Ratio',
                  _fundamentals?['peRatio']?.toString() ?? 'N/A',
                  Icons.analytics,
                  const Color(0xFF8B5CF6),
                ),
              ],
            ),
          ],
        ),
      );
    }
  }

  Widget _buildStatCard(ThemeProvider themeProvider, String title, String value, IconData icon, Color accentColor) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: themeProvider.backgroundHigh,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: accentColor.withOpacity(0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: accentColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Icon(
                    icon,
                    color: accentColor,
                    size: 14,
                  ),
                ),
                const Spacer(),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: TextStyle(
                color: themeProvider.contrast.withOpacity(0.7),
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                color: themeProvider.contrast,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAboutSection(ThemeProvider themeProvider) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: themeProvider.backgroundHigh,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: themeProvider.contrast.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'About ${widget.asset.name}',
            style: TextStyle(
              color: themeProvider.contrast,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Netflix Inc. has built an enduring reputation for development and manufacture of engines for defense and civil aircraft.',
            style: TextStyle(
              color: themeProvider.contrast.withOpacity(0.8),
              fontSize: 14,
              fontWeight: FontWeight.w500,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 16),
          GestureDetector(
            onTap: () {
              // Add view more functionality
            },
            child: Text(
              'View More',
              style: TextStyle(
                color: themeProvider.theme,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTradeButtons(ThemeProvider themeProvider) {
    return Container(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        bottom: MediaQuery.of(context).padding.bottom + 16,
        top: 16,
      ),
      decoration: BoxDecoration(
        color: themeProvider.background,
        border: Border(
          top: BorderSide(
            color: themeProvider.contrast.withOpacity(0.1),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          // Buy button
          Expanded(
            child: ElevatedButton(
              onPressed: () {
                final authProvider = Provider.of<AuthProvider>(context, listen: false);
                if (authProvider.user != null) {
                  showDialog(
                    context: context,
                    builder: (context) => TradeDialog(
                      asset: widget.asset,
                      userId: authProvider.user!.id,
                      initialTab: 0, // Buy tab
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF22C55E),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              child: const Text(
                'BUY',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Sell button (only show if holding)
          if (widget.isHolding)
            Expanded(
              child: ElevatedButton(
                onPressed: () {
                  final authProvider = Provider.of<AuthProvider>(context, listen: false);
                  if (authProvider.user != null) {
                    showDialog(
                      context: context,
                      builder: (context) => TradeDialog(
                        asset: widget.asset,
                        userId: authProvider.user!.id,
                        initialTab: 1, // Sell tab
                        maxQuantity: widget.holdingDetails?.quantity ?? 0,
                      ),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFEF4444),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                child: const Text(
                  'SELL',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            )
          else
            // Watch button for non-holdings
            Expanded(
              child: OutlinedButton(
                onPressed: () {
                  // Add to watchlist functionality
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Added ${widget.asset.symbol} to watchlist'),
                      backgroundColor: themeProvider.theme,
                    ),
                  );
                },
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: themeProvider.theme),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  'WATCH',
                  style: TextStyle(
                    color: themeProvider.theme,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}