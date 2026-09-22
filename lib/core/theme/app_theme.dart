import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_text_styles.dart';

/// ============================================================
/// APP THEME
/// ============================================================
/// Wires AppColors + AppTextStyles into a single dark ThemeData
/// used across the whole app (Scaffold, AppBar, buttons, inputs,
/// cards). Apply via MaterialApp(theme: AppTheme.dark).
/// ============================================================

class AppTheme {
  AppTheme._();

  static ThemeData get dark {
    return ThemeData(
      brightness: Brightness.dark,
      useMaterial3: true,
      scaffoldBackgroundColor: AppColors.background,
      primaryColor: AppColors.primaryNeon,
      fontFamily: AppTextStyles.bodyMd.fontFamily,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.primaryNeon,
        secondary: AppColors.primaryDeep,
        surface: AppColors.surfaceElevated,
        error: AppColors.primaryDeep,
        onPrimary: AppColors.bgNavy,
        onSecondary: Colors.white,
        onSurface: AppColors.textPrimary,
        onError: Colors.white,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.background,
        elevation: 0,
        centerTitle: false,
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
        titleTextStyle: AppTextStyles.headingLg,
      ),
      textTheme: TextTheme(
        displayLarge: AppTextStyles.display,
        headlineMedium: AppTextStyles.headingXl,
        headlineSmall: AppTextStyles.headingLg,
        titleMedium: AppTextStyles.headingMd,
        bodyLarge: AppTextStyles.bodyLg,
        bodyMedium: AppTextStyles.bodyMd,
        bodySmall: AppTextStyles.bodySm,
        labelLarge: AppTextStyles.button,
      ),
      cardTheme: CardThemeData(
        color: AppColors.surfaceElevated,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: const BorderSide(color: AppColors.borderSubtle, width: 1),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryNeon,
          foregroundColor: AppColors.bgNavy,
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: AppTextStyles.button,
          elevation: 0,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primaryNeon,
          side: const BorderSide(color: AppColors.primaryNeon, width: 1.2),
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: AppTextStyles.button,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surfaceNavy,
        hintStyle: AppTextStyles.bodyMd,
        contentPadding:
        const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.borderSubtle),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.borderSubtle),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.primaryNeon, width: 1.4),
        ),
      ),
      dividerTheme:
      const DividerThemeData(color: AppColors.borderSubtle, thickness: 1),
      splashColor: AppColors.primaryNeon.withValues(alpha: 0.08),
      highlightColor: Colors.transparent,
    );
  }
}