import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/market_provider.dart';
import '../../providers/auth_provider.dart';
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
    final marketProvider = Provider.of<MarketProvider>(context, listen: false);
    switch (_tabController.index) {
      case 0:
        marketProvider.setAssetType('all');
        break;
      case 1:
        marketProvider.setAssetType('stock');
        break;
      case 2:
        marketProvider.setAssetType('crypto');
        break;
      case 3:
        marketProvider.setAssetType('etf');
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          AppBarTitle(
            title: 'Market',
            actions: [
              IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: () {
                  Provider.of<MarketProvider>(context, listen: false).refreshAssets();
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
                            Provider.of<MarketProvider>(context, listen: false)
                                .setSearchQuery('');
                          },
                        )
                      : null,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onChanged: (value) {
                  Provider.of<MarketProvider>(context, listen: false)
                      .setSearchQuery(value);
                },
              ),
            ),
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
          Consumer<MarketProvider>(
            builder: (context, marketProvider, child) {
              if (marketProvider.isLoading && marketProvider.assets.isEmpty) {
                return const SliverFillRemaining(
                  child: LoadingWidget(),
                );
              }

              if (marketProvider.error != null) {
                return SliverFillRemaining(
                  child: ErrorStateWidget(
                    message: marketProvider.error!,
                    onRetry: () => marketProvider.refreshAssets(),
                  ),
                );
              }

              if (marketProvider.assets.isEmpty) {
                return const SliverFillRemaining(
                  child: EmptyStateWidget(
                    title: 'No Assets Found',
                    message: 'Try adjusting your search or filters',
                    icon: Icons.search_off,
                  ),
                );
              }

              return SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final asset = marketProvider.assets[index];
                    return AssetListTile(
                      asset: asset,
                      onTap: () => _showTradeDialog(context, asset),
                    );
                  },
                  childCount: marketProvider.assets.length,
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  void _showTradeDialog(BuildContext context, asset) {
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