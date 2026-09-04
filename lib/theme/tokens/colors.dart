import 'package:flutter/material.dart';

/// Design tokens — colors.
/// Ink-on-white palette (mapanytime-app style).
/// Single accent color (ink #0D0D0F), emphasizes content over brand.
class AppColors {
  AppColors._();

  static const ink = _Ink();
  static const ui = _UI();
  static const text = _Text();
  static const status = _Status();
  static const brand = _Brand();

  /// Gradient for promo scrim (map overlays, etc.)
  static const LinearGradient promoScrim = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0x000D0D0F), Color(0xBF0D0D0F)],
    stops: [0.0, 1.0],
  );

  /// Brand primary gradient
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF0D0D0F), Color(0xFF27272A)],
  );
}

class _Brand {
  const _Brand();

  Color get primary => const Color(0xFF0D0D0F);
  Color get primaryBright => const Color(0xFF27272A);
  Color get secondary => const Color(0xFF6B7280);
}

class _Ink {
  const _Ink();

  /// Ink primary — #0D0D0F (near-black).
  Color get primary => const Color(0xFF0D0D0F);

  /// Ink pressed state — #000000 (pure black).
  Color get pressed => const Color(0xFF000000);
}

class _UI {
  const _UI();

  /// App background — #F7F7F8 (very light gray).
  Color get background => const Color(0xFFF7F7F8);

  /// Primary surface — #FFFFFF (white).
  Color get surface => const Color(0xFFFFFFFF);

  /// Muted surface (nested cards, input fills) — #F5F5F6.
  Color get surfaceMuted => const Color(0xFFF5F5F6);

  /// Hairline border / divider — #ECEDF0.
  Color get borderHairline => const Color(0xFFECEDF0);

  /// Dark / elevated surface tokens
  Color get surfaceDark => const Color(0xFF18181B);
  Color get backgroundDark => const Color(0xFF0D0D0F);
  Color get surfaceElevatedDark => const Color(0xFF27272A);
  Color get borderDark => const Color(0xFF27272A);
}

class _Text {
  const _Text();

  /// Primary text — #14161C (dark gray).
  Color get primary => const Color(0xFF14161C);

  /// Secondary text — #6B7280 (medium gray).
  Color get secondary => const Color(0xFF6B7280);

  /// Tertiary text / captions — #9AA0AE (light gray).
  Color get tertiary => const Color(0xFF9AA0AE);

  /// Text on ink surfaces — #FFFFFF (white).
  Color get onInk => const Color(0xFFFFFFFF);

  /// Dark surface text tokens
  Color get primaryDark => const Color(0xFFF4F4F5);
  Color get secondaryDark => const Color(0xFFA1A1AA);
  Color get tertiaryDark => const Color(0xFF71717A);
}

class _Status {
  const _Status();

  /// Error — #E5484D (red).
  Color get error => const Color(0xFFE5484D);

  /// Success — #2FA36B (green).
  Color get success => const Color(0xFF2FA36B);

  /// Warning — #D89614 (amber).
  Color get warning => const Color(0xFFD89614);
}
