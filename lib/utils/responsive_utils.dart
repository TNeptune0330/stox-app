import 'package:flutter/material.dart';
import 'dart:io';

class ResponsiveUtils {
  static bool isTablet(BuildContext context) {
    final data = MediaQuery.of(context);
    return data.size.shortestSide >= 600;
  }

  static bool isPhone(BuildContext context) {
    return !isTablet(context);
  }

  static bool isIPad() {
    return Platform.isIOS && Platform.environment.containsKey('SIMULATOR_DEVICE_NAME') 
        ? Platform.environment['SIMULATOR_DEVICE_NAME']!.contains('iPad')
        : false;
  }

  static double getScaleFactor(BuildContext context) {
    if (isTablet(context)) {
      return 1.3; // Scale up text and UI elements for tablets
    }
    return 1.0;
  }

  static double getFontSize(BuildContext context, double baseSize) {
    return baseSize * getScaleFactor(context);
  }

  static double getIconSize(BuildContext context, double baseSize) {
    return baseSize * getScaleFactor(context);
  }

  static EdgeInsets getPadding(BuildContext context, EdgeInsets basePadding) {
    final scale = getScaleFactor(context);
    return EdgeInsets.fromLTRB(
      basePadding.left * scale,
      basePadding.top * scale,
      basePadding.right * scale,
      basePadding.bottom * scale,
    );
  }

  static double getButtonHeight(BuildContext context) {
    return isTablet(context) ? 60.0 : 48.0;
  }

  static double getCardElevation(BuildContext context) {
    return isTablet(context) ? 8.0 : 4.0;
  }

  static BorderRadius getBorderRadius(BuildContext context, double baseRadius) {
    return BorderRadius.circular(baseRadius * getScaleFactor(context));
  }

  // Responsive text styles
  static TextStyle getHeadlineStyle(BuildContext context) {
    return TextStyle(
      fontSize: getFontSize(context, 32),
      fontWeight: FontWeight.bold,
    );
  }

  static TextStyle getTitleStyle(BuildContext context) {
    return TextStyle(
      fontSize: getFontSize(context, 20),
      fontWeight: FontWeight.w600,
    );
  }

  static TextStyle getBodyStyle(BuildContext context) {
    return TextStyle(
      fontSize: getFontSize(context, 16),
      fontWeight: FontWeight.normal,
    );
  }

  static TextStyle getCaptionStyle(BuildContext context) {
    return TextStyle(
      fontSize: getFontSize(context, 12),
      fontWeight: FontWeight.normal,
    );
  }

  // Layout helpers
  static double getMaxWidth(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    if (isTablet(context)) {
      return screenWidth * 0.8; // Use 80% of screen width on tablets
    }
    return screenWidth;
  }

  static EdgeInsets getScreenPadding(BuildContext context) {
    if (isTablet(context)) {
      return const EdgeInsets.symmetric(horizontal: 80, vertical: 40);
    }
    return const EdgeInsets.symmetric(horizontal: 24, vertical: 20);
  }

  // Navigation and layout constants
  static double getAppBarHeight(BuildContext context) {
    return isTablet(context) ? 80.0 : 56.0;
  }

  static double getBottomNavHeight(BuildContext context) {
    return isTablet(context) ? 80.0 : 60.0;
  }

  static double getCardSpacing(BuildContext context) {
    return isTablet(context) ? 24.0 : 16.0;
  }
}