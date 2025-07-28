import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../models/market_asset_model.dart';
import '../../providers/portfolio_provider.dart';
import '../../providers/achievement_provider.dart';
import '../../widgets/price_change_indicator.dart';

class TradeDialog extends StatefulWidget {
  final MarketAssetModel asset;
  final String userId;
  final int initialTab;
  final int? maxQuantity;
  final String? initialAction;

  const TradeDialog({
    super.key,
    required this.asset,
    required this.userId,
    this.initialTab = 0,
    this.maxQuantity,
    this.initialAction,
  });

  @override
  State<TradeDialog> createState() => _TradeDialogState();
}

class _TradeDialogState extends State<TradeDialog> with TickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _quantityController = TextEditingController();
  bool _isLoading = false;
  int _currentQuantity = 1;

  @override
  void initState() {
    super.initState();
    
    // Determine initial tab based on action
    int initialTab = widget.initialTab;
    if (widget.initialAction == 'buy') {
      initialTab = 0;
    } else if (widget.initialAction == 'sell') {
      initialTab = 1;
    }
    
    _tabController = TabController(length: 2, vsync: this, initialIndex: initialTab);
    _quantityController.text = _currentQuantity.toString();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _quantityController.dispose();
    super.dispose();
  }

  double get _totalValue => widget.asset.price * _currentQuantity;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 400),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.asset.symbol,
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          widget.asset.name,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        widget.asset.formattedPrice,
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      PriceChangeIndicator(
                        change: widget.asset.changePercent,
                        showIcon: true,
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Trade Type Tabs
            TabBar(
              controller: _tabController,
              tabs: const [
                Tab(text: 'Buy'),
                Tab(text: 'Sell'),
              ],
            ),

            // Trade Form
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // Quantity Input
                  Row(
                    children: [
                      IconButton(
                        onPressed: _currentQuantity > 1 ? _decreaseQuantity : null,
                        icon: const Icon(Icons.remove),
                        style: IconButton.styleFrom(
                          backgroundColor: Theme.of(context).colorScheme.surface,
                        ),
                      ),
                      Expanded(
                        child: TextField(
                          controller: _quantityController,
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                          ],
                          textAlign: TextAlign.center,
                          decoration: const InputDecoration(
                            labelText: 'Quantity',
                            border: OutlineInputBorder(),
                          ),
                          onChanged: (value) {
                            final quantity = int.tryParse(value) ?? 1;
                            final maxQty = _tabController.index == 1 && widget.maxQuantity != null 
                                ? widget.maxQuantity! 
                                : 999999;
                            setState(() {
                              _currentQuantity = quantity.clamp(1, maxQty);
                            });
                          },
                        ),
                      ),
                      IconButton(
                        onPressed: _increaseQuantity,
                        icon: const Icon(Icons.add),
                        style: IconButton.styleFrom(
                          backgroundColor: Theme.of(context).colorScheme.surface,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Order Summary
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Price per share:'),
                            Text(
                              widget.asset.formattedPrice,
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Quantity:'),
                            Text(
                              _currentQuantity.toString(),
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        const Divider(),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Total:',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              '\$${_totalValue.toStringAsFixed(2)}',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Action Buttons
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.of(context).pop(),
                          child: const Text('Cancel'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Consumer<PortfolioProvider>(
                          builder: (context, portfolioProvider, child) {
                            return ElevatedButton(
                              onPressed: _isLoading || portfolioProvider.isLoading 
                                  ? null 
                                  : _executeTrade,
                              child: _isLoading || portfolioProvider.isLoading
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : Text(
                                      _tabController.index == 0 ? 'Buy' : 'Sell',
                                    ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _increaseQuantity() {
    final maxQty = _tabController.index == 1 && widget.maxQuantity != null 
        ? widget.maxQuantity! 
        : 999999;
    if (_currentQuantity < maxQty) {
      setState(() {
        _currentQuantity++;
        _quantityController.text = _currentQuantity.toString();
      });
    }
  }

  void _decreaseQuantity() {
    if (_currentQuantity > 1) {
      setState(() {
        _currentQuantity--;
        _quantityController.text = _currentQuantity.toString();
      });
    }
  }

  Future<void> _executeTrade() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final portfolioProvider = Provider.of<PortfolioProvider>(context, listen: false);
      final achievementProvider = Provider.of<AchievementProvider>(context, listen: false);
      final tradeType = _tabController.index == 0 ? 'buy' : 'sell';

      final success = await portfolioProvider.executeTrade(
        userId: widget.userId,
        symbol: widget.asset.symbol,
        type: tradeType,
        quantity: _currentQuantity,
        price: widget.asset.price,
        achievementProvider: achievementProvider,
      );

      if (mounted) {
        if (success) {
          Navigator.of(context).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Successfully ${tradeType == 'buy' ? 'bought' : 'sold'} '
                '$_currentQuantity shares of ${widget.asset.symbol}',
              ),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                portfolioProvider.error ?? 'Trade failed',
              ),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
}