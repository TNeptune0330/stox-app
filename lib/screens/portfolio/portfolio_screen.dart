import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/portfolio_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/achievement_provider.dart';
import '../../providers/market_data_provider.dart';
import '../../providers/theme_provider.dart';
import '../../widgets/portfolio_summary_card.dart';
import '../../widgets/price_change_indicator.dart';
import '../../widgets/achievement_banner_widget.dart';
import '../../widgets/portfolio_holding_tile.dart';
import '../../utils/responsive_utils.dart';
import '../../models/portfolio_model.dart';
import '../../models/market_asset_model.dart';
import '../main_navigation.dart';
import '../market/trade_dialog.dart';
import 'transaction_history.dart';

class PortfolioScreen extends StatefulWidget {
  const PortfolioScreen({super.key});

  @override
  State<PortfolioScreen> createState() => _PortfolioScreenState();
}

class _PortfolioScreenState extends State<PortfolioScreen> {
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
                  // Portfolio Summary
                  PortfolioSummaryCard(
                    cashBalance: portfolioProvider.cashBalance,
                    holdingsValue: portfolioProvider.holdingsValue,
                    netWorth: portfolioProvider.netWorth,
                    totalPnL: portfolioProvider.totalPnL,
                    totalPnLPercentage: portfolioProvider.totalPnLPercentage,
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

                  // Holdings Section
                  if (portfolioProvider.portfolio.isNotEmpty) ...[
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(
                        'Holdings',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    ...portfolioProvider.portfolio.map((holding) => PortfolioHoldingTile(
                      holding: holding,
                      onTap: () => _showSellDialog(context, holding),
                    )),
                  ] else ...[
                    const Padding(
                      padding: EdgeInsets.all(32),
                      child: EmptyStateWidget(
                        title: 'No Holdings',
                        message: 'Start trading to build your portfolio',
                        icon: Icons.trending_up,
                      ),
                    ),
                  ],
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