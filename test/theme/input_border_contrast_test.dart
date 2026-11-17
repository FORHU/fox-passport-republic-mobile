import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_template/theme/components/input_theme.dart';
import 'package:flutter_template/theme/tokens/colors.dart';
import 'package:flutter_test/flutter_test.dart';

/// WCAG contrast ratio between two colours.
double _contrast(Color a, Color b) {
  double lum(Color c) {
    double ch(double v) => v <= 0.03928
        ? v / 12.92
        : math.pow((v + 0.055) / 1.055, 2.4).toDouble();
    return 0.2126 * ch(c.r) + 0.7152 * ch(c.g) + 0.0722 * ch(c.b);
  }

  final x = lum(a);
  final y = lum(b);
  return (math.max(x, y) + 0.05) / (math.min(x, y) + 0.05);
}

void main() {
  const minimum = 3.0; // WCAG 1.4.11, non-text contrast

  test('the field border can be told from the field and the page', () {
    expect(
      _contrast(AppColors.inputBorder, AppColors.surface),
      greaterThanOrEqualTo(minimum),
    );
    expect(
      _contrast(AppColors.inputBorder, AppColors.canvas),
      greaterThanOrEqualTo(minimum),
    );
  });

  test('the focused and error borders also stand out from the field', () {
    expect(
      _contrast(AppColors.accent, AppColors.surface),
      greaterThanOrEqualTo(minimum),
    );
    expect(
      _contrast(AppColors.error, AppColors.surface),
      greaterThanOrEqualTo(minimum),
    );
  });

  test('every field state is drawn with the right border', () {
    final theme = AppInputTheme.inputDecoration;
    Color colorOf(InputBorder? b) =>
        (b! as OutlineInputBorder).borderSide.color;

    expect(colorOf(theme.border), AppColors.inputBorder);
    expect(colorOf(theme.enabledBorder), AppColors.inputBorder);
    expect(colorOf(theme.focusedBorder), AppColors.accent);
    expect(colorOf(theme.errorBorder), AppColors.error);
    expect(colorOf(theme.focusedErrorBorder), AppColors.error);
    // A disabled field stays quiet, so it reads as not available.
    expect(colorOf(theme.disabledBorder), AppColors.border);
  });
}
