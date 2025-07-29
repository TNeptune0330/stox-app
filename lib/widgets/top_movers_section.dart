import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';
import '../models/market_asset_model.dart';
import '../widgets/asset_list_tile.dart';

class TopMoversSection extends StatelessWidget {
  final String title;
  final List<MarketAssetModel> assets;
  final Function(MarketAssetModel) onAssetTap;
  final bool isLoading;

  const TopMoversSection({
    super.key,
    required this.title,
    required this.assets,
    required this.onAssetTap,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: themeProvider.backgroundHigh,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: themeProvider.theme.withOpacity(0.3),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: themeProvider.theme.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.trending_up,
                        color: themeProvider.theme,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: themeProvider.contrast,
                      ),
                    ),
                    const Spacer(),
                    if (isLoading)
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
              ),
              
              // Assets List
              if (isLoading)
                ...List.generate(3, (index) => _buildLoadingTile(themeProvider))
              else if (assets.isEmpty)
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Center(
                    child: Text(
                      'No data available',
                      style: TextStyle(
                        color: themeProvider.contrast.withOpacity(0.6),
                      ),
                    ),
                  ),
                )
              else
                ...assets.take(3).map((asset) => AssetListTile(
                  asset: asset,
                  onTap: () => onAssetTap(asset),
                )),
              
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  Widget _buildLoadingTile(ThemeProvider themeProvider) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          // Loading icon placeholder
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: themeProvider.contrast.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          
          const SizedBox(width: 12),
          
          // Loading text placeholders
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 80,
                  height: 16,
                  decoration: BoxDecoration(
                    color: themeProvider.contrast.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  width: 120,
                  height: 12,
                  decoration: BoxDecoration(
                    color: themeProvider.contrast.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ],
            ),
          ),
          
          // Loading price placeholders
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                width: 60,
                height: 16,
                decoration: BoxDecoration(
                  color: themeProvider.contrast.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(height: 4),
              Container(
                width: 40,
                height: 12,
                decoration: BoxDecoration(
                  color: themeProvider.contrast.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}