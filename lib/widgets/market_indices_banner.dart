import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';
import '../services/enhanced_market_data_service.dart';

class MarketIndicesBanner extends StatefulWidget {
  const MarketIndicesBanner({super.key});

  @override
  State<MarketIndicesBanner> createState() => _MarketIndicesBannerState();
}

class _MarketIndicesBannerState extends State<MarketIndicesBanner> {
  Map<String, Map<String, dynamic>> _indicesData = {};
  bool _isLoading = true;

  final List<Map<String, String>> _indices = [
    {'symbol': '^DJI', 'name': 'DOW', 'fullName': 'Dow Jones'},
    {'symbol': '^IXIC', 'name': 'NASDAQ', 'fullName': 'NASDAQ Composite'},
    {'symbol': '^GSPC', 'name': 'S&P 500', 'fullName': 'S&P 500'},
  ];

  @override
  void initState() {
    super.initState();
    _loadIndicesData();
  }

  Future<void> _loadIndicesData() async {
    setState(() => _isLoading = true);
    
    try {
      final Map<String, Map<String, dynamic>> newData = {};
      
      for (final index in _indices) {
        try {
          // Try to get real data for each index
          final quote = await EnhancedMarketDataService.getQuote(index['symbol']!);
          if (quote != null) {
            newData[index['symbol']!] = {
              'name': index['name']!,
              'price': quote.price,
              'change': quote.changePercent,
              'changeValue': quote.price * (quote.changePercent / 100),
            };
          } else {
            // Fallback with default values
            newData[index['symbol']!] = {
              'name': index['name']!,
              'price': _getDefaultPrice(index['symbol']!),
              'change': 0.0,
              'changeValue': 0.0,
            };
          }
        } catch (e) {
          print('Error loading ${index['name']}: $e');
          // Fallback with default values
          newData[index['symbol']!] = {
            'name': index['name']!,
            'price': _getDefaultPrice(index['symbol']!),
            'change': 0.0,
            'changeValue': 0.0,
          };
        }
      }
      
      setState(() {
        _indicesData = newData;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading indices data: $e');
      setState(() => _isLoading = false);
    }
  }

  double _getDefaultPrice(String symbol) {
    switch (symbol) {
      case '^DJI':
        return 34000.0;
      case '^IXIC':
        return 14000.0;
      case '^GSPC':
        return 4300.0;
      default:
        return 0.0;
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
            ),
            boxShadow: [
              BoxShadow(
                color: themeProvider.theme.withOpacity(0.1),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
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
                    'Market Indices',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: themeProvider.contrast,
                    ),
                  ),
                  const Spacer(),
                  if (_isLoading)
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
              
              const SizedBox(height: 16),
              
              // Indices Row
              Row(
                children: _indices.map((index) {
                  final data = _indicesData[index['symbol']];
                  return Expanded(
                    child: _buildIndexCard(
                      data?['name'] ?? index['name']!,
                      data?['price']?.toDouble() ?? 0.0,
                      data?['change']?.toDouble() ?? 0.0,
                      data?['changeValue']?.toDouble() ?? 0.0,
                      themeProvider,
                      _isLoading,
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildIndexCard(
    String name,
    double price,
    double changePercent,
    double changeValue,
    ThemeProvider themeProvider,
    bool isLoading,
  ) {
    final isPositive = changePercent >= 0;
    final color = isPositive ? Colors.green : Colors.red;
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: themeProvider.background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: themeProvider.theme.withOpacity(0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Index Name
          Text(
            name,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: themeProvider.contrast.withOpacity(0.8),
            ),
            overflow: TextOverflow.ellipsis,
          ),
          
          const SizedBox(height: 4),
          
          // Price
          if (isLoading)
            Container(
              width: 60,
              height: 16,
              decoration: BoxDecoration(
                color: themeProvider.contrast.withOpacity(0.1),
                borderRadius: BorderRadius.circular(4),
              ),
            )
          else
            Text(
              price > 1000 
                  ? '${(price / 1000).toStringAsFixed(1)}K'
                  : price.toStringAsFixed(0),
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: themeProvider.contrast,
              ),
            ),
          
          const SizedBox(height: 4),
          
          // Change
          if (isLoading)
            Container(
              width: 40,
              height: 12,
              decoration: BoxDecoration(
                color: themeProvider.contrast.withOpacity(0.1),
                borderRadius: BorderRadius.circular(4),
              ),
            )
          else
            Row(
              children: [
                Icon(
                  isPositive ? Icons.arrow_upward : Icons.arrow_downward,
                  size: 12,
                  color: color,
                ),
                const SizedBox(width: 2),
                Flexible(
                  child: Text(
                    '${changePercent.toStringAsFixed(1)}%',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: color,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}