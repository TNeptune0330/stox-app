import 'dart:convert';
import 'package:flutter/material.dart';
import '../services/local_database_service.dart';
import '../services/user_settings_service.dart';

class ThemeProvider with ChangeNotifier {
  final UserSettingsService _settingsService = UserSettingsService();
  String _selectedTheme = 'deepOcean';
  Color _primaryColor = const Color(0xFF1E88E5);
  Color _accentColor = const Color(0xFF64B5F6);

  // Getters for theme values
  String get selectedTheme => _selectedTheme;
  Color get theme => _primaryColor;
  Color get themeHigh => _accentColor;
  Color get background => const Color(0xFF0B1426);
  Color get backgroundHigh => const Color(0xFF1A2332);
  Color get contrast => Colors.white;
  
  ThemeData get themeData => ThemeData(
    brightness: Brightness.dark,
    primarySwatch: Colors.blue,
    primaryColor: _primaryColor,
    scaffoldBackgroundColor: const Color(0xFF0B1426),
    appBarTheme: AppBarTheme(
      backgroundColor: const Color(0xFF1A2332),
      foregroundColor: Colors.white,
    ),
    colorScheme: ColorScheme.dark(
      primary: _primaryColor,
      secondary: _accentColor,
      surface: const Color(0xFF1A2332),
      background: const Color(0xFF0B1426),
    ),
  );

  static List<Map<String, dynamic>> get themes => [
    {
      'value': 'deepOcean',
      'name': 'Deep Ocean',
      'color': const Color(0xFF1E88E5),
      'icon': Icons.water,
      'previewColors': [
        const Color(0xFF1E88E5),
        const Color(0xFF64B5F6),
        const Color(0xFF90CAF9),
      ],
    },
    {
      'value': 'forest',
      'name': 'Forest',
      'color': const Color(0xFF4CAF50),
      'icon': Icons.nature,
      'previewColors': [
        const Color(0xFF4CAF50),
        const Color(0xFF81C784),
        const Color(0xFFA5D6A7),
      ],
    },
    {
      'value': 'sunset',
      'name': 'Sunset',
      'color': const Color(0xFFFF9800),
      'icon': Icons.wb_sunny,
      'previewColors': [
        const Color(0xFFFF9800),
        const Color(0xFFFFB74D),
        const Color(0xFFFFCC02),
      ],
    },
  ];

  Future<void> initialize() async {
    // Load saved theme from storage
    try {
      // Use a default theme for now
      _selectedTheme = 'deepOcean';
      _updateColorsForTheme(_selectedTheme);
    } catch (e) {
      print('Error loading theme: $e');
    }
    notifyListeners();
  }

  Future<void> setTheme(String themeName) async {
    _selectedTheme = themeName;
    _updateColorsForTheme(themeName);
    
    try {
      // Theme saving temporarily disabled
      print('Theme set to: $themeName');
    } catch (e) {
      print('Error saving theme: $e');
    }
    
    notifyListeners();
  }

  void _updateColorsForTheme(String themeName) {
    switch (themeName) {
      case 'forest':
        _primaryColor = const Color(0xFF4CAF50);
        _accentColor = const Color(0xFF81C784);
        break;
      case 'sunset':
        _primaryColor = const Color(0xFFFF9800);
        _accentColor = const Color(0xFFFFB74D);
        break;
      case 'deepOcean':
      default:
        _primaryColor = const Color(0xFF1E88E5);
        _accentColor = const Color(0xFF64B5F6);
        break;
    }
  }
}