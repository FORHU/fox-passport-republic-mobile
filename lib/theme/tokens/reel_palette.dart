import 'package:flutter/material.dart';
import 'package:flutter_template/theme/tokens/colors.dart';

/// Scenery colours for the welcome reel only. The brand colours come from
/// [AppColors]; these are the per-scene backdrops and the props from the
/// "Onboarding UX Pass" design: the things you hold for each occasion, the
/// split-flap board, and the passport page and its ticket.
class ReelPalette {
  ReelPalette._();

  static const occasionGlow = Color(0xFF1B1430);
  static const occasionMid = Color(0xFF0E0A1E);
  static const occasionDeep = Color(0xFF06050F);

  static const boardGlow = Color(0xFF111C40);
  static const boardMid = Color(0xFF0A1230);
  static const boardDeep = Color(0xFF060A1C);

  static const passportGlow = Color(0xFF141A2E);
  static const passportMid = Color(0xFF0A0F1F);
  static const passportDeep = Color(0xFF05070F);

  /// The pill under the board: dark glass with a light edge.
  static const pillText = Color(0xFFCFE6FF);
  static const pillFill = Color(0x99060A18);
  static const pillEdge = Color(0x1FFFFFFF);

  // ── 1 · The things you hold ──────────────────────────────────────────────

  /// The birthday sticker's die-cut edge, labels and sprinkles. Its face is
  /// [AppColors.roleGear].
  static const stickerCream = Color(0xFFFFF1E2);
  static const sprinkleLight = Color(0xFFFFE2BF);
  static const sprinkleDark = Color(0xFF3A1504);
  static const stickerInk = Color(0xFF1F0A01);

  /// The wedding invitation: cream paper, gold rules, brown ink.
  static const paper = Color(0xFFF3ECE0);
  static const paperInk = Color(0xFF2B2418);
  static const paperMuted = Color(0xFF7A6A4F);
  static const gold = Color(0xFFB8975A);

  /// The conference badge. Its band and lanyard are [AppColors.roleTalent].
  static const badgeCard = Color(0xFFF6F8FB);
  static const badgeInk = Color(0xFF0D1320);
  static const badgeBandInk = Color(0xFF04202A);
  static const badgeRole = Color(0xFF0A7A92);
  static const badgeSlot = Color(0xFF0B1220);
  static const strapShade = Color(0xFF00B9E2);

  /// The wristband's metal clasp, lit from the top left. The band itself is
  /// [AppColors.accent] with [AppColors.onAccent] print.
  static const claspLight = Color(0xFFFFFFFF);
  static const claspMid = Color(0xFFAAAABB);
  static const claspDark = Color(0xFF666677);

  /// Speckle on paper props.
  static const grain = Color(0x14000000);

  // ── 2 · The split-flap board ─────────────────────────────────────────────

  static const boardFace = Color(0xFF0B0D12);
  static const boardEdge = Color(0xFF23262F);
  static const boardRule = Color(0xFF1D2028);
  static const flapTop = Color(0xFF1D2029);
  static const flapBottom = Color(0xFF16181F);
  static const flapInk = Color(0xFFF3E6C0);
  static const flapSplit = Color(0xA6000000);
  static const statusQuiet = Color(0xFFC9CCD6);
  static const screwLight = Color(0xFF8A8F9A);
  static const screwDark = Color(0xFF3A3D45);

  // ── 3 · The passport page and ticket ─────────────────────────────────────

  static const pageFill = Color(0xFF0F1A2C);
  static const pageEdge = Color(0x1FA0C8FF);
  static const pageHead = Color(0xFF7D93B8);
  static const pageMicro = Color(0xFF4A5F82);
  static const patternBlue = Color(0xFF7FB4FF);
  static const patternLine = Color(0xFF9FD8FF);

  /// The thermal-paper ticket.
  static const thermalPaper = Color(0xFFEFEDE6);
  static const thermalInk = Color(0xFF141414);
  static const thermalMuted = Color(0xFF555555);
  static const thermalMeta = Color(0xFF333333);
  static const thermalOffline = Color(0xFF2F4A00);

  /// The punched holes down the ticket's edge show what is behind it.
  static const ticketHole = Color(0xFF0A0F1F);

  /// Stamp inks, in the order the stamps are drawn.
  static const stampInks = <Color>[
    AppColors.accent,
    AppColors.roleVenue,
    AppColors.roleTalent,
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
