import 'package:flutter/material.dart';

/// Design tokens — colours. Source of truth: `docs/mobile-design.md` §2.
///
/// The app is dark only and mirrors the web app's `globals.css`. Lime is for
/// one primary action per screen, the active tab and small uppercase labels;
/// everything else is white or grey on dark. No gradients, glows or blobs.
///
/// Use the flat tokens (`AppColors.canvas`, `AppColors.accent`, …) in new
/// code. The `ink` / `ui` / `text` / `status` / `brand` groups are the older
/// names, kept so existing widgets pick up the dark palette without edits.
class AppColors {
  AppColors._();

  // ── Surfaces ────────────────────────────────────────────────────────────

  /// App background.
  static const canvas = Color(0xFF02040A);

  /// Cards, inputs, bottom bar.
  static const surface = Color(0xFF0F111A);

  /// Nested surfaces, image placeholders, sheets.
  static const surfaceRaised = Color(0xFF1A1A24);

  /// Hairline on cards and inputs (white at 10% on canvas).
  static const border = Color(0xFF20232E);

  /// Outlined buttons, chips.
  static const borderStrong = Color(0xFF2A2D3A);

  // ── Accent (lime) ───────────────────────────────────────────────────────

  /// Primary button, active tab, key labels.
  static const accent = Color(0xFFCCFF00);
  static const accentPressed = Color(0xFFB8E600);

  /// Text and icons on lime. Never white.
  static const onAccent = Color(0xFF1A2000);

  /// Lime-tinted tiles and highlighted card borders.
  static const accentTintBg = Color(0xFF1A2000);
  static const accentTintBorder = Color(0xFF55660A);

  // ── Text ────────────────────────────────────────────────────────────────

  static const textPrimary = Color(0xFFFFFFFF);
  static const textSecondary = Color(0xFFA9ADBA);

  /// Placeholders, captions, inactive icons.
  static const textMuted = Color(0xFF8B90A0);

  /// The "or" in dividers, disabled.
  static const textFaint = Color(0xFF5A5F70);

  // ── Status ──────────────────────────────────────────────────────────────

  static const error = Color(0xFFF87171);
  static const success = Color(0xFF4ADE80);
  static const warning = Color(0xFFFBBF24);

  // ── Foxer role colours (chips and role labels only, never buttons) ──────

  static const roleEvent = Color(0xFFCCFF00);
  static const roleVenue = Color(0xFFA78BFA);
  static const roleGear = Color(0xFFF97316);
  static const roleTalent = Color(0xFF00D2FF);
  static const rolePerformer = Color(0xFFF59E0B);

  /// The "Foxer" label on Foxer cards.
  static const roleLabel = Color(0xFFFF00AA);

  // ── Legacy groups (same values, older names) ────────────────────────────

  static const ink = _Ink();
  static const ui = _UI();
  static const text = _Text();
  static const status = _Status();
  static const brand = _Brand();
}

class _Brand {
  const _Brand();

  Color get primary => AppColors.accent;
  Color get primaryBright => AppColors.accentPressed;
  Color get secondary => AppColors.textSecondary;
}

/// The old "ink" accent, now the lime accent.
class _Ink {
  const _Ink();

  Color get primary => AppColors.accent;
  Color get pressed => AppColors.accentPressed;
}

class _UI {
  const _UI();

  Color get background => AppColors.canvas;
  Color get surface => AppColors.surface;

  /// Nested cards and input fills.
  Color get surfaceMuted => AppColors.surfaceRaised;
  Color get borderHairline => AppColors.border;

  // Older dark-surface names — the whole app is dark now.
  Color get surfaceDark => AppColors.surface;
  Color get backgroundDark => AppColors.canvas;
  Color get surfaceElevatedDark => AppColors.surfaceRaised;
  Color get borderDark => AppColors.border;
}

class _Text {
  const _Text();

  Color get primary => AppColors.textPrimary;
  Color get secondary => AppColors.textSecondary;
  Color get tertiary => AppColors.textMuted;

  /// Text on the accent fill — `onAccent`, never white.
  Color get onInk => AppColors.onAccent;

  Color get primaryDark => AppColors.textPrimary;
  Color get secondaryDark => AppColors.textSecondary;
  Color get tertiaryDark => AppColors.textMuted;
}

class _Status {
  const _Status();

  Color get error => AppColors.error;
  Color get success => AppColors.success;
  Color get warning => AppColors.warning;
}
