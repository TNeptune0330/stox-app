import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';
import '../services/market_indices_service.dart';
import '../models/market_asset_model.dart';

class MarketIndicesBanner extends StatefulWidget {
  const MarketIndicesBanner({super.key});

  @override
  State<MarketIndicesBanner> createState() => _MarketIndicesBannerState();
}

class _MarketIndicesBannerState extends State<MarketIndicesBanner> {
  List<MarketAssetModel> _indicesData = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    print('📊 MarketIndicesBanner: Widget initialized - FORCING immediate data load...');
    
    // Immediate load - no delay
    _loadRealIndicesData();
    
    // Backup attempts at regular intervals
    Future.delayed(const Duration(milliseconds: 1000), () {
      if (mounted && _indicesData.isEmpty) {
        print('📊 MarketIndicesBanner: Retry attempt #1...');
        _loadRealIndicesData();
      }
    });
    
    Future.delayed(const Duration(milliseconds: 3000), () {
      if (mounted && _indicesData.isEmpty) {
        print('📊 MarketIndicesBanner: Retry attempt #2...');
        _loadRealIndicesData();
      }
    });
  }

  Future<void> _loadRealIndicesData() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    
    try {
      print('📊 MarketIndicesBanner: FORCING fresh real market indices data (no cache)...');
      
      // Clear any existing data first to prevent showing stale data
      setState(() {
        _indicesData = [];
      });
      
      // Use dedicated market indices service for accurate data
      final realIndicesData = await MarketIndicesService.getRealMarketIndices();
      
      if (!mounted) return;
      setState(() {
        _indicesData = realIndicesData;
        _isLoading = false;
      });
      
      if (realIndicesData.isNotEmpty) {
        print('✅ MarketIndicesBanner: Successfully loaded ${realIndicesData.length} market indices');
        for (final index in realIndicesData) {
          print('   📈 ${index.name}: \$${index.price.toStringAsFixed(2)} (${index.changePercent >= 0 ? '+' : ''}${index.changePercent.toStringAsFixed(2)}%)');
        }
      } else {
        print('⚠️ MarketIndicesBanner: No market indices data loaded - this may indicate API issues');
      }
    } catch (e) {
      print('❌ MarketIndicesBanner: Error loading real indices data: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
          // Keep any existing data instead of clearing it
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        if (_isLoading) {
          return Container(
            height: 50,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Center(
              child: SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: themeProvider.theme,
                ),
              ),
            ),
          );
        }

        if (_indicesData.isEmpty) {
          return Container(
            height: 50,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.error_outline,
                  size: 16,
                  color: themeProvider.contrast.withOpacity(0.5),
                ),
                const SizedBox(width: 8),
                Text(
                  'Real market data unavailable',
                  style: TextStyle(
                    color: themeProvider.contrast.withOpacity(0.7),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: _loadRealIndicesData,
                  child: Icon(
                    Icons.refresh,
                    size: 16,
                    color: themeProvider.theme,
                  ),
                ),
              ],
            ),
          );
        }

        return Container(
          height: 50,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              ..._indicesData.map((index) => _buildIndexItem(index, themeProvider)).toList(),
              // Add refresh button
              GestureDetector(
                onTap: _loadRealIndicesData,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  child: Icon(
                    Icons.refresh,
                    size: 16,
                    color: themeProvider.theme.withOpacity(0.7),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildIndexItem(MarketAssetModel index, ThemeProvider themeProvider) {
    final isPositive = index.changePercent >= 0;
    final color = isPositive ? const Color(0xFF3B82F6) : Colors.red;

    return Expanded(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            index.name,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: themeProvider.contrast,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            index.price.toStringAsFixed(0),
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: themeProvider.contrast,
            ),
          ),
          Text(
            '${isPositive ? '+' : ''}${index.changePercent.toStringAsFixed(2)}%',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w500,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}