import 'package:flutter/material.dart';

// ─── Theme extension for app-specific surface / text colors ──────────────────
//
// Access via:  context.tc.surface  (BuildContext extension below)

class AppThemeColors extends ThemeExtension<AppThemeColors> {
  final Color background;      // scaffold / page background
  final Color surface;         // card / panel background
  final Color surfaceElevated; // nested card (slightly lighter/darker)
  final Color inputFill;       // text field fill
  final Color textPrimary;     // main body text
  final Color textSecondary;   // sub-labels
  final Color textTertiary;    // hints / placeholders
  final Color border;          // dividers / outlines
  final Color primaryLight;    // selected / highlight tint

  const AppThemeColors({
    required this.background,
    required this.surface,
    required this.surfaceElevated,
    required this.inputFill,
    required this.textPrimary,
    required this.textSecondary,
    required this.textTertiary,
    required this.border,
    required this.primaryLight,
  });

  // ─── Light palette ──────────────────────────────────────────────────────────

  static const light = AppThemeColors(
    background: Color(0xFFF2F2F7),
    surface: Color(0xFFFFFFFF),
    surfaceElevated: Color(0xFFFFFFFF),
    inputFill: Color(0xFFF2F2F7),
    textPrimary: Color(0xFF1C1C1E),
    textSecondary: Color(0xFF6B7280),
    textTertiary: Color(0xFF8E8E93),
    border: Color(0xFFE5E7EB),
    primaryLight: Color(0xFFF0F5FF),
  );

  // ─── Dark palette ───────────────────────────────────────────────────────────

  static const dark = AppThemeColors(
    background: Color(0xFF0D0D14),
    surface: Color(0xFF1A1A26),
    surfaceElevated: Color(0xFF242434),
    inputFill: Color(0xFF141420),
    textPrimary: Color(0xFFF2F2F7),
    textSecondary: Color(0xFF9EA8B2),
    textTertiary: Color(0xFF636D77),
    border: Color(0xFF2A2A3C),
    primaryLight: Color(0xFF182040),
  );

  // ─── ThemeExtension overrides ───────────────────────────────────────────────

  @override
  AppThemeColors copyWith({
    Color? background,
    Color? surface,
    Color? surfaceElevated,
    Color? inputFill,
    Color? textPrimary,
    Color? textSecondary,
    Color? textTertiary,
    Color? border,
    Color? primaryLight,
  }) =>
      AppThemeColors(
        background: background ?? this.background,
        surface: surface ?? this.surface,
        surfaceElevated: surfaceElevated ?? this.surfaceElevated,
        inputFill: inputFill ?? this.inputFill,
        textPrimary: textPrimary ?? this.textPrimary,
        textSecondary: textSecondary ?? this.textSecondary,
        textTertiary: textTertiary ?? this.textTertiary,
        border: border ?? this.border,
        primaryLight: primaryLight ?? this.primaryLight,
      );

  @override
  AppThemeColors lerp(AppThemeColors other, double t) => AppThemeColors(
        background: Color.lerp(background, other.background, t)!,
        surface: Color.lerp(surface, other.surface, t)!,
        surfaceElevated: Color.lerp(surfaceElevated, other.surfaceElevated, t)!,
        inputFill: Color.lerp(inputFill, other.inputFill, t)!,
        textPrimary: Color.lerp(textPrimary, other.textPrimary, t)!,
        textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
        textTertiary: Color.lerp(textTertiary, other.textTertiary, t)!,
        border: Color.lerp(border, other.border, t)!,
        primaryLight: Color.lerp(primaryLight, other.primaryLight, t)!,
      );
}

// ─── BuildContext shortcut ────────────────────────────────────────────────────

extension AppThemeColorsExt on BuildContext {
  /// Shorthand: `context.tc.surface`, `context.tc.textPrimary`, …
  AppThemeColors get tc =>
      Theme.of(this).extension<AppThemeColors>() ?? AppThemeColors.light;
}
