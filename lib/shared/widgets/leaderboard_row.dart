import 'package:flutter/material.dart';
import 'package:flutter_template/core/utils/context_extensions.dart';
import 'package:flutter_template/routes/route_names.dart';
import 'package:flutter_template/shared/widgets/reward_tile.dart';

/// "Leaderboard", a tile that opens the Foxer leaderboard.
/// For the citizen Passport's rewards grid.
class LeaderboardRow extends StatelessWidget {
  const LeaderboardRow({super.key});

  @override
  Widget build(BuildContext context) => RewardTile(
        icon: Icons.emoji_events_outlined,
        title: context.l10n.leaderboardTitle,
        route: RouteNames.leaderboard,
      );
}
