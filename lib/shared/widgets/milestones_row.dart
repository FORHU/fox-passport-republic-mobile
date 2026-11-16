import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_template/core/utils/context_extensions.dart';
import 'package:flutter_template/features/gamification/data/milestones_repository.dart';
import 'package:flutter_template/features/gamification/presentation/milestone_labels.dart';
import 'package:flutter_template/routes/route_names.dart';
import 'package:flutter_template/theme/tokens/colors.dart';
import 'package:flutter_template/theme/tokens/radius.dart';
import 'package:flutter_template/theme/tokens/typography.dart';
import 'package:go_router/go_router.dart';

/// "Milestones", a row that opens the milestones screen, with the closest
/// reward under it ("2 more bookings") once that is known. For the citizen
/// Passport, under the Leaderboard row. The hint is left out while loading and
/// when it fails: the row still opens the screen.
class MilestonesRow extends ConsumerWidget {
  const MilestonesRow({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final closest = ref.watch(milestonesProvider).value?.closest;
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: InkWell(
        borderRadius: AppRadius.brMd,
        onTap: () => context.push(RouteNames.milestones),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          decoration: BoxDecoration(
            color: AppColors.surfaceRaised,
            borderRadius: AppRadius.brMd,
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              const Icon(
                Icons.flag_outlined,
                size: 18,
                color: AppColors.textPrimary,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.l10n.milestonesTitle,
                      style: AppTypography.display(size: 14),
                    ),
                    if (closest != null)
                      Text(
                        milestoneMoreLabel(context, closest, closest.remaining),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.body(
                          size: 12,
                          color: AppColors.accent,
                        ),
                      ),
                  ],
                ),
              ),
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
