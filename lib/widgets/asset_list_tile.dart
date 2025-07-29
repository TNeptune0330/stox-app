import 'package:flutter/material.dart';
import '../models/market_asset_model.dart';
import 'price_change_indicator.dart';

class AssetListTile extends StatelessWidget {
  final MarketAssetModel asset;
  final VoidCallback onTap;

  const AssetListTile({
    super.key,
    required this.asset,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // Handle error assets with special display
    if (asset.isError) {
      return Card(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        child: ListTile(
          leading: CircleAvatar(
            backgroundColor: Colors.red.shade400,
            child: const Icon(
              Icons.error_outline,
              color: Colors.white,
            ),
          ),
          title: Text(
            asset.symbol,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.red.shade600,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          subtitle: const Text(
            'Data unavailable - symbol may not exist',
            style: TextStyle(
              color: Colors.red,
              fontSize: 12,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          trailing: const SizedBox(
            width: 80,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Icon(
                  Icons.warning,
                  color: Colors.red,
                  size: 20,
                ),
                Text(
                  'Error',
                  style: TextStyle(
                    color: Colors.red,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          onTap: () {
            // Show error dialog instead of navigating
            showDialog(
              context: context,
              builder: (context) => AlertDialog(
                title: Text('Data Unavailable'),
                content: Text(asset.errorMessage),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text('OK'),
                  ),
                ],
              ),
            );
          },
        ),
      );
    }

    // Normal asset display
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: _getAssetColor(),
          child: Text(
            asset.symbol.length >= 2 
                ? asset.symbol.substring(0, 2).toUpperCase()
                : asset.symbol.toUpperCase(),
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
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(
          asset.name,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: SizedBox(
          width: 80,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                asset.formattedPrice,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              PriceChangeIndicator(
                change: asset.changePercent,
                showIcon: true,
              ),
            ],
          ),
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
      case 'error':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}