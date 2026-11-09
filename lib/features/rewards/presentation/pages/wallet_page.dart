import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_template/core/utils/context_extensions.dart';
import 'package:flutter_template/features/rewards/data/rewards_repository.dart';
import 'package:flutter_template/features/rewards/domain/wallet.dart';
import 'package:flutter_template/features/rewards/domain/wallet_rank.dart';
import 'package:flutter_template/features/rewards/presentation/widgets/wallet_entry_title.dart';
import 'package:flutter_template/routes/route_names.dart';
import 'package:flutter_template/shared/widgets/app_state_view.dart';
import 'package:flutter_template/shared/widgets/buttons.dart';
import 'package:flutter_template/shared/widgets/coins_chip.dart';
import 'package:flutter_template/shared/widgets/rank_badge.dart';
import 'package:flutter_template/theme/tokens/colors.dart';
import 'package:flutter_template/theme/tokens/radius.dart';
import 'package:flutter_template/theme/tokens/typography.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

/// Your Coins: what you can spend, what is waiting, and what changed them.
class WalletPage extends ConsumerWidget {
  const WalletPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final wallet = ref.watch(walletProvider);

    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: AppBar(
        backgroundColor: AppColors.canvas,
        title: Text(
          l10n.rewardsWalletTitle,
          style: AppTypography.display(size: 22),
        ),
      ),
      body: wallet.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.accent),
        ),
        error: (_, __) => AppStateView(
          kind: AppStateKind.error,
          title: l10n.apiLoadFailed,
          actionLabel: l10n.retry,
          onAction: () => ref.invalidate(walletProvider),
        ),
        data: (summary) => RefreshIndicator(
          color: AppColors.accent,
          onRefresh: () => ref.refresh(walletProvider.future),
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
            children: [
              _BalanceCard(summary: summary),
              const SizedBox(height: 20),
              if (summary.history.isEmpty)
                _Empty(
                  onFind: () => context.push(RouteNames.search),
                )
              else ...[
                Text(
                  l10n.rewardsHistory,
                  style: AppTypography.display(size: 18),
                ),
                const SizedBox(height: 8),
                for (final entry in summary.history) _HistoryRow(entry: entry),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _BalanceCard extends StatelessWidget {
  const _BalanceCard({required this.summary});

  final WalletSummary summary;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final locale = Localizations.localeOf(context).toString();
    final format = NumberFormat.decimalPattern(locale);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.brLg,
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.rewardsBalanceLabel.toUpperCase(),
            style: AppTypography.label(),
          ),
          const SizedBox(height: 6),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              const Icon(coinsIcon, size: 28),
              const SizedBox(width: 8),
              Text(
                format.format(summary.coins),
                style: AppTypography.display(size: 40),
              ),
              const SizedBox(width: 6),
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Text(
                  l10n.rewardsCoins,
                  style: AppTypography.body(),
                ),
              ),
            ],
          ),
          if (summary.hasRank) ...[
            const SizedBox(height: 4),
            Row(
              children: [
                RankBadge.forLevel(summary.level),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    l10n.rewardsRankLevel(summary.rank, summary.level),
                    style: AppTypography.display(
                      size: 13,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
          ],
          if (summary.pendingCoins > 0) ...[
            const SizedBox(height: 8),
            Text(
              l10n.rewardsPending(format.format(summary.pendingCoins)),
              style: AppTypography.display(
                size: 13,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              l10n.rewardsPendingHint,
              style: AppTypography.body(
                size: 12,
                color: AppColors.textMuted,
              ),
            ),
          ],
          const SizedBox(height: 16),
          PrimaryButton(
            label: l10n.rewardsRedeemRewards,
            onPressed: () => context.push(RouteNames.rewards),
          ),
        ],
      ),
    );
  }
}

class _Empty extends StatelessWidget {
  const _Empty({required this.onFind});

  final VoidCallback onFind;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Column(
      children: [
        const SizedBox(height: 24),
        const Icon(coinsIcon, size: 44, color: AppColors.textMuted),
        const SizedBox(height: 12),
        Text(
          l10n.rewardsEmptyTitle,
          style: AppTypography.display(size: 18),
        ),
        const SizedBox(height: 6),
        Text(
          l10n.rewardsEmptyBody,
          textAlign: TextAlign.center,
          style: AppTypography.body(color: AppColors.textMuted),
        ),
        const SizedBox(height: 16),
        SecondaryButton(label: l10n.rewardsFindEvent, onPressed: onFind),
      ],
    );
  }
}

class _HistoryRow extends StatelessWidget {
  const _HistoryRow({required this.entry});

  final WalletEntry entry;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final locale = Localizations.localeOf(context).toString();
    final earned = entry.coinsDelta > 0;
    final number = NumberFormat.decimalPattern(locale);
    final amount = entry.coinsDelta == 0
        ? ''
        : '${earned ? '+' : '−'}${number.format(entry.coinsDelta.abs())}';
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: AppColors.surfaceRaised,
              borderRadius: AppRadius.brPill,
            ),
            child: Icon(
              earned ? Icons.north_east_rounded : Icons.south_west_rounded,
              size: 16,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  walletEntryTitle(l10n, entry),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.display(size: 14),
                ),
                const SizedBox(height: 2),
                Text(
                  DateFormat.yMMMd(locale).format(entry.createdAt),
                  style: AppTypography.body(
                    size: 12,
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
          Text(
            amount,
            style: AppTypography.display(
              size: 15,
              color: earned ? AppColors.status.success : AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}
