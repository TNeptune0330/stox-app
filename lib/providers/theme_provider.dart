import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/local_database_service.dart';
import '../services/user_settings_service.dart';
import '../models/app_theme_model.dart';
import '../models/five_color_theme.dart';

// Neon Navy Design System Color Tokens
class NeonNavyColors {
  // Primary Colors
  static const Color primary = Color(0xFF22C55E);        // Electric green
  static const Color primaryDim = Color(0xFF16A34A);
  static const Color error = Color(0xFFEF4444);          // Modern red
  static const Color warning = Color(0xFFF59E0B);
  static const Color info = Color(0xFF3B82F6);           // Blue accents/links
  
  // Background Colors
  static const Color bgDark = Color(0xFF0B1220);         // App background
  static const Color surfaceDark = Color(0xFF151E2E);    // Primary cards
  static const Color surfaceDark2 = Color(0xFF1D2A3B);   // Secondary cards/inputs
  static const Color strokeDark = Color(0xFF243145);
  
  // Text Colors
  static const Color textPrimary = Color(0xFFE9F1FF);
  static const Color textSecondary = Color(0xFFA7B4C7);
  static const Color textMuted = Color(0xFF7B8AA0);
  
  // Chart Colors
  static const Color chartLine = Color(0xFF22C55E);
  static const Color donutIncome = Color(0xFF22C55E);
  static const Color donutOutcome = Color(0xFFEF4444);
  
  // Badge Colors  
  static const Color badgeRed = Color(0xFFEF4444);
  static const Color badgeOrange = Color(0xFFF59E0B);
  static const Color badgeYellow = Color(0xFFF59E0B);  // Bright yellow accent
  static const Color badgeGreen = Color(0xFF22C55E);
  static const Color badgeBlue = Color(0xFF3B82F6);
  static const Color badgePurple = Color(0xFF8B5CF6);
  static const Color badgePink = Color(0xFFEC4899);     // Pink accent
  
  // Additional Accent Colors
  static const Color accentPink = Color(0xFFEC4899);     // Pink/Rose
  static const Color accentOrange = Color(0xFFEA580C);   // Orange
  static const Color accentYellow = Color(0xFFEAB308);   // Yellow/Amber
  static const Color accentCyan = Color(0xFF06B6D4);     // Cyan
  static const Color accentViolet = Color(0xFF7C3AED);   // Violet
}

class ThemeProvider with ChangeNotifier {
  final UserSettingsService _settingsService = UserSettingsService();
  String _selectedTheme = 'neonNavy';
  String? _currentUserId;
  
  String get selectedTheme => _selectedTheme;
  
  // Quick access to design tokens
  Color get background => NeonNavyColors.bgDark;
  Color get backgroundHigh => NeonNavyColors.surfaceDark;
  Color get theme => NeonNavyColors.primary;
  Color get themeHigh => NeonNavyColors.primaryDim;
  Color get contrast => NeonNavyColors.textPrimary;
  bool get isDark => true;
  
  // Legacy getters for backward compatibility
  Color get customPrimaryColor => NeonNavyColors.primary;
  Color get customBackgroundColor => NeonNavyColors.bgDark;
  AppThemeModel get currentTheme => _createNeonNavyTheme();
  FiveColorTheme get fiveColorTheme => _createFiveColorTheme();
  
  AppThemeModel _createNeonNavyTheme() {
    return const AppThemeModel(
      name: 'Neon Navy',
      primaryColor: NeonNavyColors.primary,
      secondaryColor: NeonNavyColors.primaryDim,
      backgroundColor: NeonNavyColors.bgDark,
      surfaceColor: NeonNavyColors.surfaceDark,
      cardColor: NeonNavyColors.surfaceDark,
      textColor: NeonNavyColors.textPrimary,
      subtitleColor: NeonNavyColors.textSecondary,
      dividerColor: NeonNavyColors.strokeDark,
      appBarColor: NeonNavyColors.surfaceDark,
      bottomNavColor: NeonNavyColors.surfaceDark,
      successColor: NeonNavyColors.primary,
      errorColor: NeonNavyColors.error,
      warningColor: NeonNavyColors.warning,
      infoColor: NeonNavyColors.info,
      positiveColor: NeonNavyColors.primary,
      negativeColor: NeonNavyColors.error,
      shadowColor: Colors.black,
      borderColor: NeonNavyColors.strokeDark,
      accentColor: NeonNavyColors.primary,
      highlightColor: NeonNavyColors.primaryDim,
      disabledColor: NeonNavyColors.textMuted,
      iconColor: NeonNavyColors.textPrimary,
      buttonColor: NeonNavyColors.primary,
      chipColor: NeonNavyColors.surfaceDark2,
      tabBarColor: NeonNavyColors.surfaceDark,
      modalColor: NeonNavyColors.surfaceDark,
      overlayColor: Color(0x80000000),
      gradientStartColor: NeonNavyColors.primaryDim,
      gradientEndColor: NeonNavyColors.primary,
      isDark: true,
    );
  }
  
  FiveColorTheme _createFiveColorTheme() {
    return FiveColorTheme.custom(
      background: NeonNavyColors.bgDark,
      backgroundHigh: NeonNavyColors.surfaceDark,
      theme: NeonNavyColors.primary,
      themeHigh: NeonNavyColors.primaryDim,
      contrast: NeonNavyColors.textPrimary,
      name: 'Neon Navy',
      isDark: true,
    );
  }

  Future<void> initialize([String? userId]) async {
    try {
      _currentUserId = userId;
      print('📱 ThemeProvider: Initializing Neon Navy theme for user: ${userId ?? 'anonymous'}');
      
      if (userId != null) {
        _selectedTheme = await _settingsService.getSetting<String>(
          userId: userId,
          key: 'selected_theme',
          defaultValue: 'neonNavy',
        ) ?? 'neonNavy';
      } else {
        _selectedTheme = LocalDatabaseService.getSetting<String>('selected_theme') ?? 'neonNavy';
      }
      
      notifyListeners();
    } catch (e) {
      print('Error initializing theme: $e');
      _selectedTheme = 'neonNavy';
      notifyListeners();
    }
  }

  Future<void> setTheme(String theme) async {
    try {
      _selectedTheme = theme;
      
      if (_currentUserId != null) {
        await _settingsService.saveSetting(
          userId: _currentUserId!,
          key: 'selected_theme',
          value: theme,
        );
      } else {
        await LocalDatabaseService.saveSetting('selected_theme', theme);
      }
      
      notifyListeners();
    } catch (e) {
      print('Error saving theme: $e');
      _selectedTheme = theme;
      notifyListeners();
    }
  }
  /// Set theme using the 5-color system (simplified for Neon Navy)
  Future<void> setFiveColorTheme(FiveColorTheme fiveColorTheme) async {
    await setTheme('neonNavy'); // Always use Neon Navy theme
  }

  // Set current user ID for Supabase sync
  void setUserId(String? userId) {
    if (_currentUserId != userId) {
      _currentUserId = userId;
      print('📱 ThemeProvider: User ID changed to $userId, re-initializing...');
      if (userId != null) {
        initialize(userId);
      }
    }
  }

  Future<void> setCustomTheme(AppThemeModel theme) async {
    await setTheme('neonNavy'); // Always use Neon Navy theme
  }
  
  Future<void> setCustomColors(Color primary, Color background) async {
    await setTheme('neonNavy'); // Always use Neon Navy theme
  }

  ThemeData get themeData {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      
      // Color Scheme
      colorScheme: const ColorScheme.dark(
        primary: NeonNavyColors.primary,
        onPrimary: Colors.white,
        secondary: NeonNavyColors.primaryDim,
        onSecondary: Colors.white,
        error: NeonNavyColors.error,
        onError: Colors.white,
        surface: NeonNavyColors.surfaceDark,
        onSurface: NeonNavyColors.textPrimary,
        background: NeonNavyColors.bgDark,
        onBackground: NeonNavyColors.textPrimary,
        outline: NeonNavyColors.strokeDark,
      ),
      
      // Typography with Nunito
      textTheme: GoogleFonts.nunitoTextTheme(const TextTheme(
        displayLarge: TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: NeonNavyColors.textPrimary),
        headlineLarge: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: NeonNavyColors.textPrimary),
        bodyLarge: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: NeonNavyColors.textPrimary),
        bodyMedium: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: NeonNavyColors.textSecondary),
        labelMedium: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: NeonNavyColors.textMuted),
      )),
      
      // App Bar Theme
      appBarTheme: const AppBarTheme(
        backgroundColor: NeonNavyColors.surfaceDark,
        foregroundColor: NeonNavyColors.textPrimary,
        elevation: 0,
      ),
      
      // Card Theme
      cardTheme: CardThemeData(
        color: NeonNavyColors.surfaceDark,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        elevation: 6,
        shadowColor: Colors.black.withOpacity(0.24),
      ),
      
      // Elevated Button Theme
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: NeonNavyColors.primary,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        ),
      ),
      
      // Outlined Button Theme
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: NeonNavyColors.textPrimary,
          side: const BorderSide(color: NeonNavyColors.strokeDark),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        ),
      ),
      
      // Chip Theme
      chipTheme: const ChipThemeData(
        backgroundColor: NeonNavyColors.surfaceDark2,
        labelStyle: TextStyle(color: NeonNavyColors.textPrimary, fontWeight: FontWeight.w700),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(16)),
          side: BorderSide(color: NeonNavyColors.strokeDark),
        ),
      ),
      
      // Input Decoration Theme
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: NeonNavyColors.surfaceDark2,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: NeonNavyColors.strokeDark),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: NeonNavyColors.strokeDark),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: NeonNavyColors.primary),
        ),
        labelStyle: const TextStyle(color: NeonNavyColors.textSecondary),
        hintStyle: const TextStyle(color: NeonNavyColors.textMuted),
      ),
      
      // Bottom Navigation Bar Theme
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: NeonNavyColors.surfaceDark,
        selectedItemColor: NeonNavyColors.primary,
        unselectedItemColor: NeonNavyColors.textMuted,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),
    );
  }

  AppThemeModel _getPresetTheme(String themeName) {
    return _createNeonNavyTheme(); // Always return Neon Navy theme
  }

  // Color control methods (simplified for Neon Navy)
  Future<void> updatePrimaryColor(Color color) async => setTheme('neonNavy');
  Future<void> updateBackgroundColor(Color color) async => setTheme('neonNavy');
  Future<void> updateTextColor(Color color) async => setTheme('neonNavy');
  Future<void> updateCardColor(Color color) async => setTheme('neonNavy');
  Future<void> updateAccentColor(Color color) async => setTheme('neonNavy');
  Future<void> updateSuccessColor(Color color) async => setTheme('neonNavy');
  Future<void> updateErrorColor(Color color) async => setTheme('neonNavy');
  Future<void> updateWarningColor(Color color) async => setTheme('neonNavy');

  Future<void> updateMultipleColors(Map<String, Color> colors) async {
    await setTheme('neonNavy'); // Always use Neon Navy theme
  }

  // Get available theme colors for customization
  Map<String, Color> getThemeColors() {
    final theme = _createNeonNavyTheme();
    return {
      'primary': theme.primaryColor,
      'secondary': theme.secondaryColor,
      'background': theme.backgroundColor,
      'surface': theme.surfaceColor,
      'card': theme.cardColor,
      'text': theme.textColor,
      'subtitle': theme.subtitleColor,
      'accent': theme.accentColor,
      'success': theme.successColor,
      'error': theme.errorColor,
      'warning': theme.warningColor,
      'positive': theme.positiveColor,
      'negative': theme.negativeColor,
    };
  }

  /// Get all available themes for UI selection
  static List<Map<String, dynamic>> get themes {
    return [
      {
        'name': 'Neon Navy',
        'value': 'neonNavy',
        'icon': Icons.palette,
        'color': NeonNavyColors.primary,
        'previewColors': [
          NeonNavyColors.bgDark,
          NeonNavyColors.surfaceDark,
          NeonNavyColors.primary,
          NeonNavyColors.primaryDim,
          NeonNavyColors.textPrimary,
        ],
      },
    ];
  }
  
  static String _getThemeKey(String name) {
    return 'neonNavy'; // Always return Neon Navy
  }
  
  static IconData _getThemeIcon(String name) {
    return Icons.palette; // Always return palette icon
  }
}