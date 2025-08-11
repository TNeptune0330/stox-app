import 'package:flutter/material.dart';

class ModernTheme {
  // Dark theme colors matching the reference image
  static const Color backgroundPrimary = Color(0xFF0F172A); // Very dark blue
  static const Color backgroundCard = Color(0xFF1E293B); // Dark blue card
  static const Color backgroundElevated = Color(0xFF334155); // Elevated surface
  static const Color backgroundAccent = Color(0xFF475569); // Accent background
  
  // Vibrant accent colors matching reference image
  static const Color accentBlue = Color(0xFF3B82F6); // Bright blue
  static const Color accentGreen = Color(0xFF10B981); // Vibrant green like reference
  static const Color accentRed = Color(0xFFEF4444); // Bright red
  static const Color accentOrange = Color(0xFFF97316); // Bright orange like reference
  static const Color accentPurple = Color(0xFF8B5CF6); // Bright purple
  static const Color accentYellow = Color(0xFFEAB308); // Bright yellow
  static const Color accentPink = Color(0xFFEC4899); // Pink like reference
  static const Color accentTeal = Color(0xFF14B8A6); // Teal accent
  
  // Text colors for dark theme
  static const Color textPrimary = Color(0xFFFFFFFF); // White text
  static const Color textSecondary = Color(0xFFCBD5E1); // Light gray text
  static const Color textMuted = Color(0xFF94A3B8); // Muted gray
  static const Color textOnAccent = Color(0xFFFFFFFF); // White on colored backgrounds
  
  // Border and divider colors for dark theme
  static const Color borderLight = Color(0xFF475569); // Dark border
  static const Color borderMedium = Color(0xFF64748B); // Medium border
  static const Color divider = Color(0xFF374151); // Divider color
  
  // Shadow colors for dark theme
  static const Color shadowLight = Color(0x20000000); // Dark shadow
  static const Color shadowMedium = Color(0x40000000); // Stronger shadow
  
  // Spacing system (8pt grid)
  static const double spaceXS = 4.0;
  static const double spaceS = 8.0;
  static const double spaceM = 16.0;
  static const double spaceL = 24.0;
  static const double spaceXL = 32.0;
  static const double spaceXXL = 48.0;
  
  // Radius system - more rounded like reference
  static const double radiusXS = 6.0;
  static const double radiusS = 12.0;
  static const double radiusM = 16.0;
  static const double radiusL = 20.0;
  static const double radiusXL = 32.0;
  
  // Professional shadows
  static const List<BoxShadow> shadowCard = [
    BoxShadow(
      color: shadowLight,
      blurRadius: 10,
      offset: Offset(0, 1),
    ),
    BoxShadow(
      color: shadowMedium,
      blurRadius: 3,
      offset: Offset(0, 1),
    ),
  ];
  
  static const List<BoxShadow> shadowButton = [
    BoxShadow(
      color: shadowMedium,
      blurRadius: 8,
      offset: Offset(0, 2),
    ),
  ];
  
  // Animation durations
  static const Duration animationFast = Duration(milliseconds: 150);
  static const Duration animationMedium = Duration(milliseconds: 250);
  static const Duration animationSlow = Duration(milliseconds: 400);
  
  // Typography system
  static const TextStyle displayLarge = TextStyle(
    fontSize: 32,
    fontWeight: FontWeight.bold,
    height: 1.2,
    letterSpacing: -0.5,
    color: textPrimary,
  );
  
  static const TextStyle displayMedium = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.bold,
    height: 1.2,
    letterSpacing: -0.25,
    color: textPrimary,
  );
  
  static const TextStyle headlineLarge = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.w600,
    height: 1.3,
    color: textPrimary,
  );
  
  static const TextStyle headlineMedium = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    height: 1.3,
    color: textPrimary,
  );
  
  static const TextStyle titleLarge = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    height: 1.4,
    color: textPrimary,
  );
  
  static const TextStyle titleMedium = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w500,
    height: 1.4,
    color: textPrimary,
  );
  
  static const TextStyle bodyLarge = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.normal,
    height: 1.5,
    color: textPrimary,
  );
  
  static const TextStyle bodyMedium = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.normal,
    height: 1.5,
    color: textSecondary,
  );
  
  static const TextStyle bodySmall = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.normal,
    height: 1.4,
    color: textMuted,
  );
  
  static const TextStyle labelLarge = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    height: 1.4,
    color: textPrimary,
  );
  
  static const TextStyle labelMedium = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    height: 1.3,
    color: textSecondary,
  );
  
  // Dark Theme matching reference image
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: const ColorScheme.dark(
        primary: accentBlue,
        secondary: accentPurple,
        surface: backgroundCard,
        background: backgroundPrimary,
        error: accentRed,
        onPrimary: textOnAccent,
        onSecondary: textOnAccent,
        onSurface: textPrimary,
        onBackground: textPrimary,
        onError: textOnAccent,
      ),
      scaffoldBackgroundColor: backgroundPrimary,
      appBarTheme: const AppBarTheme(
        backgroundColor: backgroundPrimary,
        foregroundColor: textPrimary,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: headlineMedium,
        centerTitle: false,
      ),
      cardTheme: CardThemeData(
        color: backgroundCard,
        elevation: 0,
        shadowColor: shadowLight,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusL),
        ),
        margin: EdgeInsets.zero,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: accentBlue,
          foregroundColor: textOnAccent,
          elevation: 0,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusM),
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: spaceL,
            vertical: spaceM,
          ),
          textStyle: labelLarge.copyWith(color: textOnAccent),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: accentBlue,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusS),
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: spaceM,
            vertical: spaceS,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: backgroundElevated,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusM),
          borderSide: const BorderSide(color: borderLight),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusM),
          borderSide: const BorderSide(color: borderLight),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusM),
          borderSide: const BorderSide(color: accentBlue, width: 2),
        ),
        contentPadding: const EdgeInsets.all(spaceM),
        hintStyle: bodyMedium,
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: backgroundCard,
        selectedItemColor: accentBlue,
        unselectedItemColor: textMuted,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      ),
      dividerTheme: const DividerThemeData(
        color: divider,
        thickness: 1,
        space: 1,
      ),
    );
  }
}