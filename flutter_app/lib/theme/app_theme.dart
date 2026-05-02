// lib/theme/app_theme.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// =====================================================
// Color Palette — "Midnight Bistro"
// =====================================================
class AppColors {
  static const Color bg         = Color(0xFF0D0D0D);
  static const Color surface    = Color(0xFF1A1A1A);
  static const Color surfaceAlt = Color(0xFF242424);
  static const Color card       = Color(0xFF1E1E1E);
  static const Color border     = Color(0xFF2E2E2E);

  static const Color gold       = Color(0xFFC9A84C);
  static const Color goldLight  = Color(0xFFE4C76B);
  static const Color goldDark   = Color(0xFF9E7B2A);

  static const Color cream      = Color(0xFFF5EDD8);
  static const Color creamDim   = Color(0xFFD4C4A0);

  static const Color textPrimary   = Color(0xFFF2EDE4);
  static const Color textSecondary = Color(0xFF9A8F7E);
  static const Color textHint      = Color(0xFF5C5448);

  static const Color success  = Color(0xFF4CAF82);
  static const Color warning  = Color(0xFFE6A817);
  static const Color error    = Color(0xFFE05252);
  static const Color info     = Color(0xFF5B9BD5);

  // ✅ สำคัญ: เพิ่มกลับมา
  static const Color indoor   = Color(0xFF5B9BD5);
  static const Color outdoor  = Color(0xFF4CAF82);
  static const Color vip      = Color(0xFFC9A84C);
  static const Color rooftop  = Color(0xFFE05252);
}

class AppTheme {
  static ThemeData get dark {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.bg,
      primaryColor: AppColors.gold,

      colorScheme: const ColorScheme.dark(
        primary: AppColors.gold,
        secondary: AppColors.goldLight,
        surface: AppColors.surface,
        error: AppColors.error,
        onPrimary: AppColors.bg,
        onSecondary: AppColors.bg,
        onSurface: AppColors.textPrimary,
      ),

      textTheme: GoogleFonts.kanitTextTheme(
        const TextTheme(
          displayLarge:  TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w700),
          displayMedium: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w700),
          headlineLarge: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w700),
          headlineMedium:TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600),
          titleLarge:    TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600),
          titleMedium:   TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w500),
          bodyLarge:     TextStyle(color: AppColors.textPrimary),
          bodyMedium:    TextStyle(color: AppColors.textSecondary),
          labelLarge:    TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600),
        ),
      ),

      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.bg,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: GoogleFonts.kanit(
          color: AppColors.textPrimary,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.gold,
          foregroundColor: AppColors.bg,
          minimumSize: const Size(double.infinity, 54),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: GoogleFonts.kanit(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
          elevation: 0,
        ),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surfaceAlt,
        hintStyle: GoogleFonts.kanit(color: AppColors.textHint),
        labelStyle: GoogleFonts.kanit(color: AppColors.textSecondary),

        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.border),
        ),

        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.border),
        ),

        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.gold, width: 1.5),
        ),

        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),

      cardTheme: const CardThemeData(
        color: AppColors.card,
        elevation: 0,
        margin: EdgeInsets.symmetric(vertical: 6, horizontal: 0),
      ),

      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.surface,
        selectedItemColor: AppColors.gold,
        unselectedItemColor: AppColors.textHint,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),
    );
  }
}

