import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/portfolio_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/market_data_provider.dart';
import '../../providers/theme_provider.dart';
import '../../models/market_asset_model.dart';
import '../market/asset_detail_screen.dart';

class HoldingsPage extends StatefulWidget {
  const HoldingsPage({super.key});

  @override
  State<HoldingsPage> createState() => _HoldingsPageState();
}

class _HoldingsPageState extends State<HoldingsPage> {
  
  @override
  void initState() {
    super.initState();
    _loadHoldingsData();
  }
  
  void _loadHoldingsData() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final portfolioProvider = Provider.of<PortfolioProvider>(context, listen: false);
    final marketDataProvider = Provider.of<MarketDataProvider>(context, listen: false);
    
    if (authProvider.user != null) {
      portfolioProvider.loadPortfolio(authProvider.user!.id);
      
      // Pre-load market data for all holdings
      if (portfolioProvider.portfolio.isNotEmpty) {
        final symbols = portfolioProvider.portfolio.map((h) => h.symbol).toList();
        marketDataProvider.preloadSymbolPrices(symbols);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return Scaffold(
          backgroundColor: themeProvider.background,
          appBar: AppBar(
            backgroundColor: themeProvider.background,
            elevation: 0,
            leading: IconButton(
              icon: Icon(Icons.arrow_back, color: themeProvider.contrast),
              onPressed: () => Navigator.of(context).pop(),
            ),
            title: Text(
              'Holdings',
              style: TextStyle(
                color: themeProvider.contrast,
                fontSize: 24,
                fontWeight: FontWeight.w800,
              ),
            ),
            actions: [
              IconButton(
                icon: Icon(Icons.refresh, color: themeProvider.contrast),
                onPressed: _loadHoldingsData,
              ),
            ],
          ),
          body: Consumer2<PortfolioProvider, MarketDataProvider>(
            builder: (context, portfolioProvider, marketDataProvider, child) {
              if (portfolioProvider.isLoading) {
                return const Center(
                  child: CircularProgressIndicator(),
                );
              }

              return SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Portfolio Summary Card
                    _buildPortfolioSummaryCard(themeProvider, portfolioProvider),
                    const SizedBox(height: 24),
                    
                    // Analytics Cards Row
                    _buildAnalyticsRow(themeProvider, portfolioProvider),
                    const SizedBox(height: 24),
                    
                    // Holdings Header
                    Text(
                      'Your Holdings',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: themeProvider.contrast,
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    // Holdings List
                    if (portfolioProvider.portfolio.isEmpty)
                      _buildEmptyState(themeProvider)
                    else
                      _buildHoldingsList(portfolioProvider, marketDataProvider, themeProvider),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildPortfolioSummaryCard(ThemeProvider themeProvider, PortfolioProvider portfolioProvider) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [themeProvider.themeHigh, themeProvider.theme],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.24),
            blurRadius: 24,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Portfolio Value',
            style: TextStyle(
              color: Colors.white.withOpacity(0.8),
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '\$${portfolioProvider.netWorth.toStringAsFixed(2)}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 32,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Total P&L',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.7),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: portfolioProvider.totalPnL >= 0 
                          ? const Color(0xFF3B82F6).withOpacity(0.2)
                          : const Color(0xFFEF4444).withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: portfolioProvider.totalPnL >= 0 
                            ? const Color(0xFF3B82F6)
                            : const Color(0xFFEF4444),
                        ),
                      ),
                      child: Text(
                        '${portfolioProvider.totalPnL >= 0 ? '+' : ''}\$${portfolioProvider.totalPnL.toStringAsFixed(2)}',
                        style: TextStyle(
                          color: portfolioProvider.totalPnL >= 0 
                            ? const Color(0xFF3B82F6)
                            : const Color(0xFFEF4444),
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'P&L %',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.7),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: portfolioProvider.totalPnLPercentage >= 0 
                          ? const Color(0xFF3B82F6).withOpacity(0.2)
                          : const Color(0xFFEF4444).withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: portfolioProvider.totalPnLPercentage >= 0 
                            ? const Color(0xFF3B82F6)
                            : const Color(0xFFEF4444),
                        ),
                      ),
                      child: Text(
                        '${portfolioProvider.totalPnLPercentage >= 0 ? '+' : ''}${portfolioProvider.totalPnLPercentage.toStringAsFixed(2)}%',
                        style: TextStyle(
                          color: portfolioProvider.totalPnLPercentage >= 0 
                            ? const Color(0xFF3B82F6)
                            : const Color(0xFFEF4444),
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
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

  Widget _buildAnalyticsRow(ThemeProvider themeProvider, PortfolioProvider portfolioProvider) {
    return Row(
      children: [
        Expanded(
          child: _buildAnalyticsCard(
            themeProvider,
            'Holdings',
            '${portfolioProvider.portfolio.length}',
            Icons.account_balance_wallet,
            const Color(0xFF3B82F6),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildAnalyticsCard(
            themeProvider,
            'Cash Balance',
            '\$${portfolioProvider.cashBalance.toStringAsFixed(2)}',
            Icons.account_balance,
            const Color(0xFFEC4899),
          ),
        ),
      ],
    );
  }

  Widget _buildAnalyticsCard(ThemeProvider themeProvider, String title, String value, IconData icon, Color accentColor) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: themeProvider.backgroundHigh,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: accentColor.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.12),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: accentColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  color: accentColor,
                  size: 16,
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
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              color: themeProvider.contrast,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(ThemeProvider themeProvider) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: themeProvider.backgroundHigh,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: themeProvider.contrast.withOpacity(0.1)),
      ),
      child: Column(
        children: [
          Icon(
            Icons.trending_up,
            size: 64,
            color: themeProvider.theme.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            'No Holdings Yet',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: themeProvider.contrast,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Start trading to build your portfolio and see your holdings here',
            style: TextStyle(
              color: themeProvider.contrast.withOpacity(0.7),
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildHoldingsList(PortfolioProvider portfolioProvider, MarketDataProvider marketDataProvider, ThemeProvider themeProvider) {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: portfolioProvider.portfolio.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final holding = portfolioProvider.portfolio[index];
        
        // Get live market data
        MarketAssetModel? marketAsset;
        try {
          marketAsset = marketDataProvider.allAssets.firstWhere(
            (asset) => asset.symbol.toUpperCase() == holding.symbol.toUpperCase(),
          );
        } catch (e) {
          // Create fallback asset
          marketAsset = MarketAssetModel(
            symbol: holding.symbol,
            name: holding.symbol,
            price: holding.avgPrice,
            change: 0.0,
            changePercent: 0.0,
            type: 'stock',
            lastUpdated: DateTime.now(),
          );
        }
        
        final currentPrice = marketAsset.price;
        final pnlDollar = currentPrice - holding.avgPrice;
        final pnlPercent = holding.avgPrice > 0 ? (pnlDollar / holding.avgPrice) * 100 : 0.0;
        final isPositive = pnlDollar >= 0;
        final pnlColor = isPositive ? const Color(0xFF3B82F6) : const Color(0xFFEF4444);
        
        // Use colorful accents for variety
        final colors = [
          const Color(0xFF3B82F6), // Green
          const Color(0xFFEC4899), // Pink
          const Color(0xFFEAB308), // Yellow
          const Color(0xFF06B6D4), // Cyan
          const Color(0xFF8B5CF6), // Purple
          const Color(0xFFEA580C), // Orange
        ];
        final accentColor = colors[index % colors.length];
        
        return GestureDetector(
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => AssetDetailScreen(
                  asset: marketAsset!,
                  isHolding: true, // Mark as holding
                  holdingDetails: holding, // Pass holding details
                ),
              ),
            );
          },
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: themeProvider.backgroundHigh,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: accentColor.withOpacity(0.2)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.12),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    // Company symbol and logo area
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: accentColor.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        holding.symbol,
                        style: TextStyle(
                          color: accentColor,
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    
                    // Stock info
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            marketAsset.name,
                            style: TextStyle(
                              color: themeProvider.contrast,
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${holding.quantity.toStringAsFixed(2)} shares • Avg \$${holding.avgPrice.toStringAsFixed(2)}',
                            style: TextStyle(
                              color: themeProvider.contrast.withOpacity(0.7),
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    // Current price and change
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '\$${currentPrice.toStringAsFixed(2)}',
                          style: TextStyle(
                            color: themeProvider.contrast,
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: pnlColor,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '${isPositive ? '+' : ''}${pnlPercent.toStringAsFixed(1)}%',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                
                // P&L breakdown
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: themeProvider.background.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Market Value',
                              style: TextStyle(
                                color: themeProvider.contrast.withOpacity(0.7),
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '\$${(currentPrice * holding.quantity).toStringAsFixed(2)}',
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
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Text(
                              'Cost Basis',
                              style: TextStyle(
                                color: themeProvider.contrast.withOpacity(0.7),
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '\$${(holding.avgPrice * holding.quantity).toStringAsFixed(2)}',
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
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              'Total P&L',
                              style: TextStyle(
                                color: themeProvider.contrast.withOpacity(0.7),
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${isPositive ? '+' : ''}\$${(pnlDollar * holding.quantity).toStringAsFixed(2)}',
                              style: TextStyle(
                                color: pnlColor,
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}