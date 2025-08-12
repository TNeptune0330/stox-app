import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';
import '../services/market_indices_service.dart';
import '../models/market_asset_model.dart';

class StyledMarketIndicesWidget extends StatefulWidget {
  const StyledMarketIndicesWidget({super.key});

  @override
  State<StyledMarketIndicesWidget> createState() => _StyledMarketIndicesWidgetState();
}

class _StyledMarketIndicesWidgetState extends State<StyledMarketIndicesWidget> {
  List<MarketAssetModel> _indicesData = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    print('📊 StyledMarketIndicesWidget: Initializing with styled bubble design...');
    _loadRealIndicesData();
  }

  Future<void> _loadRealIndicesData() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    
    try {
      print('📊 StyledMarketIndicesWidget: Loading real ETF-based market indices...');
      
      final realIndicesData = await MarketIndicesService.getRealMarketIndices();
      
      if (!mounted) return;
      setState(() {
        _indicesData = realIndicesData;
        _isLoading = false;
      });
      
      if (realIndicesData.isNotEmpty) {
        print('✅ StyledMarketIndicesWidget: Successfully loaded ${realIndicesData.length} market indices');
      } else {
        print('⚠️ StyledMarketIndicesWidget: No real market data available');
      }
    } catch (e) {
      print('❌ StyledMarketIndicesWidget: Error loading indices: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: themeProvider.backgroundHigh,
            borderRadius: BorderRadius.circular(16),
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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with refresh button
              Row(
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
                      size: 16,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Market Indices',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: themeProvider.contrast,
                      ),
                    ),
                  ),
                  if (!_isLoading)
                    GestureDetector(
                      onTap: _loadRealIndicesData,
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: themeProvider.theme.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Icon(
                          Icons.refresh,
                          size: 16,
                          color: themeProvider.theme,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              
              // Indices data
              if (_isLoading)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: themeProvider.theme,
                      ),
                    ),
                  ),
                )
              else if (_indicesData.isEmpty)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: themeProvider.background.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(12),
                  ),
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
                    ],
                  ),
                )
              else
                // Indices bubbles row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ..._indicesData.map((index) => _buildIndexBubble(index, themeProvider)).toList(),
                  ],
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildIndexBubble(MarketAssetModel index, ThemeProvider themeProvider) {
    final isPositive = index.changePercent >= 0;
    final changeColor = isPositive ? Colors.green : Colors.red;

    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: themeProvider.background.withOpacity(0.3),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: changeColor.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              index.name,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: themeProvider.contrast,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              index.price.toStringAsFixed(0),
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: themeProvider.contrast,
              ),
            ),
            const SizedBox(height: 2),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  isPositive ? Icons.arrow_upward : Icons.arrow_downward,
                  size: 10,
                  color: changeColor,
                ),
                const SizedBox(width: 2),
                Text(
                  '${index.changePercent.abs().toStringAsFixed(1)}%',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: changeColor,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}