import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_template/core/utils/context_extensions.dart';
import 'package:flutter_template/features/gamification/data/milestones_repository.dart';
import 'package:flutter_template/features/gamification/presentation/milestone_labels.dart';
import 'package:flutter_template/routes/route_names.dart';
import 'package:flutter_template/shared/widgets/reward_tile.dart';

/// "Milestones", a tile that opens the milestones screen, with the closest
/// reward under it ("2 more bookings") once that is known. For the citizen
/// Passport's rewards grid. The hint is left out while loading and when it
/// fails: the tile still opens the screen.
class MilestonesRow extends ConsumerWidget {
  const MilestonesRow({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final closest = ref.watch(milestonesProvider).value?.closest;
    return RewardTile(
      icon: Icons.flag_outlined,
      title: context.l10n.milestonesTitle,
      route: RouteNames.milestones,
      hint: closest == null
          ? null
          : milestoneMoreLabel(context, closest, closest.remaining),
    );
  }
}
