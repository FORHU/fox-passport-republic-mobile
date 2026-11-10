import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_template/core/utils/context_extensions.dart';
import 'package:flutter_template/features/rewards/data/rewards_repository.dart';
import 'package:flutter_template/features/rewards/domain/reward_item.dart';
import 'package:flutter_template/features/rewards/presentation/widgets/redeem_sheet.dart';
import 'package:flutter_template/features/rewards/presentation/widgets/reward_label.dart';
import 'package:flutter_template/shared/widgets/app_state_view.dart';
import 'package:flutter_template/shared/widgets/buttons.dart';
import 'package:flutter_template/shared/widgets/coins_chip.dart';
import 'package:flutter_template/shared/widgets/segmented_pills.dart';
import 'package:flutter_template/theme/tokens/colors.dart';
import 'package:flutter_template/theme/tokens/radius.dart';
import 'package:flutter_template/theme/tokens/typography.dart';
import 'package:intl/intl.dart';

enum _Filter { all, discounts, perks }

/// What Coins can buy: discount vouchers and perks, with what you can afford
/// now, what is almost within reach, and what waits for a higher level.
class RewardsPage extends ConsumerStatefulWidget {
  const RewardsPage({super.key});

  @override
  ConsumerState<RewardsPage> createState() => _RewardsPageState();
}

class _RewardsPageState extends ConsumerState<RewardsPage> {
  _Filter _filter = _Filter.all;

  List<RewardItem> _shown(List<RewardItem> all) {
    final items = switch (_filter) {
      _Filter.all => all,
      _Filter.discounts => [
          for (final r in all)
            if (r.isDiscount) r,
        ],
      _Filter.perks => [
          for (final r in all)
            if (!r.isDiscount) r,
        ],
    };
    return [...items]..sort((a, b) => a.coinCost.compareTo(b.coinCost));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final catalog = ref.watch(rewardCatalogProvider);
    final balance = ref.watch(walletProvider).value?.coins ?? 0;

    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: AppBar(
        backgroundColor: AppColors.canvas,
        title: Text(
          l10n.rewardsTitle,
          style: AppTypography.display(size: 22),
        ),
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 12),
            child: Center(child: CoinsChip()),
          ),
        ],
      ),
      body: catalog.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.accent),
        ),
        error: (_, __) => AppStateView(
          kind: AppStateKind.error,
          title: l10n.apiLoadFailed,
          actionLabel: l10n.retry,
          onAction: () => ref.invalidate(rewardCatalogProvider),
        ),
        data: (all) {
          final items = _shown(all);
          return RefreshIndicator(
            color: AppColors.accent,
            onRefresh: () async {
              ref
                ..invalidate(walletProvider)
                ..invalidate(rewardCatalogProvider);
              await ref.read(rewardCatalogProvider.future);
            },
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
              children: [
                SegmentedPills<_Filter>(
                  value: _filter,
                  onChanged: (f) => setState(() => _filter = f),
                  options: [
                    SegmentOption(_Filter.all, l10n.rewardsFilterAll),
                    SegmentOption(
                      _Filter.discounts,
                      l10n.rewardsFilterDiscounts,
                    ),
                    SegmentOption(_Filter.perks, l10n.rewardsFilterPerks),
                  ],
                ),
                const SizedBox(height: 16),
                if (items.isEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 48),
                    child: Text(
                      l10n.rewardsNoneHere,
                      textAlign: TextAlign.center,
                      style: AppTypography.body(color: AppColors.textMuted),
                    ),
                  )
                else
                  for (final item in items)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _RewardCard(item: item, balance: balance),
                    ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _RewardCard extends ConsumerWidget {
  const _RewardCard({required this.item, required this.balance});

  final RewardItem item;
  final int balance;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final format = NumberFormat.decimalPattern(
      Localizations.localeOf(context).toString(),
    );
    final locked = !item.levelQualified;
    final canRedeem = !locked && item.canAfford;
    final toGo = (item.coinCost - balance).clamp(0, item.coinCost);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.brLg,
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  rewardTitle(l10n, item),
                  style: AppTypography.display(),
                ),
              ),
              const SizedBox(width: 8),
              const Icon(coinsIcon, size: 16),
              const SizedBox(width: 4),
              Text(
                format.format(item.coinCost),
                style: AppTypography.display(size: 15),
              ),
            ],
          ),
          if (item.description?.isNotEmpty ?? false) ...[
            const SizedBox(height: 4),
            Text(
              item.description!,
              style: AppTypography.body(
                size: 13,
                color: AppColors.textMuted,
              ),
            ),
          ],
          const SizedBox(height: 12),
          if (locked)
            _Note(
              icon: Icons.lock_outline_rounded,
              text: l10n.rewardsUnlocksAtLevel(item.minLevel),
            )
          else if (canRedeem)
            SecondaryButton(
              label: l10n.rewardsRedeem,
              onPressed: () => showRedeemSheet(
                context,
                item: item,
                balance: balance,
              ),
            )
          else ...[
            ClipRRect(
              borderRadius: AppRadius.brPill,
              child: LinearProgressIndicator(
                value: item.coinCost == 0
                    ? 0
                    : (balance / item.coinCost).clamp(0, 1).toDouble(),
                minHeight: 6,
                backgroundColor: AppColors.surfaceRaised,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              l10n.rewardsToGo(format.format(toGo)),
              style: AppTypography.body(size: 12, color: AppColors.textMuted),
            ),
          ],
        ],
      ),
    );
  }
}

class _Note extends StatelessWidget {
  const _Note({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.surfaceRaised,
          borderRadius: AppRadius.brMd,
        ),
        child: Row(
          children: [
            Icon(icon, size: 16, color: AppColors.textMuted),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                text,
                style: AppTypography.body(size: 13, color: AppColors.textMuted),
              ),
            ),
          ],
        ),
      );
}
