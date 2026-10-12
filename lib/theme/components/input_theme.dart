import 'package:flutter/material.dart';
import 'package:flutter_template/theme/tokens/colors.dart';

class AppInputTheme {
  AppInputTheme._();

  static InputDecorationTheme get inputDecoration => InputDecorationTheme(
        fillColor: AppColors.ui.surfaceMuted,
        filled: true,
        contentPadding: const EdgeInsets.all(16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: BorderSide(
            color: AppColors.ink.primary,
            width: 2,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: BorderSide(
            color: AppColors.status.error,
            width: 2,
          ),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: BorderSide(
            color: AppColors.status.error,
            width: 2,
          ),
        ),
        hintStyle: TextStyle(
          color: AppColors.text.tertiary,
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
      );
}
