import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/portfolio_model.dart';
import '../models/market_asset_model.dart';
import '../providers/market_data_provider.dart';
import '../widgets/price_change_indicator.dart';
import '../utils/responsive_utils.dart';

class PortfolioHoldingTile extends StatelessWidget {
  final PortfolioModel holding;
  final VoidCallback onTap;

  const PortfolioHoldingTile({
    super.key,
    required this.holding,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<MarketDataProvider>(
      builder: (context, marketDataProvider, child) {
        // Get current market price
        final marketAsset = marketDataProvider.allAssets.firstWhere(
          (asset) => asset.symbol == holding.symbol,
          orElse: () => MarketAssetModel(
            symbol: holding.symbol,
            name: holding.symbol,
            price: holding.avgPrice, // Fallback to average price
            change: 0.0,
            changePercent: 0.0,
            type: 'stock',
            lastUpdated: DateTime.now(),
          ),
        );

        // Calculate P&L
        final currentPrice = marketAsset.price;
        final pnl = holding.calculatePnL(currentPrice);
        final pnlPercentage = holding.calculatePnLPercentage(currentPrice);
        final currentValue = holding.quantity * currentPrice;

        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
          child: ListTile(
            dense: true,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            leading: CircleAvatar(
              backgroundColor: _getAssetColor(marketAsset.type),
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
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '${holding.quantity} shares @ \$${holding.avgPrice.toStringAsFixed(2)}',
                  style: const TextStyle(fontSize: 14),
                ),
                Text(
                  'Current: \$${currentPrice.toStringAsFixed(2)}',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
              ],
            ),
            trailing: SizedBox(
              width: 120,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '\$${currentValue.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 2),
                  PriceChangeIndicator(
                    change: pnlPercentage,
                    showIcon: true,
                  ),
                ],
              ),
            ),
            onTap: onTap,
          ),
        );
      },
    );
  }

  Color _getAssetColor(String type) {
    switch (type.toLowerCase()) {
      case 'stock':
        return Colors.blue;
      case 'etf':
        return Colors.green;
      case 'crypto':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }
}