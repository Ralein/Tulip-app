import 'package:flutter/material.dart';

class AppDimensions {
  AppDimensions._();

  // Spacing Tokens (Eighth-based / Soft Grid)
  static const double space4 = 4.0;
  static const double space8 = 8.0;
  static const double space12 = 12.0;
  static const double space16 = 16.0;
  static const double space24 = 24.0;
  static const double space32 = 32.0;
  static const double space40 = 40.0;
  static const double space48 = 48.0;
  static const double space64 = 64.0;

  // Border Radii Tokens
  static const double radius8 = 8.0;
  static const double radius12 = 12.0;
  static const double radius16 = 16.0;
  static const double radius24 = 24.0;
  static const double radius32 = 32.0;
  static const double radiusFull = 999.0;

  // Glassmorphic Shadows
  static List<BoxShadow> glassShadow({required bool isDark}) {
    return [
      BoxShadow(
        color: isDark ? Colors.black.withValues(alpha: 0.3) : Colors.black.withValues(alpha: 0.05),
        blurRadius: 20,
        spreadRadius: -5,
        offset: const Offset(0, 10),
      ),
      BoxShadow(
        color: isDark ? Colors.white.withValues(alpha: 0.02) : Colors.white.withValues(alpha: 0.2),
        blurRadius: 0,
        spreadRadius: 1,
        offset: const Offset(0, -1), // Top highlight
      ),
    ];
  }

  static List<BoxShadow> organicShadow = [
    BoxShadow(
      color: const Color(0x11E91E63),
      blurRadius: 15,
      spreadRadius: 0,
      offset: const Offset(0, 8),
    ),
  ];
}
