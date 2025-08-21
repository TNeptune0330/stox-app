import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/watchlist_provider.dart';
import '../../providers/theme_provider.dart';
import '../../models/market_asset_model.dart';
import '../market/asset_detail_screen.dart';

class WatchlistPage extends StatefulWidget {
  const WatchlistPage({super.key});

  @override
  State<WatchlistPage> createState() => _WatchlistPageState();
}

class _WatchlistPageState extends State<WatchlistPage> {
  
  @override
  void initState() {
    super.initState();
    _loadWatchlistData();
  }
  
  void _loadWatchlistData() {
    final watchlistProvider = Provider.of<WatchlistProvider>(context, listen: false);
    watchlistProvider.initialize();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return Scaffold(
          backgroundColor: themeProvider.background,
          appBar: AppBar(
            backgroundColor: themeProvider.background,
            elevation: 0,
            leading: IconButton(
              icon: Icon(Icons.arrow_back, color: themeProvider.contrast),
              onPressed: () => Navigator.of(context).pop(),
            ),
            title: Text(
              'Watchlist',
              style: TextStyle(
                color: themeProvider.contrast,
                fontSize: 24,
                fontWeight: FontWeight.w800,
              ),
            ),
            actions: [
              IconButton(
                icon: Icon(Icons.refresh, color: themeProvider.contrast),
                onPressed: () {
                  final watchlistProvider = Provider.of<WatchlistProvider>(context, listen: false);
                  watchlistProvider.refresh();
                },
              ),
              IconButton(
                icon: Icon(Icons.add, color: themeProvider.contrast),
                onPressed: () => _showAddToWatchlistDialog(),
              ),
            ],
          ),
          body: Consumer<WatchlistProvider>(
            builder: (context, watchlistProvider, child) {
              if (watchlistProvider.isLoading) {
                return const Center(
                  child: CircularProgressIndicator(),
                );
              }

              if (watchlistProvider.error != null) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.error_outline,
                        size: 64,
                        color: themeProvider.contrast.withOpacity(0.5),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Error Loading Watchlist',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: themeProvider.contrast,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        watchlistProvider.error!,
                        style: TextStyle(
                          color: themeProvider.contrast.withOpacity(0.7),
                          fontSize: 14,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadWatchlistData,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                );
              }

              if (watchlistProvider.watchlistAssets.isEmpty) {
                return _buildEmptyState(themeProvider);
              }

              return SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Stats header
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: themeProvider.backgroundHigh,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: themeProvider.theme.withOpacity(0.2)),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.bookmark,
                            color: themeProvider.theme,
                            size: 24,
                          ),
                          const SizedBox(width: 12),
                          Text(
                            '${watchlistProvider.watchlistAssets.length} stocks in your watchlist',
                            style: TextStyle(
                              color: themeProvider.contrast,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    
                    // Watchlist grid
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        childAspectRatio: 1.35,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                      ),
                      itemCount: watchlistProvider.watchlistAssets.length,
                      itemBuilder: (context, index) {
                        final asset = watchlistProvider.watchlistAssets[index];
                        return _buildWatchlistCard(asset, index, themeProvider, watchlistProvider);
                      },
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildEmptyState(ThemeProvider themeProvider) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.bookmark_outline,
              size: 80,
              color: themeProvider.theme.withOpacity(0.5),
            ),
            const SizedBox(height: 24),
            Text(
              'Your Watchlist is Empty',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: themeProvider.contrast,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Add stocks you\'re interested in to track their performance and get quick access for trading.',
              style: TextStyle(
                color: themeProvider.contrast.withOpacity(0.7),
                fontSize: 16,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: _showAddToWatchlistDialog,
              icon: const Icon(Icons.add),
              label: const Text('Add to Watchlist'),
              style: ElevatedButton.styleFrom(
                backgroundColor: themeProvider.theme,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWatchlistCard(MarketAssetModel asset, int index, ThemeProvider themeProvider, WatchlistProvider watchlistProvider) {
    final isPositive = asset.changePercent >= 0;
    final changeColor = isPositive ? const Color(0xFF3B82F6) : const Color(0xFFEF4444);
    
    // Use colorful accents for variety
    final colors = [
      const Color(0xFF3B82F6), // Blue
      const Color(0xFFEC4899), // Pink
      const Color(0xFFEAB308), // Yellow
      const Color(0xFF06B6D4), // Cyan
      const Color(0xFF8B5CF6), // Purple
      const Color(0xFFEA580C), // Orange
    ];
    final accentColor = colors[index % colors.length];
    
    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => AssetDetailScreen(
              asset: asset,
              isHolding: false, // Not a holding
            ),
          ),
        );
      },
      onLongPress: () => _showRemoveDialog(asset, watchlistProvider),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: themeProvider.backgroundHigh,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: accentColor.withOpacity(0.2)),
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
          children: [
            // Header with big ticker and remove button
            Row(
              children: [
                // Bigger, more prominent ticker symbol
                Flexible(
                  child: Text(
                    asset.symbol,
                    style: TextStyle(
                      color: themeProvider.contrast,
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.5,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const Spacer(),
                GestureDetector(
                  onTap: () => _showRemoveDialog(asset, watchlistProvider),
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: themeProvider.contrast.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Icon(
                      Icons.close,
                      size: 16,
                      color: themeProvider.contrast.withOpacity(0.7),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            
            // Company name (shortened)
            Flexible(
              child: Text(
                asset.name.length > 20 ? '${asset.name.substring(0, 20)}...' : asset.name,
                style: TextStyle(
                  color: themeProvider.contrast.withOpacity(0.8),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const Spacer(),
            
            // Price and change in a more compact layout
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '\$${asset.price.toStringAsFixed(2)}',
                  style: TextStyle(
                    color: themeProvider.contrast,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: changeColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: changeColor.withOpacity(0.3),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isPositive ? Icons.trending_up : Icons.trending_down,
                        size: 14,
                        color: changeColor,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${asset.changePercent >= 0 ? '+' : ''}${asset.changePercent.toStringAsFixed(2)}%',
                        style: TextStyle(
                          color: changeColor,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
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

  void _showAddToWatchlistDialog() {
    final TextEditingController controller = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add to Watchlist'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: 'Enter stock symbol (e.g., AAPL)',
            border: OutlineInputBorder(),
          ),
          textCapitalization: TextCapitalization.characters,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              final symbol = controller.text.trim().toUpperCase();
              if (symbol.isNotEmpty) {
                final watchlistProvider = Provider.of<WatchlistProvider>(context, listen: false);
                await watchlistProvider.addToWatchlist(symbol);
                if (context.mounted) {
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Added $symbol to watchlist')),
                  );
                }
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _showRemoveDialog(MarketAssetModel asset, WatchlistProvider watchlistProvider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove from Watchlist'),
        content: Text('Remove ${asset.symbol} from your watchlist?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              await watchlistProvider.removeFromWatchlist(asset.symbol);
              if (context.mounted) {
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Removed ${asset.symbol} from watchlist')),
                );
              }
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
  }
}