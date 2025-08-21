class NumberFormatter {
  /// Format numbers with commas and k/m/b abbreviations
  static String formatLargeNumber(double number) {
    if (number >= 1000000000000) {
      return '${(number / 1000000000000).toStringAsFixed(1)}T';
    } else if (number >= 1000000000) {
      return '${(number / 1000000000).toStringAsFixed(1)}B';
    } else if (number >= 1000000) {
      return '${(number / 1000000).toStringAsFixed(1)}M';
    } else if (number >= 1000) {
      return '${(number / 1000).toStringAsFixed(1)}K';
    } else {
      return number.toStringAsFixed(0);
    }
  }

  /// Format currency with proper notation
  static String formatCurrency(double amount) {
    if (amount >= 1000000000000) {
      return '\$${(amount / 1000000000000).toStringAsFixed(2)}T';
    } else if (amount >= 1000000000) {
      return '\$${(amount / 1000000000).toStringAsFixed(2)}B';
    } else if (amount >= 1000000) {
      return '\$${(amount / 1000000).toStringAsFixed(1)}M';
    } else if (amount >= 1000) {
      return '\$${(amount / 1000).toStringAsFixed(1)}K';
    } else if (amount >= 1) {
      return '\$${amount.toStringAsFixed(2)}';
    } else {
      return '\$${amount.toStringAsFixed(4)}';
    }
  }

  /// Format regular numbers with commas
  static String formatWithCommas(double number) {
    if (number.isNaN || number.isInfinite) return 'N/A';
    
    final parts = number.toStringAsFixed(2).split('.');
    final integerPart = parts[0];
    final decimalPart = parts[1];
    
    // Add commas to integer part
    String formattedInteger = '';
    for (int i = 0; i < integerPart.length; i++) {
      if (i > 0 && (integerPart.length - i) % 3 == 0) {
        formattedInteger += ',';
      }
      formattedInteger += integerPart[i];
    }
    
    // Remove trailing zeros from decimal part
    String trimmedDecimal = decimalPart.replaceAll(RegExp(r'0+$'), '');
    if (trimmedDecimal.isEmpty) {
      return formattedInteger;
    } else {
      return '$formattedInteger.$trimmedDecimal';
    }
  }

  /// Format percentage
  static String formatPercentage(double percentage) {
    if (percentage.isNaN || percentage.isInfinite) return 'N/A';
    return '${percentage >= 0 ? '+' : ''}${percentage.toStringAsFixed(2)}%';
  }

  /// Format volume
  static String formatVolume(double volume) {
    if (volume.isNaN || volume.isInfinite) return 'N/A';
    return formatLargeNumber(volume);
  }

  /// Format P/E ratio
  static String formatPERatio(double? peRatio) {
    if (peRatio == null || peRatio.isNaN || peRatio.isInfinite || peRatio <= 0) {
      return 'N/A';
    }
    return peRatio.toStringAsFixed(2);
  }

  /// Format dividend yield
  static String formatDividendYield(double? dividendYield) {
    if (dividendYield == null || dividendYield.isNaN || dividendYield.isInfinite) {
      return 'N/A';
    }
    return '${dividendYield.toStringAsFixed(2)}%';
  }

  /// Format price with appropriate decimal places
  static String formatPrice(double price) {
    if (price.isNaN || price.isInfinite) return 'N/A';
    
    if (price >= 1000) {
      return formatWithCommas(price);
    } else if (price >= 100) {
      return price.toStringAsFixed(2);
    } else if (price >= 10) {
      return price.toStringAsFixed(2);
    } else if (price >= 1) {
      return price.toStringAsFixed(3);
    } else {
      return price.toStringAsFixed(4);
    }
  }
}