import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_template/core/utils/context_extensions.dart';
import 'package:flutter_template/features/auth/presentation/controllers/auth_controller.dart';
import 'package:flutter_template/features/rewards/data/rewards_repository.dart';
import 'package:flutter_template/features/rewards/domain/wallet_rank.dart';
import 'package:flutter_template/features/spaces/domain/app_space.dart';
import 'package:flutter_template/features/spaces/presentation/widgets/more_row.dart';
import 'package:flutter_template/routes/route_names.dart';
import 'package:flutter_template/shared/widgets/rank_badge.dart';
import 'package:flutter_template/theme/tokens/typography.dart';
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
    final wallet = ref.watch(walletForPathProvider(space.xpPath(roles))).value;
    return MoreRow(
      icon: Icons.badge_outlined,
      title: context.l10n.passport,
      compact: compact,
      // The rank and level for this role, once the server has named them.
      subtitle: wallet != null && wallet.hasRank && !compact
          ? Row(
              children: [
                RankBadge.forLevel(wallet.level, size: 18),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    context.l10n.rewardsRankLevel(wallet.rank, wallet.level),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.body(),
                  ),
                ),
              ],
            )
          : null,
      onTap: () => context.push(
        RouteNames.foxerPassportFor(space.xpPath(roles)),
      ),
    );
  }
}
