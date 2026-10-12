import 'package:flutter/material.dart';
import 'package:flutter_template/theme/components/button_theme.dart';
import 'package:flutter_template/theme/components/card_theme.dart';
import 'package:flutter_template/theme/components/input_theme.dart';
import 'package:flutter_template/theme/tokens/colors.dart';
import 'package:flutter_template/theme/tokens/radius.dart';
import 'package:flutter_template/theme/tokens/typography.dart';

/// The app's one theme: dark, lime-accented, matching the web app.
/// See `docs/mobile-design.md`. There is no light variant.
class AppTheme {
  AppTheme._();

  static ThemeData get dark => _build();

  static ThemeData _build() {
    final textTheme = AppTypography.textTheme.apply(
      bodyColor: AppColors.textPrimary,
      displayColor: AppColors.textPrimary,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.accent,
        onPrimary: AppColors.onAccent,
        secondary: AppColors.accent,
        onSecondary: AppColors.onAccent,
        surface: AppColors.surface,
        onSurface: AppColors.textPrimary,
        onSurfaceVariant: AppColors.textSecondary,
        surfaceContainerHighest: AppColors.surfaceRaised,
        outline: AppColors.borderStrong,
        outlineVariant: AppColors.border,
        error: AppColors.error,
        onError: AppColors.canvas,
        inverseSurface: AppColors.surfaceRaised,
        onInverseSurface: AppColors.textPrimary,
      ),
      scaffoldBackgroundColor: AppColors.canvas,
      canvasColor: AppColors.canvas,
      textTheme: textTheme,
      appBarTheme: AppBarTheme(
        centerTitle: true,
        backgroundColor: AppColors.canvas,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
        titleTextStyle: textTheme.titleLarge,
      ),
      elevatedButtonTheme: AppButtonTheme.elevated,
      outlinedButtonTheme: AppButtonTheme.outlined,
      textButtonTheme: AppButtonTheme.text,
      inputDecorationTheme: AppInputTheme.inputDecoration,
      cardTheme: AppCardTheme.cardTheme,
      dividerTheme: const DividerThemeData(
        color: AppColors.border,
        thickness: 1,
        space: 1,
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppColors.surfaceRaised,
        surfaceTintColor: Colors.transparent,
        showDragHandle: true,
        dragHandleColor: AppColors.borderStrong,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppRadius.xl),
          ),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.surfaceRaised,
        contentTextStyle: textTheme.bodyMedium,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.brMd,
          side: const BorderSide(color: AppColors.border),
        ),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.accent,
      ),
      textSelectionTheme: const TextSelectionThemeData(
        cursorColor: AppColors.accent,
        selectionHandleColor: AppColors.accent,
      ),
    );
  }
}
