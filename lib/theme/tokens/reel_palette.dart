import 'package:flutter/material.dart';
import 'package:flutter_template/theme/tokens/colors.dart';

/// Scenery colours for the welcome reel only. The brand colours come from
/// [AppColors] and the occasion tiles from `OccasionColors`; these are the
/// per-scene backdrops and the props (the night-map picture, the passport page
/// and ticket) from the "Onboarding UX Pass" design.
class ReelPalette {
  ReelPalette._();

  static const occasionGlow = Color(0xFF1B1430);
  static const occasionMid = Color(0xFF0E0A1E);
  static const occasionDeep = Color(0xFF06050F);

  /// The space behind the globe.
  static const globeSpace = Color(0xFF060A1C);

  static const passportGlow = Color(0xFF141A2E);
  static const passportMid = Color(0xFF0A0F1F);
  static const passportDeep = Color(0xFF05070F);

  /// The pill under the globe and the pause button: dark glass with a light
  /// edge.
  static const pillText = Color(0xFFCFE6FF);
  static const pillFill = Color(0x99060A18);
  static const pillEdge = Color(0x1FFFFFFF);
  static const glassFill = Color(0x8C06080E);
  static const glassEdge = Color(0x33FFFFFF);

  // The night map of the Philippines, shown while the live globe loads.
  static const planetTop = Color(0xFF17264C);
  static const planetMid = Color(0xFF0B1430);
  static const planetDeep = Color(0xFF050914);
  static const planetLine = Color(0xFF9FD8FF);
  static const land = Color(0xFF111C40);
  static const regionLabel = Color(0xFF8CA7CF);
  static const cityGlow = Color(0xFFF1FFB0);
  static const cityDot = Color(0xFFF4FFC8);
  static const mapLabel = Color(0xFFCFE6FF);
  static const mapLabelEdge = Color(0xFF050914);

  // The passport page and ticket.
  static const pageFill = Color(0xFF0F1424);
  static const ticketNotch = Color(0xFF0C1122);

  /// Passport stamps, as (border, fill, ink).
  static const stamps = <({Color border, Color fill, Color ink})>[
    (
      border: AppColors.accentTintBorder,
      fill: AppColors.accentTintBg,
      ink: AppColors.accent,
    ),
    (
      border: Color(0xFF3B2D5C),
      fill: Color(0xFF241B3A),
      ink: AppColors.roleVenue,
    ),
    (
      border: Color(0xFF0E4A5C),
      fill: Color(0xFF081C24),
      ink: AppColors.roleTalent,
    ),
  ];

  /// A scene's backdrop: a glow at the top fading into the canvas.
  static BoxDecoration backdrop(Color glow, Color mid, Color deep) =>
      BoxDecoration(
        gradient: RadialGradient(
          center: const Alignment(0, -0.88),
          radius: 1.3,
          colors: [glow, mid, deep, AppColors.canvas],
          stops: const [0, 0.44, 0.74, 1],
        ),
      );
}
