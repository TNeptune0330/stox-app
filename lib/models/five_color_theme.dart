import 'package:flutter/material.dart';
import 'app_theme_model.dart';
import 'harmonious_palettes.dart';

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
    // Text colors are ALWAYS white or black - no theme colors
    final textColor = isDark ? Colors.white : Colors.black;
    final subtitleColor = isDark ? Colors.white.withOpacity(0.7) : Colors.black.withOpacity(0.6);
    
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

  // Use harmonious palettes from the new system
  static FiveColorTheme get darkBlue => HarmoniousPalettes.deepOcean;
  static FiveColorTheme get lightBlue => HarmoniousPalettes.lightProfessional;
  static FiveColorTheme get darkGreen => HarmoniousPalettes.forestTwilight;
  static FiveColorTheme get lightGreen => HarmoniousPalettes.lightMint;
  static FiveColorTheme get darkPurple => HarmoniousPalettes.royalPurple;
  static FiveColorTheme get lightPurple => HarmoniousPalettes.lightLavender;

  /// Get all available themes
  static List<FiveColorTheme> getAllThemes() {
    return HarmoniousPalettes.getAllThemes();
  }
  
  /// Get theme by name
  static FiveColorTheme getThemeByName(String name) {
    // Try harmonious palettes first
    final theme = HarmoniousPalettes.getThemeByName(name);
    if (theme != null) return theme;
    
    // Fallback to legacy names
    switch (name) {
      case 'darkBlue':
        return HarmoniousPalettes.deepOcean;
      case 'lightBlue':
        return HarmoniousPalettes.lightProfessional;
      case 'darkGreen':
        return HarmoniousPalettes.forestTwilight;
      case 'lightGreen':
        return HarmoniousPalettes.lightMint;
      case 'darkPurple':
        return HarmoniousPalettes.royalPurple;
      case 'lightPurple':
        return HarmoniousPalettes.lightLavender;
      default:
        return HarmoniousPalettes.deepOcean;
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