import 'package:flutter/material.dart';
import 'package:flutter_template/theme/tokens/colors.dart';
import 'package:flutter_template/theme/tokens/radius.dart';
import 'package:flutter_template/theme/tokens/typography.dart';

/// Material button themes for `docs/mobile-design.md` §3: 52 tall, radius 16,
/// Space Grotesk 700, no shadow.
class AppButtonTheme {
  AppButtonTheme._();

  static const double height = 52;

  static final _shape = RoundedRectangleBorder(borderRadius: AppRadius.brMd);

  /// Primary: lime fill, `onAccent` text.
  static ElevatedButtonThemeData get elevated => ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.accent,
          foregroundColor: AppColors.onAccent,
          disabledBackgroundColor: AppColors.accent.withValues(alpha: 0.4),
          disabledForegroundColor: AppColors.onAccent.withValues(alpha: 0.6),
          minimumSize: const Size.fromHeight(height),
          shape: _shape,
          elevation: 0,
          shadowColor: Colors.transparent,
          textStyle: AppTypography.display(size: 15),
        ),
      );

  /// Secondary: transparent, 1px `borderStrong`, white text.
  static OutlinedButtonThemeData get outlined => OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.textPrimary,
          minimumSize: const Size.fromHeight(height),
          shape: _shape,
          side: const BorderSide(color: AppColors.borderStrong),
          textStyle: AppTypography.display(size: 14),
        ),
      );

  /// Text link: lime, bold, no underline.
  static TextButtonThemeData get text => TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.accent,
          textStyle: AppTypography.body(
            weight: FontWeight.w700,
          ),
        ),
      );
}
