import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_template/core/utils/context_extensions.dart';
import 'package:flutter_template/features/gamification/domain/milestones.dart';
import 'package:flutter_template/features/gamification/presentation/widgets/milestone_badge.dart';
import 'package:flutter_template/shared/widgets/brand_logo.dart';
import 'package:flutter_template/theme/tokens/colors.dart';
import 'package:flutter_template/theme/tokens/radius.dart';
import 'package:flutter_template/theme/tokens/typography.dart';

/// A ring that fills clockwise from the top, with [child] in the middle.
/// [progress] is 0 to 1.
class ProgressRing extends StatelessWidget {
  const ProgressRing({
    required this.progress,
    required this.size,
    required this.child,
    this.strokeWidth = 8,
    super.key,
  });

  final double progress;
  final double size;
  final double strokeWidth;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _RingPainter(progress.clamp(0, 1), strokeWidth),
        child: Center(child: child),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  _RingPainter(this.progress, this.strokeWidth);

  final double progress;
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final arcRect = rect.deflate(strokeWidth / 2);
    final base = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..color = AppColors.border;
    canvas.drawArc(arcRect, 0, math.pi * 2, false, base);
    if (progress <= 0) return;
    final arc = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = strokeWidth
      ..color = AppColors.accent;
    canvas.drawArc(arcRect, -math.pi / 2, math.pi * 2 * progress, false, arc);
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
      old.progress != progress || old.strokeWidth != strokeWidth;
}

/// The fox mark on a white disc: the emblem of a track.
class FoxEmblem extends StatelessWidget {
  const FoxEmblem({required this.size, super.key});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.textPrimary,
      ),
      child: FoxLogo(size: size * 0.62, color: AppColors.canvas),
    );
  }
}

/// The tiers of a track as small dots on a line: a check when reached, an
/// accent ring on the next one, grey when locked, each showing its target.
class TierDots extends StatelessWidget {
  const TierDots({required this.milestone, super.key});

  final Milestone milestone;

  @override
  Widget build(BuildContext context) {
    final tiers = milestone.tiers;
    return Row(
      children: [
        for (final (i, t) in tiers.indexed) ...[
          if (i > 0)
            Expanded(
              child: Container(
                height: 2,
                color: tiers[i - 1].isReached
                    ? AppColors.textPrimary
                    : AppColors.border,
              ),
            ),
          _dot(t),
        ],
      ],
    );
  }

  Widget _dot(MilestoneTier t) {
    final isNext = t.tier == milestone.nextTier;
    return Container(
      width: 28,
      height: 28,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: t.isReached ? AppColors.textPrimary : AppColors.surface,
        border: Border.all(
          color: isNext ? AppColors.accent : AppColors.borderStrong,
          width: isNext ? 2 : 1,
        ),
      ),
      child: t.isReached
          ? const Icon(Icons.check_rounded, size: 16, color: AppColors.canvas)
          : Text(
              '${t.target}',
              maxLines: 1,
              style: AppTypography.body(
                size: 10,
                color: isNext ? AppColors.textPrimary : AppColors.textMuted,
              ),
            ),
    );
  }
}

/// The journey's tier nodes, each a [MilestoneBadge] whose shape is its
/// rarity: filled when reached, outlined when next, grey when locked. Every
/// node is a button that picks that tier; [selected] is the one being looked
/// at.
class TierBadgeRow extends StatelessWidget {
  const TierBadgeRow({
    required this.milestone,
    required this.selected,
    required this.onTap,
    super.key,
  });

  final Milestone milestone;
  final int selected;
  final ValueChanged<int> onTap;

  static const double _size = 52;

  @override
  Widget build(BuildContext context) {
    final tiers = milestone.tiers;
    return Row(
      children: [
        for (final (i, t) in tiers.indexed) ...[
          if (i > 0)
            Expanded(
              child: Container(
                height: 3,
                color: tiers[i - 1].isReached
                    ? AppColors.textPrimary
                    : AppColors.border,
              ),
            ),
          Semantics(
            button: true,
            selected: selected == i,
            label: context.l10n.milestonesTierPosition(t.tier, tiers.length),
            child: InkResponse(
              onTap: () => onTap(i),
              radius: _size / 2,
              child: _badge(t, isSelected: i == selected),
            ),
          ),
        ],
      ],
    );
  }

  Widget _badge(MilestoneTier t, {required bool isSelected}) {
    final isNext = t.tier == milestone.nextTier;
    // The one being looked at gets a white halo, so it is clear even when it
    // is not the next tier.
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: isSelected ? AppColors.textPrimary : AppColors.clear,
        ),
      ),
      child: MilestoneBadge(
        rarity: t.tier - 1,
        state: t.isReached
            ? MilestoneBadgeState.earned
            : isNext
                ? MilestoneBadgeState.next
                : MilestoneBadgeState.locked,
      ),
    );
  }
}

/// A small lime pill: "+25 Tokens".
class RewardChip extends StatelessWidget {
  const RewardChip({required this.label, this.accent = true, super.key});

  final String label;
  final bool accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: accent ? AppColors.accentTintBg : AppColors.surfaceRaised,
        borderRadius: AppRadius.brPill,
        border: Border.all(
          color: accent ? AppColors.accentTintBorder : AppColors.borderStrong,
        ),
      ),
      child: Text(
        label,
        style: AppTypography.body(
          size: 12,
          color: accent ? AppColors.accent : AppColors.textPrimary,
        ),
      ),
    );
  }
}
