import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_template/core/utils/context_extensions.dart';
import 'package:flutter_template/theme/tokens/colors.dart';
import 'package:flutter_template/theme/tokens/radius.dart';
import 'package:flutter_template/theme/tokens/typography.dart';

/// Total earnings with how they moved and, once there are enough payouts, a
/// bar for each of the last weeks with the latest in lime. Opens Earnings.
class EarningsCard extends StatelessWidget {
  const EarningsCard({
    required this.paid,
    required this.pending,
    required this.onTap,
    this.change,
    this.weeks,
    super.key,
  });

  /// The amounts, already formatted.
  final String paid;
  final String pending;

  /// Percent against last month; null hides it.
  final double? change;

  /// Paid per week, oldest first; null for too few payouts to chart.
  final List<num>? weeks;

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final change = this.change;
    final weeks = this.weeks;
    return Material(
      color: AppColors.surface,
      borderRadius: AppRadius.brCard,
      child: InkWell(
        borderRadius: AppRadius.brCard,
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: AppRadius.brCard,
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      l10n.earningsTotal,
                      style: AppTypography.body(size: 13),
                    ),
                  ),
                  const Icon(
                    Icons.chevron_right_rounded,
                    color: AppColors.textMuted,
                  ),
                ],
              ),
              const SizedBox(height: 2),
              Text(paid, style: AppTypography.display(size: 28)),
              const SizedBox(height: 4),
              Wrap(
                spacing: 10,
                children: [
                  if (change != null) _Change(change),
                  Text(
                    l10n.earningsPendingAmount(pending),
                    style: AppTypography.body(size: 12),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              if (weeks == null)
                Text(
                  l10n.earningsChartLater,
                  style: AppTypography.body(color: AppColors.textMuted),
                )
              else ...[
                _Bars(weeks),
                const SizedBox(height: 6),
                Text(
                  l10n.earningsLastWeeks(weeks.length),
                  style: AppTypography.label(),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _Change extends StatelessWidget {
  const _Change(this.percent);

  final double percent;

  @override
  Widget build(BuildContext context) {
    final up = percent >= 0;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          up ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded,
          size: 14,
          color: up ? AppColors.success : AppColors.error,
        ),
        const SizedBox(width: 2),
        Text(
          context.l10n.earningsChange(percent.abs().round()),
          style: AppTypography.body(
            size: 12,
            color: up ? AppColors.success : AppColors.error,
          ),
        ),
      ],
    );
  }
}

class _Bars extends StatelessWidget {
  const _Bars(this.values);

  final List<num> values;

  @override
  Widget build(BuildContext context) {
    final top = values.fold<num>(0, math.max);
    return SizedBox(
      height: 72,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          for (final (i, v) in values.indexed) ...[
            if (i > 0) const SizedBox(width: 6),
            Expanded(
              child: Container(
                // A week with nothing still shows a stub, so the row reads as
                // a chart.
                height: top == 0 ? 4 : math.max(4, 72 * (v / top)),
                decoration: BoxDecoration(
                  color: i == values.length - 1
                      ? AppColors.accent
                      : AppColors.borderStrong,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
