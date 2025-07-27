import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/market_data_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/theme_provider.dart';
import '../../models/market_asset_model.dart';
import '../../widgets/asset_list_tile.dart';
import '../main_navigation.dart';
import 'trade_dialog.dart';

class MarketScreen extends StatefulWidget {
  const MarketScreen({super.key});

  @override
  State<MarketScreen> createState() => _MarketScreenState();
}

class _MarketScreenState extends State<MarketScreen> with TickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _tabController.addListener(_onTabChanged);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onTabChanged() {
    final marketProvider = Provider.of<MarketDataProvider>(context, listen: false);
    switch (_tabController.index) {
      case 0:
        marketProvider.setFilter('all');
        break;
      case 1:
        marketProvider.setFilter('stock');
        break;
      case 2:
        marketProvider.setFilter('crypto');
        break;
      case 3:
        marketProvider.setFilter('etf');
        break;
    }
  }

  bool _isWeekend() {
    final now = DateTime.now();
    return now.weekday == DateTime.saturday || now.weekday == DateTime.sunday;
  }

  Widget _buildWeekendBanner(ThemeProvider themeProvider) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: themeProvider.backgroundHigh,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: themeProvider.theme.withOpacity(0.3),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: themeProvider.theme.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: themeProvider.theme.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.schedule,
              color: themeProvider.theme,
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
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: themeProvider.contrast,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Stock markets are closed on weekends. Trading will resume Monday.',
                  style: TextStyle(
                    fontSize: 14,
                    color: themeProvider.contrast,
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
          body: CustomScrollView(
            slivers: [
              AppBarTitle(
                title: 'Market',
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
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Search assets...',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                _searchController.clear();
                                Provider.of<MarketDataProvider>(context, listen: false)
                                    .setSearchQuery('');
                              },
                            )
                          : null,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onChanged: (value) {
                      Provider.of<MarketDataProvider>(context, listen: false)
                          .setSearchQuery(value);
                    },
                  ),
                ),
              ),
              
              // Weekend Banner (only show on weekends)
              if (_isWeekend())
                SliverToBoxAdapter(
                  child: _buildWeekendBanner(themeProvider),
                ),
              
              // Asset Type Tabs
          SliverToBoxAdapter(
            child: TabBar(
              controller: _tabController,
              tabs: const [
                Tab(text: 'All'),
                Tab(text: 'Stocks'),
                Tab(text: 'Crypto'),
                Tab(text: 'ETFs'),
              ],
            ),
          ),
          
          // Asset List
          Consumer<MarketDataProvider>(
            builder: (context, marketProvider, child) {
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
                        const Icon(Icons.search_off, size: 64, color: Colors.grey),
                        const SizedBox(height: 16),
                        Text(
                          'No Assets Found',
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Try adjusting your search or filters',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.white70,
                          ),
                        ),
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
                      onTap: () => _showTradeDialog(context, asset),
                    );
                  },
                  childCount: marketProvider.filteredAssets.length,
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