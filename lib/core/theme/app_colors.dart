import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // Base
  static const Color background = Color(0xFFFAFAF7);      // off-white
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceMuted = Color(0xFFF0F0EC);

  // Primary accent — Mint Green
  static const Color primary = Color(0xFF6FD7A0);
  static const Color primaryDark = Color(0xFF4FB37F);       // pressed states
  static const Color primaryLight = Color(0xFFA8E8C4);      // light bg/hover

  // Secondary accent — Periwinkle Blue
  static const Color secondary = Color(0xFF92A4FF);
  static const Color secondaryDark = Color(0xFF6E82E8);
  static const Color secondaryLight = Color(0xFFC5CFFF);

  // Text
  static const Color textPrimary = Color(0xFF25261F);
  static const Color textSecondary = Color(0xFF6B6B60);
  static const Color textMuted = Color(0xFFA0A096);

  // Status colors
  static const Color success = Color(0xFF4FB37F);
  static const Color error = Color(0xFFE5615C);
  static const Color warning = Color(0xFFF0B85A);

  // Gradient (buttons/highlights ke liye)
  static const List<Color> primaryGradient = [
    Color(0xFF6FD7A0),
    Color(0xFF92A4FF),
  ];
}