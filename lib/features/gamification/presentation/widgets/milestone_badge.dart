import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_template/shared/widgets/brand_logo.dart';
import 'package:flutter_template/theme/tokens/colors.dart';

/// Where a badge stands: earned (white fill, dark fox), next to earn (white
/// outline) or locked (grey outline).
enum MilestoneBadgeState { earned, next, locked }

/// A milestone badge. Each tier upgrades it, and shape carries the rarity so
/// it reads without colour: circle, ringed circle, hexagon, octagon,
/// eight-point star (Common, Uncommon, Rare, Epic, Legendary). Flat fills
/// only. [rarity] is 0 to 4, the tier minus one. Small badges thicken their
/// inner line so it survives at 40 px.
class MilestoneBadge extends StatelessWidget {
  const MilestoneBadge({
    required this.rarity,
    required this.state,
    this.size = 52,
    super.key,
  });

  /// 0 (Common) to 4 (Legendary); values outside are held to that range.
  final int rarity;
  final MilestoneBadgeState state;
  final double size;

  @override
  Widget build(BuildContext context) {
    final r = rarity.clamp(0, 4);
    final ink = switch (state) {
      MilestoneBadgeState.earned => AppColors.canvas,
      MilestoneBadgeState.next => AppColors.textPrimary,
      MilestoneBadgeState.locked => AppColors.textFaint,
    };
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _BadgePainter(r, state, small: size <= 40),
        child: Center(
          child: FoxLogo(size: size * (r == 4 ? 0.44 : 0.5), color: ink),
        ),
      ),
    );
  }
}

class _BadgePainter extends CustomPainter {
  _BadgePainter(this.rarity, this.state, {required this.small});

  final int rarity;
  final MilestoneBadgeState state;
  final bool small;

  static const Color _white = AppColors.textPrimary;

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final full = size.width / 2;
    final outerWidth = size.width * 0.06;
    // The inner line is thicker on a small badge so it still shows.
    final innerWidth = math.max(small ? 1.6 : 1.2, size.width * 0.03);

    if (state == MilestoneBadgeState.earned) {
      canvas.drawPath(_outer(c, full - 0.5), Paint()..color = _white);
      final inner = _inner(c, full);
      if (inner != null) {
        canvas.drawPath(
          inner,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = innerWidth
            ..color = AppColors.canvas,
        );
        if (rarity == 1) _dots(canvas, c, full, AppColors.canvas);
      }
      return;
    }

    final color =
        state == MilestoneBadgeState.next ? _white : AppColors.textFaint;
    canvas.drawPath(
      _outer(c, full - outerWidth / 2),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = outerWidth
        ..strokeJoin = StrokeJoin.round
        ..color = color,
    );
    final inner = _inner(c, full - outerWidth);
    if (inner != null) {
      canvas.drawPath(
        inner,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = innerWidth
          ..strokeJoin = StrokeJoin.round
          ..color = color,
      );
      if (rarity == 1) _dots(canvas, c, full - outerWidth, color);
    }
  }

  /// The outline: circle, circle, hexagon, octagon, eight-point star.
  Path _outer(Offset c, double r) => switch (rarity) {
        2 => _polygon(c, r, 6, -math.pi / 2),
        3 => _polygon(c, r, 8, -math.pi / 2 + math.pi / 8),
        4 => _star(c, r),
        _ => Path()..addOval(Rect.fromCircle(center: c, radius: r)),
      };

  /// The line inside the outline; Common has none.
  Path? _inner(Offset c, double r) => switch (rarity) {
        1 => Path()..addOval(Rect.fromCircle(center: c, radius: r * 0.8)),
        2 => _polygon(c, r * 0.76, 6, -math.pi / 2),
        3 => _polygon(c, r * 0.8, 8, -math.pi / 2 + math.pi / 8),
        4 => Path()..addOval(Rect.fromCircle(center: c, radius: r * 0.62)),
        _ => null,
      };

  /// The two small dots that mark an Uncommon ring.
  void _dots(Canvas canvas, Offset c, double r, Color color) {
    final p = Paint()..color = color;
    final dot = math.max(1.2, r * 0.05);
    canvas
      ..drawCircle(Offset(c.dx - r * 0.9, c.dy), dot, p)
      ..drawCircle(Offset(c.dx + r * 0.9, c.dy), dot, p);
  }

  static Path _polygon(Offset c, double r, int sides, double start) {
    final path = Path();
    for (var i = 0; i < sides; i++) {
      final a = start + math.pi * 2 / sides * i;
      final p = Offset(c.dx + r * math.cos(a), c.dy + r * math.sin(a));
      i == 0 ? path.moveTo(p.dx, p.dy) : path.lineTo(p.dx, p.dy);
    }
    return path..close();
  }

  static Path _star(Offset c, double r) {
    final path = Path();
    for (var i = 0; i < 16; i++) {
      final radius = i.isEven ? r : r * 0.74;
      final a = -math.pi / 2 + math.pi / 8 * i;
      final p =
          Offset(c.dx + radius * math.cos(a), c.dy + radius * math.sin(a));
      i == 0 ? path.moveTo(p.dx, p.dy) : path.lineTo(p.dx, p.dy);
    }
    return path..close();
  }

  @override
  bool shouldRepaint(_BadgePainter old) =>
      old.rarity != rarity || old.state != state || old.small != small;
}
