import 'package:flutter/material.dart';
import 'package:flutter_template/core/utils/context_extensions.dart';
import 'package:flutter_template/routes/route_names.dart';
import 'package:flutter_template/shared/widgets/reward_tile.dart';

/// "Challenges", a tile that opens the booking challenges.
/// For the citizen Passport's rewards grid.
class ChallengesRow extends StatelessWidget {
  const ChallengesRow({super.key});

  @override
  Widget build(BuildContext context) => RewardTile(
        icon: Icons.bolt_outlined,
        title: context.l10n.challengesTitle,
        route: RouteNames.challenges,
      );
}
