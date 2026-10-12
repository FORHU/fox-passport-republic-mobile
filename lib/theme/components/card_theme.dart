import 'package:flutter/material.dart';
import 'package:flutter_template/theme/tokens/colors.dart';
import 'package:flutter_template/theme/tokens/radius.dart';

class AppCardTheme {
  AppCardTheme._();

  static CardThemeData get cardTheme => CardThemeData(
        color: AppColors.ui.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.card),
        ),
        elevation: 1,
        clipBehavior: Clip.antiAlias,
      );
}
