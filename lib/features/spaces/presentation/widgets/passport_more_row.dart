import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_template/core/utils/context_extensions.dart';
import 'package:flutter_template/features/auth/presentation/controllers/auth_controller.dart';
import 'package:flutter_template/features/spaces/domain/app_space.dart';
import 'package:flutter_template/features/spaces/presentation/widgets/more_row.dart';
import 'package:flutter_template/routes/route_names.dart';
import 'package:flutter_template/shared/widgets/role_progress.dart';
import 'package:go_router/go_router.dart';

/// The Passport row of a space's More tab: it opens the Foxer's Passport for
/// the role this [space] works on.
class PassportMoreRow extends ConsumerWidget {
  const PassportMoreRow({
    required this.space,
    this.compact = false,
    super.key,
  });

  final AppSpace space;
  final bool compact;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final roles = ref.watch(authControllerProvider).user?.roleType ?? const [];
    return MoreRow(
      icon: Icons.badge_outlined,
      title: context.l10n.passport,
      compact: compact,
      // The rank and level for this role, once the server has named them.
      subtitle: compact ? null : RoleRankLine(path: space.xpPath(roles)),
      onTap: () => context.push(
        RouteNames.foxerPassportFor(space.xpPath(roles)),
      ),
    );
  }
}
