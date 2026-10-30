import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_template/features/welcome/presentation/widgets/reel_night_map.dart';
import 'package:flutter_template/l10n/generated/app_localizations.dart';
import 'package:flutter_template/shared/widgets/rotating_globe/rotating_globe.dart';
import 'package:flutter_template/theme/tokens/colors.dart';
import 'package:flutter_template/theme/tokens/occasion_colors.dart';
import 'package:flutter_template/theme/tokens/reel_palette.dart';
import 'package:flutter_template/theme/tokens/typography.dart';

const double _tau = math.pi * 2;

// All the ambient motion hangs off one looping value `t` (0..1). Every wave
// uses a whole number of cycles per loop, so the loop wraps without a jump.
double _wave(double t, int cycles, [double offset = 0]) =>
    math.sin(_tau * (t * cycles + offset));

double _phase(double t, int cycles, [double offset = 0]) =>
    (t * cycles + offset) % 1;

/// The three welcome reel scenes (`docs/mobile-design.md` §4): plan any
/// occasion, what's on near you, your tickets and stamps. The motion is slow
/// and sits in the scene; the words sit on a still panel below it. [ambient]
/// is the looping 0..1 value that drives the motion; the page stops it while
/// the reel is paused, and it stands still when motion is reduced, which
/// leaves each scene as a still frame. [frozen] tells the globe to stop too.
class ReelScene extends StatelessWidget {
  /// Builds scene [index] (0 to [sceneCount] - 1).
  const ReelScene({
    required this.index,
    required this.ambient,
    required this.frozen,
    required this.l10n,
    super.key,
  });

  /// How many scenes the reel has.
  static const sceneCount = 3;

  /// How tall the fade into the words panel is. Things that must stay clear
  /// of it sit above it.
  static const double fadeHeight = 70;

  /// Which scene to draw.
  final int index;

  /// The looping value that drives the motion.
  final Animation<double> ambient;

  /// The reel is paused (by the button or a held finger).
  final bool frozen;

  /// Labels for the tiles, the map and the ticket.
  final AppLocalizations l10n;

  /// The cities the listings are in. The first is the hub the routes start
  /// from. Pins only: no counts are shown, so none are made up.
  static const List<GlobeStop> _pins = [
    GlobeStop(city: 'Metro Manila', lat: 14.6, lng: 121, eventCount: 0),
    GlobeStop(city: 'Baguio', lat: 16.41, lng: 120.59, eventCount: 0),
    GlobeStop(city: 'Clark', lat: 15.18, lng: 120.56, eventCount: 0),
    GlobeStop(city: 'Cebu', lat: 10.32, lng: 123.89, eventCount: 0),
    GlobeStop(city: 'Davao', lat: 7.19, lng: 125.46, eventCount: 0),
  ];

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: Stack(
        fit: StackFit.expand,
        children: switch (index) {
          0 => _occasions(),
          1 => _world(context),
          _ => _passport(),
        },
      ),
    );
  }

  Widget _backdrop(Color glow, Color mid, Color deep) => Positioned.fill(
        child: DecoratedBox(decoration: ReelPalette.backdrop(glow, mid, deep)),
      );

  /// The fade from the scene into the words panel.
  Widget _fade() => const Positioned(
        left: 0,
        right: 0,
        bottom: 0,
        height: fadeHeight,
        child: IgnorePointer(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [AppColors.canvasClear, AppColors.canvas],
              ),
            ),
          ),
        ),
      );

  /// Draws [child], laid out on a [width] x [height] board, scaled up or down
  /// to fill the stage between the story bars ([top]) and the fade, but no
  /// wider than a phone. Without this a board stays at its drawn size and
  /// leaves the rest of a tall stage empty.
  Widget _fit({
    required double width,
    required double height,
    required double top,
    required Widget child,
  }) =>
      Positioned.fill(
        child: Padding(
          padding: EdgeInsets.only(top: top, bottom: fadeHeight - 20),
          child: LayoutBuilder(
            builder: (context, box) => Center(
              child: SizedBox(
                width: math.min(box.maxWidth - 32, 440),
                height: box.maxHeight,
                child: FittedBox(
                  child: SizedBox(width: width, height: height, child: child),
                ),
              ),
            ),
          ),
        ),
      );

  // ── 1 · Any occasion ─────────────────────────────────────────────────────

  List<Widget> _occasions() {
    final tiles = <_OccasionTile>[
      _OccasionTile(
        style: OccasionColors.wedding,
        icon: Icons.favorite_border,
        title: l10n.welcomeOccasionWedding,
        book: l10n.welcomeOccasionWeddingBook,
      ),
      _OccasionTile(
        style: OccasionColors.birthday,
        icon: Icons.cake_outlined,
        title: l10n.welcomeOccasionBirthday,
        book: l10n.welcomeOccasionBirthdayBook,
      ),
      _OccasionTile(
        style: OccasionColors.corporate,
        icon: Icons.business_center_outlined,
        title: l10n.welcomeOccasionCorporate,
        book: l10n.welcomeOccasionCorporateBook,
      ),
      _OccasionTile(
        style: OccasionColors.social,
        icon: Icons.nightlife_outlined,
        title: l10n.welcomeOccasionNightOut,
        book: l10n.welcomeOccasionNightOutBook,
      ),
    ];
    return [
      _backdrop(
        ReelPalette.occasionGlow,
        ReelPalette.occasionMid,
        ReelPalette.occasionDeep,
      ),
      _fit(
        width: _OccasionTile.width * 2 + 10,
        height: 290,
        top: 56,
        child: Wrap(
          spacing: 10,
          runSpacing: 14,
          children: [
            for (var i = 0; i < tiles.length; i++)
              _Lit(ambient, offset: -i * 0.25, child: tiles[i]),
          ],
        ),
      ),
      _fade(),
    ];
  }

  // ── 2 · What's on near you ───────────────────────────────────────────────

  /// How fast the globe turns: slow, so the Philippines stay in view for the
  /// whole scene.
  static const double _globeSpeed = 2;

  /// The globe turns west through the Philippines over the scene (a scene is
  /// 6.5 s, so about 13 degrees), so it starts that far east of them. With
  /// motion reduced it does not turn and sits right on them.
  static const double _philippinesLng = 122.5;
  static const double _turnStartLng = 129;

  List<Widget> _world(BuildContext context) {
    final turns = !MediaQuery.disableAnimationsOf(context);
    return [
      // The app's Mapbox globe, zoomed on the Philippines, with the city
      // lights, a lime pin on each city and routes from Metro Manila. A still
      // picture of the same view shows until it has drawn; it takes no input,
      // so taps and holds reach the reel.
      Positioned.fill(
        child: RotatingGlobe(
          look: GlobeLook.neon,
          background: ReelPalette.globeSpace,
          degreesPerSecond: _globeSpeed,
          zoom: 3.5,
          startLat: 12.5,
          startLng: turns ? _turnStartLng : _philippinesLng,
          stops: _pins,
          maxCards: 0,
          bottomInset: fadeHeight,
          paused: frozen,
          still: ReelNightMap(
            ambient: ambient,
            labels: (
              baguio: l10n.welcomeCityBaguio,
              clark: l10n.welcomeCityClark,
              manila: l10n.welcomeCityManila,
              cebu: l10n.welcomeCityCebu,
              davao: l10n.welcomeCityDavao,
              luzon: l10n.welcomeRegionLuzon,
              visayas: l10n.welcomeRegionVisayas,
              mindanao: l10n.welcomeRegionMindanao,
            ),
          ),
        ),
      ),
      _fade(),
      Positioned(
        left: 0,
        right: 0,
        bottom: 40,
        child: Center(child: _Pill(l10n.welcomeVerified)),
      ),
    ];
  }

  // ── 3 · Your passport ────────────────────────────────────────────────────

  List<Widget> _passport() => [
        _backdrop(
          ReelPalette.passportGlow,
          ReelPalette.passportMid,
          ReelPalette.passportDeep,
        ),
        _fit(
          width: 304,
          height: 252,
          top: 20,
          child: _PassportArt(ambient, l10n),
        ),
        _fade(),
      ];
}

// ── Occasions ──────────────────────────────────────────────────────────────

/// One occasion: its icon, its name, and what you would book for it.
class _OccasionTile extends StatelessWidget {
  const _OccasionTile({
    required this.style,
    required this.icon,
    required this.title,
    required this.book,
  });

  static const width = 132.0;

  final OccasionStyle style;
  final IconData icon;
  final String title;
  final String book;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: 138,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: style.background,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: style.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Icon(icon, size: 30, color: style.icon),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.display(),
              ),
              const SizedBox(height: 2),
              Text(
                book,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.body(size: 11),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Lights [child] up in its turn: it grows a little and glows in its own
/// colour for a moment, then rests. Four tiles take turns over 6 seconds.
class _Lit extends StatelessWidget {
  const _Lit(this.t, {required this.child, required this.offset});

  final Animation<double> t;
  final _OccasionTile child;
  final double offset;

  /// 0 at rest, 1 lit: up over the first 6% of the cycle, held to 20%, down by
  /// 26%.
  static double _lit(double p) {
    final k = p < 0.06
        ? p / 0.06
        : p < 0.20
            ? 1.0
            : p < 0.26
                ? (0.26 - p) / 0.06
                : 0.0;
    return Curves.easeInOut.transform(k);
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: t,
      child: child,
      builder: (_, tile) {
        final k = _lit(_phase(t.value, 4, offset));
        final ink = child.style.icon;
        return Transform.scale(
          scale: 1 + 0.06 * k,
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(color: ink.withValues(alpha: k), spreadRadius: 1),
                BoxShadow(
                  color: ink.withValues(alpha: 0.45 * k),
                  blurRadius: 28,
                ),
              ],
            ),
            child: tile,
          ),
        );
      },
    );
  }
}

// ── World ──────────────────────────────────────────────────────────────────

/// A small glass pill with a verified tick.
class _Pill extends StatelessWidget {
  const _Pill(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: ReelPalette.pillFill,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: ReelPalette.pillEdge),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 5),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.verified_outlined,
              size: 13,
              color: AppColors.roleTalent,
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: AppTypography.label(
                color: ReelPalette.pillText,
              ).copyWith(fontSize: 10, letterSpacing: 0.6),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Passport ───────────────────────────────────────────────────────────────

/// The passport page with three stamps and, over it, a ticket. Drawn on a
/// 304 x 252 board.
class _PassportArt extends StatelessWidget {
  const _PassportArt(this.t, this.l10n);

  final Animation<double> t;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final codes = [
      l10n.welcomeStamp1Code,
      l10n.welcomeStamp2Code,
      l10n.welcomeStamp3Code,
    ];
    final months = [
      l10n.welcomeStamp1Month,
      l10n.welcomeStamp2Month,
      l10n.welcomeStamp3Month,
    ];
    // Left and top inside the page, and the tilt in degrees.
    const spots = <(double, double, double)>[
      (16, 34, -10),
      (90, 30, 7),
      (164, 36, -4),
    ];
    return Stack(
      clipBehavior: Clip.none,
      children: [
        // A soft lime glow behind the ticket.
        Positioned(
          left: -8,
          top: 40,
          width: 320,
          height: 220,
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                colors: [
                  AppColors.accent.withValues(alpha: 0.13),
                  AppColors.clear,
                ],
              ),
            ),
          ),
        ),
        Positioned(
          left: 26,
          top: 12,
          width: 252,
          height: 176,
          child: Transform.rotate(
            angle: 2 * math.pi / 180,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: ReelPalette.pageFill,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.borderStrong),
                boxShadow: const [
                  BoxShadow(
                    color: AppColors.shadow,
                    blurRadius: 40,
                    offset: Offset(0, 18),
                  ),
                ],
              ),
              child: Stack(
                children: [
                  Positioned(
                    left: 0,
                    right: 0,
                    top: 10,
                    child: Text(
                      l10n.welcomePassportHeader.toUpperCase(),
                      textAlign: TextAlign.center,
                      style: AppTypography.label(
                        color: AppColors.textFaint,
                      ).copyWith(fontSize: 8, letterSpacing: 1.12),
                    ),
                  ),
                  for (var i = 0; i < spots.length; i++)
                    Positioned(
                      left: spots[i].$1,
                      top: spots[i].$2,
                      child: _Float(
                        t,
                        offset: -i * 0.33,
                        tilt: spots[i].$3 * math.pi / 180,
                        child: _Stamp(
                          code: codes[i],
                          month: months[i],
                          colors: ReelPalette.stamps[i],
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
        Positioned(
          left: 37,
          top: 150,
          width: 230,
          height: 90,
          child: _Float(
            t,
            offset: -0.18,
            tilt: -4 * math.pi / 180,
            child: _Ticket(l10n),
          ),
        ),
      ],
    );
  }
}

/// Floats [child] a few pixels up and down, at a tilt.
class _Float extends StatelessWidget {
  const _Float(
    this.t, {
    required this.child,
    required this.offset,
    required this.tilt,
  });

  final Animation<double> t;
  final Widget child;
  final double offset;
  final double tilt;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: t,
      child: child,
      builder: (_, child) => Transform.translate(
        offset: Offset(0, -3 + 3 * _wave(t.value, 5, offset)),
        child: Transform.rotate(angle: tilt, child: child),
      ),
    );
  }
}

/// A round passport stamp: a code and a month inside a dashed ring.
class _Stamp extends StatelessWidget {
  const _Stamp({
    required this.code,
    required this.month,
    required this.colors,
  });

  final String code;
  final String month;
  final ({Color border, Color fill, Color ink}) colors;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 72,
      height: 72,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: colors.fill,
        border: Border.all(color: colors.border, width: 2),
      ),
      child: CustomPaint(
        painter: _DashedRingPainter(colors.ink.withValues(alpha: 0.5)),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                code,
                style: AppTypography.display(color: colors.ink),
              ),
              Text(
                month,
                style: AppTypography.label(
                  color: colors.ink,
                ).copyWith(fontSize: 9, letterSpacing: 0.72),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DashedRingPainter extends CustomPainter {
  const _DashedRingPainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = (Offset.zero & size).deflate(6);
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke;
    const dashes = 28;
    for (var i = 0; i < dashes; i++) {
      canvas.drawArc(
        rect,
        _tau * i / dashes,
        _tau / dashes * 0.55,
        false,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_DashedRingPainter old) => old.color != color;
}

/// A ticket for a confirmed booking, with a code stub that works offline.
class _Ticket extends StatelessWidget {
  const _Ticket(this.l10n);

  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.borderStrong),
        boxShadow: const [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 30,
            offset: Offset(0, 14),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: CustomPaint(
              foregroundPainter: const _TearPainter(),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.welcomeTicketConfirmed.toUpperCase(),
                      style: AppTypography.label(
                        color: AppColors.accent,
                      ).copyWith(fontSize: 9, letterSpacing: 0.9),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      l10n.welcomeTicketTitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.display(size: 13),
                    ),
                    Text(
                      l10n.welcomeTicketWhen,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.body(
                        size: 10,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          SizedBox(
            width: 66,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const _Qr(),
                const SizedBox(height: 5),
                Text(
                  l10n.welcomeTicketOffline,
                  textAlign: TextAlign.center,
                  style: AppTypography.body(
                    size: 8.5,
                    color: AppColors.textMuted,
                  ).copyWith(height: 1.1),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// The dashed tear line down the right edge of the ticket's main part, with a
/// notch cut out at each end.
class _TearPainter extends CustomPainter {
  const _TearPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final x = size.width - 0.75;
    final dash = Paint()
      ..color = AppColors.borderStrong
      ..strokeWidth = 1.5;
    for (var y = 6.0; y < size.height - 6; y += 6) {
      canvas.drawLine(Offset(x, y), Offset(x, y + 3.5), dash);
    }
    final notch = Paint()..color = ReelPalette.ticketNotch;
    canvas
      ..drawCircle(Offset(size.width, 0), 6, notch)
      ..drawCircle(Offset(size.width, size.height), 6, notch);
  }

  @override
  bool shouldRepaint(_TearPainter old) => false;
}

/// A small stand-in QR code on a white tile.
class _Qr extends StatelessWidget {
  const _Qr();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 34,
      height: 34,
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: AppColors.lightSurface,
        borderRadius: BorderRadius.circular(6),
      ),
      child: const CustomPaint(painter: _QrPainter()),
    );
  }
}

class _QrPainter extends CustomPainter {
  const _QrPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final unit = size.width / 7;
    final ink = Paint()..color = AppColors.onLightSurface;
    final paper = Paint()..color = AppColors.lightSurface;
    Rect cell(double x, double y, double w, double h) =>
        Rect.fromLTWH(x * unit, y * unit, w * unit, h * unit);
    for (final r in [
      cell(0, 0, 3, 3),
      cell(4, 0, 3, 3),
      cell(0, 4, 3, 3),
      cell(4, 4, 1, 1),
      cell(6, 5, 1, 2),
      cell(4, 6, 1, 1),
    ]) {
      canvas.drawRect(r, ink);
    }
    for (final r in [cell(1, 1, 1, 1), cell(5, 1, 1, 1), cell(1, 5, 1, 1)]) {
      canvas.drawRect(r, paper);
    }
  }

  @override
  bool shouldRepaint(_QrPainter old) => false;
}
