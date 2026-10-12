import 'package:flutter/material.dart';
import 'package:flutter_template/theme/tokens/colors.dart';
import 'package:flutter_template/theme/tokens/radius.dart';

/// `surface` fill, 1px `border`, radius 16–20, no elevation.
class AppCardTheme {
  AppCardTheme._();

  static CardThemeData get cardTheme => CardThemeData(
        color: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.brCard,
          side: const BorderSide(color: AppColors.border),
        ),
        elevation: 0,
        margin: EdgeInsets.zero,
        clipBehavior: Clip.antiAlias,
      );
}
