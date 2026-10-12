import 'package:flutter/material.dart';
import 'package:flutter_template/theme/tokens/colors.dart';
import 'package:google_fonts/google_fonts.dart';

/// Design tokens — typography. Source of truth: `docs/mobile-design.md` §2.
///
/// | Role | Font |
/// |---|---|
/// | Display / titles / buttons | Space Grotesk 700 |
/// | Body | Plus Jakarta Sans 500 |
/// | Label | Space Mono 400, 11px, uppercase, 0.12em |
/// | Hero | Archivo 900, uppercase, −0.03em, line-height 0.95 |
///
/// Scale: hero 30–34 · title 20–24 · card title 16 · body 14 · caption 12 ·
/// label 11. Nothing below 11.
class AppTypography {
  AppTypography._();

  /// Plus Jakarta Sans body text with Space Grotesk titles, for `ThemeData`.
  static TextTheme get textTheme {
    final body = GoogleFonts.plusJakartaSansTextTheme(_base);
    TextStyle? display(TextStyle? s) => s == null
        ? null
        : GoogleFonts.spaceGrotesk(textStyle: s, fontWeight: FontWeight.w700);

    return body.copyWith(
      displaySmall: display(body.displaySmall),
      headlineLarge: display(body.headlineLarge),
      headlineMedium: display(body.headlineMedium),
      titleLarge: display(body.titleLarge),
      titleMedium: display(body.titleMedium),
      titleSmall: display(body.titleSmall),
      labelLarge: display(body.labelLarge),
    );
  }

  /// Archivo 900 uppercase headline. At most one per screen.
  static TextStyle hero({
    double size = 34,
    Color color = AppColors.textPrimary,
  }) =>
      GoogleFonts.archivo(
        fontSize: size,
        fontWeight: FontWeight.w900,
        height: 0.95,
        letterSpacing: -0.03 * size,
        color: color,
      );

  /// Space Mono 11px uppercase label: eyebrows, counters, meta. The caller is
  /// responsible for upper-casing the text it passes in.
  static TextStyle label({Color color = AppColors.textMuted}) =>
      GoogleFonts.spaceMono(
        fontSize: 11,
        fontWeight: FontWeight.w400,
        letterSpacing: 0.12 * 11,
        color: color,
      );

  /// Space Grotesk 700 — button labels and card titles.
  static TextStyle display({
    double size = 16,
    Color color = AppColors.textPrimary,
  }) =>
      GoogleFonts.spaceGrotesk(
        fontSize: size,
        fontWeight: FontWeight.w700,
        color: color,
      );

  /// Plus Jakarta Sans 500 body.
  static TextStyle body({
    double size = 14,
    Color color = AppColors.textSecondary,
    FontWeight weight = FontWeight.w500,
  }) =>
      GoogleFonts.plusJakartaSans(
        fontSize: size,
        fontWeight: weight,
        color: color,
      );

  static const TextTheme _base = TextTheme(
    displaySmall: TextStyle(
      fontSize: 34,
      fontWeight: FontWeight.w700,
      height: 1.1,
    ),
    headlineLarge: TextStyle(
      fontSize: 28,
      fontWeight: FontWeight.w700,
      height: 1.15,
    ),
    headlineMedium: TextStyle(
      fontSize: 24,
      fontWeight: FontWeight.w700,
      height: 1.2,
    ),
    titleLarge: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
    titleMedium: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
    titleSmall: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
    bodyLarge: TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.w500,
      height: 1.4,
    ),
    bodyMedium: TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.w500,
      height: 1.45,
    ),
    bodySmall: TextStyle(
      fontSize: 12,
      fontWeight: FontWeight.w500,
      height: 1.4,
    ),
    labelLarge: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
    labelMedium: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
    labelSmall: TextStyle(
      fontSize: 11,
      fontWeight: FontWeight.w500,
      letterSpacing: 0.3,
    ),
  );
}
