import 'package:flutter/material.dart';
import 'app_theme_model.dart';

/// A simplified 5-color design system for consistent UI
class FiveColorTheme {
  // The 5 core colors
  final Color background;      // Main background color
  final Color backgroundHigh;  // Highlight/accent version of background
  final Color theme;          // Primary theme color
  final Color themeHigh;      // Highlight/accent version of theme
  final Color contrast;       // Color that contrasts with theme
  
  final String name;
  final bool isDark;

  const FiveColorTheme({
    required this.background,
    required this.backgroundHigh,
    required this.theme,
    required this.themeHigh,
    required this.contrast,
    required this.name,
    required this.isDark,
  });

  /// Convert to the existing AppThemeModel system
  AppThemeModel toAppThemeModel() {
    // Text colors based on contrast
    final textColor = isDark ? Colors.white : Colors.black;
    final subtitleColor = isDark ? Colors.white70 : Colors.black54;
    
    return AppThemeModel(
      name: name,
      
      // Core colors mapped to 5-color system
      primaryColor: theme,
      secondaryColor: themeHigh,
      backgroundColor: background,
      surfaceColor: backgroundHigh,
      cardColor: backgroundHigh,
      
      // Text colors
      textColor: textColor,
      subtitleColor: subtitleColor,
      
      // UI elements use the 5 colors strategically
      appBarColor: backgroundHigh,
      bottomNavColor: backgroundHigh,
      dividerColor: backgroundHigh,
      borderColor: backgroundHigh,
      
      // Interactive elements use theme colors
      buttonColor: theme,
      accentColor: themeHigh,
      highlightColor: themeHigh,
      chipColor: backgroundHigh,
      tabBarColor: backgroundHigh,
      modalColor: backgroundHigh,
      
      // Status colors use contrast for visibility
      successColor: isDark ? Colors.green.shade400 : Colors.green.shade600,
      errorColor: contrast,
      warningColor: isDark ? Colors.orange.shade400 : Colors.orange.shade600,
      infoColor: theme,
      positiveColor: isDark ? Colors.green.shade400 : Colors.green.shade600,
      negativeColor: contrast,
      
      // System colors
      shadowColor: isDark ? Colors.black : Colors.grey.shade300,
      disabledColor: isDark ? Colors.grey.shade600 : Colors.grey.shade400,
      iconColor: textColor,
      overlayColor: isDark ? Colors.black54 : Colors.white54,
      
      // Gradients use background colors
      gradientStartColor: background,
      gradientEndColor: backgroundHigh,
      
      isDark: isDark,
    );
  }

  // Predefined 5-color themes
  
  /// Dark Blue theme - professional and modern
  static const FiveColorTheme darkBlue = FiveColorTheme(
    background: Color(0xFF0f1419),      // Dark navy background
    backgroundHigh: Color(0xFF1a1a2e),  // Lighter navy for cards/surfaces
    theme: Color(0xFF2196F3),           // Bright blue primary
    themeHigh: Color(0xFF42A5F5),       // Lighter blue for highlights
    contrast: Color(0xFFf44336),        // Red for contrast/errors
    name: 'Dark Blue',
    isDark: true,
  );
  
  /// Light Blue theme - clean and bright
  static const FiveColorTheme lightBlue = FiveColorTheme(
    background: Color(0xFFF8F9FA),      // Light grey background
    backgroundHigh: Color(0xFFFFFFFF),  // White for cards/surfaces
    theme: Color(0xFF1976D2),           // Deep blue primary
    themeHigh: Color(0xFF42A5F5),       // Light blue for highlights
    contrast: Color(0xFFD32F2F),        // Red for contrast/errors
    name: 'Light Blue',
    isDark: false,
  );
  
  /// Dark Green theme - financial/money focused
  static const FiveColorTheme darkGreen = FiveColorTheme(
    background: Color(0xFF0D1F0D),      // Dark forest background
    backgroundHigh: Color(0xFF1B2E1B),  // Lighter forest for cards
    theme: Color(0xFF4CAF50),           // Green primary
    themeHigh: Color(0xFF66BB6A),       // Light green for highlights
    contrast: Color(0xFFf44336),        // Red for contrast/losses
    name: 'Dark Green',
    isDark: true,
  );
  
  /// Light Green theme - fresh and natural
  static const FiveColorTheme lightGreen = FiveColorTheme(
    background: Color(0xFFF1F8E9),      // Very light green background
    backgroundHigh: Color(0xFFFFFFFF),  // White for cards/surfaces
    theme: Color(0xFF2E7D32),           // Deep green primary
    themeHigh: Color(0xFF4CAF50),       // Medium green for highlights
    contrast: Color(0xFFD32F2F),        // Red for contrast/losses
    name: 'Light Green',
    isDark: false,
  );
  
  /// Dark Purple theme - premium and elegant
  static const FiveColorTheme darkPurple = FiveColorTheme(
    background: Color(0xFF1A0E2E),      // Dark purple background
    backgroundHigh: Color(0xFF2D1B42),  // Lighter purple for cards
    theme: Color(0xFF9C27B0),           // Purple primary
    themeHigh: Color(0xFFBA68C8),       // Light purple for highlights
    contrast: Color(0xFFFF5722),        // Orange for contrast
    name: 'Dark Purple',
    isDark: true,
  );
  
  /// Light Purple theme - creative and modern
  static const FiveColorTheme lightPurple = FiveColorTheme(
    background: Color(0xFFF8F5FF),      // Very light purple background
    backgroundHigh: Color(0xFFFFFFFF),  // White for cards/surfaces
    theme: Color(0xFF7B1FA2),           // Deep purple primary
    themeHigh: Color(0xFF9C27B0),       // Medium purple for highlights
    contrast: Color(0xFFFF5722),        // Orange for contrast
    name: 'Light Purple',
    isDark: false,
  );

  /// Get all available themes
  static List<FiveColorTheme> getAllThemes() {
    return [
      darkBlue,
      lightBlue,
      darkGreen,
      lightGreen,
      darkPurple,
      lightPurple,
    ];
  }
  
  /// Get theme by name
  static FiveColorTheme getThemeByName(String name) {
    switch (name) {
      case 'darkBlue':
        return darkBlue;
      case 'lightBlue':
        return lightBlue;
      case 'darkGreen':
        return darkGreen;
      case 'lightGreen':
        return lightGreen;
      case 'darkPurple':
        return darkPurple;
      case 'lightPurple':
        return lightPurple;
      default:
        return darkBlue;
    }
  }
  
  /// Create a custom theme from 5 colors
  static FiveColorTheme custom({
    required Color background,
    required Color backgroundHigh,
    required Color theme,
    required Color themeHigh,
    required Color contrast,
    String name = 'Custom',
    bool? isDark,
  }) {
    // Auto-detect if theme is dark based on background luminance
    final isThemeDark = isDark ?? background.computeLuminance() < 0.5;
    
    return FiveColorTheme(
      background: background,
      backgroundHigh: backgroundHigh,
      theme: theme,
      themeHigh: themeHigh,
      contrast: contrast,
      name: name,
      isDark: isThemeDark,
    );
  }
  
  /// Helper to generate a harmonious theme from a single primary color
  static FiveColorTheme fromPrimaryColor(Color primaryColor, {bool isDark = true, String name = 'Custom'}) {
    final hsl = HSLColor.fromColor(primaryColor);
    
    if (isDark) {
      return FiveColorTheme(
        background: HSLColor.fromAHSL(1.0, hsl.hue, 0.3, 0.05).toColor(),
        backgroundHigh: HSLColor.fromAHSL(1.0, hsl.hue, 0.2, 0.12).toColor(),
        theme: primaryColor,
        themeHigh: HSLColor.fromAHSL(1.0, hsl.hue, hsl.saturation, hsl.lightness + 0.1).toColor(),
        contrast: HSLColor.fromAHSL(1.0, (hsl.hue + 180) % 360, 0.8, 0.5).toColor(),
        name: name,
        isDark: true,
      );
    } else {
      return FiveColorTheme(
        background: HSLColor.fromAHSL(1.0, hsl.hue, 0.1, 0.98).toColor(),
        backgroundHigh: Colors.white,
        theme: primaryColor,
        themeHigh: HSLColor.fromAHSL(1.0, hsl.hue, hsl.saturation * 0.7, hsl.lightness + 0.2).toColor(),
        contrast: HSLColor.fromAHSL(1.0, (hsl.hue + 180) % 360, 0.8, 0.4).toColor(),
        name: name,
        isDark: false,
      );
    }
  }
}