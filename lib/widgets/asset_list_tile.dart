import 'package:flutter/material.dart';
import '../models/asset_model.dart';
import 'price_change_indicator.dart';

class AssetListTile extends StatelessWidget {
  final AssetModel asset;
  final VoidCallback onTap;

  const AssetListTile({
    super.key,
    required this.asset,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: _getAssetColor(),
          child: Text(
            asset.symbol.substring(0, 2).toUpperCase(),
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Text(
          asset.symbol,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Text(
          asset.name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              asset.formattedPrice,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            PriceChangeIndicator(
              change: asset.changePercent24h,
              showIcon: true,
            ),
          ],
        ),
        onTap: onTap,
      ),
    );
  }

  Color _getAssetColor() {
    switch (asset.type) {
      case 'stock':
        return Colors.blue;
      case 'crypto':
        return Colors.orange;
      case 'etf':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }
}