import 'package:flutter/material.dart';
import 'five_color_theme.dart';

/// Scientifically harmonious 5-color palettes inspired by color theory
/// These palettes are designed using principles from colormind.io and color harmony theory
class HarmoniousPalettes {
  
  /// Deep Ocean - Cool, professional, trustworthy
  /// Based on triadic harmony with deep blues and teals
  static const FiveColorTheme deepOcean = FiveColorTheme(
    background: Color(0xFF0B1426),      // Deep navy background
    backgroundHigh: Color(0xFF1A2B42),  // Lighter navy for surfaces
    theme: Color(0xFF2E86AB),           // Ocean blue primary
    themeHigh: Color(0xFF48CAE4),       // Teal accent
    contrast: Color(0xFFFFFFFF),        // Pure white for dark themes
    name: 'Deep Ocean',
    isDark: true,
  );
  
  /// Forest Twilight - Natural, calming, growth-focused
  /// Based on analogous harmony with greens and blues
  static const FiveColorTheme forestTwilight = FiveColorTheme(
    background: Color(0xFF0D1B0D),      // Deep forest background
    backgroundHigh: Color(0xFF1E2F1E),  // Forest green surface
    theme: Color(0xFF2D5A27),           // Deep forest green
    themeHigh: Color(0xFF4A7C59),       // Sage green accent
    contrast: Color(0xFFFFFFFF),        // Pure white for dark themes
    name: 'Forest Twilight',
    isDark: true,
  );
  
  /// Royal Purple - Premium, luxury, sophisticated
  /// Based on split-complementary harmony
  static const FiveColorTheme royalPurple = FiveColorTheme(
    background: Color(0xFF1A0D2E),      // Deep purple background
    backgroundHigh: Color(0xFF2D1B4E),  // Purple surface
    theme: Color(0xFF6A4C93),           // Royal purple
    themeHigh: Color(0xFF9B59B6),       // Bright purple accent
    contrast: Color(0xFFFFFFFF),        // Pure white for dark themes
    name: 'Royal Purple',
    isDark: true,
  );
  
  /// Sunset Warmth - Energetic, modern, creative
  /// Based on warm analogous harmony
  static const FiveColorTheme sunsetWarmth = FiveColorTheme(
    background: Color(0xFF2C1810),      // Deep brown background
    backgroundHigh: Color(0xFF4A2C1A),  // Warm brown surface
    theme: Color(0xFFE67E22),           // Orange primary
    themeHigh: Color(0xFFF39C12),       // Golden accent
    contrast: Color(0xFFFFFFFF),        // Pure white for dark themes
    name: 'Sunset Warmth',
    isDark: true,
  );
  
  /// Arctic Blue - Clean, minimalist, high-tech
  /// Based on monochromatic harmony with blue
  static const FiveColorTheme arcticBlue = FiveColorTheme(
    background: Color(0xFF0A1628),      // Deep arctic background
    backgroundHigh: Color(0xFF1B2951),  // Ice blue surface
    theme: Color(0xFF3498DB),           // Clear blue
    themeHigh: Color(0xFF85C1E9),       // Light blue accent
    contrast: Color(0xFFFFFFFF),        // Pure white for dark themes
    name: 'Arctic Blue',
    isDark: true,
  );
  
  /// Light Professional - Clean, trustworthy, business
  /// Light mode with sophisticated blues
  static const FiveColorTheme lightProfessional = FiveColorTheme(
    background: Color(0xFFF8FAFC),      // Very light blue-grey
    backgroundHigh: Color(0xFFFFFFFF),  // Pure white surface
    theme: Color(0xFF1E40AF),           // Professional blue
    themeHigh: Color(0xFF3B82F6),       // Bright blue accent
    contrast: Color(0xFF000000),        // Pure black for light themes
    name: 'Light Professional',
    isDark: false,
  );
  
  /// Light Mint - Fresh, natural, clean
  /// Light mode with greens and teals
  static const FiveColorTheme lightMint = FiveColorTheme(
    background: Color(0xFFF0FDF4),      // Very light green
    backgroundHigh: Color(0xFFFFFFFF),  // Pure white surface
    theme: Color(0xFF059669),           // Fresh green
    themeHigh: Color(0xFF10B981),       // Bright green accent
    contrast: Color(0xFF000000),        // Pure black for light themes
    name: 'Light Mint',
    isDark: false,
  );
  
  /// Light Lavender - Gentle, creative, modern
  /// Light mode with soft purples
  static const FiveColorTheme lightLavender = FiveColorTheme(
    background: Color(0xFFFAF5FF),      // Very light purple
    backgroundHigh: Color(0xFFFFFFFF),  // Pure white surface
    theme: Color(0xFF7C3AED),           // Deep purple
    themeHigh: Color(0xFF8B5CF6),       // Bright purple accent
    contrast: Color(0xFF000000),        // Pure black for light themes
    name: 'Light Lavender',
    isDark: false,
  );
  
  /// Monochrome Dark - Timeless, focused, elegant
  /// Pure grayscale for minimal distraction
  static const FiveColorTheme monochromeDark = FiveColorTheme(
    background: Color(0xFF0A0A0A),      // Pure black background
    backgroundHigh: Color(0xFF1A1A1A),  // Dark grey surface
    theme: Color(0xFF404040),           // Medium grey
    themeHigh: Color(0xFF666666),       // Light grey accent
    contrast: Color(0xFFFFFFFF),        // Pure white for dark themes
    name: 'Monochrome Dark',
    isDark: true,
  );
  
  /// Monochrome Light - Clean, minimal, focused
  /// Pure grayscale light mode
  static const FiveColorTheme monochromeLight = FiveColorTheme(
    background: Color(0xFFFFFFFF),      // Pure white background
    backgroundHigh: Color(0xFFF5F5F5),  // Light grey surface
    theme: Color(0xFF404040),           // Dark grey
    themeHigh: Color(0xFF666666),       // Medium grey accent
    contrast: Color(0xFF000000),        // Pure black for light themes
    name: 'Monochrome Light',
    isDark: false,
  );
  
  /// Get all harmonious themes
  static List<FiveColorTheme> getAllThemes() {
    return [
      deepOcean,
      forestTwilight,
      royalPurple,
      sunsetWarmth,
      arcticBlue,
      lightProfessional,
      lightMint,
      lightLavender,
      monochromeDark,
      monochromeLight,
    ];
  }
  
  /// Get theme by name
  static FiveColorTheme? getThemeByName(String name) {
    switch (name) {
      case 'deepOcean':
        return deepOcean;
      case 'forestTwilight':
        return forestTwilight;
      case 'royalPurple':
        return royalPurple;
      case 'sunsetWarmth':
        return sunsetWarmth;
      case 'arcticBlue':
        return arcticBlue;
      case 'lightProfessional':
        return lightProfessional;
      case 'lightMint':
        return lightMint;
      case 'lightLavender':
        return lightLavender;
      case 'monochromeDark':
        return monochromeDark;
      case 'monochromeLight':
        return monochromeLight;
      default:
        return null;
    }
  }
  
  /// Generate harmonious palette from a primary color using color theory
  static FiveColorTheme generateFromPrimary(Color primaryColor, {
    bool isDark = true,
    String name = 'Custom',
  }) {
    final hsl = HSLColor.fromColor(primaryColor);
    
    if (isDark) {
      // Dark theme generation
      return FiveColorTheme(
        background: HSLColor.fromAHSL(1.0, hsl.hue, 0.4, 0.06).toColor(),
        backgroundHigh: HSLColor.fromAHSL(1.0, hsl.hue, 0.3, 0.15).toColor(),
        theme: primaryColor,
        themeHigh: HSLColor.fromAHSL(1.0, hsl.hue, hsl.saturation * 0.8, hsl.lightness + 0.15).toColor(),
        contrast: HSLColor.fromAHSL(1.0, (hsl.hue + 180) % 360, 0.7, 0.55).toColor(),
        name: name,
        isDark: true,
      );
    } else {
      // Light theme generation
      return FiveColorTheme(
        background: HSLColor.fromAHSL(1.0, hsl.hue, 0.15, 0.98).toColor(),
        backgroundHigh: Colors.white,
        theme: primaryColor,
        themeHigh: HSLColor.fromAHSL(1.0, hsl.hue, hsl.saturation * 0.9, hsl.lightness + 0.1).toColor(),
        contrast: HSLColor.fromAHSL(1.0, (hsl.hue + 180) % 360, 0.8, 0.4).toColor(),
        name: name,
        isDark: false,
      );
    }
  }
  
  /// Generate triadic harmony palette (3 colors 120° apart)
  static FiveColorTheme generateTriadic(Color primaryColor, {
    bool isDark = true,
    String name = 'Triadic',
  }) {
    final hsl = HSLColor.fromColor(primaryColor);
    final secondary = HSLColor.fromAHSL(1.0, (hsl.hue + 120) % 360, hsl.saturation, hsl.lightness);
    
    if (isDark) {
      return FiveColorTheme(
        background: HSLColor.fromAHSL(1.0, hsl.hue, 0.4, 0.06).toColor(),
        backgroundHigh: HSLColor.fromAHSL(1.0, hsl.hue, 0.3, 0.15).toColor(),
        theme: primaryColor,
        themeHigh: secondary.toColor(),
        contrast: HSLColor.fromAHSL(1.0, (hsl.hue + 240) % 360, 0.7, 0.55).toColor(),
        name: name,
        isDark: true,
      );
    } else {
      return FiveColorTheme(
        background: HSLColor.fromAHSL(1.0, hsl.hue, 0.15, 0.98).toColor(),
        backgroundHigh: Colors.white,
        theme: primaryColor,
        themeHigh: secondary.toColor(),
        contrast: HSLColor.fromAHSL(1.0, (hsl.hue + 240) % 360, 0.8, 0.4).toColor(),
        name: name,
        isDark: false,
      );
    }
  }
  
  /// Generate analogous harmony palette (adjacent colors)
  static FiveColorTheme generateAnalogous(Color primaryColor, {
    bool isDark = true,
    String name = 'Analogous',
  }) {
    final hsl = HSLColor.fromColor(primaryColor);
    final adjacent = HSLColor.fromAHSL(1.0, (hsl.hue + 30) % 360, hsl.saturation, hsl.lightness);
    
    if (isDark) {
      return FiveColorTheme(
        background: HSLColor.fromAHSL(1.0, hsl.hue, 0.4, 0.06).toColor(),
        backgroundHigh: HSLColor.fromAHSL(1.0, (hsl.hue + 15) % 360, 0.3, 0.15).toColor(),
        theme: primaryColor,
        themeHigh: adjacent.toColor(),
        contrast: HSLColor.fromAHSL(1.0, (hsl.hue + 180) % 360, 0.7, 0.55).toColor(),
        name: name,
        isDark: true,
      );
    } else {
      return FiveColorTheme(
        background: HSLColor.fromAHSL(1.0, hsl.hue, 0.15, 0.98).toColor(),
        backgroundHigh: Colors.white,
        theme: primaryColor,
        themeHigh: adjacent.toColor(),
        contrast: HSLColor.fromAHSL(1.0, (hsl.hue + 180) % 360, 0.8, 0.4).toColor(),
        name: name,
        isDark: false,
      );
    }
  }
}