import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_template/l10n/generated/app_localizations.dart';
import 'package:flutter_template/theme/tokens/colors.dart';
import 'package:flutter_template/theme/tokens/reel_palette.dart';
import 'package:flutter_template/theme/tokens/typography.dart';

const double _tau = math.pi * 2;

// All the ambient motion hangs off one looping value `t` (0..1). Every wave
// uses a whole number of cycles per loop, so the loop wraps without a jump.
double _wave(double t, int cycles, [double offset = 0]) =>
    math.sin(_tau * (t * cycles + offset));

double _phase(double t, int cycles, [double offset = 0]) =>
    (t * cycles + offset) % 1;

/// 0 at rest, 1 at its peak: up over the first 6% of a cycle [p], held to
/// 20%, down by 26%.
double _bump(double p) {
  final k = p < 0.06
      ? p / 0.06
      : p < 0.20
          ? 1.0
          : p < 0.26
              ? (0.26 - p) / 0.06
              : 0.0;
  return Curves.easeInOut.transform(k);
}

double _deg(double degrees) => degrees * math.pi / 180;

/// The three welcome reel scenes (`docs/mobile-design.md` §4): plan any
/// occasion, what's on near you, your tickets and stamps. Each is made of
/// real things: what you hold for an occasion, a split-flap board, a stamped
/// passport page. The motion is slow and sits in the scene; the words sit on
/// a still panel below it. [ambient] is the looping 0..1 value that drives
/// the motion; the page stops it while the reel is paused or held, and it
/// stands still when motion is reduced, which leaves each scene a still frame.
class ReelScene extends StatelessWidget {
  /// Builds scene [index] (0 to [sceneCount] - 1).
  const ReelScene({
    required this.index,
    required this.ambient,
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

  /// The words printed on the props.
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: Stack(
        fit: StackFit.expand,
        children: switch (index) {
          0 => _occasions(),
          1 => _board(),
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

  List<Widget> _occasions() => [
        _backdrop(
          ReelPalette.occasionGlow,
          ReelPalette.occasionMid,
          ReelPalette.occasionDeep,
        ),
        _fit(
          width: 304,
          height: 300,
          top: 48,
          child: _OccasionPile(ambient, l10n),
        ),
        _fade(),
      ];

  // ── 2 · What's on near you ───────────────────────────────────────────────

  List<Widget> _board() => [
        _backdrop(
          ReelPalette.boardGlow,
          ReelPalette.boardMid,
          ReelPalette.boardDeep,
        ),
        _fit(
          width: 304,
          height: 230,
          top: 40,
          child: Center(child: ReelBoard(ambient: ambient, l10n: l10n)),
        ),
        _fade(),
        Positioned(
          left: 0,
          right: 0,
          bottom: 40,
          child: Center(child: _Pill(l10n.welcomeVerified)),
        ),
      ];

  // ── 3 · Your passport ────────────────────────────────────────────────────

  List<Widget> _passport() => [
        _backdrop(
          ReelPalette.passportGlow,
          ReelPalette.passportMid,
          ReelPalette.passportDeep,
        ),
        _fit(
          width: 304,
          height: 262,
          top: 24,
          child: _PassportArt(ambient, l10n),
        ),
        _fade(),
      ];
}

// ── 1 · The things you hold ────────────────────────────────────────────────

/// What you would hold for each occasion, in a pile: a birthday sticker, a
/// wedding invitation, a conference badge on its lanyard and a VIP wristband.
/// Drawn on a 304 x 300 board. They take turns to lift.
class _OccasionPile extends StatelessWidget {
  const _OccasionPile(this.t, this.l10n);

  final Animation<double> t;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    return Stack(
      key: const ValueKey('reel-occasions'),
      clipBehavior: Clip.none,
      children: [
        _Prop(
          t,
          centre: const Offset(72, 96),
          size: const Size(104, 104),
          tilt: -11,
          turn: 1,
          child: _BirthdaySticker(l10n),
        ),
        _Prop(
          t,
          centre: const Offset(156, 164),
          size: const Size(124, 164),
          tilt: 3,
          turn: 0,
          child: _Invitation(l10n),
        ),
        _Prop(
          t,
          centre: const Offset(238, 114),
          size: const Size(96, 126),
          tilt: 9,
          turn: 2,
          child: _Badge(l10n),
        ),
        _Prop(
          t,
          centre: const Offset(152, 262),
          size: const Size(316, 30),
          tilt: -6,
          turn: 3,
          child: _Wristband(l10n),
        ),
      ],
    );
  }
}

/// One prop in the pile, centred on [centre] at a [tilt] in degrees. Four
/// props take turns ([turn] 0 to 3) over 6 seconds: each rises a little and
/// grows, then rests.
class _Prop extends StatelessWidget {
  const _Prop(
    this.t, {
    required this.centre,
    required this.size,
    required this.tilt,
    required this.turn,
    required this.child,
  });

  final Animation<double> t;
  final Offset centre;
  final Size size;
  final double tilt;
  final int turn;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: centre.dx - size.width / 2,
      top: centre.dy - size.height / 2,
      width: size.width,
      height: size.height,
      child: AnimatedBuilder(
        animation: t,
        child: child,
        builder: (_, child) {
          final k = _bump(_phase(t.value, 4, -turn * 0.25));
          return Transform.translate(
            offset: Offset(0, -9 * k),
            child: Transform.rotate(
              angle: _deg(tilt),
              child: Transform.scale(scale: 1 + 0.04 * k, child: child),
            ),
          );
        },
      ),
    );
  }
}

const _propShadow = BoxShadow(
  color: AppColors.shadow,
  blurRadius: 30,
  offset: Offset(0, 16),
);

/// A die-cut birthday sticker: orange with sprinkles, a cream edge, and a
/// big age.
class _BirthdaySticker extends StatelessWidget {
  const _BirthdaySticker(this.l10n);

  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.roleGear,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: ReelPalette.stickerCream, width: 4),
        boxShadow: const [_propShadow],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: CustomPaint(
          painter: const _SprinklesPainter(),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _Tag(l10n.welcomeArtBirthdayName.toUpperCase()),
                Text(
                  l10n.welcomeArtBirthdayAge,
                  style: AppTypography.hero(
                    size: 50,
                    color: ReelPalette.stickerInk,
                  ).copyWith(
                    shadows: const [
                      Shadow(
                        color: ReelPalette.stickerCream,
                        offset: Offset(2, 2),
                      ),
                    ],
                  ),
                ),
                _Tag(l10n.welcomeArtBirthdayWhen.toUpperCase()),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// A small cream label on the sticker.
class _Tag extends StatelessWidget {
  const _Tag(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: ReelPalette.stickerCream,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
        child: Text(
          text,
          maxLines: 1,
          style: AppTypography.label(
            color: ReelPalette.stickerInk,
          ).copyWith(fontSize: 8, letterSpacing: 1.1, height: 1.3),
        ),
      ),
    );
  }
}

class _SprinklesPainter extends CustomPainter {
  const _SprinklesPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final light = Paint()..color = ReelPalette.sprinkleLight;
    final dark = Paint()..color = ReelPalette.sprinkleDark;
    for (var y = 7.5; y < size.height; y += 15) {
      for (var x = 7.5; x < size.width; x += 15) {
        canvas.drawCircle(Offset(x, y), 1.5, light);
      }
    }
    for (var y = 15.5; y < size.height; y += 19) {
      for (var x = 17.5; x < size.width; x += 19) {
        canvas.drawCircle(Offset(x, y), 1.3, dark);
      }
    }
  }

  @override
  bool shouldRepaint(_SprinklesPainter old) => false;
}

/// A printed wedding invitation: cream paper, two gold rules, the couple's
/// names in script, the date and the place.
class _Invitation extends StatelessWidget {
  const _Invitation(this.l10n);

  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final muted = AppTypography.label(color: ReelPalette.paperMuted);
    final rule = BoxDecoration(border: Border.all(color: ReelPalette.gold));
    return DecoratedBox(
      decoration: BoxDecoration(
        color: ReelPalette.paper,
        borderRadius: BorderRadius.circular(3),
        boxShadow: const [_propShadow],
      ),
      child: CustomPaint(
        painter: const _GrainPainter(seed: 3),
        child: Padding(
          padding: const EdgeInsets.all(6),
          child: DecoratedBox(
            decoration: rule,
            child: Padding(
              padding: const EdgeInsets.all(3),
              child: DecoratedBox(
                decoration: rule,
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        l10n.welcomeArtWeddingFamilies.toUpperCase(),
                        textAlign: TextAlign.center,
                        style: muted.copyWith(
                          fontSize: 6,
                          letterSpacing: 1.2,
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text.rich(
                        TextSpan(
                          children: [
                            TextSpan(text: '${l10n.welcomeArtWeddingFirst}\n'),
                            TextSpan(
                              text: '& ',
                              style: AppTypography.script(
                                size: 19,
                                color: ReelPalette.gold,
                              ),
                            ),
                            TextSpan(text: l10n.welcomeArtWeddingSecond),
                          ],
                        ),
                        textAlign: TextAlign.center,
                        style: AppTypography.script(
                          color: ReelPalette.paperInk,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Transform.rotate(
                        angle: math.pi / 4,
                        child: const SizedBox.square(
                          dimension: 5,
                          child: ColoredBox(color: ReelPalette.gold),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        l10n.welcomeArtWeddingDate,
                        style: AppTypography.label(
                          color: ReelPalette.paperInk,
                        ).copyWith(fontSize: 8, letterSpacing: 1.3),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        l10n.welcomeArtWeddingPlace.toUpperCase(),
                        style: muted.copyWith(fontSize: 6, letterSpacing: 1.4),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// A fine speckle on paper, from a fixed seed so it is the same every time.
class _GrainPainter extends CustomPainter {
  const _GrainPainter({required this.seed});

  final int seed;

  @override
  void paint(Canvas canvas, Size size) {
    final random = math.Random(seed);
    final speck = Paint()..color = ReelPalette.grain;
    final count = (size.width * size.height / 60).round();
    for (var i = 0; i < count; i++) {
      canvas.drawCircle(
        Offset(
          random.nextDouble() * size.width,
          random.nextDouble() * size.height,
        ),
        0.2 + random.nextDouble() * 0.7,
        speck,
      );
    }
  }

  @override
  bool shouldRepaint(_GrainPainter old) => old.seed != seed;
}

/// A conference badge on its lanyard: a cyan band with the event, the role,
/// the name and a code. The lanyard fades out as it goes up.
class _Badge extends StatelessWidget {
  const _Badge(this.l10n);

  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Positioned(
          left: 40,
          top: -60,
          width: 16,
          height: 64,
          child: ShaderMask(
            blendMode: BlendMode.dstIn,
            shaderCallback: (rect) => const LinearGradient(
              begin: Alignment.bottomCenter,
              end: Alignment.topCenter,
              colors: [AppColors.textPrimary, AppColors.clear],
              stops: [0.55, 1],
            ).createShader(rect),
            child: const CustomPaint(painter: _StrapPainter()),
          ),
        ),
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: ReelPalette.badgeCard,
              borderRadius: BorderRadius.circular(9),
              boxShadow: const [_propShadow],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                DecoratedBox(
                  decoration: const BoxDecoration(
                    color: AppColors.roleTalent,
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(9),
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(9, 18, 9, 6),
                    child: Text(
                      l10n.welcomeArtBadgeEvent.toUpperCase(),
                      maxLines: 1,
                      overflow: TextOverflow.clip,
                      softWrap: false,
                      style: AppTypography.hero(
                        size: 12,
                        color: ReelPalette.badgeBandInk,
                      ).copyWith(letterSpacing: 0),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(9, 9, 9, 0),
                  child: Text(
                    l10n.welcomeArtBadgeRole.toUpperCase(),
                    maxLines: 1,
                    style: AppTypography.label(
                      color: ReelPalette.badgeRole,
                    ).copyWith(fontSize: 7, letterSpacing: 1.3, height: 1.2),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(9, 1, 9, 0),
                  child: Text(
                    l10n.welcomeArtBadgeName,
                    maxLines: 1,
                    overflow: TextOverflow.clip,
                    softWrap: false,
                    style: AppTypography.display(
                      size: 15,
                      color: ReelPalette.badgeInk,
                    ).copyWith(height: 1.1),
                  ),
                ),
                const Spacer(),
                const Padding(
                  padding: EdgeInsets.fromLTRB(0, 0, 9, 10),
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: SizedBox.square(
                      dimension: 26,
                      child: CustomPaint(painter: _QrPainter()),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        // The punched slot the lanyard clip goes through.
        Positioned(
          left: 37,
          top: 7,
          width: 22,
          height: 5,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: ReelPalette.badgeSlot,
              borderRadius: BorderRadius.circular(3),
            ),
          ),
        ),
      ],
    );
  }
}

/// The lanyard's woven stripes.
class _StrapPainter extends CustomPainter {
  const _StrapPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final light = Paint()..color = AppColors.roleTalent;
    final shade = Paint()..color = ReelPalette.strapShade;
    for (var y = 0.0; y < size.height; y += 14) {
      canvas
        ..drawRect(Rect.fromLTWH(0, y, size.width, 7), shade)
        ..drawRect(Rect.fromLTWH(0, y + 7, size.width, 7), light);
    }
  }

  @override
  bool shouldRepaint(_StrapPainter old) => false;
}

/// A woven lime VIP wristband with its print and a metal clasp, longer than
/// the stage is wide.
class _Wristband extends StatelessWidget {
  const _Wristband(this.l10n);

  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final print = List.filled(3, l10n.welcomeArtWristband).join(' · ');
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.accent,
        borderRadius: BorderRadius.circular(6),
        boxShadow: const [_propShadow],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(6),
        child: CustomPaint(
          painter: const _WeavePainter(),
          child: Stack(
            children: [
              Positioned.fill(
                child: Padding(
                  padding: const EdgeInsets.only(left: 14, right: 40),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      print.toUpperCase(),
                      maxLines: 1,
                      softWrap: false,
                      overflow: TextOverflow.clip,
                      style: AppTypography.hero(
                        size: 12,
                        color: AppColors.onAccent,
                      ).copyWith(letterSpacing: 1),
                    ),
                  ),
                ),
              ),
              const Positioned(
                right: 18,
                top: 7,
                width: 16,
                height: 16,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      center: Alignment(-0.3, -0.3),
                      colors: [
                        ReelPalette.claspLight,
                        ReelPalette.claspMid,
                        ReelPalette.claspDark,
                      ],
                      stops: [0, 0.6, 1],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The wristband's weave, and a sheen across the top.
class _WeavePainter extends CustomPainter {
  const _WeavePainter();

  @override
  void paint(Canvas canvas, Size size) {
    final thread = Paint()
      ..color = AppColors.onAccent.withValues(alpha: 0.08)
      ..strokeWidth = 1;
    for (var x = 0.5; x < size.width; x += 3) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), thread);
    }
    final rect = Offset.zero & size;
    canvas.drawRect(
      rect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppColors.textPrimary.withValues(alpha: 0.28),
            AppColors.clear,
            AppColors.onLightSurface.withValues(alpha: 0.14),
          ],
          stops: const [0, 0.4, 1],
        ).createShader(rect),
    );
  }

  @override
  bool shouldRepaint(_WeavePainter old) => false;
}

// ── 2 · The split-flap board ───────────────────────────────────────────────

/// How a row on the board stands.
enum ReelBoardStatus { live, fewLeft, tonight, sat, sun }

/// One row of the board: a city, an event and how it stands.
typedef ReelBoardRow = ({String city, String event, ReelBoardStatus status});

/// A split-flap board, like at an airport: what's on tonight in cities around
/// the world. Every 2.4 seconds one row turns over, letter by letter, to an
/// event in another city. It runs off the reel's [ambient] loop, so it stops
/// when the reel is paused or held and stands still with motion reduced.
class ReelBoard extends StatelessWidget {
  const ReelBoard({required this.ambient, required this.l10n, super.key});

  final Animation<double> ambient;
  final AppLocalizations l10n;

  /// Letters for the city and for the event.
  static const cityCells = 8;
  static const eventCells = 11;

  /// Row changes per loop: one every 2.4 s of the 24 s loop.
  static const steps = 10;

  /// The order the rows change in: across the board, not down it.
  static const _order = [0, 2, 4, 1, 3];

  static const double _stepSeconds = 2.4;
  static const double _flipSeconds = 0.32;
  static const double _staggerSeconds = 0.028;

  /// The board at [t] (0..1 through the loop), starting from [start]. Over
  /// the first half of the loop the rows turn over, one at a time, to [feed];
  /// over the second half they turn back, so the loop ends where it began.
  /// `rows` is what each row shows now; `flipping` is the row turning over in
  /// this step, which showed `before` until the step began; `into` is how far
  /// through the step it is (0..1).
  static ({
    List<ReelBoardRow> rows,
    List<ReelBoardRow> before,
    int flipping,
    double into,
  }) at(double t, List<ReelBoardRow> start, List<ReelBoardRow> feed) {
    final position = (t % 1) * steps;
    final step = position.floor().clamp(0, steps - 1);
    List<ReelBoardRow> after(int last) {
      final rows = [...start];
      for (var k = 0; k <= last; k++) {
        final row = _order[k % _order.length];
        rows[row] = k < _order.length ? feed[k] : start[row];
      }
      return rows;
    }

    return (
      rows: after(step),
      before: step == 0 ? [...start] : after(step - 1),
      flipping: _order[step % _order.length],
      into: position - step,
    );
  }

  /// How far letter [cell] of the turning row is through its flip (0..1), a
  /// fraction [into] of the way through the step. Each letter starts a little
  /// after the one before it.
  static double flipOf(double into, int cell) =>
      ((into * _stepSeconds - cell * _staggerSeconds) / _flipSeconds)
          .clamp(0.0, 1.0);

  List<ReelBoardRow> get _start => [
        (
          city: l10n.welcomeBoardCity1,
          event: l10n.welcomeBoardEvent1,
          status: ReelBoardStatus.live,
        ),
        (
          city: l10n.welcomeBoardCity2,
          event: l10n.welcomeBoardEvent2,
          status: ReelBoardStatus.tonight,
        ),
        (
          city: l10n.welcomeBoardCity3,
          event: l10n.welcomeBoardEvent3,
          status: ReelBoardStatus.fewLeft,
        ),
        (
          city: l10n.welcomeBoardCity4,
          event: l10n.welcomeBoardEvent4,
          status: ReelBoardStatus.sat,
        ),
        (
          city: l10n.welcomeBoardCity5,
          event: l10n.welcomeBoardEvent5,
          status: ReelBoardStatus.sun,
        ),
      ];

  List<ReelBoardRow> get _feed => [
        (
          city: l10n.welcomeBoardCity6,
          event: l10n.welcomeBoardEvent6,
          status: ReelBoardStatus.tonight,
        ),
        (
          city: l10n.welcomeBoardCity7,
          event: l10n.welcomeBoardEvent7,
          status: ReelBoardStatus.live,
        ),
        (
          city: l10n.welcomeBoardCity8,
          event: l10n.welcomeBoardEvent8,
          status: ReelBoardStatus.tonight,
        ),
        (
          city: l10n.welcomeBoardCity9,
          event: l10n.welcomeBoardEvent9,
          status: ReelBoardStatus.sat,
        ),
        (
          city: l10n.welcomeBoardCity10,
          event: l10n.welcomeBoardEvent10,
          status: ReelBoardStatus.live,
        ),
      ];

  @override
  Widget build(BuildContext context) {
    final start = _start;
    final feed = _feed;
    final faint = AppTypography.label(
      color: AppColors.textFaint,
    ).copyWith(fontSize: 6.5, letterSpacing: 1.2, height: 1.2);
    final title = AppTypography.hero(
      size: 13,
      color: ReelPalette.flapInk,
    ).copyWith(letterSpacing: 0.5);

    // Mounted on a wall and tilted back a little.
    return Transform(
      alignment: Alignment.center,
      transform: Matrix4.identity()
        ..setEntry(3, 2, 0.0015)
        ..rotateX(-0.157),
      child: Container(
        key: const ValueKey('reel-board'),
        width: 282,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: ReelPalette.boardFace,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: ReelPalette.boardEdge),
          boxShadow: const [
            BoxShadow(
              color: AppColors.shadow,
              blurRadius: 44,
              offset: Offset(0, 24),
            ),
          ],
        ),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: Text.rich(
                        TextSpan(
                          children: [
                            TextSpan(
                              text: '${l10n.welcomeBoardTitle.toUpperCase()} ',
                            ),
                            TextSpan(
                              text: '·',
                              style: title.copyWith(color: AppColors.accent),
                            ),
                            TextSpan(
                              text: ' ${l10n.welcomeBoardWhen.toUpperCase()}',
                            ),
                          ],
                        ),
                        maxLines: 1,
                        softWrap: false,
                        overflow: TextOverflow.clip,
                        style: title,
                      ),
                    ),
                    AnimatedBuilder(
                      animation: ambient,
                      builder: (context, _) => Text(
                        l10n
                            .welcomeBoardLocalTime(
                              MaterialLocalizations.of(context).formatTimeOfDay(
                                TimeOfDay.now(),
                                alwaysUse24HourFormat: true,
                              ),
                            )
                            .toUpperCase(),
                        style: AppTypography.label().copyWith(
                          fontSize: 8,
                          letterSpacing: 1.1,
                          height: 1.2,
                        ),
                      ),
                    ),
                  ],
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: SizedBox(
                    height: 1,
                    child: ColoredBox(color: ReelPalette.boardRule),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(bottom: 5),
                  child: Row(
                    children: [
                      SizedBox(
                        width: cityCells * 10 + 6,
                        child: Text(
                          l10n.welcomeBoardColCity.toUpperCase(),
                          style: faint,
                        ),
                      ),
                      Expanded(
                        child: Text(
                          l10n.welcomeBoardColEvent.toUpperCase(),
                          style: faint,
                        ),
                      ),
                      Text(
                        l10n.welcomeBoardColStatus.toUpperCase(),
                        style: faint,
                      ),
                    ],
                  ),
                ),
                AnimatedBuilder(
                  animation: ambient,
                  builder: (context, child) {
                    final board = at(ambient.value, start, feed);
                    return Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        for (var r = 0; r < start.length; r++)
                          Padding(
                            padding: EdgeInsets.only(top: r == 0 ? 0 : 5),
                            child: _BoardRow(
                              row: board.rows[r],
                              before: board.before[r],
                              into: r == board.flipping ? board.into : null,
                              l10n: l10n,
                            ),
                          ),
                      ],
                    );
                  },
                ),
              ],
            ),
            const Positioned(left: -6, top: -6, child: _Screw()),
            const Positioned(right: -6, top: -6, child: _Screw()),
          ],
        ),
      ),
    );
  }
}

/// A row of letters on the board. While it turns over ([into] is not null),
/// each letter flips from what it showed [before] to what it shows now.
class _BoardRow extends StatelessWidget {
  const _BoardRow({
    required this.row,
    required this.before,
    required this.into,
    required this.l10n,
  });

  final ReelBoardRow row;
  final ReelBoardRow before;
  final double? into;
  final AppLocalizations l10n;

  static String _pad(String text, int cells) =>
      text.toUpperCase().padRight(cells).substring(0, cells);

  List<Widget> _cells(String now, String was, int cells, int offset) {
    final next = _pad(now, cells);
    final last = _pad(was, cells);
    final turning = into;
    return [
      for (var i = 0; i < cells; i++)
        Padding(
          padding: EdgeInsets.only(right: i == cells - 1 ? 0 : 1),
          child: () {
            if (turning == null || next[i] == last[i]) {
              return _Flap(next[i], angle: 0);
            }
            final k = ReelBoard.flipOf(turning, offset + i);
            return k < 0.5
                ? _Flap(last[i], angle: k * math.pi)
                : _Flap(next[i], angle: (1 - k) * math.pi);
          }(),
        ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final turning = into;
    final status =
        turning != null && turning < 0.18 ? before.status : row.status;
    return Row(
      children: [
        ..._cells(row.city, before.city, ReelBoard.cityCells, 0),
        const SizedBox(width: 6),
        ..._cells(
          row.event,
          before.event,
          ReelBoard.eventCells,
          ReelBoard.cityCells,
        ),
        Expanded(
          child: Align(
            alignment: Alignment.centerRight,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: _Status(status, l10n),
            ),
          ),
        ),
      ],
    );
  }
}

/// One split-flap letter: two halves with a split between them, turned
/// [angle] radians about its middle.
class _Flap extends StatelessWidget {
  const _Flap(this.letter, {required this.angle});

  final String letter;
  final double angle;

  @override
  Widget build(BuildContext context) {
    return Transform(
      alignment: Alignment.center,
      transform: Matrix4.identity()
        ..setEntry(3, 2, 0.006)
        ..rotateX(angle),
      child: Container(
        width: 9,
        height: 15,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(2),
          gradient: const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              ReelPalette.flapTop,
              ReelPalette.flapTop,
              ReelPalette.flapBottom,
              ReelPalette.flapBottom,
            ],
            stops: [0, 0.5, 0.5, 1],
          ),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Text(
              letter,
              style: AppTypography.label(
                color: ReelPalette.flapInk,
              ).copyWith(fontSize: 9, letterSpacing: 0, height: 1),
            ),
            const Positioned(
              left: 0,
              right: 0,
              top: 7,
              height: 1,
              child: ColoredBox(color: ReelPalette.flapSplit),
            ),
          ],
        ),
      ),
    );
  }
}

/// The tag at the end of a board row: live in lime, few left in amber, the
/// rest quiet.
class _Status extends StatelessWidget {
  const _Status(this.status, this.l10n);

  final ReelBoardStatus status;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final (word, fill, ink, edge) = switch (status) {
      ReelBoardStatus.live => (
          l10n.welcomeBoardLive,
          AppColors.accent,
          AppColors.onAccent,
          AppColors.accent,
        ),
      ReelBoardStatus.fewLeft => (
          l10n.welcomeBoardFewLeft,
          AppColors.clear,
          AppColors.warning,
          AppColors.warning.withValues(alpha: 0.5),
        ),
      ReelBoardStatus.tonight => (
          l10n.welcomeBoardTonight,
          AppColors.clear,
          ReelPalette.statusQuiet,
          AppColors.borderStrong,
        ),
      ReelBoardStatus.sat => (
          l10n.welcomeBoardSat,
          AppColors.clear,
          ReelPalette.statusQuiet,
          AppColors.borderStrong,
        ),
      ReelBoardStatus.sun => (
          l10n.welcomeBoardSun,
          AppColors.clear,
          ReelPalette.statusQuiet,
          AppColors.borderStrong,
        ),
    };
    return DecoratedBox(
      decoration: BoxDecoration(
        color: fill,
        borderRadius: BorderRadius.circular(3),
        border: Border.all(color: edge),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
        child: Text(
          word.toUpperCase(),
          style: AppTypography.label(
            color: ink,
          ).copyWith(fontSize: 7, letterSpacing: 0.7, height: 1.2),
        ),
      ),
    );
  }
}

/// A screw head in the board's corner.
class _Screw extends StatelessWidget {
  const _Screw();

  @override
  Widget build(BuildContext context) {
    return const SizedBox.square(
      dimension: 5,
      child: DecoratedBox(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            center: Alignment(-0.3, -0.3),
            colors: [ReelPalette.screwLight, ReelPalette.screwDark],
          ),
        ),
      ),
    );
  }
}

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

// ── 3 · The passport page ──────────────────────────────────────────────────

/// A passport page with three stamps and, over its corner, a thermal ticket.
/// Drawn on a 304 x 262 board.
class _PassportArt extends StatelessWidget {
  const _PassportArt(this.t, this.l10n);

  final Animation<double> t;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        // A soft lime glow behind the ticket.
        Positioned(
          left: 40,
          top: 90,
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
          top: 4,
          width: 252,
          height: 204,
          child: Transform.rotate(
            angle: _deg(-2),
            child: _PassportPage(l10n),
          ),
        ),
        Positioned(
          left: 142,
          top: 160,
          width: 150,
          child: _Float(
            t,
            offset: -0.18,
            tilt: _deg(8),
            child: _ThermalTicket(l10n),
          ),
        ),
      ],
    );
  }
}

/// The page itself: a security pattern, the page's heading and number, a
/// line of tiny repeated text, the fox-keyhole watermark, and three rubber
/// stamps in worn ink.
class _PassportPage extends StatelessWidget {
  const _PassportPage(this.l10n);

  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final head = AppTypography.label(
      color: ReelPalette.pageHead,
    ).copyWith(fontSize: 7.5, letterSpacing: 1.6, height: 1.2);
    final micro = List.filled(
      6,
      l10n.welcomePassportMicro.toUpperCase(),
    ).join(' · ');
    return DecoratedBox(
      decoration: BoxDecoration(
        color: ReelPalette.pageFill,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: ReelPalette.pageEdge),
        boxShadow: const [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 44,
            offset: Offset(0, 22),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: Stack(
          children: [
            const Positioned.fill(
              child: CustomPaint(painter: _SecurityPatternPainter()),
            ),
            Positioned(
              left: 14,
              right: 14,
              top: 10,
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      l10n.welcomePassportHeader.toUpperCase(),
                      maxLines: 1,
                      style: head,
                    ),
                  ),
                  Text('07', style: head),
                ],
              ),
            ),
            Positioned(
              left: 14,
              right: 14,
              top: 24,
              child: Text(
                micro,
                maxLines: 1,
                softWrap: false,
                overflow: TextOverflow.clip,
                style: AppTypography.label(
                  color: ReelPalette.pageMicro,
                ).copyWith(fontSize: 5, letterSpacing: 0.9, height: 1.2),
              ),
            ),
            Positioned(
              left: 18,
              top: 40,
              child: Transform.rotate(
                angle: _deg(-14),
                child: _InkStamp(
                  shape: _StampShape.round,
                  size: const Size(96, 96),
                  ink: ReelPalette.stampInks[0],
                  big: l10n.welcomeStamp1Code,
                  small: l10n.welcomeStamp1Date,
                  ring: l10n.welcomeStamp1Ring,
                  seed: 4,
                ),
              ),
            ),
            Positioned(
              left: 128,
              top: 36,
              child: Transform.rotate(
                angle: _deg(7),
                child: _InkStamp(
                  shape: _StampShape.oblong,
                  size: const Size(106, 66),
                  ink: ReelPalette.stampInks[1],
                  big: l10n.welcomeStamp2Code,
                  small: l10n.welcomeStamp2Date,
                  top: l10n.welcomeStamp2Kind,
                  seed: 9,
                ),
              ),
            ),
            Positioned(
              left: 30,
              top: 112,
              child: Transform.rotate(
                angle: _deg(-6),
                child: _InkStamp(
                  shape: _StampShape.octagon,
                  size: const Size(84, 84),
                  ink: ReelPalette.stampInks[2],
                  big: l10n.welcomeStamp3Code,
                  small: l10n.welcomeStamp3Date,
                  top: l10n.welcomeStamp3Kind,
                  seed: 17,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The page's security printing: two sets of fine waves, a rosette of
/// ellipses, and the fox-keyhole mark as a watermark.
class _SecurityPatternPainter extends CustomPainter {
  const _SecurityPatternPainter();

  void _waves(
    Canvas canvas,
    Size size, {
    required Color color,
    required double gap,
    required double height,
    required double period,
    required double width,
  }) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = width;
    for (var y = gap / 2; y < size.height; y += gap) {
      final path = Path()..moveTo(0, y);
      for (var x = 0.0; x <= size.width; x += 3) {
        path.lineTo(x, y + height * math.sin(_tau * x / period));
      }
      canvas.drawPath(path, paint);
    }
  }

  @override
  void paint(Canvas canvas, Size size) {
    _waves(
      canvas,
      size,
      color: ReelPalette.patternBlue.withValues(alpha: 0.10),
      gap: 10,
      height: 2.5,
      period: 36,
      width: 0.6,
    );
    _waves(
      canvas,
      size,
      color: AppColors.accent.withValues(alpha: 0.07),
      gap: 14,
      height: 3.5,
      period: 48,
      width: 0.5,
    );

    final line = Paint()
      ..color = ReelPalette.patternLine.withValues(alpha: 0.08)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.7;
    canvas
      ..save()
      ..translate(size.width / 2, size.height * 0.54);
    for (var i = 0; i < 12; i++) {
      canvas
        ..save()
        ..rotate(i * math.pi / 12)
        ..drawOval(
          Rect.fromCenter(center: Offset.zero, width: 148, height: 44),
          line,
        )
        ..restore();
    }
    canvas.restore();

    final mark = Paint()
      ..color = ReelPalette.patternLine.withValues(alpha: 0.12)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4
      ..strokeJoin = StrokeJoin.round;
    final fox = Path()
      ..moveTo(2, 2)
      ..lineTo(20, 22)
      ..lineTo(30, 18)
      ..lineTo(40, 22)
      ..lineTo(58, 2)
      ..lineTo(52, 34)
      ..lineTo(30, 54)
      ..lineTo(8, 34)
      ..close();
    final keyhole = Path()
      ..moveTo(28, 34)
      ..lineTo(26, 44)
      ..lineTo(34, 44)
      ..lineTo(32, 34);
    canvas
      ..save()
      ..translate(size.width - 84, size.height * 0.45)
      ..drawPath(fox, mark)
      ..drawCircle(const Offset(30, 31), 4, mark)
      ..drawPath(keyhole, mark)
      ..restore();
  }

  @override
  bool shouldRepaint(_SecurityPatternPainter old) => false;
}

enum _StampShape { round, oblong, octagon }

/// A rubber stamp in worn ink.
class _InkStamp extends StatelessWidget {
  const _InkStamp({
    required this.shape,
    required this.size,
    required this.ink,
    required this.big,
    required this.small,
    required this.seed,
    this.top,
    this.ring,
  });

  final _StampShape shape;
  final Size size;
  final Color ink;
  final String big;
  final String small;
  final int seed;

  /// A small line above [big] (oblong and octagon stamps).
  final String? top;

  /// Text running round the ring (round stamps).
  final String? ring;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: size,
      painter: _StampPainter(
        shape: shape,
        ink: ink,
        big: big,
        small: small,
        top: top,
        ring: ring,
        seed: seed,
      ),
    );
  }
}

class _StampPainter extends CustomPainter {
  const _StampPainter({
    required this.shape,
    required this.ink,
    required this.big,
    required this.small,
    required this.top,
    required this.ring,
    required this.seed,
  });

  final _StampShape shape;
  final Color ink;
  final String big;
  final String small;
  final String? top;
  final String? ring;
  final int seed;

  TextPainter _layout(String text, TextStyle style) => TextPainter(
        text: TextSpan(text: text, style: style),
        textDirection: TextDirection.ltr,
      )..layout();

  /// Paints [text] centred on [x] with its baseline on [y].
  void _line(Canvas canvas, String text, TextStyle style, double x, double y) {
    final painter = _layout(text, style);
    painter.paint(
      canvas,
      Offset(
        x - painter.width / 2,
        y - painter.computeDistanceToActualBaseline(TextBaseline.alphabetic),
      ),
    );
  }

  /// Paints [text] round a circle of radius [r] about [centre], starting at
  /// the left and going over the top, each letter upright to the ring.
  void _round(
    Canvas canvas,
    String text,
    TextStyle style,
    Offset centre,
    double r,
    double spacing,
  ) {
    var angle = -math.pi;
    for (final letter in text.split('')) {
      final painter = _layout(letter, style);
      final step = (painter.width + spacing) / r;
      final mid = angle + step / 2;
      canvas
        ..save()
        ..translate(
          centre.dx + r * math.cos(mid),
          centre.dy + r * math.sin(mid),
        )
        ..rotate(mid + math.pi / 2);
      painter.paint(canvas, Offset(-painter.width / 2, -painter.height));
      canvas.restore();
      angle += step;
    }
  }

  Path _octagon(double inset, double scale) {
    final points = [
      const Offset(25, 2),
      const Offset(59, 2),
      const Offset(82, 25),
      const Offset(82, 59),
      const Offset(59, 82),
      const Offset(25, 82),
      const Offset(2, 59),
      const Offset(2, 25),
    ];
    const middle = Offset(42, 42);
    final path = Path();
    for (var i = 0; i < points.length; i++) {
      final towards = middle - points[i];
      final p = (points[i] + towards / towards.distance * inset) * scale;
      if (i == 0) {
        path.moveTo(p.dx, p.dy);
      } else {
        path.lineTo(p.dx, p.dy);
      }
    }
    return path..close();
  }

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final unit = shape == _StampShape.oblong ? h / 66 : w / 100;
    final thick = Paint()
      ..color = ink
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.6 * unit;
    final thin = Paint()
      ..color = ink
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.1 * unit;
    final words = AppTypography.label(color: ink).copyWith(letterSpacing: 0);
    final title = AppTypography.hero(color: ink).copyWith(letterSpacing: 0.4);

    // Stamped ink is a little see-through.
    canvas.saveLayer(
      Offset.zero & size,
      Paint()..color = AppColors.onLightSurface.withValues(alpha: 0.92),
    );
    switch (shape) {
      case _StampShape.round:
        final centre = Offset(w / 2, h / 2);
        canvas
          ..drawCircle(centre, w * 0.47, thick)
          ..drawCircle(centre, w * 0.33, thin);
        final around = ring;
        if (around != null) {
          _round(
            canvas,
            '${around.toUpperCase()} ',
            words.copyWith(fontSize: 7 * unit),
            centre,
            w * 0.40,
            1.5 * unit,
          );
        }
        _line(canvas, big, title.copyWith(fontSize: 19 * unit), w / 2, h * .57);
        _line(
          canvas,
          small.toUpperCase(),
          words.copyWith(fontSize: 6.4 * unit),
          w / 2,
          h * 0.68,
        );
      case _StampShape.oblong:
        canvas
          ..drawRRect(
            RRect.fromRectAndRadius(
              (Offset.zero & size).deflate(2 * unit),
              Radius.circular(7 * unit),
            ),
            thick,
          )
          ..drawRRect(
            RRect.fromRectAndRadius(
              (Offset.zero & size).deflate(7 * unit),
              Radius.circular(4 * unit),
            ),
            thin,
          );
        final above = top;
        if (above != null) {
          _layout(
            above.toUpperCase(),
            words.copyWith(fontSize: 7 * unit),
          ).paint(canvas, Offset(14 * unit, 13 * unit));
        }
        _line(
          canvas,
          big.toUpperCase(),
          title.copyWith(fontSize: 16 * unit),
          w / 2,
          h * 0.6,
        );
        _line(
          canvas,
          small.toUpperCase(),
          words.copyWith(fontSize: 6.2 * unit),
          w / 2,
          h * 0.78,
        );
      case _StampShape.octagon:
        final scale = w / 84;
        canvas
          ..drawPath(_octagon(0, scale), thick)
          ..drawPath(_octagon(8, scale), thin);
        final above = top;
        if (above != null) {
          _line(
            canvas,
            above.toUpperCase(),
            words.copyWith(fontSize: 6.4 * scale),
            w / 2,
            h * 0.36,
          );
        }
        _line(
          canvas,
          big.toUpperCase(),
          title.copyWith(fontSize: 17 * scale),
          w / 2,
          h * 0.58,
        );
        _line(
          canvas,
          small.toUpperCase(),
          words.copyWith(fontSize: 6.2 * scale),
          w / 2,
          h * 0.71,
        );
    }

    // Worn ink: specks and soft patches where the stamp did not take. The
    // seed keeps the wear the same on every frame and every run.
    final random = math.Random(seed);
    final speck = Paint()
      ..blendMode = BlendMode.dstOut
      ..color = AppColors.onLightSurface;
    for (var i = 0; i < 170; i++) {
      canvas.drawCircle(
        Offset(random.nextDouble() * w, random.nextDouble() * h),
        0.35 + random.nextDouble(),
        speck,
      );
    }
    final patch = Paint()
      ..blendMode = BlendMode.dstOut
      ..color = AppColors.onLightSurface.withValues(alpha: 0.35)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);
    for (var i = 0; i < 6; i++) {
      canvas.drawCircle(
        Offset(random.nextDouble() * w, random.nextDouble() * h),
        4 + random.nextDouble() * 6,
        patch,
      );
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(_StampPainter old) =>
      old.shape != shape ||
      old.ink != ink ||
      old.big != big ||
      old.small != small ||
      old.top != top ||
      old.ring != ring ||
      old.seed != seed;
}

/// Floats [child] a few pixels up and down, at a [tilt] in radians.
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

/// A thermal-paper ticket: punched holes down one edge, the event, a barcode,
/// and a note that it works offline at the door.
class _ThermalTicket extends StatelessWidget {
  const _ThermalTicket(this.l10n);

  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final small = AppTypography.label(
      color: ReelPalette.thermalMuted,
    ).copyWith(fontSize: 6.5, letterSpacing: 1, height: 1.2);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: ReelPalette.thermalPaper,
        borderRadius: BorderRadius.circular(4),
        boxShadow: const [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 26,
            offset: Offset(0, 14),
          ),
        ],
      ),
      child: CustomPaint(
        painter: const _GrainPainter(seed: 11),
        foregroundPainter: const _PerforationPainter(),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(17, 8, 10, 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      l10n.welcomeTicketBrand.toUpperCase(),
                      maxLines: 1,
                      style: small,
                    ),
                  ),
                  Text(l10n.welcomeTicketAdmit.toUpperCase(), style: small),
                ],
              ),
              const SizedBox(height: 5),
              Text(
                l10n.welcomeTicketTitle.toUpperCase(),
                maxLines: 1,
                softWrap: false,
                overflow: TextOverflow.clip,
                style: AppTypography.hero(
                  size: 11.5,
                  color: ReelPalette.thermalInk,
                ).copyWith(letterSpacing: 0, height: 1),
              ),
              const SizedBox(height: 3),
              Text(
                l10n.welcomeTicketWhen,
                maxLines: 1,
                softWrap: false,
                overflow: TextOverflow.clip,
                style: AppTypography.label(
                  color: ReelPalette.thermalMeta,
                ).copyWith(fontSize: 6.5, letterSpacing: 0.4, height: 1.2),
              ),
              const SizedBox(height: 6),
              const SizedBox(
                height: 16,
                width: double.infinity,
                child: CustomPaint(painter: _BarcodePainter()),
              ),
              const SizedBox(height: 5),
              Row(
                children: [
                  const Icon(
                    Icons.wifi_off,
                    size: 10,
                    color: ReelPalette.thermalOffline,
                  ),
                  const SizedBox(width: 3),
                  Expanded(
                    child: Text(
                      l10n.welcomeTicketOffline.toUpperCase(),
                      maxLines: 1,
                      style: AppTypography.label(
                        color: ReelPalette.thermalOffline,
                      ).copyWith(
                        fontSize: 6.5,
                        letterSpacing: 0.8,
                        height: 1.2,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The punched holes down the ticket's left edge.
class _PerforationPainter extends CustomPainter {
  const _PerforationPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final hole = Paint()..color = ReelPalette.ticketHole;
    for (var y = 8.0; y < size.height - 4; y += 8) {
      canvas.drawCircle(Offset(7, y), 1.8, hole);
    }
  }

  @override
  bool shouldRepaint(_PerforationPainter old) => false;
}

/// A barcode: bars of a few widths in a fixed pattern.
class _BarcodePainter extends CustomPainter {
  const _BarcodePainter();

  static const _bars = [1, 2, 1, 1, 3, 1, 2, 2, 1, 3, 1, 1, 2, 1, 3, 2, 1];

  @override
  void paint(Canvas canvas, Size size) {
    final bar = Paint()..color = ReelPalette.thermalInk;
    var x = 0.0;
    var i = 0;
    while (x < size.width) {
      final width = _bars[i % _bars.length].toDouble();
      canvas.drawRect(Rect.fromLTWH(x, 0, width, size.height), bar);
      x += width + 1 + (i % 3);
      i++;
    }
  }

  @override
  bool shouldRepaint(_BarcodePainter old) => false;
}

/// A small stand-in QR code.
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
