import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_template/core/utils/context_extensions.dart';
import 'package:flutter_template/features/auth/presentation/controllers/auth_controller.dart';
import 'package:flutter_template/features/spaces/domain/app_space.dart';
import 'package:flutter_template/shared/widgets/role_progress.dart';
import 'package:flutter_template/theme/tokens/typography.dart';

/// The top of a space's Overview: a greeting by first name. Which role this
/// is shows in the space switcher, and switching lives in More.
class OverviewGreeting extends ConsumerWidget {
  const OverviewGreeting({required this.space, super.key});

  /// The space this Overview belongs to, whose role the progress line shows.
  final AppSpace space;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final user = ref.watch(authControllerProvider).user;
    final name = user?.name.trim() ?? '';
    final first = name.isEmpty ? '' : name.split(RegExp(r'\s+')).first;
    final hour = DateTime.now().hour;
    final greeting = first.isEmpty
        ? l10n.overviewGreetingNoName
        : hour < 12
            ? l10n.overviewGreetingMorning(first)
            : hour < 18
                ? l10n.overviewGreetingAfternoon(first)
                : l10n.overviewGreetingEvening(first);

    return Padding(
      padding: const EdgeInsets.only(top: 4, bottom: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            greeting,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.display(size: 22),
          ),
          // Rank, level and Coins for this role; nothing until known.
          RoleProgress(path: space.xpPath(user?.roleType ?? const [])),
        ],
      ),
    );
  }
}
