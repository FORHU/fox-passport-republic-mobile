import 'package:flutter/material.dart';
import 'package:flutter_template/theme/components/button_theme.dart';
import 'package:flutter_template/theme/components/card_theme.dart';
import 'package:flutter_template/theme/components/input_theme.dart';
import 'package:flutter_template/theme/tokens/colors.dart';
import 'package:flutter_template/theme/tokens/typography.dart';

class LightTheme {
  LightTheme._();

  static ThemeData build() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,

      /// Ink-on-white color scheme (mapanytime-app style).
      /// Single accent: ink (#0D0D0F), clean surfaces, subtle text hierarchy.
      colorScheme: ColorScheme.light(
        primary: AppColors.ink.primary,
        onPrimary: AppColors.text.onInk,
        secondary: AppColors.ink.primary,
        onSecondary: AppColors.text.onInk,
        surface: AppColors.ui.surface,
        onSurface: AppColors.text.primary,
        onSurfaceVariant: AppColors.text.secondary,
        surfaceContainerHighest: AppColors.ui.surfaceMuted,
        outline: AppColors.ui.borderHairline,
        error: AppColors.status.error,
        onError: AppColors.text.onInk,
      ),

      scaffoldBackgroundColor: AppColors.ui.background,

      // Global Typography — Inter font with primary text color
      textTheme: AppTypography.textTheme.apply(
        bodyColor: AppColors.text.primary,
        displayColor: AppColors.text.primary,
      ),

      // AppBar — light background, ink text
      appBarTheme: AppBarTheme(
        centerTitle: true,
        backgroundColor: AppColors.ui.background,
        elevation: 0,
        iconTheme: IconThemeData(color: AppColors.text.primary),
        titleTextStyle: AppTypography.textTheme.titleLarge?.copyWith(
          color: AppColors.text.primary,
        ),
      ),

      // Components
      elevatedButtonTheme: AppButtonTheme.elevated,
      inputDecorationTheme: AppInputTheme.inputDecoration,
      cardTheme: AppCardTheme.cardTheme,
    );
  }
}
