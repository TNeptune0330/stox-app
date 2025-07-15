import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class PortfolioSummaryCard extends StatelessWidget {
  final double cashBalance;
  final double holdingsValue;
  final double netWorth;
  final double totalPnL;
  final double totalPnLPercentage;

  const PortfolioSummaryCard({
    super.key,
    required this.cashBalance,
    required this.holdingsValue,
    required this.netWorth,
    required this.totalPnL,
    required this.totalPnLPercentage,
  });

  @override
  Widget build(BuildContext context) {
    final currencyFormatter = NumberFormat.currency(symbol: '\$', decimalDigits: 2);
    final isPositivePnL = totalPnL >= 0;

    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Net Worth
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Net Worth',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                Text(
                  currencyFormatter.format(netWorth),
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // P&L
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Total P&L',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      currencyFormatter.format(totalPnL),
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: isPositivePnL ? Colors.green : Colors.red,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '${isPositivePnL ? '+' : ''}${totalPnLPercentage.toStringAsFixed(2)}%',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: isPositivePnL ? Colors.green : Colors.red,
                      ),
                    ),
                  ],
                ),
              ],
            ),

            const Divider(height: 24),

            // Breakdown
            Row(
              children: [
                Expanded(
                  child: _buildBreakdownItem(
                    context,
                    'Cash',
                    currencyFormatter.format(cashBalance),
                    Colors.blue,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildBreakdownItem(
                    context,
                    'Holdings',
                    currencyFormatter.format(holdingsValue),
                    Colors.green,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBreakdownItem(
    BuildContext context,
    String label,
    String value,
    Color color,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}