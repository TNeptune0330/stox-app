import 'dart:convert';
import 'package:flutter/material.dart';
import '../services/local_database_service.dart';
import '../services/user_settings_service.dart';
import '../models/app_theme_model.dart';
import '../models/five_color_theme.dart';

class ThemeProvider with ChangeNotifier {
  final UserSettingsService _settingsService = UserSettingsService();
  String _selectedTheme = 'darkBlue';
  AppThemeModel _currentTheme = AppThemeModel.darkBlue;
  FiveColorTheme _fiveColorTheme = FiveColorTheme.darkBlue;
  String? _currentUserId;
  
  String get selectedTheme => _selectedTheme;
  AppThemeModel get currentTheme => _currentTheme;
  FiveColorTheme get fiveColorTheme => _fiveColorTheme;
  
  // Quick access to the 5 core colors
  Color get background => _fiveColorTheme.background;
  Color get backgroundHigh => _fiveColorTheme.backgroundHigh;
  Color get theme => _fiveColorTheme.theme;
  Color get themeHigh => _fiveColorTheme.themeHigh;
  Color get contrast => _fiveColorTheme.contrast;
  bool get isDark => _fiveColorTheme.isDark;
  
  // Legacy getters for backward compatibility
  Color get customPrimaryColor => _currentTheme.primaryColor;
  Color get customBackgroundColor => _currentTheme.backgroundColor;

  Future<void> initialize([String? userId]) async {
    try {
      _currentUserId = userId;
      
      if (userId != null) {
        // Load from Supabase with local fallback
        _selectedTheme = await _settingsService.getSetting<String>(
          userId: userId,
          key: 'selected_theme',
          defaultValue: 'darkBlue',
        ) ?? 'darkBlue';
        
        // Load full theme customization
        final savedThemeJson = await _settingsService.getSetting<String>(
          userId: userId,
          key: 'custom_theme_json',
        );
        
        if (savedThemeJson != null && _selectedTheme == 'custom') {
          try {
            final themeMap = Map<String, dynamic>.from(json.decode(savedThemeJson));
            _currentTheme = AppThemeModel.fromJson(themeMap);
            // Try to create a FiveColorTheme from the custom theme
            _fiveColorTheme = FiveColorTheme.custom(
              background: _currentTheme.backgroundColor,
              backgroundHigh: _currentTheme.surfaceColor,
              theme: _currentTheme.primaryColor,
              themeHigh: _currentTheme.secondaryColor,
              contrast: _currentTheme.errorColor,
              name: _currentTheme.name,
              isDark: _currentTheme.isDark,
            );
          } catch (e) {
            print('Error loading custom theme: $e');
            _fiveColorTheme = FiveColorTheme.darkBlue;
            _currentTheme = _fiveColorTheme.toAppThemeModel();
          }
        } else {
          _fiveColorTheme = FiveColorTheme.getThemeByName(_selectedTheme);
          _currentTheme = _fiveColorTheme.toAppThemeModel();
        }
      } else {
        // Fallback to local storage
        _selectedTheme = LocalDatabaseService.getSetting<String>('selected_theme') ?? 'darkBlue';
        final savedThemeJson = LocalDatabaseService.getSetting<String>('custom_theme_json');
        
        if (savedThemeJson != null && _selectedTheme == 'custom') {
          try {
            final themeMap = Map<String, dynamic>.from(json.decode(savedThemeJson));
            _currentTheme = AppThemeModel.fromJson(themeMap);
            // Try to create a FiveColorTheme from the custom theme
            _fiveColorTheme = FiveColorTheme.custom(
              background: _currentTheme.backgroundColor,
              backgroundHigh: _currentTheme.surfaceColor,
              theme: _currentTheme.primaryColor,
              themeHigh: _currentTheme.secondaryColor,
              contrast: _currentTheme.errorColor,
              name: _currentTheme.name,
              isDark: _currentTheme.isDark,
            );
          } catch (e) {
            print('Error loading custom theme: $e');
            _fiveColorTheme = FiveColorTheme.darkBlue;
            _currentTheme = _fiveColorTheme.toAppThemeModel();
          }
        } else {
          _fiveColorTheme = FiveColorTheme.getThemeByName(_selectedTheme);
          _currentTheme = _fiveColorTheme.toAppThemeModel();
        }
      }
      
      notifyListeners();
    } catch (e) {
      print('Error initializing theme: $e');
      // Use default values if everything fails
      _selectedTheme = 'darkBlue';
      _fiveColorTheme = FiveColorTheme.darkBlue;
      _currentTheme = _fiveColorTheme.toAppThemeModel();
      notifyListeners();
    }
  }

  Future<void> setTheme(String theme) async {
    try {
      _selectedTheme = theme;
      _fiveColorTheme = FiveColorTheme.getThemeByName(theme);
      _currentTheme = _fiveColorTheme.toAppThemeModel();
      
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
      // Still update the theme in memory even if saving fails
      _selectedTheme = theme;
      _fiveColorTheme = FiveColorTheme.getThemeByName(theme);
      _currentTheme = _fiveColorTheme.toAppThemeModel();
      notifyListeners();
    }
  }
  
  /// Set theme using the 5-color system
  Future<void> setFiveColorTheme(FiveColorTheme fiveColorTheme) async {
    try {
      _fiveColorTheme = fiveColorTheme;
      _currentTheme = fiveColorTheme.toAppThemeModel();
      _selectedTheme = 'custom';
      
      // Save the 5-color theme data
      final themeData = {
        'background': fiveColorTheme.background.value,
        'backgroundHigh': fiveColorTheme.backgroundHigh.value,
        'theme': fiveColorTheme.theme.value,
        'themeHigh': fiveColorTheme.themeHigh.value,
        'contrast': fiveColorTheme.contrast.value,
        'name': fiveColorTheme.name,
        'isDark': fiveColorTheme.isDark,
      };
      
      if (_currentUserId != null) {
        await _settingsService.saveSetting(
          userId: _currentUserId!,
          key: 'selected_theme',
          value: 'custom',
        );
        await _settingsService.saveSetting(
          userId: _currentUserId!,
          key: 'five_color_theme',
          value: json.encode(themeData),
        );
        await _settingsService.saveSetting(
          userId: _currentUserId!,
          key: 'custom_theme_json',
          value: json.encode(_currentTheme.toJson()),
        );
      } else {
        await LocalDatabaseService.saveSetting('selected_theme', 'custom');
        await LocalDatabaseService.saveSetting('five_color_theme', json.encode(themeData));
        await LocalDatabaseService.saveSetting('custom_theme_json', json.encode(_currentTheme.toJson()));
      }
      
      notifyListeners();
    } catch (e) {
      print('Error saving 5-color theme: $e');
      notifyListeners();
    }
  }

  // Set current user ID for Supabase sync
  void setUserId(String? userId) {
    _currentUserId = userId;
    if (userId != null) {
      // Re-initialize with user data
      initialize(userId);
    }
  }

  Future<void> setCustomTheme(AppThemeModel theme) async {
    try {
      _currentTheme = theme;
      _selectedTheme = 'custom';
      
      final themeJson = json.encode(theme.toJson());
      
      if (_currentUserId != null) {
        await _settingsService.saveSetting(
          userId: _currentUserId!,
          key: 'selected_theme',
          value: 'custom',
        );
        await _settingsService.saveSetting(
          userId: _currentUserId!,
          key: 'custom_theme_json',
          value: themeJson,
        );
      } else {
        await LocalDatabaseService.saveSetting('selected_theme', 'custom');
        await LocalDatabaseService.saveSetting('custom_theme_json', themeJson);
      }
      
      notifyListeners();
    } catch (e) {
      print('Error saving custom theme: $e');
      // Still update the theme in memory even if saving fails
      _currentTheme = theme;
      _selectedTheme = 'custom';
      notifyListeners();
    }
  }
  
  Future<void> setCustomColors(Color primary, Color background) async {
    final customTheme = _currentTheme.copyWith(
      primaryColor: primary,
      backgroundColor: background,
      name: 'Custom',
    );
    await setCustomTheme(customTheme);
  }

  ThemeData get themeData {
    return _currentTheme.toThemeData();
  }

  AppThemeModel _getPresetTheme(String themeName) {
    switch (themeName) {
      case 'darkBlue':
        return AppThemeModel.darkBlue;
      case 'blue_black':
        return const AppThemeModel(
          name: 'Blue & Black',
          primaryColor: Colors.blue,
          secondaryColor: Color(0xFF42a5f5),
          backgroundColor: Colors.black,
          surfaceColor: Color(0xFF1a1a1a),
          cardColor: Color(0xFF2D2D2D),
          textColor: Colors.white,
          subtitleColor: Color(0xFFB0B0B0),
          dividerColor: Color(0xFF404040),
          appBarColor: Colors.blue,
          bottomNavColor: Color(0xFF1a1a1a),
          successColor: Colors.green,
          errorColor: Colors.red,
          warningColor: Colors.orange,
          infoColor: Colors.blue,
          positiveColor: Colors.green,
          negativeColor: Colors.red,
          shadowColor: Colors.black,
          borderColor: Color(0xFF404040),
          accentColor: Color(0xFFf39c12),
          highlightColor: Color(0xFF3F51B5),
          disabledColor: Color(0xFF616161),
          iconColor: Colors.white,
          buttonColor: Colors.blue,
          chipColor: Color(0xFF3F51B5),
          tabBarColor: Color(0xFF1a1a1a),
          modalColor: Color(0xFF2D2D2D),
          overlayColor: Color(0x80000000),
          gradientStartColor: Color(0xFF1a1a2e),
          gradientEndColor: Color(0xFF0f1419),
          isDark: true,
        );
      case 'game':
        return const AppThemeModel(
          name: 'Business Empire',
          primaryColor: Color(0xFFf39c12),
          secondaryColor: Color(0xFF7209b7),
          backgroundColor: Color(0xFF0f1419),
          surfaceColor: Color(0xFF1a1a2e),
          cardColor: Color(0xFF1a1a2e),
          textColor: Colors.white,
          subtitleColor: Color(0xFFB0B0B0),
          dividerColor: Color(0xFF404040),
          appBarColor: Color(0xFF1a1a2e),
          bottomNavColor: Color(0xFF1a1a2e),
          successColor: Color(0xFF27ae60),
          errorColor: Color(0xFFe74c3c),
          warningColor: Colors.orange,
          infoColor: Color(0xFF2196F3),
          positiveColor: Color(0xFF27ae60),
          negativeColor: Color(0xFFe74c3c),
          shadowColor: Colors.black,
          borderColor: Color(0xFF404040),
          accentColor: Color(0xFFf39c12),
          highlightColor: Color(0xFF3F51B5),
          disabledColor: Color(0xFF616161),
          iconColor: Colors.white,
          buttonColor: Color(0xFFf39c12),
          chipColor: Color(0xFF3F51B5),
          tabBarColor: Color(0xFF1a1a2e),
          modalColor: Color(0xFF2D2D2D),
          overlayColor: Color(0x80000000),
          gradientStartColor: Color(0xFF1a1a2e),
          gradientEndColor: Color(0xFF0f1419),
          isDark: true,
        );
      case 'light':
        return const AppThemeModel(
          name: 'Light',
          primaryColor: Colors.blue,
          secondaryColor: Color(0xFF42a5f5),
          backgroundColor: Colors.white,
          surfaceColor: Color(0xFFF5F5F5),
          cardColor: Colors.white,
          textColor: Colors.black,
          subtitleColor: Color(0xFF757575),
          dividerColor: Color(0xFFE0E0E0),
          appBarColor: Colors.blue,
          bottomNavColor: Colors.white,
          successColor: Colors.green,
          errorColor: Colors.red,
          warningColor: Colors.orange,
          infoColor: Colors.blue,
          positiveColor: Colors.green,
          negativeColor: Colors.red,
          shadowColor: Colors.black,
          borderColor: Color(0xFFE0E0E0),
          accentColor: Color(0xFFf39c12),
          highlightColor: Color(0xFF3F51B5),
          disabledColor: Color(0xFF9E9E9E),
          iconColor: Colors.black,
          buttonColor: Colors.blue,
          chipColor: Color(0xFF3F51B5),
          tabBarColor: Colors.white,
          modalColor: Colors.white,
          overlayColor: Color(0x80000000),
          gradientStartColor: Color(0xFFE3F2FD),
          gradientEndColor: Color(0xFFBBDEFB),
          isDark: false,
        );
      case 'green':
        return const AppThemeModel(
          name: 'Trading Green',
          primaryColor: Colors.green,
          secondaryColor: Color(0xFF66BB6A),
          backgroundColor: Color(0xFF0d1117),
          surfaceColor: Color(0xFF1a1a1a),
          cardColor: Color(0xFF2D2D2D),
          textColor: Colors.white,
          subtitleColor: Color(0xFFB0B0B0),
          dividerColor: Color(0xFF404040),
          appBarColor: Colors.green,
          bottomNavColor: Color(0xFF1a1a1a),
          successColor: Colors.green,
          errorColor: Colors.red,
          warningColor: Colors.orange,
          infoColor: Colors.blue,
          positiveColor: Colors.green,
          negativeColor: Colors.red,
          shadowColor: Colors.black,
          borderColor: Color(0xFF404040),
          accentColor: Color(0xFFf39c12),
          highlightColor: Color(0xFF3F51B5),
          disabledColor: Color(0xFF616161),
          iconColor: Colors.white,
          buttonColor: Colors.green,
          chipColor: Color(0xFF3F51B5),
          tabBarColor: Color(0xFF1a1a1a),
          modalColor: Color(0xFF2D2D2D),
          overlayColor: Color(0x80000000),
          gradientStartColor: Color(0xFF1a1a2e),
          gradientEndColor: Color(0xFF0f1419),
          isDark: true,
        );
      case 'blue':
        return const AppThemeModel(
          name: 'Ocean Blue',
          primaryColor: Colors.indigo,
          secondaryColor: Color(0xFF5C6BC0),
          backgroundColor: Color(0xFF0d1117),
          surfaceColor: Color(0xFF1a1a1a),
          cardColor: Color(0xFF2D2D2D),
          textColor: Colors.white,
          subtitleColor: Color(0xFFB0B0B0),
          dividerColor: Color(0xFF404040),
          appBarColor: Colors.indigo,
          bottomNavColor: Color(0xFF1a1a1a),
          successColor: Colors.green,
          errorColor: Colors.red,
          warningColor: Colors.orange,
          infoColor: Colors.blue,
          positiveColor: Colors.green,
          negativeColor: Colors.red,
          shadowColor: Colors.black,
          borderColor: Color(0xFF404040),
          accentColor: Color(0xFFf39c12),
          highlightColor: Color(0xFF3F51B5),
          disabledColor: Color(0xFF616161),
          iconColor: Colors.white,
          buttonColor: Colors.indigo,
          chipColor: Color(0xFF3F51B5),
          tabBarColor: Color(0xFF1a1a1a),
          modalColor: Color(0xFF2D2D2D),
          overlayColor: Color(0x80000000),
          gradientStartColor: Color(0xFF1a1a2e),
          gradientEndColor: Color(0xFF0f1419),
          isDark: true,
        );
      case 'dark':
        return const AppThemeModel(
          name: 'Dark Blue',
          primaryColor: Color(0xFF1565c0),
          secondaryColor: Color(0xFF42a5f5),
          backgroundColor: Color(0xFF0a0a0a),
          surfaceColor: Color(0xFF1a1a1a),
          cardColor: Color(0xFF1a1a1a),
          textColor: Colors.white,
          subtitleColor: Color(0xFFB0B0B0),
          dividerColor: Color(0xFF404040),
          appBarColor: Color(0xFF1a1a1a),
          bottomNavColor: Color(0xFF1a1a1a),
          successColor: Color(0xFF27ae60),
          errorColor: Color(0xFFe74c3c),
          warningColor: Colors.orange,
          infoColor: Color(0xFF2196F3),
          positiveColor: Color(0xFF27ae60),
          negativeColor: Color(0xFFe74c3c),
          shadowColor: Colors.black,
          borderColor: Color(0xFF404040),
          accentColor: Color(0xFFf39c12),
          highlightColor: Color(0xFF3F51B5),
          disabledColor: Color(0xFF616161),
          iconColor: Colors.white,
          buttonColor: Color(0xFF1565c0),
          chipColor: Color(0xFF3F51B5),
          tabBarColor: Color(0xFF1a1a1a),
          modalColor: Color(0xFF2D2D2D),
          overlayColor: Color(0x80000000),
          gradientStartColor: Color(0xFF1a1a2e),
          gradientEndColor: Color(0xFF0f1419),
          isDark: true,
        );
      default:
        return AppThemeModel.darkBlue;
    }
  }

  // Color control methods for easy customization
  Future<void> updatePrimaryColor(Color color) async {
    final updatedTheme = _currentTheme.copyWith(primaryColor: color);
    await setCustomTheme(updatedTheme);
  }

  Future<void> updateBackgroundColor(Color color) async {
    final updatedTheme = _currentTheme.copyWith(backgroundColor: color);
    await setCustomTheme(updatedTheme);
  }

  Future<void> updateTextColor(Color color) async {
    final updatedTheme = _currentTheme.copyWith(textColor: color);
    await setCustomTheme(updatedTheme);
  }

  Future<void> updateCardColor(Color color) async {
    final updatedTheme = _currentTheme.copyWith(cardColor: color);
    await setCustomTheme(updatedTheme);
  }

  Future<void> updateAccentColor(Color color) async {
    final updatedTheme = _currentTheme.copyWith(accentColor: color);
    await setCustomTheme(updatedTheme);
  }

  Future<void> updateSuccessColor(Color color) async {
    final updatedTheme = _currentTheme.copyWith(successColor: color);
    await setCustomTheme(updatedTheme);
  }

  Future<void> updateErrorColor(Color color) async {
    final updatedTheme = _currentTheme.copyWith(errorColor: color);
    await setCustomTheme(updatedTheme);
  }

  Future<void> updateWarningColor(Color color) async {
    final updatedTheme = _currentTheme.copyWith(warningColor: color);
    await setCustomTheme(updatedTheme);
  }

  Future<void> updateMultipleColors(Map<String, Color> colors) async {
    AppThemeModel updatedTheme = _currentTheme;
    
    colors.forEach((key, color) {
      switch (key) {
        case 'primary':
          updatedTheme = updatedTheme.copyWith(primaryColor: color);
          break;
        case 'secondary':
          updatedTheme = updatedTheme.copyWith(secondaryColor: color);
          break;
        case 'background':
          updatedTheme = updatedTheme.copyWith(backgroundColor: color);
          break;
        case 'surface':
          updatedTheme = updatedTheme.copyWith(surfaceColor: color);
          break;
        case 'card':
          updatedTheme = updatedTheme.copyWith(cardColor: color);
          break;
        case 'text':
          updatedTheme = updatedTheme.copyWith(textColor: color);
          break;
        case 'subtitle':
          updatedTheme = updatedTheme.copyWith(subtitleColor: color);
          break;
        case 'accent':
          updatedTheme = updatedTheme.copyWith(accentColor: color);
          break;
        case 'success':
          updatedTheme = updatedTheme.copyWith(successColor: color);
          break;
        case 'error':
          updatedTheme = updatedTheme.copyWith(errorColor: color);
          break;
        case 'warning':
          updatedTheme = updatedTheme.copyWith(warningColor: color);
          break;
        case 'positive':
          updatedTheme = updatedTheme.copyWith(positiveColor: color);
          break;
        case 'negative':
          updatedTheme = updatedTheme.copyWith(negativeColor: color);
          break;
        case 'button':
          updatedTheme = updatedTheme.copyWith(buttonColor: color);
          break;
        case 'icon':
          updatedTheme = updatedTheme.copyWith(iconColor: color);
          break;
        case 'appBar':
          updatedTheme = updatedTheme.copyWith(appBarColor: color);
          break;
        case 'bottomNav':
          updatedTheme = updatedTheme.copyWith(bottomNavColor: color);
          break;
        case 'modal':
          updatedTheme = updatedTheme.copyWith(modalColor: color);
          break;
        case 'chip':
          updatedTheme = updatedTheme.copyWith(chipColor: color);
          break;
        case 'divider':
          updatedTheme = updatedTheme.copyWith(dividerColor: color);
          break;
        case 'border':
          updatedTheme = updatedTheme.copyWith(borderColor: color);
          break;
        case 'highlight':
          updatedTheme = updatedTheme.copyWith(highlightColor: color);
          break;
        case 'disabled':
          updatedTheme = updatedTheme.copyWith(disabledColor: color);
          break;
        case 'shadow':
          updatedTheme = updatedTheme.copyWith(shadowColor: color);
          break;
        case 'overlay':
          updatedTheme = updatedTheme.copyWith(overlayColor: color);
          break;
        case 'gradientStart':
          updatedTheme = updatedTheme.copyWith(gradientStartColor: color);
          break;
        case 'gradientEnd':
          updatedTheme = updatedTheme.copyWith(gradientEndColor: color);
          break;
      }
    });
    
    await setCustomTheme(updatedTheme);
  }

  // Get available theme colors for customization
  Map<String, Color> getThemeColors() {
    return {
      'primary': _currentTheme.primaryColor,
      'secondary': _currentTheme.secondaryColor,
      'background': _currentTheme.backgroundColor,
      'surface': _currentTheme.surfaceColor,
      'card': _currentTheme.cardColor,
      'text': _currentTheme.textColor,
      'subtitle': _currentTheme.subtitleColor,
      'accent': _currentTheme.accentColor,
      'success': _currentTheme.successColor,
      'error': _currentTheme.errorColor,
      'warning': _currentTheme.warningColor,
      'positive': _currentTheme.positiveColor,
      'negative': _currentTheme.negativeColor,
      'button': _currentTheme.buttonColor,
      'icon': _currentTheme.iconColor,
      'appBar': _currentTheme.appBarColor,
      'bottomNav': _currentTheme.bottomNavColor,
      'modal': _currentTheme.modalColor,
      'chip': _currentTheme.chipColor,
      'divider': _currentTheme.dividerColor,
      'border': _currentTheme.borderColor,
      'highlight': _currentTheme.highlightColor,
      'disabled': _currentTheme.disabledColor,
      'shadow': _currentTheme.shadowColor,
      'overlay': _currentTheme.overlayColor,
      'gradientStart': _currentTheme.gradientStartColor,
      'gradientEnd': _currentTheme.gradientEndColor,
    };
  }

  static const List<Map<String, dynamic>> themes = [
    {
      'name': 'Dark Blue (Default)',
      'value': 'darkBlue',
      'icon': Icons.palette,
      'color': Color(0xFF2196F3),
    },
    {
      'name': 'Blue & Black',
      'value': 'blue_black',
      'icon': Icons.dark_mode,
      'color': Colors.blue,
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
      'name': 'Dark Mode',
      'value': 'dark',
      'icon': Icons.brightness_3,
      'color': Color(0xFF1565c0),
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