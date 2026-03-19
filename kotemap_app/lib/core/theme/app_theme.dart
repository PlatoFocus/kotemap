import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants/app_colors.dart';
import 'app_theme_colors.dart';

class AppTheme {
  AppTheme._();

  // ─── Light ─────────────────────────────────────────────────────────────────

  static ThemeData get light {
    final base = ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primary,
        primary: AppColors.primary,
        surface: AppThemeColors.light.surface,
        brightness: Brightness.light,
      ),
      scaffoldBackgroundColor: AppThemeColors.light.background,
    );
    return base.copyWith(
      extensions: const [AppThemeColors.light],
      textTheme: GoogleFonts.interTextTheme(base.textTheme),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: AppThemeColors.light.surface,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppThemeColors.light.textTertiary,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppThemeColors.light.inputFill,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 10,
        ),
      ),
      cardTheme: CardThemeData(
        color: AppThemeColors.light.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(color: AppThemeColors.light.border),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: const Color(0xFFEEF2FF),
        selectedColor: AppColors.primary,
        labelStyle: const TextStyle(
          color: Color(0xFF3730A3),
          fontSize: 11,
          fontWeight: FontWeight.w500,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),
      dividerTheme: DividerThemeData(
        color: AppThemeColors.light.border,
        thickness: 1,
      ),
    );
  }

  // ─── Dark ──────────────────────────────────────────────────────────────────

  static ThemeData get dark {
    final base = ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primary,
        primary: AppColors.primary,
        surface: AppThemeColors.dark.surface,
        brightness: Brightness.dark,
      ),
      scaffoldBackgroundColor: AppThemeColors.dark.background,
    );
    return base.copyWith(
      extensions: const [AppThemeColors.dark],
      textTheme: GoogleFonts.interTextTheme(base.textTheme),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.primaryDark,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: AppThemeColors.dark.surface,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppThemeColors.dark.textTertiary,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppThemeColors.dark.inputFill,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        hintStyle: TextStyle(color: AppThemeColors.dark.textTertiary),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 10,
        ),
      ),
      cardTheme: CardThemeData(
        color: AppThemeColors.dark.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(color: AppThemeColors.dark.border),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: const Color(0xFF1A2040),
        selectedColor: AppColors.primary,
        labelStyle: const TextStyle(
          color: Color(0xFF93A3D4),
          fontSize: 11,
          fontWeight: FontWeight.w500,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),
      dividerTheme: DividerThemeData(
        color: AppThemeColors.dark.border,
        thickness: 1,
      ),
    );
  }
}
