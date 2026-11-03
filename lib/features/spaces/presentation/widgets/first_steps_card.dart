import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_template/core/utils/context_extensions.dart';
import 'package:flutter_template/theme/tokens/colors.dart';
import 'package:flutter_template/theme/tokens/radius.dart';
import 'package:flutter_template/theme/tokens/typography.dart';

/// One step of a role's getting-started list.
class FirstStep {
  const FirstStep({required this.label, required this.done, this.onTap});

  final String label;
  final bool done;

  /// Where the step is done; null for a step with nowhere to go.
  final VoidCallback? onTap;
}

/// What a newly approved Foxer does first, with a ring showing how far along
/// they are. Each step ticks itself off from real data, and the whole card
/// disappears once every step is done.
class FirstStepsCard extends StatelessWidget {
  const FirstStepsCard({required this.steps, super.key});

  final List<FirstStep> steps;

  @override
  Widget build(BuildContext context) {
    final done = steps.where((s) => s.done).length;
    if (steps.isEmpty || done == steps.length) return const SizedBox.shrink();
    final l10n = context.l10n;
    final next = steps.indexWhere((s) => !s.done);

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.brCard,
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                ProgressRing(value: done / steps.length),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.firstStepsTitle,
                        style: AppTypography.display(size: 17),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        l10n.firstStepsDone(done, steps.length),
                        style: AppTypography.body(size: 13),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          for (var i = 0; i < steps.length; i++) ...[
            const Divider(height: 1, color: AppColors.border),
            _StepRow(
              number: i + 1,
              step: steps[i],
              isNext: i == next,
            ),
          ],
        ],
      ),
    );
  }
}

class _StepRow extends StatelessWidget {
  const _StepRow({
    required this.number,
    required this.step,
    required this.isNext,
  });

  final int number;
  final FirstStep step;
  final bool isNext;

  @override
  Widget build(BuildContext context) {
    final tappable = !step.done && step.onTap != null;
    return InkWell(
      onTap: tappable ? step.onTap : null,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 52),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          child: Row(
            children: [
              Container(
                width: 26,
                height: 26,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: step.done ? AppColors.accent : AppColors.clear,
                  border: Border.all(
                    color:
                        step.done ? AppColors.accent : AppColors.borderStrong,
                    width: 1.5,
                  ),
                ),
                child: step.done
                    ? const Icon(
                        Icons.check_rounded,
                        size: 16,
                        color: AppColors.onAccent,
                      )
                    : Text(
                        '$number',
                        style: AppTypography.label(),
                      ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  step.label,
                  style: AppTypography.body(
                    color: step.done
                        ? AppColors.textSecondary
                        : isNext
                            ? AppColors.textPrimary
                            : AppColors.textMuted,
                  ),
                ),
              ),
              if (tappable)
                const Icon(
                  Icons.chevron_right_rounded,
                  color: AppColors.textMuted,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A ring that fills to [value] (0 to 1) once when it appears, with the
/// percentage counting up in the middle. With reduced motion on it shows the
/// final state straight away.
class ProgressRing extends StatefulWidget {
  const ProgressRing({required this.value, this.size = 64, super.key});

  final double value;
  final double size;

  @override
  State<ProgressRing> createState() => _ProgressRingState();
}

class _ProgressRingState extends State<ProgressRing>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1200),
  );
  late final Animation<double> _eased = CurvedAnimation(
    parent: _controller,
    curve: Curves.easeOutCubic,
  );
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    if (MediaQuery.disableAnimationsOf(context)) {
      _controller.value = 1;
    } else {
      _controller.forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final target = widget.value.clamp(0.0, 1.0);
    return Semantics(
      label: '${(target * 100).round()}%',
      child: ExcludeSemantics(
        child: SizedBox.square(
          dimension: widget.size,
          child: AnimatedBuilder(
            animation: _eased,
            builder: (context, _) {
              final shown = target * _eased.value;
              return CustomPaint(
                painter: _RingPainter(shown),
                child: Center(
                  child: Text(
                    '${(shown * 100).round()}%',
                    style: AppTypography.display(size: widget.size * 0.24),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  _RingPainter(this.value);

  final double value;

  @override
  void paint(Canvas canvas, Size size) {
    const stroke = 7.0;
    final rect = Offset.zero & size;
    final arc = rect.deflate(stroke / 2);
    final track = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..color = AppColors.surfaceRaised;
    final fill = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round
      ..color = AppColors.accent;
    canvas
      ..drawArc(arc, 0, 2 * math.pi, false, track)
      ..drawArc(arc, -math.pi / 2, 2 * math.pi * value, false, fill);
  }

  @override
  bool shouldRepaint(_RingPainter old) => old.value != value;
}
