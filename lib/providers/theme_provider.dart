import 'package:flutter/material.dart';
import '../services/storage_service.dart';

class ThemeProvider with ChangeNotifier {
  String _selectedTheme = 'light';
  
  String get selectedTheme => _selectedTheme;

  Future<void> initialize() async {
    _selectedTheme = StorageService.getTheme();
    notifyListeners();
  }

  Future<void> setTheme(String theme) async {
    _selectedTheme = theme;
    await StorageService.saveTheme(theme);
    notifyListeners();
  }

  ThemeData get themeData {
    switch (_selectedTheme) {
      case 'dark':
        return _gameTheme;
      case 'green':
        return _greenTheme;
      case 'blue':
        return _blueTheme;
      case 'light':
      default:
        return _gameTheme; // Default to game theme
    }
  }

  static final ThemeData _gameTheme = ThemeData(
    useMaterial3: true,
    colorScheme: const ColorScheme.dark(
      background: Color(0xFF0f1419),
      surface: Color(0xFF1a1a2e),
      primary: Color(0xFFf39c12),
      secondary: Color(0xFF7209b7),
      tertiary: Color(0xFF27ae60),
      error: Color(0xFFe74c3c),
      onBackground: Colors.white,
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

  static const List<Map<String, dynamic>> themes = [
    {
      'name': 'Light',
      'value': 'light',
      'icon': Icons.light_mode,
      'color': Colors.white,
    },
    {
      'name': 'Dark',
      'value': 'dark',
      'icon': Icons.dark_mode,
      'color': Colors.black,
    },
    {
      'name': 'Green',
      'value': 'green',
      'icon': Icons.nature,
      'color': Colors.green,
    },
    {
      'name': 'Blue',
      'value': 'blue',
      'icon': Icons.water,
      'color': Colors.indigo,
    },
  ];
}