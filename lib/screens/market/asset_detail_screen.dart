import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/market_asset_model.dart';
import '../../models/portfolio_model.dart';
import '../../providers/theme_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/portfolio_provider.dart';
import '../../providers/watchlist_provider.dart';
import '../../services/enhanced_market_data_service.dart';
import '../../services/stock_descriptions_service.dart';
import '../../services/financial_news_service.dart';
import '../../utils/number_formatter.dart';
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
    _loadChartData();
    _loadFundamentals();
    _loadNews();
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
        _priceData = chartData;
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
        final changeColor = isPositive ? const Color(0xFF10B981) : const Color(0xFFEF4444);
        
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
                      Consumer<WatchlistProvider>(
                        builder: (context, watchlistProvider, child) {
                          final isInWatchlist = watchlistProvider.isInWatchlist(widget.asset.symbol);
                          return GestureDetector(
                            onTap: () async {
                              if (isInWatchlist) {
                                await watchlistProvider.removeFromWatchlist(widget.asset.symbol);
                              } else {
                                await watchlistProvider.addToWatchlist(widget.asset.symbol);
                              }
                            },
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: themeProvider.backgroundHigh,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                isInWatchlist ? Icons.favorite : Icons.favorite_border,
                                color: isInWatchlist ? themeProvider.theme : themeProvider.contrast,
                                size: 20,
                              ),
                            ),
                          );
                        },
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

                // Direct content from overview tab (chart, metrics, etc.)
                
                // Chart section
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

                // Stock Metrics Widgets (only the new ones)
                if (_fundamentals != null) ...[
                  // Daily metrics (Open, High, Low)
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: themeProvider.backgroundHigh,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: themeProvider.theme.withOpacity(0.2)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Daily Range',
                          style: TextStyle(
                            color: themeProvider.contrast,
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: _buildMetricItem(
                                'Open',
                                NumberFormatter.formatPrice(_fundamentals!['openPrice'] ?? widget.asset.price),
                                themeProvider,
                              ),
                            ),
                            Expanded(
                              child: _buildMetricItem(
                                'High',
                                NumberFormatter.formatPrice(_fundamentals!['dayHigh'] ?? widget.asset.price),
                                themeProvider,
                              ),
                            ),
                            Expanded(
                              child: _buildMetricItem(
                                'Low',
                                NumberFormatter.formatPrice(_fundamentals!['dayLow'] ?? widget.asset.price),
                                themeProvider,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // 52-week range
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: themeProvider.backgroundHigh,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: themeProvider.theme.withOpacity(0.2)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '52-Week Range',
                          style: TextStyle(
                            color: themeProvider.contrast,
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: _buildMetricItem(
                                '52W High',
                                NumberFormatter.formatPrice(_fundamentals!['weekHigh52'] ?? widget.asset.price),
                                themeProvider,
                              ),
                            ),
                            Expanded(
                              child: _buildMetricItem(
                                '52W Low',
                                NumberFormatter.formatPrice(_fundamentals!['weekLow52'] ?? widget.asset.price),
                                themeProvider,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Financial Ratios
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: themeProvider.backgroundHigh,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: themeProvider.theme.withOpacity(0.2)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Key Metrics',
                          style: TextStyle(
                            color: themeProvider.contrast,
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: _buildMetricItem(
                                'P/E Ratio',
                                NumberFormatter.formatPERatio(_fundamentals!['peRatio']),
                                themeProvider,
                              ),
                            ),
                            Expanded(
                              child: _buildMetricItem(
                                'Dividend Yield',
                                NumberFormatter.formatDividendYield(_fundamentals!['dividendYield']),
                                themeProvider,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: _buildMetricItem(
                                'Market Cap',
                                NumberFormatter.formatCurrency(_fundamentals!['marketCap']?.toDouble() ?? 0),
                                themeProvider,
                              ),
                            ),
                            Expanded(
                              child: _buildMetricItem(
                                'Volume',
                                NumberFormatter.formatVolume(_fundamentals!['volume']?.toDouble() ?? 0),
                                themeProvider,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],

                // Holdings section (only show if this is a holding)
                if (widget.isHolding && widget.holdingDetails != null)
                  _buildHoldingsSection(themeProvider),

                // About section
                _buildAboutSection(themeProvider),

                // News section at bottom
                _buildNewsSection(themeProvider),

                const SizedBox(height: 100), // Space for trade buttons
              ],
            ),
          ),
          bottomNavigationBar: _buildTradeButtons(themeProvider),
        );
      },
    );
  }

  Widget _buildNewsSection(ThemeProvider themeProvider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 24),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'Latest News',
            style: TextStyle(
              color: themeProvider.contrast,
              fontSize: 20,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        const SizedBox(height: 16),
        if (_isLoadingNews)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(32.0),
              child: CircularProgressIndicator(),
            ),
          )
        else if (_newsArticles.isEmpty)
          Center(
            child: Padding(
              padding: const EdgeInsets.all(32.0),
              child: Column(
                children: [
                  Icon(
                    Icons.article_outlined,
                    size: 64,
                    color: themeProvider.contrast.withOpacity(0.5),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No News Available',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: themeProvider.contrast,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Check back later for the latest news about ${widget.asset.symbol}',
                    style: TextStyle(
                      color: themeProvider.contrast.withOpacity(0.7),
                      fontSize: 14,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          )
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: _newsArticles.length,
            itemBuilder: (context, index) {
              final article = _newsArticles[index];
              return _buildNewsCard(article, themeProvider);
            },
          ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildNewsCard(NewsArticle article, ThemeProvider themeProvider) {
    Color sentimentColor;
    IconData sentimentIcon;
    
    switch (article.sentiment) {
      case 'Bullish':
        sentimentColor = const Color(0xFF3B82F6);
        sentimentIcon = Icons.trending_up;
        break;
      case 'Bearish':
        sentimentColor = const Color(0xFFEF4444);
        sentimentIcon = Icons.trending_down;
        break;
      default:
        sentimentColor = themeProvider.contrast.withOpacity(0.6);
        sentimentIcon = Icons.remove;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: themeProvider.backgroundHigh,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: themeProvider.contrast.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with source and sentiment
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: themeProvider.theme.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  article.source,
                  style: TextStyle(
                    color: themeProvider.theme,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: sentimentColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      sentimentIcon,
                      size: 12,
                      color: sentimentColor,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      article.sentiment,
                      style: TextStyle(
                        color: sentimentColor,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          
          // Title
          Text(
            article.title,
            style: TextStyle(
              color: themeProvider.contrast,
              fontSize: 16,
              fontWeight: FontWeight.w700,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 8),
          
          // Summary
          Text(
            article.summary,
            style: TextStyle(
              color: themeProvider.contrast.withOpacity(0.8),
              fontSize: 14,
              height: 1.4,
            ),
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 12),
          
          // Footer with time and read more
          Row(
            children: [
              Text(
                article.timeAgo,
                style: TextStyle(
                  color: themeProvider.contrast.withOpacity(0.6),
                  fontSize: 12,
                ),
              ),
              const Spacer(),
              GestureDetector(
                onTap: () => _launchWebsite(article.url),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: themeProvider.theme.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.open_in_new,
                        size: 12,
                        color: themeProvider.theme,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Read More',
                        style: TextStyle(
                          color: themeProvider.theme,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
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
                      spots: _priceData.map((spot) => FlSpot(spot.x, double.parse(spot.y.toStringAsFixed(2)))).toList(),
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
                  extraLinesData: ExtraLinesData(
                    horizontalLines: _fundamentals != null ? [
                      // Opening price baseline
                      if (_fundamentals!['openPrice'] != null)
                        HorizontalLine(
                          y: double.parse((_fundamentals!['openPrice'] as double).toStringAsFixed(2)),
                          color: Colors.white.withOpacity(0.6),
                          strokeWidth: 2,
                          dashArray: [5, 5],
                          label: HorizontalLineLabel(
                            show: true,
                            alignment: Alignment.topRight,
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                            labelResolver: (line) => 'Open: \$${line.y.toStringAsFixed(2)}',
                          ),
                        ),
                      // Previous day's closing price baseline
                      if (_fundamentals!['previousClose'] != null)
                        HorizontalLine(
                          y: double.parse((_fundamentals!['previousClose'] as double).toStringAsFixed(2)),
                          color: Colors.orange.withOpacity(0.7),
                          strokeWidth: 2,
                          dashArray: [8, 4],
                          label: HorizontalLineLabel(
                            show: true,
                            alignment: Alignment.bottomRight,
                            style: const TextStyle(
                              color: Colors.orange,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                            labelResolver: (line) => 'Prev Close: \$${line.y.toStringAsFixed(2)}',
                          ),
                        ),
                    ] : [],
                  ),
                  minX: 0,
                  maxX: _priceData.isNotEmpty ? _priceData.length.toDouble() - 1 : 0,
                  minY: _priceData.isNotEmpty 
                    ? double.parse((_priceData.map((e) => e.y).reduce((a, b) => a < b ? a : b) * 0.95).toStringAsFixed(2))
                    : 0,
                  maxY: _priceData.isNotEmpty 
                    ? double.parse((_priceData.map((e) => e.y).reduce((a, b) => a > b ? a : b) * 1.05).toStringAsFixed(2))
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
    final pnlColor = isPositive ? const Color(0xFF3B82F6) : const Color(0xFFEF4444);

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
                  const Color(0xFF3B82F6),
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

  String _getCompanyDescription() {
    final symbol = widget.asset.symbol;
    final name = widget.asset.name;
    
    // Create more useful descriptions based on company ticker and name
    final descriptions = {
      'AAPL': 'Apple Inc. is a multinational technology company that designs, develops, and sells consumer electronics, computer software, and online services. Known for products like iPhone, iPad, Mac, Apple Watch, and services like the App Store and iCloud.',
      'MSFT': 'Microsoft Corporation is a multinational technology company that develops, manufactures, licenses, supports, and sells computer software, consumer electronics, personal computers, and related services. Known for Windows, Office, Azure, Xbox, and LinkedIn.',
      'GOOGL': 'Alphabet Inc. is a multinational conglomerate holding company created through Google\'s restructuring. The company operates through Google and Other Bets segments, with core business in internet search, advertising, cloud computing, and artificial intelligence.',
      'AMZN': 'Amazon.com Inc. is a multinational technology company focusing on e-commerce, cloud computing, digital streaming, and artificial intelligence. It\'s one of the world\'s largest online retailers and cloud service providers.',
      'TSLA': 'Tesla Inc. is an electric vehicle and clean energy company that designs, develops, manufactures, and sells fully electric vehicles, energy generation and storage systems, and related services and technologies.',
      'META': 'Meta Platforms Inc. operates social networking platforms including Facebook, Instagram, WhatsApp, and Messenger. The company is also investing heavily in virtual and augmented reality technologies and the metaverse.',
      'NVDA': 'NVIDIA Corporation is a multinational technology company known for designing graphics processing units (GPUs) for gaming, professional, and data center markets, as well as system on chip units (SoCs) for mobile computing and automotive applications.',
      'NFLX': 'Netflix Inc. is a streaming entertainment service company that operates in over 190 countries, offering TV series, documentaries, and feature films across a variety of genres and languages.',
      'CRM': 'Salesforce Inc. is a cloud-based software company that provides customer relationship management (CRM) services and a complementary suite of enterprise applications focused on customer service, marketing automation, analytics, and application development.',
      'ADBE': 'Adobe Inc. is a multinational computer software company known for multimedia and creativity software products including Photoshop, Illustrator, After Effects, and the Adobe Creative Cloud suite.',
    };
    
    // Return specific description if available, otherwise create a generic one
    return descriptions[symbol] ?? 
           '$name is a publicly traded company operating in the ${_inferIndustryFromName(name)} sector. The company provides products and services to customers and operates within the broader market ecosystem.';
  }
  
  String _inferIndustryFromName(String name) {
    final nameLower = name.toLowerCase();
    
    if (nameLower.contains('bank') || nameLower.contains('financial')) return 'financial services';
    if (nameLower.contains('tech') || nameLower.contains('software') || nameLower.contains('systems')) return 'technology';
    if (nameLower.contains('pharma') || nameLower.contains('bio') || nameLower.contains('health')) return 'healthcare';
    if (nameLower.contains('energy') || nameLower.contains('oil') || nameLower.contains('gas')) return 'energy';
    if (nameLower.contains('retail') || nameLower.contains('store') || nameLower.contains('market')) return 'retail';
    if (nameLower.contains('auto') || nameLower.contains('motor') || nameLower.contains('vehicle')) return 'automotive';
    if (nameLower.contains('real estate') || nameLower.contains('property')) return 'real estate';
    if (nameLower.contains('media') || nameLower.contains('entertainment') || nameLower.contains('network')) return 'media & entertainment';
    if (nameLower.contains('food') || nameLower.contains('restaurant') || nameLower.contains('beverage')) return 'food & beverage';
    if (nameLower.contains('airline') || nameLower.contains('transport') || nameLower.contains('logistics')) return 'transportation';
    
    return 'industrial';
  }

  Widget _buildAboutSection(ThemeProvider themeProvider) {
    // Get company description from fundamentals or create a meaningful business description
    String description = _getCompanyDescription();
    
    if (_fundamentals != null) {
      // Try to get description from fundamentals data
      description = _fundamentals!['description'] ?? 
                   _fundamentals!['longBusinessSummary'] ?? 
                   _fundamentals!['businessSummary'] ??
                   description;
    }
    
    // Truncate if too long for initial display
    final shortDescription = description.length > 200 
        ? '${description.substring(0, 200)}...' 
        : description;
    
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
          Row(
            children: [
              Text(
                'About ${widget.asset.name}',
                style: TextStyle(
                  color: themeProvider.contrast,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const Spacer(),
              if (_fundamentals != null && _fundamentals!['website'] != null)
                GestureDetector(
                  onTap: () => _launchWebsite(_fundamentals!['website']),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: themeProvider.theme.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.language,
                          size: 14,
                          color: themeProvider.theme,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Website',
                          style: TextStyle(
                            color: themeProvider.theme,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            shortDescription,
            style: TextStyle(
              color: themeProvider.contrast.withOpacity(0.8),
              fontSize: 14,
              fontWeight: FontWeight.w500,
              height: 1.5,
            ),
          ),
          if (description.length > 200) ...[
            const SizedBox(height: 12),
            GestureDetector(
              onTap: () => _showFullDescription(description),
              child: Text(
                'Read More',
                style: TextStyle(
                  color: themeProvider.theme,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _launchWebsite(String url) async {
    final Uri uri = Uri.parse(url.startsWith('http') ? url : 'https://$url');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  void _showFullDescription(String description) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('About ${widget.asset.name}'),
          content: SingleChildScrollView(
            child: Text(
              description,
              style: const TextStyle(fontSize: 14, height: 1.5),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
          ],
        );
      },
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
          // Buy button (always show)
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
                backgroundColor: const Color(0xFF3B82F6), // Blue for Buy
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
          // Sell button (always show)
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
                backgroundColor: const Color(0xFFEF4444), // Red for Sell
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
          ),
        ],
      ),
    );
  }

  Widget _buildMetricItem(String title, String value, ThemeProvider themeProvider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            color: themeProvider.contrast.withOpacity(0.7),
            fontSize: 12,
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
        ),
      ],
    );
  }
}