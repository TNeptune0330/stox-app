import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/market_data_provider.dart';
import '../../providers/auth_provider.dart';
import '../../theme/modern_theme.dart';
import '../../models/market_asset_model.dart';
import '../stock/stock_detail_screen.dart';
import '../../widgets/animations/animations.dart';

class SimpleMarketScreen extends StatefulWidget {
  const SimpleMarketScreen({super.key});

  @override
  State<SimpleMarketScreen> createState() => _SimpleMarketScreenState();
}

class _SimpleMarketScreenState extends State<SimpleMarketScreen> {
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

  Widget _buildWeekendBanner() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: ModernTheme.backgroundCard,
        borderRadius: BorderRadius.circular(ModernTheme.radiusM),
        border: Border.all(color: ModernTheme.borderLight),
        boxShadow: ModernTheme.shadowCard,
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: ModernTheme.accentOrange.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.schedule,
              color: ModernTheme.accentOrange,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Markets Closed',
                  style: ModernTheme.titleMedium,
                ),
                const SizedBox(height: 4),
                Text(
                  'Stock markets are closed on weekends. Trading will resume Monday.',
                  style: ModernTheme.bodyMedium,
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
    return Scaffold(
      backgroundColor: ModernTheme.backgroundPrimary,
      resizeToAvoidBottomInset: false,
      body: CustomScrollView(
        slivers: [
          // Modern App Bar
          SliverAppBar(
            leading: const Padding(
              padding: EdgeInsets.all(8.0),
              child: Icon(
                Icons.trending_up,
                size: 32,
                color: ModernTheme.accentBlue,
              ),
            ),
            title: Text(
              'Market',
              style: ModernTheme.headlineLarge.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            backgroundColor: ModernTheme.backgroundPrimary,
            foregroundColor: ModernTheme.textPrimary,
            elevation: 0,
            surfaceTintColor: Colors.transparent,
            floating: true,
            actions: [
              IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: () {
                  Provider.of<MarketDataProvider>(context, listen: false).refreshMarketData();
                },
              ),
            ],
          ),
          
          // Search Bar
          SliverToBoxAdapter(
            child: PageEntryAnimations.fadeSlideIn(
              delay: const Duration(milliseconds: 100),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Consumer<MarketDataProvider>(
                builder: (context, marketProvider, child) {
                  return Container(
                    decoration: BoxDecoration(
                      color: ModernTheme.backgroundCard,
                      borderRadius: BorderRadius.circular(ModernTheme.radiusL),
                      boxShadow: ModernTheme.shadowCard,
                    ),
                    child: TextField(
                      controller: _searchController,
                      autocorrect: false,
                      enableSuggestions: false,
                      textInputAction: TextInputAction.search,
                      decoration: InputDecoration(
                        hintText: 'Search stocks...',
                        hintStyle: ModernTheme.bodyMedium.copyWith(
                          color: ModernTheme.textMuted,
                        ),
                        prefixIcon: marketProvider.isLoading && _searchController.text.isNotEmpty
                            ? Padding(
                                padding: const EdgeInsets.all(12.0),
                                child: SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(ModernTheme.accentBlue),
                                  ),
                                ),
                              )
                            : Icon(
                                Icons.search,
                                color: ModernTheme.accentBlue,
                              ),
                        suffixIcon: _searchController.text.isNotEmpty
                            ? IconButton(
                                icon: Icon(
                                  Icons.clear,
                                  color: ModernTheme.textMuted,
                                ),
                                onPressed: () {
                                  _searchController.clear();
                                  marketProvider.setSearchQuery('');
                                },
                              )
                            : null,
                      ),
                      style: ModernTheme.bodyLarge,
                      onChanged: (value) {
                        marketProvider.setSearchQuery(value);
                      },
                      onSubmitted: (value) {
                        marketProvider.performSearch();
                      },
                    ),
                  );
                },
              ),
            ),
            ),
          ),
          
          // Weekend Banner (only show on weekends)
          if (_isWeekend()) 
            SliverToBoxAdapter(
              child: _buildWeekendBanner(),
            ),
          
          // Market Indices Overview
          SliverToBoxAdapter(
            child: PageEntryAnimations.fadeSlideIn(
              delay: const Duration(milliseconds: 200),
              child: _buildMarketIndicesSection(),
            ),
          ),
          
          // Section Header
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'Search Results',
                style: ModernTheme.titleLarge.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          
          // Content
          SliverFillRemaining(
            child: Consumer<MarketDataProvider>(
              builder: (context, marketProvider, child) {
                if (marketProvider.isLoading && marketProvider.filteredAssets.isEmpty) {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                }

                if (marketProvider.error != null) {
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
                          'Error',
                          style: ModernTheme.headlineMedium,
                        ),
                        const SizedBox(height: ModernTheme.spaceS),
                        Text(
                          marketProvider.error!,
                          textAlign: TextAlign.center,
                          style: ModernTheme.bodyMedium,
                        ),
                        const SizedBox(height: ModernTheme.spaceL),
                        ElevatedButton(
                          onPressed: () => marketProvider.refreshMarketData(),
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  );
                }

                // Show search prompt when no search has been performed
                if (marketProvider.filteredAssets.isEmpty && !marketProvider.hasSearchBeenPerformed) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.search,
                          size: 48,
                          color: ModernTheme.accentBlue,
                        ),
                        const SizedBox(height: ModernTheme.spaceL),
                        Text(
                          'Search for Stocks',
                          style: ModernTheme.headlineMedium,
                        ),
                        const SizedBox(height: ModernTheme.spaceS),
                        Text(
                          'Enter a ticker symbol or company name above',
                          style: ModernTheme.bodyMedium.copyWith(
                            color: ModernTheme.textMuted,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  );
                }
                
                // Show search results or "no results found"
                if (marketProvider.filteredAssets.isEmpty && marketProvider.hasSearchBeenPerformed) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          marketProvider.isLoading ? Icons.search : Icons.search_off,
                          size: 64,
                          color: marketProvider.isLoading ? ModernTheme.accentBlue : ModernTheme.textMuted,
                        ),
                        const SizedBox(height: ModernTheme.spaceL),
                        Text(
                          marketProvider.isLoading ? 'Searching...' : 'No Results Found',
                          style: ModernTheme.headlineMedium,
                        ),
                        const SizedBox(height: ModernTheme.spaceS),
                        Text(
                          marketProvider.isLoading 
                              ? 'Looking for "${_searchController.text}" in global markets...'
                              : 'We searched global markets but couldn\'t find "${_searchController.text}". Try checking the spelling or symbol.',
                          style: ModernTheme.bodyMedium,
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: marketProvider.filteredAssets.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final asset = marketProvider.filteredAssets[index];
                    return _buildAssetTile(asset);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAssetTile(MarketAssetModel asset) {
    final isPositive = asset.change >= 0;
    final changeColor = isPositive ? ModernTheme.accentGreen : ModernTheme.accentRed;
    
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => StockDetailScreen(asset: asset),
        ),
      ),
      child: AnimatedContainer(
        duration: ModernTheme.animationFast,
        margin: const EdgeInsets.only(bottom: ModernTheme.spaceS),
        padding: const EdgeInsets.all(ModernTheme.spaceM),
        decoration: BoxDecoration(
          color: ModernTheme.backgroundCard,
          borderRadius: BorderRadius.circular(ModernTheme.radiusL),
          boxShadow: ModernTheme.shadowCard,
        ),
        child: Row(
          children: [
            // Stock Icon
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: ModernTheme.accentBlue.withOpacity(0.2),
                borderRadius: BorderRadius.circular(ModernTheme.radiusM),
              ),
              child: Center(
                child: Text(
                  asset.symbol.substring(0, asset.symbol.length > 2 ? 2 : asset.symbol.length),
                  style: ModernTheme.titleMedium.copyWith(
                    color: ModernTheme.accentBlue,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            
            const SizedBox(width: ModernTheme.spaceM),
            
            // Stock Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    asset.symbol,
                    style: ModernTheme.titleMedium.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    asset.name,
                    style: ModernTheme.bodySmall.copyWith(
                      color: ModernTheme.textMuted,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            
            // Price & Change
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '\$${asset.price.toStringAsFixed(2)}',
                  style: ModernTheme.titleMedium.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: changeColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isPositive ? Icons.trending_up : Icons.trending_down,
                        size: 14,
                        color: changeColor,
                      ),
                      const SizedBox(width: 2),
                      Text(
                        '${isPositive ? '+' : ''}${asset.changePercent.toStringAsFixed(2)}%',
                        style: ModernTheme.bodySmall.copyWith(
                          color: changeColor,
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
    );
  }


  Widget _buildMarketIndicesSection() {
    return Container(
      margin: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.trending_up,
                color: ModernTheme.accentGreen,
                size: 24,
              ),
              const SizedBox(width: ModernTheme.spaceM),
              Text(
                'Market Indices',
                style: ModernTheme.titleLarge.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: ModernTheme.spaceM),
          SizedBox(
            height: 200,
            child: Consumer<MarketDataProvider>(
              builder: (context, marketProvider, child) {
                return ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    _buildIndexCard(
                      'NASDAQ 100',
                      marketProvider.nasdaq100Movers,
                      ModernTheme.accentBlue,
                    ),
                    _buildIndexCard(
                      'S&P 500',
                      marketProvider.sp500Movers,
                      ModernTheme.accentGreen,
                    ),
                    _buildIndexCard(
                      'DOW JONES',
                      marketProvider.dowJonesMovers,
                      ModernTheme.accentOrange,
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIndexCard(String indexName, List<MarketAssetModel> movers, Color accentColor) {
    return GestureDetector(
      onTap: movers.isEmpty ? () {
        Provider.of<MarketDataProvider>(context, listen: false).refreshMarketData();
      } : null,
      child: Container(
        width: 280,
        margin: const EdgeInsets.only(right: ModernTheme.spaceM),
        padding: const EdgeInsets.all(ModernTheme.spaceM),
        decoration: BoxDecoration(
          color: ModernTheme.backgroundCard,
          borderRadius: BorderRadius.circular(ModernTheme.radiusL),
          boxShadow: ModernTheme.shadowCard,
          border: Border.all(
            color: accentColor.withOpacity(0.3),
            width: 1,
          ),
        ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: accentColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.show_chart,
                  color: accentColor,
                  size: 20,
                ),
              ),
              const SizedBox(width: ModernTheme.spaceS),
              Text(
                indexName,
                style: ModernTheme.titleMedium.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: ModernTheme.spaceM),
          
          // Top Movers
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Top Movers',
                  style: ModernTheme.bodySmall.copyWith(
                    color: ModernTheme.textMuted,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: ModernTheme.spaceS),
                Expanded(
                  child: movers.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.refresh,
                                color: ModernTheme.textMuted,
                                size: 20,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Tap to refresh',
                                style: ModernTheme.bodySmall.copyWith(
                                  color: ModernTheme.textMuted,
                                ),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          itemCount: movers.take(3).length,
                          itemBuilder: (context, index) {
                            final asset = movers[index];
                            final isPositive = asset.changePercent >= 0;
                            final changeColor = isPositive ? ModernTheme.accentGreen : ModernTheme.accentRed;
                            
                            return GestureDetector(
                              onTap: () => _navigateToStockDetail(asset),
                              child: Container(
                                margin: const EdgeInsets.only(bottom: 6),
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: changeColor.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        asset.symbol,
                                        style: ModernTheme.bodySmall.copyWith(
                                          fontWeight: FontWeight.w600,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    Text(
                                      '${isPositive ? '+' : ''}${asset.changePercent.toStringAsFixed(1)}%',
                                      style: ModernTheme.bodySmall.copyWith(
                                        color: changeColor,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
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

  void _navigateToStockDetail(MarketAssetModel asset) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => StockDetailScreen(asset: asset),
      ),
    );
  }

  void _showTradeDialog(BuildContext context, MarketAssetModel asset) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    
    if (authProvider.user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please sign in to trade'),
          backgroundColor: ModernTheme.accentRed,
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => _buildMarketTradeDialog(asset),
    );
  }

  Widget _buildMarketTradeDialog(MarketAssetModel asset) {
    final TextEditingController quantityController = TextEditingController();
    
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.all(ModernTheme.spaceL),
        decoration: BoxDecoration(
          color: ModernTheme.backgroundCard,
          borderRadius: BorderRadius.circular(ModernTheme.radiusXL),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: ModernTheme.accentBlue.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(ModernTheme.radiusM),
                  ),
                  child: Center(
                    child: Text(
                      asset.symbol.substring(0, 1),
                      style: ModernTheme.titleLarge.copyWith(
                        color: ModernTheme.accentBlue,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: ModernTheme.spaceM),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        asset.symbol,
                        style: ModernTheme.titleLarge.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        asset.name,
                        style: ModernTheme.bodyMedium.copyWith(
                          color: ModernTheme.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                  color: ModernTheme.textMuted,
                ),
              ],
            ),
            
            const SizedBox(height: ModernTheme.spaceXL),
            
            // Current Price Info
            Container(
              padding: const EdgeInsets.all(ModernTheme.spaceM),
              decoration: BoxDecoration(
                color: ModernTheme.backgroundPrimary,
                borderRadius: BorderRadius.circular(ModernTheme.radiusM),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Current Price:',
                    style: ModernTheme.bodyMedium,
                  ),
                  Text(
                    '\$${asset.price.toStringAsFixed(2)}',
                    style: ModernTheme.bodyMedium.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: ModernTheme.spaceL),
            
            // Quantity Input
            TextField(
              controller: quantityController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Quantity',
                hintText: 'Enter number of shares',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(ModernTheme.radiusM),
                ),
              ),
            ),
            
            const SizedBox(height: ModernTheme.spaceXL),
            
            // Action Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  _executeMarketTrade(context, asset, quantityController.text);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: ModernTheme.accentGreen,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: ModernTheme.spaceM),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(ModernTheme.radiusM),
                  ),
                ),
                child: Text(
                  'BUY',
                  style: ModernTheme.titleMedium.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _executeMarketTrade(BuildContext context, MarketAssetModel asset, String quantityText) {
    final quantity = int.tryParse(quantityText);
    if (quantity == null || quantity <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please enter a valid quantity'),
          backgroundColor: ModernTheme.accentRed,
        ),
      );
      return;
    }

    Navigator.pop(context);
    
    // Show success message with animation
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('BUY order for $quantity shares of ${asset.symbol} executed!'),
        backgroundColor: ModernTheme.accentGreen,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(ModernTheme.radiusM),
        ),
      ),
    );
  }
}