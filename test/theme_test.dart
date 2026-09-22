import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:blastix_esports/core/theme/app_colors.dart';
import 'package:blastix_esports/core/theme/app_theme.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Blastix Theme & AppColors Tokens Test', () {
    test('Verify Base Color Tokens', () {
      expect(AppColors.bgBlack, equals(const Color(0xFF000000)));
      expect(AppColors.bgDeep, equals(const Color(0xFF02080D)));
      expect(AppColors.bgNavy, equals(const Color(0xFF061A2B)));
      expect(AppColors.surfaceNavy, equals(const Color(0xFF0B2235)));
      expect(AppColors.surfaceElevated, equals(const Color(0xFF122E43)));

      expect(AppColors.background, equals(AppColors.bgNavy));
      expect(AppColors.surface, equals(AppColors.surfaceElevated));
    });

    test('Verify Border Tokens', () {
      expect(AppColors.borderSubtle, equals(const Color(0xFF1E2E3C)));
      expect(AppColors.borderCyan, equals(const Color(0x1F0FFCBE)));
    });

    test('Verify Accent Color Tokens', () {
      expect(AppColors.primaryNeon, equals(const Color(0xFF0FFCBE)));
      expect(AppColors.primaryDark, equals(const Color(0xFF0AB085)));
      expect(AppColors.primaryDeep, equals(const Color(0xFF087E5F)));
      expect(AppColors.glowSoft, equals(const Color(0xFF57FDD2)));
      expect(AppColors.glowLight, equals(const Color(0xFFB7FEEC)));

      expect(AppColors.primary, equals(AppColors.primaryNeon));
      expect(AppColors.secondary, equals(AppColors.primaryDeep));
    });

    test('Verify Text Color Tokens', () {
      expect(AppColors.textPrimary, equals(const Color(0xFFF4F7F8)));
      expect(AppColors.textSecondary, equals(const Color(0xFFB4BABF)));
    });

    test('Verify Gradients', () {
      expect(
        AppColors.blastixCoreGradient.colors,
        containsAllInOrder([AppColors.bgNavy, AppColors.primaryNeon]),
      );
      expect(
        AppColors.cyanIceGradient.colors,
        containsAllInOrder([AppColors.primaryNeon, const Color(0xFFCFFEF2)]),
      );
      expect(
        AppColors.auroraGradient.colors,
        containsAllInOrder([AppColors.bgNavy, AppColors.primaryDark]),
      );
    });

    test('Verify ThemeData Dark Theme wiring', () {
      final theme = AppTheme.dark;
      expect(theme.brightness, equals(Brightness.dark));
      expect(theme.scaffoldBackgroundColor, equals(AppColors.bgNavy));
      expect(theme.primaryColor, equals(AppColors.primaryNeon));
      expect(theme.colorScheme.primary, equals(AppColors.primaryNeon));
      expect(theme.colorScheme.secondary, equals(AppColors.primaryDeep));
      expect(theme.colorScheme.surface, equals(AppColors.surfaceElevated));
    });
  });
}
