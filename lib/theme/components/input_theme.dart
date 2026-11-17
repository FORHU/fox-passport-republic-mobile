import 'package:flutter/material.dart';
import 'package:flutter_template/theme/tokens/colors.dart';
import 'package:flutter_template/theme/tokens/radius.dart';
import 'package:flutter_template/theme/tokens/typography.dart';

/// `surface` fill, 1px `inputBorder` (3:1 or better against the fill), radius
/// 16, focused border lime 2px, error border `error`, a disabled field on the
/// quiet `border`, placeholder in `textMuted`.
class AppInputTheme {
  AppInputTheme._();

  static OutlineInputBorder _border(Color color, [double width = 1]) =>
      OutlineInputBorder(
        borderRadius: AppRadius.brMd,
        borderSide: BorderSide(color: color, width: width),
      );

  static InputDecorationTheme get inputDecoration => InputDecorationTheme(
        fillColor: AppColors.surface,
        filled: true,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        border: _border(AppColors.inputBorder),
        enabledBorder: _border(AppColors.inputBorder),
        disabledBorder: _border(AppColors.border),
        focusedBorder: _border(AppColors.accent, 2),
        errorBorder: _border(AppColors.error),
        focusedErrorBorder: _border(AppColors.error, 2),
        hintStyle: AppTypography.body(size: 15, color: AppColors.textMuted),
        errorStyle: AppTypography.body(size: 12, color: AppColors.error),
        prefixIconColor: AppColors.textMuted,
        suffixIconColor: AppColors.textMuted,
      );
}
