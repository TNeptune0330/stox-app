import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/portfolio_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/market_data_provider.dart';
import '../../models/market_asset_model.dart';
import '../../theme/modern_theme.dart';

class SimplePortfolioScreen extends StatefulWidget {
  const SimplePortfolioScreen({super.key});

  @override
  State<SimplePortfolioScreen> createState() => _SimplePortfolioScreenState();
}

class _SimplePortfolioScreenState extends State<SimplePortfolioScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializePortfolio();
    });
  }

  void _initializePortfolio() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final portfolioProvider = Provider.of<PortfolioProvider>(context, listen: false);
    
    if (authProvider.user != null) {
      portfolioProvider.loadPortfolio(authProvider.user!.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ModernTheme.backgroundPrimary,
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        title: const Text('Portfolio'),
        backgroundColor: ModernTheme.backgroundPrimary,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
      ),
      body: Consumer<PortfolioProvider>(
        builder: (context, portfolioProvider, child) {
          if (portfolioProvider.isLoading) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (portfolioProvider.error != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 64,
                    color: ModernTheme.accentRed,
                  ),
                  const SizedBox(height: ModernTheme.spaceL),
                  Text(
                    'Error loading portfolio',
                    style: ModernTheme.headlineMedium,
                  ),
                  const SizedBox(height: ModernTheme.spaceM),
                  Text(
                    portfolioProvider.error!,
                    textAlign: TextAlign.center,
                    style: ModernTheme.bodyMedium,
                  ),
                  const SizedBox(height: ModernTheme.spaceL),
                  ElevatedButton(
                    onPressed: () {
                      final authProvider = Provider.of<AuthProvider>(context, listen: false);
                      if (authProvider.user != null) {
                        portfolioProvider.loadPortfolio(authProvider.user!.id);
                      }
                    },
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(ModernTheme.spaceM),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Portfolio Summary Card - Dark theme style
                Container(
                  margin: const EdgeInsets.all(ModernTheme.spaceM),
                  padding: const EdgeInsets.all(ModernTheme.spaceL),
                  decoration: BoxDecoration(
                    color: ModernTheme.backgroundCard,
                    borderRadius: BorderRadius.circular(ModernTheme.radiusL),
                    boxShadow: ModernTheme.shadowCard,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Net Worth',
                        style: ModernTheme.bodyMedium.copyWith(
                          color: ModernTheme.textSecondary,
                        ),
                      ),
                      const SizedBox(height: ModernTheme.spaceS),
                      Text(
                        '\$${portfolioProvider.netWorth.toStringAsFixed(2)}',
                        style: ModernTheme.displayMedium.copyWith(
                          color: ModernTheme.accentBlue,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: ModernTheme.spaceM),
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Cash Balance',
                                  style: ModernTheme.bodySmall.copyWith(
                                    color: ModernTheme.textMuted,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '\$${portfolioProvider.cashBalance.toStringAsFixed(2)}',
                                  style: ModernTheme.titleMedium.copyWith(
                                    color: ModernTheme.textPrimary,
                                    fontWeight: FontWeight.w600,
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
                                  'Holdings Value',
                                  style: ModernTheme.bodySmall.copyWith(
                                    color: ModernTheme.textMuted,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '\$${portfolioProvider.holdingsValue.toStringAsFixed(2)}',
                                  style: ModernTheme.titleMedium.copyWith(
                                    color: ModernTheme.textPrimary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: ModernTheme.spaceL),
                
                // Holdings Section
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: ModernTheme.spaceM),
                  child: Text(
                    'Holdings',
                    style: ModernTheme.headlineMedium.copyWith(
                      color: ModernTheme.textPrimary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: ModernTheme.spaceM),
                
                if (portfolioProvider.portfolio.isEmpty)
                  Container(
                    margin: const EdgeInsets.all(ModernTheme.spaceM),
                    padding: const EdgeInsets.all(ModernTheme.spaceXL),
                    decoration: BoxDecoration(
                      color: ModernTheme.backgroundCard,
                      borderRadius: BorderRadius.circular(ModernTheme.radiusL),
                      boxShadow: ModernTheme.shadowCard,
                    ),
                    child: Column(
                      children: [
                        Icon(
                          Icons.account_balance_wallet_outlined,
                          size: 64,
                          color: ModernTheme.textMuted,
                        ),
                        const SizedBox(height: ModernTheme.spaceM),
                        Text(
                          'No Holdings',
                          style: ModernTheme.titleLarge.copyWith(
                            color: ModernTheme.textPrimary,
                          ),
                        ),
                        const SizedBox(height: ModernTheme.spaceS),
                        Text(
                          'Start trading to build your portfolio',
                          style: ModernTheme.bodyMedium.copyWith(
                            color: ModernTheme.textSecondary,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  )
                else
                  Consumer<MarketDataProvider>(
                    builder: (context, marketDataProvider, child) {
                      return Column(
                        children: portfolioProvider.portfolio.map((holding) {
                          // Get current market price
                          MarketAssetModel? marketAsset;
                          try {
                            marketAsset = marketDataProvider.assets.firstWhere(
                              (asset) => asset.symbol.toUpperCase() == holding.symbol.toUpperCase(),
                            );
                          } catch (e) {
                            // Skip if no market data available
                            return const SizedBox.shrink();
                          }
                          
                          final currentPrice = marketAsset?.price ?? 0.0;
                          final changePerShare = currentPrice - holding.avgPrice;
                          final changePercentPerShare = holding.avgPrice > 0 ? (changePerShare / holding.avgPrice) * 100 : 0.0;
                          final totalValue = currentPrice * holding.quantity;
                          final totalPnL = changePerShare * holding.quantity;
                          final totalCost = holding.avgPrice * holding.quantity;
                          final isPositive = changePerShare >= 0;
                          
                          return Container(
                            margin: const EdgeInsets.symmetric(
                              horizontal: ModernTheme.spaceM,
                              vertical: ModernTheme.spaceS,
                            ),
                            padding: const EdgeInsets.all(ModernTheme.spaceL),
                            decoration: BoxDecoration(
                              color: ModernTheme.backgroundCard,
                              borderRadius: BorderRadius.circular(ModernTheme.radiusL),
                              boxShadow: ModernTheme.shadowCard,
                            ),
                            child: Column(
                              children: [
                                // Header Row: Symbol and Total Value
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Row(
                                      children: [
                                        Container(
                                          width: 45,
                                          height: 45,
                                          decoration: BoxDecoration(
                                            color: ModernTheme.accentBlue.withOpacity(0.1),
                                            borderRadius: BorderRadius.circular(ModernTheme.radiusM),
                                          ),
                                          child: Center(
                                            child: Text(
                                              holding.symbol.substring(0, min(2, holding.symbol.length)),
                                              style: ModernTheme.labelLarge.copyWith(
                                                color: ModernTheme.accentBlue,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: ModernTheme.spaceM),
                                        Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              holding.symbol,
                                              style: ModernTheme.titleLarge.copyWith(
                                                color: ModernTheme.textPrimary,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            Text(
                                              '${holding.quantity.toStringAsFixed(0)} shares',
                                              style: ModernTheme.bodySmall.copyWith(
                                                color: ModernTheme.textMuted,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.end,
                                      children: [
                                        Text(
                                          '\$${totalValue.toStringAsFixed(2)}',
                                          style: ModernTheme.titleLarge.copyWith(
                                            color: ModernTheme.textPrimary,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        Text(
                                          'Total Value',
                                          style: ModernTheme.bodySmall.copyWith(
                                            color: ModernTheme.textMuted,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                
                                const SizedBox(height: ModernTheme.spaceM),
                                
                                // Price Information Grid
                                Row(
                                  children: [
                                    Expanded(
                                      child: _buildPriceInfoCard(
                                        'Bought At',
                                        '\$${holding.avgPrice.toStringAsFixed(2)}',
                                        null,
                                      ),
                                    ),
                                    const SizedBox(width: ModernTheme.spaceS),
                                    Expanded(
                                      child: _buildPriceInfoCard(
                                        'Current Price',
                                        '\$${currentPrice.toStringAsFixed(2)}',
                                        null,
                                      ),
                                    ),
                                  ],
                                ),
                                
                                const SizedBox(height: ModernTheme.spaceS),
                                
                                Row(
                                  children: [
                                    Expanded(
                                      child: _buildPriceInfoCard(
                                        'Change/Share',
                                        '${isPositive ? '+' : ''}\$${changePerShare.toStringAsFixed(2)}',
                                        isPositive,
                                      ),
                                    ),
                                    const SizedBox(width: ModernTheme.spaceS),
                                    Expanded(
                                      child: _buildPriceInfoCard(
                                        'Total P&L',
                                        '${isPositive ? '+' : ''}\$${totalPnL.toStringAsFixed(2)}',
                                        isPositive,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      );
                    },
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
  
  int min(int a, int b) => a < b ? a : b;
  
  Widget _buildPriceInfoCard(String label, String value, bool? isPositive) {
    Color valueColor = ModernTheme.textPrimary;
    if (isPositive != null) {
      valueColor = isPositive ? ModernTheme.accentGreen : ModernTheme.accentRed;
    }
    
    return Container(
      padding: const EdgeInsets.all(ModernTheme.spaceM),
      decoration: BoxDecoration(
        color: ModernTheme.backgroundPrimary,
        borderRadius: BorderRadius.circular(ModernTheme.radiusM),
        border: Border.all(
          color: ModernTheme.borderLight.withOpacity(0.5),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            label,
            style: ModernTheme.bodySmall.copyWith(
              color: ModernTheme.textMuted,
              fontSize: 11,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: ModernTheme.labelLarge.copyWith(
              color: valueColor,
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}