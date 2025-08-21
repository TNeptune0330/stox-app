import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/market_data_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/theme_provider.dart';
import '../../models/market_asset_model.dart';
import '../../widgets/asset_list_tile.dart';
import '../../widgets/styled_market_indices_widget.dart';
import '../main_navigation.dart';
import 'trade_dialog.dart';
import 'asset_detail_screen.dart';

class MarketScreen extends StatefulWidget {
  const MarketScreen({super.key});

  @override
  State<MarketScreen> createState() => _MarketScreenState();
}

class _MarketScreenState extends State<MarketScreen> {
  final TextEditingController _searchController = TextEditingController();
  
  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  bool _isWeekend() {
    final now = DateTime.now();
    return now.weekday == DateTime.saturday || now.weekday == DateTime.sunday;
  }

  Widget _buildWeekendBanner(ThemeProvider themeProvider) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: themeProvider.backgroundHigh,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: themeProvider.contrast.withOpacity(0.1),
          width: 1,
        ),
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
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF59E0B).withOpacity(0.2), // Warning color
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.schedule,
              color: Color(0xFFF59E0B),
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Markets Closed',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: themeProvider.contrast,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Stock markets are closed on weekends. Trading will resume Monday.',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: themeProvider.contrast.withOpacity(0.7),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return Scaffold(
          backgroundColor: themeProvider.background,
          body: CustomScrollView(
            slivers: [
              // Simple app bar with Neon Navy styling
              SliverAppBar(
                backgroundColor: themeProvider.background,
                elevation: 0,
                pinned: true,
                title: Text(
                  'Markets',
                  style: Theme.of(context).textTheme.headlineLarge,
                ),
                actions: [
                  IconButton(
                    icon: Icon(Icons.refresh, color: themeProvider.contrast),
                    onPressed: () {
                      Provider.of<MarketDataProvider>(context, listen: false).refreshMarketData();
                    },
                  ),
                ],
              ),
              
              // Search Bar with Neon Navy styling
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Consumer<MarketDataProvider>(
                    builder: (context, marketProvider, child) {
                      return Column(
                        children: [
                          TextField(
                            controller: _searchController,
                            autocorrect: false,
                            enableSuggestions: false,
                            textInputAction: TextInputAction.search,
                            decoration: InputDecoration(
                              hintText: 'Search stocks...',
                              hintStyle: TextStyle(
                                color: themeProvider.contrast.withOpacity(0.6),
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                              prefixIcon: marketProvider.isLoading && _searchController.text.isNotEmpty
                                  ? Padding(
                                      padding: const EdgeInsets.all(12.0),
                                      child: SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          valueColor: AlwaysStoppedAnimation<Color>(themeProvider.theme),
                                        ),
                                      ),
                                    )
                                  : Icon(
                                      Icons.search,
                                      color: themeProvider.theme,
                                    ),
                              suffixIcon: _searchController.text.isNotEmpty
                                  ? IconButton(
                                      icon: Icon(
                                        Icons.clear,
                                        color: themeProvider.contrast.withOpacity(0.7),
                                      ),
                                      onPressed: () {
                                        _searchController.clear();
                                        marketProvider.setSearchQuery('');
                                      },
                                    )
                                  : null,
                              // Use theme's input decoration
                            ),
                            style: TextStyle(
                              color: themeProvider.contrast,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                            onChanged: (value) {
                              marketProvider.setSearchQuery(value);
                            },
                            onSubmitted: (value) {
                              marketProvider.performSearch();
                            },
                          ),
                          
                          // Search instruction widget with clickable suggestions
                          if (!marketProvider.hasSearchBeenPerformed) ...[
                            const SizedBox(height: 16),
                            Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: themeProvider.backgroundHigh,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: themeProvider.theme.withOpacity(0.3),
                                ),
                              ),
                              child: Column(
                                children: [
                                  Icon(
                                    Icons.search,
                                    size: 48,
                                    color: themeProvider.theme,
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    'Search for Stocks',
                                    style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: themeProvider.contrast,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Tap a suggestion below or enter a ticker symbol',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: themeProvider.contrast.withOpacity(0.7),
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                  const SizedBox(height: 12),
                                  Wrap(
                                    spacing: 8,
                                    runSpacing: 4,
                                    children: ['AAPL', 'TSLA', 'GOOGL', 'MSFT', 'AMZN', 'META', 'NVDA', 'NFLX']
                                        .map((ticker) => GestureDetector(
                                              onTap: () {
                                                _searchController.text = ticker;
                                                marketProvider.setSearchQuery(ticker);
                                                marketProvider.performSearch();
                                              },
                                              child: Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                                decoration: BoxDecoration(
                                                  color: themeProvider.theme.withOpacity(0.1),
                                                  borderRadius: BorderRadius.circular(8),
                                                  border: Border.all(
                                                    color: themeProvider.theme.withOpacity(0.3),
                                                  ),
                                                ),
                                                child: Text(
                                                  ticker,
                                                  style: TextStyle(
                                                    color: themeProvider.theme,
                                                    fontSize: 14,
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                ),
                                              ),
                                            ))
                                        .toList(),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      );
                    },
                  ),
                ),
              ),
              
              // Market Indices Widget (styled with bubbles)
              const SliverToBoxAdapter(
                child: StyledMarketIndicesWidget(),
              ),

              // Weekend Banner (only show on weekends)
              if (_isWeekend())
                SliverToBoxAdapter(
                  child: _buildWeekendBanner(themeProvider),
                ),
          
          // Content - either search results or top movers
          Consumer<MarketDataProvider>(
            builder: (context, marketProvider, child) {
              // Only show search results if user has performed a search (hit enter)
              final isShowingSearchResults = marketProvider.hasSearchBeenPerformed;
              
              if (isShowingSearchResults) {
                // Show search results
                if (marketProvider.isLoading && marketProvider.filteredAssets.isEmpty) {
                  return const SliverFillRemaining(
                    child: Center(
                      child: CircularProgressIndicator(),
                    ),
                  );
                }

                if (marketProvider.error != null) {
                  return SliverFillRemaining(
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.error_outline, size: 64, color: Colors.red),
                          const SizedBox(height: 16),
                          Text(
                            'Error',
                            style: Theme.of(context).textTheme.headlineSmall,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            marketProvider.error!,
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Colors.white70,
                            ),
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: () => marketProvider.refreshMarketData(),
                            child: const Text('Retry'),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                if (marketProvider.filteredAssets.isEmpty) {
                  return SliverFillRemaining(
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            marketProvider.isLoading ? Icons.search : Icons.search_off, 
                            size: 64, 
                            color: marketProvider.isLoading ? themeProvider.theme : Colors.grey,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            marketProvider.isLoading ? 'Searching...' : 'No Results Found',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: themeProvider.contrast,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            marketProvider.isLoading 
                                ? 'Looking for "${_searchController.text}" in global markets...'
                                : 'We searched global markets but couldn\'t find "${_searchController.text}". Try checking the spelling or symbol.',
                            style: TextStyle(
                              fontSize: 16,
                              color: themeProvider.contrast.withOpacity(0.7),
                            ),
                            textAlign: TextAlign.center,
                          ),
                          if (!marketProvider.isLoading) ...[
                            const SizedBox(height: 16),
                            Container(
                              padding: const EdgeInsets.all(16),
                              margin: const EdgeInsets.symmetric(horizontal: 32),
                              decoration: BoxDecoration(
                                color: themeProvider.theme.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: themeProvider.theme.withOpacity(0.3),
                                ),
                              ),
                              child: Column(
                                children: [
                                  Icon(
                                    Icons.lightbulb_outline,
                                    color: themeProvider.theme,
                                    size: 24,
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Try searching for:',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: themeProvider.contrast,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '• Company names: "Apple", "Tesla"\n• Stock symbols: "AAPL", "TSLA"\n• ETFs: "SPY", "QQQ", "SOXL"\n• Crypto: "Bitcoin", "Ethereum"',
                                    style: TextStyle(
                                      color: themeProvider.contrast.withOpacity(0.8),
                                      fontSize: 14,
                                    ),
                                    textAlign: TextAlign.left,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  );
                }

                return SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final asset = marketProvider.filteredAssets[index];
                      return AssetListTile(
                        asset: asset,
                        onTap: () => _showAssetDetail(context, asset),
                      );
                    },
                    childCount: marketProvider.filteredAssets.length,
                  ),
                );
              } else {
                // Show market movers when not searching
                return SliverList(
                  delegate: SliverChildListDelegate([
                    // Market Movers Sections
                    _buildMoverSection(context, themeProvider, 'NASDAQ 100', marketProvider.nasdaq100Movers),
                    _buildMoverSection(context, themeProvider, 'S&P 500', marketProvider.sp500Movers),
                    _buildMoverSection(context, themeProvider, 'DOW JONES', marketProvider.dowJonesMovers),
                  ]),
                );
              }
            },
          ),
        ],
      ),
    );
      },
    );
  }

  Widget _buildMoverSection(BuildContext context, ThemeProvider themeProvider, String title, List<MarketAssetModel> movers) {
    if (movers.isEmpty) {
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
            Icon(
              Icons.trending_up,
              color: themeProvider.theme,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                '$title Movers',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: themeProvider.contrast,
                ),
              ),
            ),
            SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(themeProvider.theme),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4), // Reduced margin
      decoration: BoxDecoration(
        color: themeProvider.backgroundHigh,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: themeProvider.theme.withOpacity(0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Compact Header
          Padding(
            padding: const EdgeInsets.all(12), // Reduced padding
            child: Row(
              children: [
                Icon(
                  Icons.trending_up,
                  color: themeProvider.theme,
                  size: 16, // Smaller icon
                ),
                const SizedBox(width: 8),
                Text(
                  '$title',
                  style: TextStyle(
                    fontSize: 14, // Smaller font
                    fontWeight: FontWeight.w700,
                    color: themeProvider.contrast,
                  ),
                ),
              ],
            ),
          ),
          // Compact Movers List - Show only top 2
          ...movers.take(2).map((asset) => Container(
            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
            child: _buildCompactAssetTile(asset, themeProvider),
          )),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildCompactAssetTile(MarketAssetModel asset, ThemeProvider themeProvider) {
    final isPositive = asset.changePercent >= 0;
    final changeColor = isPositive ? const Color(0xFF3B82F6) : const Color(0xFFEF4444);
    
    return GestureDetector(
      onTap: () => _showAssetDetail(context, asset),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: themeProvider.background.withOpacity(0.3),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: changeColor.withOpacity(0.2),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            // Symbol and name
            Expanded(
              flex: 3,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    asset.symbol,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: themeProvider.contrast,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    asset.name,
                    style: TextStyle(
                      fontSize: 10,
                      color: themeProvider.contrast.withOpacity(0.6),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            // Price
            Expanded(
              flex: 2,
              child: Text(
                '\$${asset.price.toStringAsFixed(2)}',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: themeProvider.contrast,
                ),
                textAlign: TextAlign.right,
              ),
            ),
            const SizedBox(width: 8),
            // Change percentage
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: changeColor,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    isPositive ? Icons.arrow_upward : Icons.arrow_downward,
                    size: 8,
                    color: Colors.white,
                  ),
                  const SizedBox(width: 2),
                  Text(
                    '${asset.changePercent.abs().toStringAsFixed(1)}%',
                    style: const TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
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

  void _showAssetDetail(BuildContext context, MarketAssetModel asset) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => AssetDetailScreen(asset: asset),
      ),
    );
  }

  void _showTradeDialog(BuildContext context, MarketAssetModel asset) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    
    if (authProvider.user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please sign in to trade'),
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => TradeDialog(
        asset: asset,
        userId: authProvider.user!.id,
      ),
    );
  }
}