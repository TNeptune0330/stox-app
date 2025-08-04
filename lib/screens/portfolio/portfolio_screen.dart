import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/portfolio_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/achievement_provider.dart';
import '../../providers/market_data_provider.dart';
import '../../providers/theme_provider.dart';
import '../../widgets/portfolio_summary_card.dart';
import '../../widgets/achievement_banner_widget.dart';
import '../../utils/responsive_utils.dart';
import '../../models/portfolio_model.dart';
import '../../models/market_asset_model.dart';
import '../../mixins/performance_optimized_mixin.dart';
import '../main_navigation.dart';
import '../market/trade_dialog.dart';
import 'transaction_history.dart';

class PortfolioScreen extends StatefulWidget {
  const PortfolioScreen({super.key});

  @override
  State<PortfolioScreen> createState() => _PortfolioScreenState();
}

class _PortfolioScreenState extends State<PortfolioScreen> 
    with PerformanceOptimizedMixin, TickerProviderStateMixin {
  
  @override
  void initState() {
    super.initState();
    
    // Use debounced initialization to avoid unnecessary calls
    debouncedSetState(() {
      _initializePortfolioData();
    }, delay: const Duration(milliseconds: 100));
  }
  
  void _initializePortfolioData() {
    // Use throttled execution to prevent multiple simultaneous loads
    throttle('portfolio_load', () {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final portfolioProvider = Provider.of<PortfolioProvider>(context, listen: false);
      
      if (authProvider.user != null) {
        print('🏦 PortfolioScreen: Auto-loading portfolio for user: ${authProvider.user!.id}');
        portfolioProvider.loadPortfolio(authProvider.user!.id);
      } else {
        print('⚠️ PortfolioScreen: No authenticated user found');
        // Don't load demo data immediately - wait for auth to complete
      }
    });
  }
  
  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return Scaffold(
          backgroundColor: themeProvider.background,
          body: CustomScrollView(
            slivers: [
              // Header with 5-color theme
              SliverAppBar(
                expandedHeight: ResponsiveUtils.isTablet(context) ? 160 : 120,
                floating: false,
                pinned: true,
                backgroundColor: themeProvider.backgroundHigh,
                foregroundColor: themeProvider.contrast,
                flexibleSpace: FlexibleSpaceBar(
                  background: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          themeProvider.themeHigh,
                          themeProvider.theme,
                        ],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: themeProvider.themeHigh.withOpacity(0.3),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: themeProvider.background.withOpacity(0.3),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.account_balance_wallet,
                              size: ResponsiveUtils.getIconSize(context, 36),
                              color: themeProvider.contrast,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'PORTFOLIO',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w900,
                              color: themeProvider.contrast,
                              letterSpacing: 2,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Consumer<PortfolioProvider>(
                            builder: (context, portfolioProvider, child) {
                              return Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                decoration: BoxDecoration(
                                  color: themeProvider.background.withOpacity(0.3),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  'Net Worth: \$${portfolioProvider.netWorth.toStringAsFixed(2)}',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: themeProvider.contrast,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                actions: [
                  IconButton(
                    icon: Icon(Icons.history, color: themeProvider.contrast),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const TransactionHistoryScreen(),
                        ),
                      );
                    },
                ),
                IconButton(
                  icon: Icon(Icons.refresh, color: themeProvider.contrast),
                  onPressed: () {
                    final authProvider = Provider.of<AuthProvider>(context, listen: false);
                    if (authProvider.user != null) {
                      Provider.of<PortfolioProvider>(context, listen: false)
                          .forceRefreshWithConnection(authProvider.user!.id);
                    }
                  },
                ),
              ],
              ),

              Consumer<PortfolioProvider>(
                builder: (context, portfolioProvider, child) {
              if (portfolioProvider.isLoading) {
                return const SliverFillRemaining(
                  child: LoadingWidget(),
                );
              }

              if (portfolioProvider.error != null) {
                return SliverFillRemaining(
                  child: ErrorStateWidget(
                    message: portfolioProvider.error!,
                    onRetry: () {
                      final authProvider = Provider.of<AuthProvider>(context, listen: false);
                      if (authProvider.user != null) {
                        portfolioProvider.loadPortfolio(authProvider.user!.id);
                      }
                    },
                  ),
                );
              }

              return SliverList(
                delegate: SliverChildListDelegate([
                  // Portfolio Summary Card (clickable to show holdings)
                  GestureDetector(
                    onTap: () => _showHoldingsPopup(context, portfolioProvider),
                    child: PortfolioSummaryCard(
                      cashBalance: portfolioProvider.cashBalance,
                      holdingsValue: portfolioProvider.holdingsValue,
                      netWorth: portfolioProvider.netWorth,
                      totalPnL: portfolioProvider.totalPnL,
                      totalPnLPercentage: portfolioProvider.totalPnLPercentage,
                    ),
                  ),

                  // Achievement Banner
                  const AchievementBannerWidget(),

                  // Recent Achievements Preview
                  Consumer<AchievementProvider>(
                    builder: (context, achievementProvider, child) {
                      final recentAchievements = achievementProvider.getRecentlyUnlocked();
                      if (recentAchievements.isEmpty) return const SizedBox.shrink();
                      
                      return Container(
                        margin: const EdgeInsets.all(16),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: themeProvider.backgroundHigh,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: themeProvider.themeHigh, width: 2),
                          boxShadow: [
                            BoxShadow(
                              color: themeProvider.themeHigh.withOpacity(0.2),
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
                                Icon(Icons.emoji_events, color: themeProvider.themeHigh, size: 20),
                                const SizedBox(width: 8),
                                Text(
                                  'Recent Achievements',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: themeProvider.contrast,
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            ...recentAchievements.map((achievement) => Padding(
                              padding: const EdgeInsets.only(bottom: 4),
                              child: Row(
                                children: [
                                  Icon(achievement.icon, color: achievement.color, size: 16),
                                  const SizedBox(width: 8),
                                  Text(
                                    achievement.title,
                                    style: TextStyle(color: themeProvider.contrast, fontSize: 12),
                                  ),
                                ],
                              ),
                            )),
                          ],
                        ),
                      );
                    },
                  ),
                ]),
              );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _showHoldingsPopup(BuildContext context, PortfolioProvider portfolioProvider) {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final marketDataProvider = Provider.of<MarketDataProvider>(context, listen: false);
    
    // Ensure holdings are loaded
    if (authProvider.user != null) {
      portfolioProvider.loadPortfolio(authProvider.user!.id);
    }
    
    // Pre-load market data for all holdings
    if (portfolioProvider.portfolio.isNotEmpty) {
      final symbols = portfolioProvider.portfolio.map((h) => h.symbol).toList();
      marketDataProvider.preloadSymbolPrices(symbols);
    }
    
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Container(
          constraints: const BoxConstraints(maxHeight: 600, maxWidth: 400),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: themeProvider.theme,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.account_balance_wallet,
                      color: themeProvider.contrast,
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Portfolio Holdings',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: themeProvider.contrast,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: Icon(
                        Icons.close,
                        color: themeProvider.contrast,
                      ),
                    ),
                  ],
                ),
              ),
              
              // Holdings List
              Flexible(
                child: Consumer<PortfolioProvider>(
                  builder: (context, provider, child) {
                    if (provider.isLoading) {
                      return const Padding(
                        padding: EdgeInsets.all(40),
                        child: Center(
                          child: CircularProgressIndicator(),
                        ),
                      );
                    }
                    
                    if (provider.portfolio.isEmpty) {
                      return Padding(
                        padding: const EdgeInsets.all(40),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.trending_up,
                              size: 48,
                              color: themeProvider.theme.withOpacity(0.5),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No Holdings',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: themeProvider.contrast,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Start trading to build your portfolio',
                              style: TextStyle(
                                color: themeProvider.contrast.withOpacity(0.7),
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      );
                    }
                    
                    return ListView.separated(
                      padding: const EdgeInsets.all(16),
                      shrinkWrap: true,
                      itemCount: provider.portfolio.length,
                      separatorBuilder: (context, index) => const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        final holding = provider.portfolio[index];
                        
                        // Get current market price from MarketDataProvider (using fresh Finnhub data)
                        final marketDataProvider = Provider.of<MarketDataProvider>(context, listen: false);
                        MarketAssetModel? marketAsset;
                        
                        try {
                          marketAsset = marketDataProvider.allAssets.firstWhere(
                            (asset) => asset.symbol.toUpperCase() == holding.symbol.toUpperCase(),
                          );
                          print('📊 Portfolio UI: Found market data for ${holding.symbol}: \$${marketAsset.price.toStringAsFixed(2)} (updated: ${marketAsset.lastUpdated})');
                        } catch (e) {
                          print('❌ Portfolio UI: No market data available for ${holding.symbol}');
                          marketAsset = null;
                        }
                        
                        // Calculate values using the most accurate price data
                        final currentPrice = marketAsset?.price ?? holding.avgPrice;
                        final currentValue = holding.quantity * currentPrice;
                        final purchaseValue = holding.quantity * holding.avgPrice;
                        final pnlDollar = currentValue - purchaseValue;
                        final pnlPercent = purchaseValue > 0 ? (pnlDollar / purchaseValue) * 100 : 0.0;
                        
                        if (marketAsset != null) {
                          print('✅ Portfolio UI: Using live Finnhub price for ${holding.symbol}: \$${currentPrice.toStringAsFixed(2)}');
                        } else {
                          print('⚠️ Portfolio UI: Using average price fallback for ${holding.symbol}: \$${currentPrice.toStringAsFixed(2)}');
                        }
                        
                        print('📊 P&L Debug for ${holding.symbol}:');
                        print('   Current Price: \$${currentPrice.toStringAsFixed(2)}');
                        print('   Quantity: ${holding.quantity}');
                        print('   Current Value: \$${currentValue.toStringAsFixed(2)}');
                        print('   Purchase Value: \$${purchaseValue.toStringAsFixed(2)}');
                        print('   P&L Dollar: \$${pnlDollar.toStringAsFixed(2)}');
                        print('   P&L Percent: ${pnlPercent.toStringAsFixed(2)}%');
                        
                        // Helper function to format currency values properly
                        String formatCurrency(double value) {
                          if (value.abs() >= 1000000) {
                            return '\$${(value / 1000000).toStringAsFixed(2)}M';
                          } else if (value.abs() >= 1000) {
                            return '\$${(value / 1000).toStringAsFixed(1)}K';
                          } else {
                            return '\$${value.toStringAsFixed(2)}';
                          }
                        }
                        
                        // Determine colors
                        final isPositive = pnlDollar >= 0;
                        final pnlColor = isPositive ? Colors.green : Colors.red;
                        
                        return GestureDetector(
                          onTap: () {
                            Navigator.of(context).pop();
                            _showSellDialog(context, holding);
                          },
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: themeProvider.backgroundHigh,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: themeProvider.theme.withOpacity(0.3),
                              ),
                            ),
                            child: Row(
                              children: [
                                // Stock Symbol and Quantity
                                Expanded(
                                  flex: 3,
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        holding.symbol,
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                          color: themeProvider.contrast,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      Text(
                                        '${holding.quantity.toStringAsFixed(2)} shares',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: themeProvider.contrast.withOpacity(0.7),
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      Text(
                                        'Avg: \$${holding.avgPrice.toStringAsFixed(2)}',
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: themeProvider.contrast.withOpacity(0.6),
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                                
                                // Current Price and Value
                                Expanded(
                                  flex: 2,
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.center,
                                    children: [
                                      Text(
                                        '\$${currentPrice.toStringAsFixed(2)}',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                          color: themeProvider.contrast,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      Text(
                                        'Price',
                                        style: TextStyle(
                                          fontSize: 10,
                                          color: themeProvider.contrast.withOpacity(0.6),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                
                                // P&L Display
                                Expanded(
                                  flex: 2,
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.end,
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            isPositive ? Icons.trending_up : Icons.trending_down,
                                            size: 16,
                                            color: pnlColor,
                                          ),
                                          const SizedBox(width: 4),
                                          Flexible(
                                            child: Text(
                                              '${isPositive ? '+' : ''}${formatCurrency(pnlDollar)}',
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 13,
                                                color: pnlColor,
                                              ),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ],
                                      ),
                                      Text(
                                        '${isPositive ? '+' : ''}${pnlPercent.toStringAsFixed(2)}%',
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          color: pnlColor,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Icon(
                                        Icons.arrow_forward_ios,
                                        size: 12,
                                        color: themeProvider.theme.withOpacity(0.7),
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
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showSellDialog(BuildContext context, PortfolioModel holding) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final marketDataProvider = Provider.of<MarketDataProvider>(context, listen: false);
    
    if (authProvider.user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please sign in to trade'),
        ),
      );
      return;
    }

    // Find the current market price for this asset
    final marketAsset = marketDataProvider.allAssets.firstWhere(
      (asset) => asset.symbol == holding.symbol,
      orElse: () => MarketAssetModel(
        symbol: holding.symbol,
        name: holding.symbol,
        price: holding.avgPrice, // Use avg price as fallback
        change: 0.0,
        changePercent: 0.0,
        type: 'stock',
        lastUpdated: DateTime.now(),
      ),
    );

    showDialog(
      context: context,
      builder: (context) => TradeDialog(
        asset: marketAsset,
        userId: authProvider.user!.id,
        initialTab: 1, // Start on sell tab
        maxQuantity: holding.quantity,
      ),
    );
  }
}