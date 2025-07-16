import 'package:flutter/material.dart';
import '../services/local_database_service.dart';

class ThemeProvider with ChangeNotifier {
  String _selectedTheme = 'blue_black';
  Color _customPrimaryColor = Colors.blue;
  Color _customBackgroundColor = Colors.black;
  
  String get selectedTheme => _selectedTheme;
  Color get customPrimaryColor => _customPrimaryColor;
  Color get customBackgroundColor => _customBackgroundColor;

  Future<void> initialize() async {
    try {
      _selectedTheme = LocalDatabaseService.getSetting<String>('selected_theme') ?? 'blue_black';
      final savedPrimary = LocalDatabaseService.getSetting<int>('custom_primary_color');
      final savedBackground = LocalDatabaseService.getSetting<int>('custom_background_color');
      
      if (savedPrimary != null) {
        _customPrimaryColor = Color(savedPrimary);
      }
      if (savedBackground != null) {
        _customBackgroundColor = Color(savedBackground);
      }
      
      notifyListeners();
    } catch (e) {
      print('Error initializing theme: $e');
      // Use default values if database isn't ready
      _selectedTheme = 'blue_black';
      _customPrimaryColor = Colors.blue;
      _customBackgroundColor = Colors.black;
      notifyListeners();
    }
  }

  Future<void> setTheme(String theme) async {
    try {
      _selectedTheme = theme;
      await LocalDatabaseService.saveSetting('selected_theme', theme);
      notifyListeners();
    } catch (e) {
      print('Error saving theme: $e');
      // Still update the theme in memory even if saving fails
      _selectedTheme = theme;
      notifyListeners();
    }
  }

  Future<void> setCustomColors(Color primary, Color background) async {
    try {
      _customPrimaryColor = primary;
      _customBackgroundColor = background;
      _selectedTheme = 'custom';
      
      await LocalDatabaseService.saveSetting('selected_theme', 'custom');
      await LocalDatabaseService.saveSetting('custom_primary_color', primary.value);
      await LocalDatabaseService.saveSetting('custom_background_color', background.value);
      
      notifyListeners();
    } catch (e) {
      print('Error saving custom colors: $e');
      // Still update the colors in memory even if saving fails
      _customPrimaryColor = primary;
      _customBackgroundColor = background;
      _selectedTheme = 'custom';
      notifyListeners();
    }
  }

  ThemeData get themeData {
    switch (_selectedTheme) {
      case 'blue_black':
        return _blueBlackTheme;
      case 'dark':
        return _gameTheme;
      case 'green':
        return _greenTheme;
      case 'blue':
        return _blueTheme;
      case 'game':
        return _businessEmpireTheme;
      case 'light':
        return _lightTheme;
      case 'custom':
        return _customTheme;
      default:
        return _blueBlackTheme; // Default to blue/black theme
    }
  }

  ThemeData get _customTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.dark(
        surface: _customBackgroundColor,
        primary: _customPrimaryColor,
        secondary: _customPrimaryColor.withOpacity(0.7),
        tertiary: _customPrimaryColor.withOpacity(0.5),
        error: Colors.red,
        onSurface: Colors.white,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
      ),
      scaffoldBackgroundColor: _customBackgroundColor,
      appBarTheme: AppBarTheme(
        backgroundColor: _customPrimaryColor,
        foregroundColor: Colors.white,
        centerTitle: true,
        elevation: 0,
      ),
      cardTheme: CardThemeData(
        color: _customBackgroundColor == Colors.black ? Colors.grey[900] : _customBackgroundColor.withOpacity(0.8),
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: _customPrimaryColor,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: _customBackgroundColor == Colors.black ? Colors.grey[900] : _customBackgroundColor.withOpacity(0.9),
        selectedItemColor: _customPrimaryColor,
        unselectedItemColor: Colors.white60,
        elevation: 8,
      ),
    );
  }

  static final ThemeData _blueBlackTheme = ThemeData(
    useMaterial3: true,
    colorScheme: const ColorScheme.dark(
      surface: Colors.black,
      primary: Colors.blue,
      secondary: Color(0xFF42a5f5),
      tertiary: Color(0xFF1976d2),
      error: Colors.red,
      onSurface: Colors.white,
      onPrimary: Colors.white,
      onSecondary: Colors.white,
    ),
    scaffoldBackgroundColor: Colors.black,
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.blue,
      foregroundColor: Colors.white,
      centerTitle: true,
      elevation: 0,
    ),
    cardTheme: CardThemeData(
      color: Colors.grey[900],
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    ),
    bottomNavigationBarTheme: BottomNavigationBarThemeData(
      backgroundColor: Colors.grey[900],
      selectedItemColor: Colors.blue,
      unselectedItemColor: Colors.white60,
      elevation: 8,
    ),
  );

  static final ThemeData _gameTheme = ThemeData(
    useMaterial3: true,
    colorScheme: const ColorScheme.dark(
      surface: Color(0xFF0a0a0a),
      primary: Color(0xFF1565c0),
      secondary: Color(0xFF42a5f5),
      tertiary: Color(0xFF27ae60),
      error: Color(0xFFe74c3c),
      onSurface: Colors.white,
      onPrimary: Colors.white,
      onSecondary: Colors.white,
    ),
    scaffoldBackgroundColor: const Color(0xFF0a0a0a),
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFF1a1a1a),
      foregroundColor: Colors.white,
      centerTitle: true,
      elevation: 0,
    ),
    cardTheme: CardThemeData(
      color: const Color(0xFF1a1a1a),
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF1565c0),
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: Color(0xFF1a1a1a),
      selectedItemColor: Color(0xFF42a5f5),
      unselectedItemColor: Colors.white60,
      elevation: 8,
    ),
  );

  static final ThemeData _lightTheme = ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: Colors.blue,
      brightness: Brightness.light,
    ),
    appBarTheme: const AppBarTheme(
      centerTitle: true,
      elevation: 0,
    ),
    cardTheme: CardThemeData(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    ),
  );

  static final ThemeData _darkTheme = ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: Colors.blue,
      brightness: Brightness.dark,
    ),
    appBarTheme: const AppBarTheme(
      centerTitle: true,
      elevation: 0,
    ),
    cardTheme: CardThemeData(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    ),
  );

  static final ThemeData _greenTheme = ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: Colors.green,
      brightness: Brightness.light,
    ),
    appBarTheme: const AppBarTheme(
      centerTitle: true,
      elevation: 0,
    ),
    cardTheme: CardThemeData(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    ),
  );

  static final ThemeData _blueTheme = ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: Colors.indigo,
      brightness: Brightness.light,
    ),
    appBarTheme: const AppBarTheme(
      centerTitle: true,
      elevation: 0,
    ),
    cardTheme: CardThemeData(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    ),
  );

  static final ThemeData _businessEmpireTheme = ThemeData(
    useMaterial3: true,
    colorScheme: const ColorScheme.dark(
      surface: Color(0xFF0f1419),
      primary: Color(0xFFf39c12),
      secondary: Color(0xFF7209b7),
      tertiary: Color(0xFF27ae60),
      error: Color(0xFFe74c3c),
      onSurface: Colors.white,
      onPrimary: Colors.black,
      onSecondary: Colors.white,
    ),
    scaffoldBackgroundColor: const Color(0xFF0f1419),
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFF1a1a2e),
      foregroundColor: Colors.white,
      centerTitle: true,
      elevation: 0,
    ),
    cardTheme: CardThemeData(
      color: const Color(0xFF1a1a2e),
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFFf39c12),
        foregroundColor: Colors.black,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: Color(0xFF1a1a2e),
      selectedItemColor: Color(0xFFf39c12),
      unselectedItemColor: Colors.white60,
      elevation: 8,
    ),
  );

  static const List<Map<String, dynamic>> themes = [
    {
      'name': 'Blue & Black (Default)',
      'value': 'blue_black',
      'icon': Icons.palette,
      'color': Colors.blue,
    },
    {
      'name': 'Dark Blue',
      'value': 'dark',
      'icon': Icons.dark_mode,
      'color': Color(0xFF1565c0),
    },
    {
      'name': 'Classic Light',
      'value': 'light',
      'icon': Icons.light_mode,
      'color': Colors.white,
    },
    {
      'name': 'Trading Green',
      'value': 'green',
      'icon': Icons.trending_up,
      'color': Colors.green,
    },
    {
      'name': 'Ocean Blue',
      'value': 'blue',
      'icon': Icons.water_drop,
      'color': Colors.indigo,
    },
    {
      'name': 'Business Empire',
      'value': 'game',
      'icon': Icons.videogame_asset,
      'color': Color(0xFFf39c12),
    },
    {
      'name': 'Custom Colors',
      'value': 'custom',
      'icon': Icons.color_lens,
      'color': Colors.purple,
    },
  ];
}