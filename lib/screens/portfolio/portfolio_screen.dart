import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/portfolio_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/achievement_provider.dart';
import '../../widgets/portfolio_summary_card.dart';
import '../../widgets/price_change_indicator.dart';
import '../main_navigation.dart';
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
              expandedHeight: 120,
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
                  child: const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.account_balance_wallet,
                          size: 48,
                          color: Color(0xFFf39c12),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'TRADING EMPIRE',
                          style: TextStyle(
                            fontSize: 24,
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
                          .loadPortfolio(authProvider.user!.id);
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
                    ...portfolioProvider.portfolio.map((holding) => Card(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Colors.blue,
                          child: Text(
                            holding.symbol.substring(0, 2).toUpperCase(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        title: Text(
                          holding.symbol,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        subtitle: Text(
                          '${holding.quantity} shares @ \$${holding.avgPrice.toStringAsFixed(2)}',
                        ),
                        trailing: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              '\$${holding.totalValue.toStringAsFixed(2)}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            // Note: This would need current price to calculate P&L
                            // For now, showing a placeholder
                            const PriceChangeIndicator(
                              change: 0.0,
                              showIcon: true,
                            ),
                          ],
                        ),
                      ),
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
}