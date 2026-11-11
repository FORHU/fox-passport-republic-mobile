import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_template/core/utils/context_extensions.dart';
import 'package:flutter_template/features/rewards/data/rewards_repository.dart';
import 'package:flutter_template/routes/route_names.dart';
import 'package:flutter_template/theme/tokens/colors.dart';
import 'package:flutter_template/theme/tokens/radius.dart';
import 'package:flutter_template/theme/tokens/typography.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

/// The Tokens icon, one for every place Tokens show.
const IconData coinsIcon = Icons.toll_rounded;

String _coins(BuildContext context, int n) =>
    NumberFormat.decimalPattern(Localizations.localeOf(context).toString())
        .format(n);

/// The signed-in person's Tokens, as a small chip that opens the Wallet. It
/// takes no room until the balance is known: while it loads, when it fails and
/// when nobody is signed in, the screen around it is left as it was. Foxer
/// spaces do not show it: a Foxer earns Tokens only as a citizen.
class CoinsChip extends ConsumerWidget {
  const CoinsChip({this.trailingGap = 0, super.key});

  /// Space after the chip, taken only while the chip shows.
  final double trailingGap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final wallet = ref.watch(walletProvider).value;
    if (wallet == null) return const SizedBox.shrink();
    final chip = Semantics(
      button: true,
      label: context.l10n.rewardsOpenWallet,
      child: InkWell(
        borderRadius: AppRadius.brPill,
        onTap: () => context.push(RouteNames.wallet),
        child: Container(
          height: 36,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: AppRadius.brPill,
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(coinsIcon, size: 16, color: AppColors.textPrimary),
              const SizedBox(width: 6),
              // A big balance shrinks to the room the chip is given.
              Flexible(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    _coins(context, wallet.coins),
                    style: AppTypography.display(size: 14),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
    return trailingGap == 0
        ? chip
        : Padding(padding: EdgeInsets.only(right: trailingGap), child: chip);
  }
}

/// "Wallet · 1,240 Tokens", a row that opens the Wallet. For the Passport.
/// Left out the same way as [CoinsChip].
class WalletRow extends ConsumerWidget {
  const WalletRow({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final wallet = ref.watch(walletProvider).value;
    if (wallet == null) return const SizedBox.shrink();
    final l10n = context.l10n;
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: InkWell(
        borderRadius: AppRadius.brMd,
        onTap: () => context.push(RouteNames.wallet),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          decoration: BoxDecoration(
            color: AppColors.surfaceRaised,
            borderRadius: AppRadius.brMd,
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              const Icon(coinsIcon, size: 18, color: AppColors.textPrimary),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.rewardsWalletTitle,
                      style: AppTypography.display(size: 14),
                    ),
                  ],
                ),
              ),
              ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: MediaQuery.sizeOf(context).width * 0.4,
                ),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerRight,
                  child: Text(
                    '${_coins(context, wallet.coins)} ${l10n.rewardsCoins}',
                    style: AppTypography.body(),
                  ),
                ),
              ),
              const SizedBox(width: 4),
              const Icon(
                Icons.chevron_right_rounded,
                color: AppColors.textMuted,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
