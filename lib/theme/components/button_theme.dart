import 'package:flutter/material.dart';
import 'package:flutter_template/theme/tokens/colors.dart';
import 'package:flutter_template/theme/tokens/radius.dart';
import 'package:flutter_template/theme/tokens/spacing.dart';
import 'package:flutter_template/theme/tokens/typography.dart';

class AppButtonTheme {
  AppButtonTheme._();

  static ElevatedButtonThemeData get elevated => ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.ink.primary,
          foregroundColor: AppColors.text.onInk,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: 16, // 24px button height (16 + 8 * 2)
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.pill),
          ),
          elevation: 0,
          // Dark pill button styling
          textStyle: AppTypography.textTheme.labelLarge?.copyWith(
            color: AppColors.text.onInk,
          ),
        ),
      );
}
