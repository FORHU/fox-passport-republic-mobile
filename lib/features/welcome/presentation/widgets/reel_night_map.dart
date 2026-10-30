import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_template/features/welcome/presentation/widgets/reel_coast_data.dart';
import 'package:flutter_template/theme/tokens/colors.dart';
import 'package:flutter_template/theme/tokens/reel_palette.dart';
import 'package:flutter_template/theme/tokens/typography.dart';

/// The place names on the map: five cities and the three island groups.
typedef ReelMapLabels = ({
  String baguio,
  String clark,
  String manila,
  String cebu,
  String davao,
  String luzon,
  String visayas,
  String mindanao,
});

/// A picture of the Philippines at night: the real coastlines (Natural Earth,
/// public domain), a faint grid, the five cities where the listings are at
/// their real latitude and longitude, and routes from Metro Manila. It stands
/// in until the live Mapbox globe has drawn, and whenever there is no token or
/// web view, so a slow or missing map never leaves the slide blank. It is drawn
/// in code from a small data file, so no image ships with the app.
class ReelNightMap extends StatelessWidget {
  const ReelNightMap({required this.labels, this.ambient, super.key});

  final ReelMapLabels labels;

  /// The reel's looping 0..1 value. With it the cities ping and the routes
  /// flow; without it (or while it stands still) the picture is still.
  final Animation<double>? ambient;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _NightMapPainter(labels, ambient),
      size: Size.infinite,
    );
  }
}

class _City {
  const _City(this.lng, this.lat, this.glow);

  final double lng;
  final double lat;

  /// Radius of its soft light, in board units.
  final double glow;
}

class _NightMapPainter extends CustomPainter {
  _NightMapPainter(this.labels, this.t) : super(repaint: t);

  final ReelMapLabels labels;
  final Animation<double>? t;

  // The picture is drawn on a board 304 wide, scaled to the width of the space
  // and pinned to its top. It is a Mercator map, 15.2 board units to a degree
  // of longitude, with 121.5°E 12.8°N at the middle of the board's width.
  static const _w = 304.0;
  static const _unitsPerDegree = 15.2;
  static const _lng0 = 121.5;
  static const _lat0 = 12.8;
  static const _x0 = 152.0;
  static const _y0 = 190.0;

  static double _mercator(double lat) =>
      math.log(math.tan(math.pi / 4 + lat * math.pi / 360));

  static Offset _at(double lng, double lat) => Offset(
        _x0 + (lng - _lng0) * _unitsPerDegree,
        _y0 -
            (_mercator(lat) - _mercator(_lat0)) *
                _unitsPerDegree *
                180 /
                math.pi,
      );

  // The cities, at their real coordinates.
  static const _manila = _City(121, 14.6, 22);
  static const _baguio = _City(120.59, 16.41, 13);
  static const _clark = _City(120.56, 15.18, 11);
  static const _cebu = _City(123.89, 10.32, 18);
  static const _davao = _City(125.46, 7.19, 16);

  static Offset _of(_City c) => _at(c.lng, c.lat);

  @override
  void paint(Canvas canvas, Size size) {
    final scale = size.width / _w;
    final height = size.height / scale;
    canvas
      ..clipRect(Offset.zero & size)
      ..scale(scale);
    _drawSea(canvas, height);
    _drawGrid(canvas, height);
    _drawLand(canvas);
    _drawRoutes(canvas);
    _drawCities(canvas);
    _drawPings(canvas);
    _drawLabels(canvas);
  }

  void _drawSea(Canvas canvas, double height) {
    final area = Rect.fromLTWH(0, 0, _w, height);
    canvas.drawRect(
      area,
      Paint()
        ..shader = const RadialGradient(
          center: Alignment(0, -0.9),
          radius: 1.2,
          colors: [
            ReelPalette.planetTop,
            ReelPalette.planetMid,
            ReelPalette.planetDeep,
            AppColors.canvas,
          ],
          stops: [0, 0.4, 0.72, 1],
        ).createShader(area),
    );
  }

  /// A faint grid every 5 degrees.
  void _drawGrid(Canvas canvas, double height) {
    final line = Paint()
      ..color = ReelPalette.planetLine.withValues(alpha: 0.09)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.6;
    for (var lat = 0; lat <= 25; lat += 5) {
      final y = _at(_lng0, lat.toDouble()).dy;
      canvas.drawLine(Offset(0, y), Offset(_w, y), line);
    }
    for (var lng = 110; lng <= 135; lng += 5) {
      final x = _at(lng.toDouble(), _lat0).dx;
      canvas.drawLine(Offset(x, 0), Offset(x, height), line);
    }
  }

  void _drawLand(Canvas canvas) {
    final fill = Paint()..color = ReelPalette.land;
    final coast = Paint()
      ..color = AppColors.roleTalent.withValues(alpha: 0.4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8
      ..strokeJoin = StrokeJoin.round;
    for (final island in reelCoast) {
      final path = Path();
      for (var i = 0; i + 1 < island.length; i += 2) {
        final p = _at(island[i], island[i + 1]);
        if (i == 0) {
          path.moveTo(p.dx, p.dy);
        } else {
          path.lineTo(p.dx, p.dy);
        }
      }
      path.close();
      canvas
        ..drawPath(path, fill)
        ..drawPath(path, coast);
    }
  }

  void _drawRoutes(Canvas canvas) {
    // The dashes flow along each route, a pattern length every 1.4 seconds.
    final shift = t == null ? 0.0 : _phase(t!.value, 17) * 7;
    final paint = Paint()
      ..color = AppColors.accent.withValues(alpha: 0.55)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..strokeCap = StrokeCap.round;
    final hub = _of(_manila);
    // Each route bows to one side: Baguio to the east, the others to the
    // north-east.
    for (final (city, bow) in [(_baguio, 0.2), (_cebu, -0.2), (_davao, -0.2)]) {
      final to = _of(city);
      final mid = Offset.lerp(hub, to, 0.5)!;
      final d = to - hub;
      final perp = Offset(-d.dy, d.dx);
      final control = mid + perp * bow;
      final route = Path()
        ..moveTo(hub.dx, hub.dy)
        ..quadraticBezierTo(control.dx, control.dy, to.dx, to.dy);
      _dashed(canvas, route, paint, on: 3, off: 4, shift: shift);
    }
  }

  void _dashed(
    Canvas canvas,
    Path path,
    Paint paint, {
    required double on,
    required double off,
    double shift = 0,
  }) {
    for (final metric in path.computeMetrics()) {
      for (var d = -shift; d < metric.length; d += on + off) {
        final end = math.min(d + on, metric.length);
        if (end <= 0) continue;
        canvas.drawPath(metric.extractPath(math.max(d, 0), end), paint);
      }
    }
  }

  void _drawCities(Canvas canvas) {
    final dot = Paint()..color = ReelPalette.cityDot;
    for (final city in [_baguio, _clark, _manila, _cebu, _davao]) {
      final at = _of(city);
      canvas
        ..drawCircle(
          at,
          city.glow,
          Paint()
            ..shader = RadialGradient(
              colors: [
                ReelPalette.cityGlow.withValues(alpha: 0.95),
                AppColors.accent.withValues(alpha: 0.38),
                AppColors.accent.withValues(alpha: 0),
              ],
              stops: const [0, 0.3, 1],
            ).createShader(Rect.fromCircle(center: at, radius: city.glow)),
        )
        ..drawCircle(at, city == _manila ? 3 : 2.3, dot);
    }
  }

  /// A ring opens up from each city and fades, like a signal going out.
  void _drawPings(Canvas canvas) {
    final clock = t;
    if (clock == null) return;
    var i = 0;
    for (final city in [_manila, _cebu, _davao, _baguio, _clark]) {
      final p = _phase(clock.value, 9, i++ * 0.2);
      canvas.drawCircle(
        _of(city),
        3.5 * (1 + 5 * p),
        Paint()
          ..color = AppColors.accent.withValues(alpha: 0.85 * (1 - p))
          ..style = PaintingStyle.stroke,
      );
    }
  }

  static double _phase(double t, int cycles, [double offset = 0]) =>
      (t * cycles + offset) % 1;

  void _drawLabels(Canvas canvas) {
    // Island groups, faint, centred on the middle of each.
    for (final (name, lng, lat) in [
      (labels.luzon, 122.3, 17.3),
      (labels.visayas, 121.9, 11.9),
      (labels.mindanao, 124.0, 8.3),
    ]) {
      _label(canvas, name, _at(lng, lat), anchor: 0.5, faint: true);
    }
    // Cities: the north-west ones read on the sea to their left, the rest to
    // their right.
    _label(
      canvas,
      labels.baguio,
      _of(_baguio) + const Offset(-9, 3),
      anchor: 1,
    );
    _label(canvas, labels.clark, _of(_clark) + const Offset(-9, 3), anchor: 1);
    _label(
      canvas,
      labels.manila,
      _of(_manila) + const Offset(-9, 12),
      anchor: 1,
      big: true,
    );
    _label(canvas, labels.cebu, _of(_cebu) + const Offset(9, 3));
    _label(canvas, labels.davao, _of(_davao) + const Offset(9, 3));
  }

  /// Upper-case label with a dark outline. Its baseline is at [at]; [anchor] is
  /// how much of its width sits to the left of [at] (0 starts there, 1 ends
  /// there, 0.5 is centred).
  void _label(
    Canvas canvas,
    String text,
    Offset at, {
    double anchor = 0,
    bool big = false,
    bool faint = false,
  }) {
    final base = AppTypography.label().copyWith(
      fontSize: faint ? 7.5 : (big ? 9.5 : 8.5),
      letterSpacing: faint ? 1.6 : (big ? 0.95 : 0.85),
    );
    TextPainter paint(TextStyle style) => TextPainter(
          text: TextSpan(text: text.toUpperCase(), style: style),
          textDirection: TextDirection.ltr,
        )..layout();
    final outline = paint(
      base.copyWith(
        foreground: Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3
          ..color = ReelPalette.mapLabelEdge,
      ),
    );
    final fill = paint(
      base.copyWith(
        color: faint
            ? ReelPalette.regionLabel
            : (big ? ReelPalette.cityDot : ReelPalette.mapLabel),
      ),
    );
    final baseline = fill.computeDistanceToActualBaseline(
      ui.TextBaseline.alphabetic,
    );
    final origin = Offset(at.dx - fill.width * anchor, at.dy - baseline);
    if (!faint) outline.paint(canvas, origin);
    fill.paint(canvas, origin);
  }

  @override
  bool shouldRepaint(_NightMapPainter old) =>
      old.labels != labels || old.t != t;
}
