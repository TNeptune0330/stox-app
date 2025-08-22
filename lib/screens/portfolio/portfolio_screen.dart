import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/portfolio_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/achievement_provider.dart';
import '../../providers/market_data_provider.dart';
import '../../providers/theme_provider.dart';
import '../../providers/watchlist_provider.dart';
import '../../widgets/portfolio_summary_card.dart';
import '../../widgets/achievement_banner_widget.dart';
import '../../utils/responsive_utils.dart';
import '../../models/portfolio_model.dart';
import '../../models/market_asset_model.dart';
import '../../mixins/performance_optimized_mixin.dart';
import '../main_navigation.dart';
import '../market/trade_dialog.dart';
import 'transaction_history.dart';
import 'holdings_page.dart';
import 'watchlist_page.dart';

class PortfolioScreen extends StatefulWidget {
  const PortfolioScreen({super.key});

  @override
  State<PortfolioScreen> createState() => _PortfolioScreenState();
}

class _PortfolioScreenState extends State<PortfolioScreen> 
    with PerformanceOptimizedMixin, TickerProviderStateMixin {
  
  bool get _reducedMotion => MediaQuery.maybeOf(context)?.disableAnimations ?? false;

  // Animated page route helper
  Route<T> _fadeSlideRoute<T>(Widget page) => PageRouteBuilder<T>(
    transitionDuration: _reducedMotion ? Motion.fast : Motion.med,
    reverseTransitionDuration: _reducedMotion ? Motion.fast : Motion.med,
    pageBuilder: (_, __, ___) => page,
    transitionsBuilder: (_, a, __, child) {
      final curved = CurvedAnimation(parent: a, curve: Motion.easeOut, reverseCurve: Curves.easeOut);
      if (_reducedMotion) {
        return FadeTransition(opacity: curved, child: child);
      }
      final offset = Tween(begin: const Offset(0, 0.06), end: Offset.zero).animate(curved);
      return FadeTransition(
        opacity: curved,
        child: SlideTransition(position: offset, child: child),
      );
    },
  );
  
  @override
  void initState() {
    super.initState();
    
    // Use debounced initialization to avoid unnecessary calls
    debouncedSetState(() {
      _initializePortfolioData();
      _initializeWatchlist();
    }, delay: const Duration(milliseconds: 100));
  }
  
  void _initializeWatchlist() {
    // Initialize watchlist provider
    final watchlistProvider = Provider.of<WatchlistProvider>(context, listen: false);
    watchlistProvider.initialize();
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
              // Simple app bar
              SliverAppBar(
                backgroundColor: themeProvider.background,
                elevation: 0,
                pinned: true,
                title: Text(
                  'Portfolio',
                  style: Theme.of(context).textTheme.headlineLarge,
                ),
                actions: [
                  IconButton(
                    icon: Icon(Icons.history, color: themeProvider.contrast),
                    onPressed: () {
                      Navigator.push(
                        context,
                        _fadeSlideRoute(const TransactionHistoryScreen()),
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

                  return SliverPadding(
                    padding: const EdgeInsets.all(16),
                    sliver: SliverList(
                      delegate: SliverChildListDelegate([
                        // Hero Wallet Card
                        _AnimatedListItem(
                          index: 0,
                          child: _buildWalletCard(themeProvider, portfolioProvider),
                        ),
                        const SizedBox(height: 24),
                        
                        // Stats Card
                        _AnimatedListItem(
                          index: 1,
                          child: _buildStatsCard(themeProvider, portfolioProvider),
                        ),
                        const SizedBox(height: 24),
                        
                        // Achievements Preview
                        _AnimatedListItem(
                          index: 2,
                          child: _buildAchievementsPreview(themeProvider),
                        ),
                        const SizedBox(height: 24),
                        
                        // Watchlist
                        _AnimatedListItem(
                          index: 3,
                          child: _buildWatchlist(themeProvider),
                        ),
                        const SizedBox(height: 24),
                        
                        // Transactions Button
                        _AnimatedListItem(
                          index: 4,
                          child: _buildTransactionsButton(themeProvider),
                        ),
                        const SizedBox(height: 100), // Bottom padding for nav bar
                      ]),
                    ),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }
  
  Widget _buildWalletCard(ThemeProvider themeProvider, PortfolioProvider portfolioProvider) {
    return _Pressable(
      onTap: () {
        Navigator.of(context).push(
          _fadeSlideRoute(const HoldingsPage()),
        );
      },
      child: Container(
        height: 168,
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
        child: Stack(
          children: [
            // Background pattern
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.16),
                  borderRadius: BorderRadius.circular(24),
                ),
              ),
            ),
            // Content
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Total Balance',
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
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    'Portfolio Value',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.8),
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildStatsCard(ThemeProvider themeProvider, PortfolioProvider portfolioProvider) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: themeProvider.backgroundHigh,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: themeProvider.contrast.withOpacity(0.1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.24),
            blurRadius: 24,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Total P&L',
                  style: TextStyle(
                    color: themeProvider.contrast.withOpacity(0.7),
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: portfolioProvider.totalPnL >= 0 ? themeProvider.theme : const Color(0xFFEF4444),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    '${portfolioProvider.totalPnL >= 0 ? '+' : ''}\$${portfolioProvider.totalPnL.toStringAsFixed(2)}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 24),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Day Change',
                  style: TextStyle(
                    color: themeProvider.contrast.withOpacity(0.7),
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: portfolioProvider.totalPnL >= 0 ? themeProvider.theme : const Color(0xFFEF4444),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    '${portfolioProvider.totalPnLPercentage >= 0 ? '+' : ''}${portfolioProvider.totalPnLPercentage.toStringAsFixed(2)}%',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildAchievementsPreview(ThemeProvider themeProvider) {
    return Consumer<AchievementProvider>(
      builder: (context, achievementProvider, child) {
        // Get only EARNED achievements (isUnlocked = true)
        final earnedAchievements = achievementProvider.achievements
            .where((achievement) => achievement.isUnlocked == true)
            .take(3) // Show max 3 earned achievements
            .toList();
        
        return Column(
          children: [
            // Section header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Achievements',
                  style: Theme.of(context).textTheme.headlineLarge,
                ),
                TextButton(
                  onPressed: () {
                    // Navigate to achievements tab - use a simpler approach
                    Navigator.of(context).popUntil((route) => route.isFirst);
                    // This will pop back to main navigation and user can manually tap achievements
                  },
                  child: const Text(
                    'See all',
                    style: TextStyle(
                      color: Color(0xFF3B82F6), // INFO color
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Achievement cards - ONLY EARNED ONES
            if (earnedAchievements.isNotEmpty)
              SizedBox(
                height: 100, // Reduced height for better proportion
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: earnedAchievements.length,
                  separatorBuilder: (context, index) => const SizedBox(width: 12),
                  itemBuilder: (context, index) {
                    final achievement = earnedAchievements[index];
                    // Use colorful accents for earned achievements
                    final colors = [
                      const Color(0xFFEC4899), // Pink
                      const Color(0xFFEAB308), // Yellow
                      const Color(0xFFEA580C), // Orange
                      const Color(0xFF06B6D4), // Cyan
                      const Color(0xFF8B5CF6), // Purple
                    ];
                    final accentColor = colors[index % colors.length];
                    
                    return Container(
                      width: 200, // Reduced width
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: themeProvider.backgroundHigh,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: accentColor.withOpacity(0.3)),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.12),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row( // Changed to Row for more compact layout
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: accentColor.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              achievement.icon,
                              color: accentColor,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  achievement.title,
                                  style: TextStyle(
                                    color: themeProvider.contrast,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Completed!',
                                  style: TextStyle(
                                    color: accentColor,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              )
            else
              Container(
                height: 80,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: themeProvider.backgroundHigh,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: themeProvider.contrast.withOpacity(0.1)),
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.emoji_events_outlined,
                        color: themeProvider.contrast.withOpacity(0.5),
                        size: 24,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Start trading to earn achievements!',
                        style: TextStyle(
                          color: themeProvider.contrast.withOpacity(0.7),
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
  
  Widget _buildWatchlist(ThemeProvider themeProvider) {
    return Consumer<WatchlistProvider>(
      builder: (context, watchlistProvider, child) {
        return Column(
          children: [
            // Section header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Watchlist',
                  style: Theme.of(context).textTheme.headlineLarge,
                ),
                TextButton(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => const WatchlistPage(),
                      ),
                    );
                  },
                  child: const Text(
                    'View all',
                    style: TextStyle(
                      color: Color(0xFF3B82F6), // INFO color
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Loading or error state
            if (watchlistProvider.isLoading)
              Container(
                height: 120,
                decoration: BoxDecoration(
                  color: themeProvider.backgroundHigh,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Center(
                  child: CircularProgressIndicator(),
                ),
              )
            else if (watchlistProvider.error != null)
              Container(
                height: 120,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: themeProvider.backgroundHigh,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Center(
                  child: Text(
                    'Error loading watchlist',
                    style: TextStyle(
                      color: themeProvider.contrast.withOpacity(0.7),
                      fontSize: 14,
                    ),
                  ),
                ),
              )
            else
              // Real watchlist grid
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 1.4,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                ),
                itemCount: watchlistProvider.watchlistAssets.length.clamp(0, 4), // Max 4 items
                itemBuilder: (context, index) {
                  final asset = watchlistProvider.watchlistAssets[index];
                  
                  // Use colorful accents for variety
                  final colors = [
                    const Color(0xFFEA580C), // Orange
                    const Color(0xFFEC4899), // Pink
                    const Color(0xFF3B82F6), // Blue
                    const Color(0xFF06B6D4), // Cyan
                  ];
                  final accentColor = asset.changePercent >= 0 
                      ? const Color(0xFF3B82F6) // Blue for positive
                      : const Color(0xFFEF4444);
                  
                  return GestureDetector(
                    onTap: () {
                      // TODO: Navigate to asset detail or trading screen
                    },
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: themeProvider.backgroundHigh,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: colors[index % colors.length].withOpacity(0.2)),
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
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Ticker chip
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: colors[index % colors.length].withOpacity(0.2),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              asset.symbol,
                              style: TextStyle(
                                color: colors[index % colors.length],
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          const Spacer(),
                          // Price
                          Text(
                            '\$${asset.price.toStringAsFixed(2)}',
                            style: TextStyle(
                              color: themeProvider.contrast,
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          // Percent change pill
                          Align(
                            alignment: Alignment.centerRight,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: accentColor,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                '${asset.changePercent >= 0 ? '+' : ''}${asset.changePercent.toStringAsFixed(1)}%',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
          ],
        );
      },
    );
  }
  
  Widget _buildTransactionsButton(ThemeProvider themeProvider) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const TransactionHistoryScreen(),
            ),
          );
        },
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: themeProvider.contrast.withOpacity(0.3)),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          padding: const EdgeInsets.symmetric(vertical: 16),
        ),
        child: Text(
          'View All Transactions',
          style: TextStyle(
            color: themeProvider.contrast,
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
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
                child: Consumer2<PortfolioProvider, MarketDataProvider>(
                  builder: (context, provider, marketDataProvider, child) {
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
                      separatorBuilder: (context, index) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final holding = provider.portfolio[index];
                        
                        // Use MarketDataProvider from Consumer2 for automatic updates
                        MarketAssetModel? marketAsset;
                        
                        try {
                          marketAsset = marketDataProvider.allAssets.firstWhere(
                            (asset) => asset.symbol.toUpperCase() == holding.symbol.toUpperCase(),
                          );
                          print('📊 Portfolio UI: Found live market data for ${holding.symbol}: \$${marketAsset.price.toStringAsFixed(2)} (updated: ${marketAsset.lastUpdated})');
                        } catch (e) {
                          print('❌ Portfolio UI: No market data available for ${holding.symbol} - skipping until data loads');
                          // Skip this item until real market data is available
                          return const SizedBox.shrink();
                        }
                        
                        // Only calculate if we have REAL market data
                        final currentPrice = marketAsset.price; // NO FALLBACK - only real data
                        final pnlDollar = currentPrice - holding.avgPrice; // Per-share price difference
                        final pnlPercent = holding.avgPrice > 0 ? (pnlDollar / holding.avgPrice) * 100 : 0.0;
                        
                        print('✅ Portfolio UI: Using LIVE Finnhub price for ${holding.symbol}: \$${currentPrice.toStringAsFixed(2)}');
                        
                        print('📊 P&L Debug for ${holding.symbol}:');
                        print('   Current Price: \$${currentPrice.toStringAsFixed(2)}');
                        print('   Average Price: \$${holding.avgPrice.toStringAsFixed(2)}');
                        print('   Quantity: ${holding.quantity}');  
                        print('   P&L per Share: \$${pnlDollar.toStringAsFixed(2)}');
                        print('   P&L Percent: ${pnlPercent.toStringAsFixed(2)}%');
                        
                        // Simple formatting for per-share price differences
                        String formatCurrency(double value) {
                          return '\$${value.toStringAsFixed(2)}';
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

// Animated list item with staggered entry
class _AnimatedListItem extends StatefulWidget {
  final Widget child;
  final int index;
  const _AnimatedListItem({super.key, required this.child, required this.index});
  @override State<_AnimatedListItem> createState() => _AnimatedListItemState();
}

class _AnimatedListItemState extends State<_AnimatedListItem> 
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fadeAnimation;
  late final Animation<Offset> _slideAnimation;
  
  @override
  void initState() {
    super.initState();
    
    _controller = AnimationController(
      duration: Motion.med, // Will be updated after frame
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Motion.easeOut,
    ));
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.2),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Motion.easeOut,
    ));
    
    // Delay initialization to avoid MediaQuery during initState
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final reducedMotion = MediaQuery.maybeOf(context)?.disableAnimations ?? false;
        _controller.duration = reducedMotion ? Motion.fast : Motion.med;
        
        // Stagger the animations based on index
        Future.delayed(Duration(milliseconds: widget.index * 200), () {
          if (mounted) _controller.forward();
        });
      }
    });
  }
  
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    final reducedMotion = MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    
    if (reducedMotion) {
      return widget.child;
    }
    
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return FadeTransition(
          opacity: _fadeAnimation,
          child: SlideTransition(
            position: _slideAnimation,
            child: widget.child,
          ),
        );
      },
    );
  }
}

// Pressable button with micro-motion
class _Pressable extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;
  const _Pressable({super.key, required this.child, required this.onTap});
  @override State<_Pressable> createState() => _PressableState();
}

class _PressableState extends State<_Pressable> with SingleTickerProviderStateMixin {
  late final _c = AnimationController(
    duration: Motion.fast, 
    vsync: this, 
    lowerBound: .98, 
    upperBound: 1.0,
  )..value = 1.0;
  
  @override void dispose() { _c.dispose(); super.dispose(); }
  
  @override Widget build(BuildContext context) {
    final reducedMotion = MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    
    return GestureDetector(
      onTapDown: (_) => reducedMotion ? null : _c.reverse(),
      onTapUp:   (_) => reducedMotion ? null : _c.forward(),
      onTapCancel: () => reducedMotion ? null : _c.forward(),
      onTap: widget.onTap,
      child: reducedMotion 
          ? widget.child
          : ScaleTransition(scale: _c, child: widget.child),
    );
  }
}