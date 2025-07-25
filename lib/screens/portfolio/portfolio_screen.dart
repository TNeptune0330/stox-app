import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/portfolio_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/achievement_provider.dart';
import '../../providers/market_data_provider.dart';
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
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF1a1a2e),
              Color(0xFF0f1419),
            ],
          ),
        ),
        child: CustomScrollView(
          slivers: [
            // Game-like Header
            SliverAppBar(
              expandedHeight: ResponsiveUtils.isTablet(context) ? 160 : 120,
              floating: false,
              pinned: true,
              backgroundColor: Colors.transparent,
              flexibleSpace: FlexibleSpaceBar(
                background: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFF533483), Color(0xFF7209b7)],
                    ),
                  ),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.account_balance_wallet,
                          size: ResponsiveUtils.getIconSize(context, 48),
                          color: const Color(0xFFf39c12),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'TRADING EMPIRE',
                          style: TextStyle(
                            fontSize: ResponsiveUtils.getFontSize(context, 24),
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                            letterSpacing: 2,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.history, color: Colors.white),
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
                  icon: const Icon(Icons.refresh, color: Colors.white),
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
                          color: const Color(0xFF1a1a2e),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFFf39c12), width: 2),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.emoji_events, color: Color(0xFFf39c12), size: 20),
                                const SizedBox(width: 8),
                                Text(
                                  'Recent Achievements',
                                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: const Color(0xFFf39c12),
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
                                    style: const TextStyle(color: Colors.white70, fontSize: 12),
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