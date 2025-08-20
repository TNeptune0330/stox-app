import 'package:flutter/material.dart';

class PriceChangeIndicator extends StatelessWidget {
  final double change;
  final bool showIcon;
  final TextStyle? textStyle;

  const PriceChangeIndicator({
    super.key,
    required this.change,
    this.showIcon = false,
    this.textStyle,
  });

  @override
  Widget build(BuildContext context) {
    final isPositive = change >= 0;
    final color = isPositive ? const Color(0xFF3B82F6) : const Color(0xFFE74C3C); // Blue for positive, red for negative
    final formattedChange = '${isPositive ? '+' : ''}${change.toStringAsFixed(2)}%';

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (showIcon)
          Icon(
            isPositive ? Icons.arrow_upward : Icons.arrow_downward,
            color: color,
            size: 16,
          ),
        if (showIcon) const SizedBox(width: 4),
        Text(
          formattedChange,
          style: (textStyle ?? const TextStyle()).copyWith(
            color: color,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}