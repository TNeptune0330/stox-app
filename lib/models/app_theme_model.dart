import 'package:flutter/material.dart';

class AppThemeModel {
  final String name;
  final Color primaryColor;
  final Color secondaryColor;
  final Color backgroundColor;
  final Color surfaceColor;
  final Color cardColor;
  final Color textColor;
  final Color subtitleColor;
  final Color dividerColor;
  final Color appBarColor;
  final Color bottomNavColor;
  final Color successColor;
  final Color errorColor;
  final Color warningColor;
  final Color infoColor;
  final Color positiveColor;
  final Color negativeColor;
  final Color shadowColor;
  final Color borderColor;
  final Color accentColor;
  final Color highlightColor;
  final Color disabledColor;
  final Color iconColor;
  final Color buttonColor;
  final Color chipColor;
  final Color tabBarColor;
  final Color modalColor;
  final Color overlayColor;
  final Color gradientStartColor;
  final Color gradientEndColor;
  final bool isDark;

  const AppThemeModel({
    required this.name,
    required this.primaryColor,
    required this.secondaryColor,
    required this.backgroundColor,
    required this.surfaceColor,
    required this.cardColor,
    required this.textColor,
    required this.subtitleColor,
    required this.dividerColor,
    required this.appBarColor,
    required this.bottomNavColor,
    required this.successColor,
    required this.errorColor,
    required this.warningColor,
    required this.infoColor,
    required this.positiveColor,
    required this.negativeColor,
    required this.shadowColor,
    required this.borderColor,
    required this.accentColor,
    required this.highlightColor,
    required this.disabledColor,
    required this.iconColor,
    required this.buttonColor,
    required this.chipColor,
    required this.tabBarColor,
    required this.modalColor,
    required this.overlayColor,
    required this.gradientStartColor,
    required this.gradientEndColor,
    required this.isDark,
  });

  ThemeData toThemeData() {
    return ThemeData(
      brightness: isDark ? Brightness.dark : Brightness.light,
      primarySwatch: MaterialColor(primaryColor.value, {
        50: primaryColor.withOpacity(0.1),
        100: primaryColor.withOpacity(0.2),
        200: primaryColor.withOpacity(0.3),
        300: primaryColor.withOpacity(0.4),
        400: primaryColor.withOpacity(0.5),
        500: primaryColor,
        600: primaryColor.withOpacity(0.7),
        700: primaryColor.withOpacity(0.8),
        800: primaryColor.withOpacity(0.9),
        900: primaryColor.withOpacity(1.0),
      }),
      primaryColor: primaryColor,
      scaffoldBackgroundColor: backgroundColor,
      cardColor: cardColor,
      dividerColor: dividerColor,
      shadowColor: shadowColor,
      highlightColor: highlightColor,
      disabledColor: disabledColor,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryColor,
        brightness: isDark ? Brightness.dark : Brightness.light,
        primary: primaryColor,
        secondary: secondaryColor,
        surface: surfaceColor,
        background: backgroundColor,
        error: errorColor,
        onPrimary: isDark ? Colors.white : Colors.black,
        onSecondary: isDark ? Colors.white : Colors.black,
        onSurface: textColor,
        onBackground: textColor,
        onError: Colors.white,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: appBarColor,
        foregroundColor: textColor,
        elevation: 0,
        iconTheme: IconThemeData(color: iconColor),
        titleTextStyle: TextStyle(
          color: textColor,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: bottomNavColor,
        selectedItemColor: primaryColor,
        unselectedItemColor: subtitleColor,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      ),
      textTheme: TextTheme(
        displayLarge: TextStyle(color: textColor),
        displayMedium: TextStyle(color: textColor),
        displaySmall: TextStyle(color: textColor),
        headlineLarge: TextStyle(color: textColor),
        headlineMedium: TextStyle(color: textColor),
        headlineSmall: TextStyle(color: textColor),
        titleLarge: TextStyle(color: textColor),
        titleMedium: TextStyle(color: textColor),
        titleSmall: TextStyle(color: textColor),
        bodyLarge: TextStyle(color: textColor),
        bodyMedium: TextStyle(color: textColor),
        bodySmall: TextStyle(color: subtitleColor),
        labelLarge: TextStyle(color: textColor),
        labelMedium: TextStyle(color: textColor),
        labelSmall: TextStyle(color: subtitleColor),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: buttonColor,
          foregroundColor: isDark ? Colors.white : Colors.black,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      cardTheme: CardThemeData(
        color: cardColor,
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: chipColor,
        labelStyle: TextStyle(color: textColor),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      tabBarTheme: TabBarThemeData(
        labelColor: primaryColor,
        unselectedLabelColor: subtitleColor,
        indicator: UnderlineTabIndicator(
          borderSide: BorderSide(color: primaryColor, width: 2),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: modalColor,
        titleTextStyle: TextStyle(color: textColor),
        contentTextStyle: TextStyle(color: textColor),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      iconTheme: IconThemeData(color: iconColor),
      dividerTheme: DividerThemeData(color: dividerColor),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'primaryColor': primaryColor.value,
      'secondaryColor': secondaryColor.value,
      'backgroundColor': backgroundColor.value,
      'surfaceColor': surfaceColor.value,
      'cardColor': cardColor.value,
      'textColor': textColor.value,
      'subtitleColor': subtitleColor.value,
      'dividerColor': dividerColor.value,
      'appBarColor': appBarColor.value,
      'bottomNavColor': bottomNavColor.value,
      'successColor': successColor.value,
      'errorColor': errorColor.value,
      'warningColor': warningColor.value,
      'infoColor': infoColor.value,
      'positiveColor': positiveColor.value,
      'negativeColor': negativeColor.value,
      'shadowColor': shadowColor.value,
      'borderColor': borderColor.value,
      'accentColor': accentColor.value,
      'highlightColor': highlightColor.value,
      'disabledColor': disabledColor.value,
      'iconColor': iconColor.value,
      'buttonColor': buttonColor.value,
      'chipColor': chipColor.value,
      'tabBarColor': tabBarColor.value,
      'modalColor': modalColor.value,
      'overlayColor': overlayColor.value,
      'gradientStartColor': gradientStartColor.value,
      'gradientEndColor': gradientEndColor.value,
      'isDark': isDark,
    };
  }

  factory AppThemeModel.fromJson(Map<String, dynamic> json) {
    return AppThemeModel(
      name: json['name'] ?? 'Custom',
      primaryColor: Color(json['primaryColor'] ?? 0xFF2196F3),
      secondaryColor: Color(json['secondaryColor'] ?? 0xFF03DAC6),
      backgroundColor: Color(json['backgroundColor'] ?? 0xFF000000),
      surfaceColor: Color(json['surfaceColor'] ?? 0xFF1E1E1E),
      cardColor: Color(json['cardColor'] ?? 0xFF2D2D2D),
      textColor: Color(json['textColor'] ?? 0xFFFFFFFF),
      subtitleColor: Color(json['subtitleColor'] ?? 0xFFB0B0B0),
      dividerColor: Color(json['dividerColor'] ?? 0xFF404040),
      appBarColor: Color(json['appBarColor'] ?? 0xFF1E1E1E),
      bottomNavColor: Color(json['bottomNavColor'] ?? 0xFF1E1E1E),
      successColor: Color(json['successColor'] ?? 0xFF4CAF50),
      errorColor: Color(json['errorColor'] ?? 0xFFf44336),
      warningColor: Color(json['warningColor'] ?? 0xFFFF9800),
      infoColor: Color(json['infoColor'] ?? 0xFF2196F3),
      positiveColor: Color(json['positiveColor'] ?? 0xFF4CAF50),
      negativeColor: Color(json['negativeColor'] ?? 0xFFf44336),
      shadowColor: Color(json['shadowColor'] ?? 0xFF000000),
      borderColor: Color(json['borderColor'] ?? 0xFF404040),
      accentColor: Color(json['accentColor'] ?? 0xFFFF4081),
      highlightColor: Color(json['highlightColor'] ?? 0xFF3F51B5),
      disabledColor: Color(json['disabledColor'] ?? 0xFF616161),
      iconColor: Color(json['iconColor'] ?? 0xFFFFFFFF),
      buttonColor: Color(json['buttonColor'] ?? 0xFF2196F3),
      chipColor: Color(json['chipColor'] ?? 0xFF3F51B5),
      tabBarColor: Color(json['tabBarColor'] ?? 0xFF1E1E1E),
      modalColor: Color(json['modalColor'] ?? 0xFF2D2D2D),
      overlayColor: Color(json['overlayColor'] ?? 0x80000000),
      gradientStartColor: Color(json['gradientStartColor'] ?? 0xFF1a1a2e),
      gradientEndColor: Color(json['gradientEndColor'] ?? 0xFF0f1419),
      isDark: json['isDark'] ?? true,
    );
  }

  AppThemeModel copyWith({
    String? name,
    Color? primaryColor,
    Color? secondaryColor,
    Color? backgroundColor,
    Color? surfaceColor,
    Color? cardColor,
    Color? textColor,
    Color? subtitleColor,
    Color? dividerColor,
    Color? appBarColor,
    Color? bottomNavColor,
    Color? successColor,
    Color? errorColor,
    Color? warningColor,
    Color? infoColor,
    Color? positiveColor,
    Color? negativeColor,
    Color? shadowColor,
    Color? borderColor,
    Color? accentColor,
    Color? highlightColor,
    Color? disabledColor,
    Color? iconColor,
    Color? buttonColor,
    Color? chipColor,
    Color? tabBarColor,
    Color? modalColor,
    Color? overlayColor,
    Color? gradientStartColor,
    Color? gradientEndColor,
    bool? isDark,
  }) {
    return AppThemeModel(
      name: name ?? this.name,
      primaryColor: primaryColor ?? this.primaryColor,
      secondaryColor: secondaryColor ?? this.secondaryColor,
      backgroundColor: backgroundColor ?? this.backgroundColor,
      surfaceColor: surfaceColor ?? this.surfaceColor,
      cardColor: cardColor ?? this.cardColor,
      textColor: textColor ?? this.textColor,
      subtitleColor: subtitleColor ?? this.subtitleColor,
      dividerColor: dividerColor ?? this.dividerColor,
      appBarColor: appBarColor ?? this.appBarColor,
      bottomNavColor: bottomNavColor ?? this.bottomNavColor,
      successColor: successColor ?? this.successColor,
      errorColor: errorColor ?? this.errorColor,
      warningColor: warningColor ?? this.warningColor,
      infoColor: infoColor ?? this.infoColor,
      positiveColor: positiveColor ?? this.positiveColor,
      negativeColor: negativeColor ?? this.negativeColor,
      shadowColor: shadowColor ?? this.shadowColor,
      borderColor: borderColor ?? this.borderColor,
      accentColor: accentColor ?? this.accentColor,
      highlightColor: highlightColor ?? this.highlightColor,
      disabledColor: disabledColor ?? this.disabledColor,
      iconColor: iconColor ?? this.iconColor,
      buttonColor: buttonColor ?? this.buttonColor,
      chipColor: chipColor ?? this.chipColor,
      tabBarColor: tabBarColor ?? this.tabBarColor,
      modalColor: modalColor ?? this.modalColor,
      overlayColor: overlayColor ?? this.overlayColor,
      gradientStartColor: gradientStartColor ?? this.gradientStartColor,
      gradientEndColor: gradientEndColor ?? this.gradientEndColor,
      isDark: isDark ?? this.isDark,
    );
  }

  // Predefined themes
  static const AppThemeModel darkBlue = AppThemeModel(
    name: 'Dark Blue',
    primaryColor: Color(0xFF2196F3),
    secondaryColor: Color(0xFF03DAC6),
    backgroundColor: Color(0xFF0f1419),
    surfaceColor: Color(0xFF1a1a2e),
    cardColor: Color(0xFF2D2D2D),
    textColor: Color(0xFFFFFFFF),
    subtitleColor: Color(0xFFB0B0B0),
    dividerColor: Color(0xFF404040),
    appBarColor: Color(0xFF1565c0),
    bottomNavColor: Color(0xFF1a1a2e),
    successColor: Color(0xFF4CAF50),
    errorColor: Color(0xFFf44336),
    warningColor: Color(0xFFFF9800),
    infoColor: Color(0xFF2196F3),
    positiveColor: Color(0xFF4CAF50),
    negativeColor: Color(0xFFf44336),
    shadowColor: Color(0xFF000000),
    borderColor: Color(0xFF404040),
    accentColor: Color(0xFFf39c12),
    highlightColor: Color(0xFF3F51B5),
    disabledColor: Color(0xFF616161),
    iconColor: Color(0xFFFFFFFF),
    buttonColor: Color(0xFF2196F3),
    chipColor: Color(0xFF3F51B5),
    tabBarColor: Color(0xFF1a1a2e),
    modalColor: Color(0xFF2D2D2D),
    overlayColor: Color(0x80000000),
    gradientStartColor: Color(0xFF1a1a2e),
    gradientEndColor: Color(0xFF0f1419),
    isDark: true,
  );
}