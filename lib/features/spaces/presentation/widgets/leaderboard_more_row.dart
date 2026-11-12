import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_template/core/utils/context_extensions.dart';
import 'package:flutter_template/features/auth/presentation/controllers/auth_controller.dart';
import 'package:flutter_template/features/spaces/domain/app_space.dart';
import 'package:flutter_template/features/spaces/presentation/widgets/more_row.dart';
import 'package:flutter_template/routes/route_names.dart';
import 'package:go_router/go_router.dart';

/// The Leaderboard row of a space's More tab. It opens the board on the role
/// this [space] works on; an Organizer, who has no board of their own, lands on
/// Events.
class LeaderboardMoreRow extends ConsumerWidget {
  const LeaderboardMoreRow({
    required this.space,
    this.compact = false,
    super.key,
  });

  final AppSpace space;
  final bool compact;

  /// The leaderboard role for a space and the roles the person holds.
  static String roleFor(AppSpace space, List<String> roles) => switch (space) {
        AppSpace.venue => 'venue',
        AppSpace.gear || AppSpace.services => 'providers',
        AppSpace.event || AppSpace.organizer || AppSpace.citizen => 'event',
      };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final roles = ref.watch(authControllerProvider).user?.roleType ?? const [];
    return MoreRow(
      icon: Icons.emoji_events_outlined,
      title: context.l10n.leaderboardTitle,
      compact: compact,
      onTap: () => context.push(
        RouteNames.leaderboardFor(roleFor(space, roles)),
      ),
    );
  }
}
