import 'package:flutter/material.dart';
import 'package:flutter_template/core/utils/context_extensions.dart';
import 'package:flutter_template/routes/route_names.dart';
import 'package:flutter_template/shared/widgets/reward_tile.dart';

/// "Achievements", a tile that opens the achievements screen.
/// For the citizen Passport's rewards grid.
class AchievementsRow extends StatelessWidget {
  const AchievementsRow({super.key});

  @override
  Widget build(BuildContext context) => RewardTile(
        icon: Icons.workspace_premium_outlined,
        title: context.l10n.achievementsTitle,
        route: RouteNames.achievements,
      );
}
