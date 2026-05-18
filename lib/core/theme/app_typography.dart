import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

class AppTypography {
  AppTypography._();

  // Primary Journal Headers (Playfair Display - Serif)
  static TextStyle journalTitle({required bool isDark}) {
    return GoogleFonts.playfairDisplay(
      fontSize: 28,
      fontWeight: FontWeight.bold,
      color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
    );
  }

  static TextStyle journalSubTitle({required bool isDark}) {
    return GoogleFonts.playfairDisplay(
      fontSize: 20,
      fontWeight: FontWeight.w600,
      color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
    );
  }

  // Body Texts (Nunito - Highly Readable sans-serif)
  static TextStyle bodyNormal({required bool isDark}) {
    return GoogleFonts.nunito(
      fontSize: 16,
      fontWeight: FontWeight.normal,
      color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
    );
  }

  static TextStyle bodyMedium({required bool isDark}) {
    return GoogleFonts.nunito(
      fontSize: 16,
      fontWeight: FontWeight.w600,
      color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
    );
  }

  static TextStyle bodySmall({required bool isDark}) {
    return GoogleFonts.nunito(
      fontSize: 14,
      fontWeight: FontWeight.normal,
      color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
    );
  }

  // Handwriting / Prompts Accents (Caveat - Handwriting style)
  static TextStyle handWritten({required bool isDark, double fontSize = 22}) {
    return GoogleFonts.caveat(
      fontSize: fontSize,
      fontWeight: FontWeight.w500,
      color: isDark ? AppColors.tulipPinkLight : AppColors.tulipPinkDark,
    );
  }

  // Action / Button Texts
  static TextStyle buttonText({required bool isDark}) {
    return GoogleFonts.nunito(
      fontSize: 16,
      fontWeight: FontWeight.bold,
      letterSpacing: 0.5,
      color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
    );
  }
}
