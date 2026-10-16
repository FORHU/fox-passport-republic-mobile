import 'package:flutter/material.dart';

/// One occasion's tile colours: fill, outline and icon.
class OccasionStyle {
  const OccasionStyle({
    required this.background,
    required this.border,
    required this.icon,
  });

  final Color background;
  final Color border;
  final Color icon;
}

/// Occasion tile colours. Source of truth: `docs/mobile-design.md` section 6
/// (Home). Each is a dark tint of the occasion's hue so the tiles read as a
/// set on the canvas.
class OccasionColors {
  OccasionColors._();

  /// The Foxer pink on the "Have a Foxer plan it" card.
  static const plannerBorder = Color(0xFF5C1A46);

  static const wedding = OccasionStyle(
    background: Color(0xFF1A1428),
    border: Color(0xFF3B2D5C),
    icon: Color(0xFFA78BFA),
  );
  static const birthday = OccasionStyle(
    background: Color(0xFF24140A),
    border: Color(0xFF5C3214),
    icon: Color(0xFFF97316),
  );
  static const corporate = OccasionStyle(
    background: Color(0xFF081C24),
    border: Color(0xFF0E4A5C),
    icon: Color(0xFF00D2FF),
  );
  static const social = OccasionStyle(
    background: Color(0xFF1A2000),
    border: Color(0xFF55660A),
    icon: Color(0xFFCCFF00),
  );

  /// Also what an occasion the app does not know yet gets.
  static const other = OccasionStyle(
    background: Color(0xFF0F111A),
    border: Color(0xFF2A2D3A),
    icon: Color(0xFFA9ADBA),
  );
}
