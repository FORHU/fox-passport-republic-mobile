import 'package:flutter/material.dart';
import 'package:flutter_template/theme/tokens/colors.dart';

/// A ticket: [top] and [bottom] halves split by a dashed perforation with a
/// half-circle punched out of each side.
///
/// The punches are drawn in [notchColor], so it has to match whatever sits
/// behind the card (the app canvas by default).
class TicketPanel extends StatelessWidget {
  const TicketPanel({
    required this.top,
    required this.bottom,
    this.color = AppColors.surface,
    this.borderColor,
    this.dashColor,
    this.notchColor = AppColors.canvas,
    this.radius = 24,
    super.key,
  });

  final Widget top;
  final Widget bottom;
  final Color color;
  final Color? borderColor;
  final Color? dashColor;
  final Color notchColor;
  final double radius;

  static const double _notch = 22;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(radius),
        border: borderColor == null ? null : Border.all(color: borderColor!),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          top,
          SizedBox(
            height: _notch,
            child: Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.center,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: _notch),
                  child: CustomPaint(
                    size: const Size(double.infinity, 1),
                    painter: _DashedLine(dashColor ?? AppColors.borderStrong),
                  ),
                ),
                Positioned(
                  left: -_notch / 2,
                  child: _Notch(color: notchColor, border: borderColor),
                ),
                Positioned(
                  right: -_notch / 2,
                  child: _Notch(color: notchColor, border: borderColor),
                ),
              ],
            ),
          ),
          bottom,
        ],
      ),
    );
  }
}

class _Notch extends StatelessWidget {
  const _Notch({required this.color, this.border});

  final Color color;
  final Color? border;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: TicketPanel._notch,
      height: TicketPanel._notch,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: border == null ? null : Border.all(color: border!),
      ),
    );
  }
}

class _DashedLine extends CustomPainter {
  const _DashedLine(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.5;
    const dash = 6.0;
    const gap = 5.0;
    var x = 0.0;
    while (x < size.width) {
      canvas.drawLine(
        Offset(x, 0),
        Offset((x + dash).clamp(0, size.width), 0),
        paint,
      );
      x += dash + gap;
    }
  }

  @override
  bool shouldRepaint(_DashedLine old) => old.color != color;
}
