import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_template/core/utils/context_extensions.dart';
import 'package:flutter_template/features/rewards/data/rewards_repository.dart';
import 'package:flutter_template/features/rewards/domain/wallet_rank.dart';
import 'package:flutter_template/shared/widgets/coins_chip.dart';
import 'package:flutter_template/theme/tokens/colors.dart';
import 'package:flutter_template/theme/tokens/typography.dart';

/// How a Foxer is doing in one role: the rank name and level of its XP
/// [path] ("Veteran · Level 12"), and the Coins chip, which opens the Wallet.
/// It takes no room until the server has answered, and nothing shows if it
/// fails, as with [CoinsChip].
class RoleProgress extends ConsumerWidget {
  const RoleProgress({required this.path, super.key});

  /// The XP path as the API names it (`venueFoxer`, `eventFoxer`, ...).
  final String path;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final wallet = ref.watch(walletForPathProvider(path)).value;
    if (wallet == null) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Row(
        children: [
          Expanded(
            child: wallet.hasRank
                ? Text(
                    context.l10n.rewardsRankLevel(wallet.rank, wallet.level),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.display(
                      size: 14,
                      color: AppColors.textSecondary,
                    ),
                  )
                : const SizedBox.shrink(),
          ),
          CoinsChip(path: path),
        ],
      ),
    );
  }
}
