import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_template/core/utils/context_extensions.dart';
import 'package:flutter_template/theme/tokens/colors.dart';
import 'package:flutter_template/theme/tokens/radius.dart';
import 'package:flutter_template/theme/tokens/typography.dart';

/// The things a tour can point at: a stable key per name, so a screen marks
/// the part it wants shown ([tourTarget]) and the tour finds it by name.
class TourKeys {
  const TourKeys._();

  static final _keys = <String, GlobalKey>{};

  static GlobalKey of(String id) =>
      _keys.putIfAbsent(id, () => GlobalKey(debugLabel: 'tour-$id'));

  /// The key of the [index]th tab of a space's bottom bar.
  static GlobalKey tab(int index) => of('tab-$index');
}

/// Marks [child] as something the tour can zoom in on, under [id].
Widget tourTarget(String id, Widget child) =>
    KeyedSubtree(key: TourKeys.of(id), child: child);

/// One card of a Foxer's first-time tour.
class TourStep {
  const TourStep({
    required this.icon,
    required this.title,
    required this.body,
    this.target,
    this.optional = false,
  });

  final IconData icon;
  final String title;
  final String body;

  /// What it points at (see [TourKeys]); a card on its own when null, or when
  /// the target is not on screen.
  final String? target;

  /// Left out when its [target] is not on screen, such as the getting-started
  /// card of a Foxer who has finished it.
  final bool optional;
}

/// Shows [steps] one card at a time, the screen dimmed except for the part
/// each card is about, and completes when the person finishes or skips.
Future<void> showSpaceTour(BuildContext context, List<TourStep> steps) {
  final shown = [
    for (final s in steps)
      if (!s.optional || TourKeys.of(s.target!).currentContext != null) s,
  ];
  if (shown.isEmpty) return Future.value();
  return showGeneralDialog<void>(
    context: context,
    barrierLabel: context.l10n.tourSkip,
    barrierColor: AppColors.clear,
    transitionDuration: const Duration(milliseconds: 150),
    pageBuilder: (_, __, ___) => _TourCard(steps: shown),
  );
}

class _TourCard extends StatefulWidget {
  const _TourCard({required this.steps});

  final List<TourStep> steps;

  @override
  State<_TourCard> createState() => _TourCardState();
}

class _TourCardState extends State<_TourCard> {
  int _index = 0;

  /// Where the current step's target is on screen, once found.
  Rect? _hole;

  @override
  void initState() {
    super.initState();
    unawaited(_locate());
  }

  /// Scrolls the target into view if it is not, then measures it.
  Future<void> _locate() async {
    final index = _index;
    final id = widget.steps[index].target;
    final target = id == null ? null : TourKeys.of(id).currentContext;
    Rect? hole;
    if (target != null && target.mounted) {
      if (Scrollable.maybeOf(target) != null) {
        await Scrollable.ensureVisible(
          target,
          duration: const Duration(milliseconds: 250),
          alignment: 0.3,
        );
      }
      final box = target.mounted ? target.findRenderObject() : null;
      if (box is RenderBox && box.attached) {
        hole = box.localToGlobal(Offset.zero) & box.size;
      }
    }
    if (mounted && index == _index) setState(() => _hole = hole);
  }

  void _go(int index) {
    setState(() {
      _index = index;
      _hole = null;
    });
    unawaited(_locate());
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final steps = widget.steps;
    final step = steps[_index];
    final last = _index == steps.length - 1;
    final hole = _hole?.inflate(6);
    final size = MediaQuery.sizeOf(context);
    // The card goes on the side of the screen the target is not on.
    final cardAtTop = hole != null && hole.center.dy > size.height / 2;

    return Stack(
      children: [
        Positioned.fill(
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () {},
            child: CustomPaint(painter: _SpotlightPainter(hole)),
          ),
        ),
        SafeArea(
          child: Align(
            alignment: cardAtTop ? Alignment.topCenter : Alignment.bottomCenter,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Material(
                color: AppColors.surface,
                borderRadius: AppRadius.brCard,
                child: Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    borderRadius: AppRadius.brCard,
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(step.icon, color: AppColors.accent, size: 28),
                          const Spacer(),
                          Text(
                            l10n.tourStepOf(_index + 1, steps.length),
                            style: AppTypography.label(),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        step.title,
                        style: AppTypography.display(size: 20),
                      ),
                      const SizedBox(height: 6),
                      Text(step.body, style: AppTypography.body()),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          if (!last)
                            TextButton(
                              onPressed: () => Navigator.of(context).pop(),
                              style: TextButton.styleFrom(
                                minimumSize: const Size(44, 44),
                              ),
                              child: Text(l10n.tourSkip),
                            ),
                          const Spacer(),
                          FilledButton(
                            onPressed: last
                                ? () => Navigator.of(context).pop()
                                : () => _go(_index + 1),
                            child: Text(last ? l10n.tourDone : l10n.tourNext),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// The dimmed screen with a clear, outlined window over [hole].
class _SpotlightPainter extends CustomPainter {
  const _SpotlightPainter(this.hole);

  final Rect? hole;

  @override
  void paint(Canvas canvas, Size size) {
    final dim = Paint()..color = AppColors.canvas.withValues(alpha: 0.82);
    final screen = Path()..addRect(Offset.zero & size);
    final hole = this.hole;
    if (hole == null) {
      canvas.drawPath(screen, dim);
      return;
    }
    final window = RRect.fromRectAndRadius(hole, const Radius.circular(16));
    canvas
      ..drawPath(
        Path.combine(
          PathOperation.difference,
          screen,
          Path()..addRRect(window),
        ),
        dim,
      )
      ..drawRRect(
        window,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2
          ..color = AppColors.accent,
      );
  }

  @override
  bool shouldRepaint(_SpotlightPainter old) => old.hole != hole;
}
