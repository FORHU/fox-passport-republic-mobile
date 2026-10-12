import 'package:flutter/material.dart';
import 'package:flutter_template/theme/tokens/colors.dart';
import 'package:google_fonts/google_fonts.dart';

/// Onboarding's styling helpers. The shared colours now come from [AppColors]
/// (`docs/mobile-design.md` §2), so this file only adds what onboarding alone
/// uses. It is slated to go once onboarding reads `AppColors` / `AppTypography`
/// directly and drops its glows (the spec has none).
class OnboardingPalette {
  OnboardingPalette._();

  static const Color canvas = AppColors.canvas;
  static const Color surface = AppColors.surface;
  static const Color surfaceRaised = AppColors.surfaceRaised;
  static const Color accent = AppColors.accent;
  static const Color accentHover = AppColors.accentPressed;
  static const Color intent = Color(0xFFA78BFA);
  static const Color roles = Color(0xFFEC4899);
  static const Color foxer = AppColors.roleLabel;

  static const Color success = AppColors.success;
  static const Color warning = AppColors.warning;
  static const Color orange = Color(0xFFFB923C);

  /// Tailwind's `text-white/40` etc.
  static Color white(double opacity) => Colors.white.withValues(alpha: opacity);

  /// `font-display` (Space Grotesk).
  static TextStyle display({
    double size = 18,
    FontWeight weight = FontWeight.w700,
    Color color = Colors.white,
  }) =>
      GoogleFonts.spaceGrotesk(
        fontSize: size,
        fontWeight: weight,
        color: color,
      );

  /// `font-body` (Plus Jakarta Sans).
  static TextStyle body({
    double size = 14,
    FontWeight weight = FontWeight.w500,
    Color? color,
    double? letterSpacing,
  }) =>
      GoogleFonts.plusJakartaSans(
        fontSize: size,
        fontWeight: weight,
        color: color ?? white(0.6),
        letterSpacing: letterSpacing,
      );
}
