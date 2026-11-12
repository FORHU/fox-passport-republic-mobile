import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_template/core/utils/context_extensions.dart';
import 'package:flutter_template/features/rewards/data/rewards_repository.dart';
import 'package:flutter_template/features/rewards/domain/daily_login.dart';
import 'package:flutter_template/l10n/generated/app_localizations.dart';
import 'package:flutter_template/shared/widgets/coins_chip.dart';
import 'package:flutter_template/theme/tokens/colors.dart';
import 'package:flutter_template/theme/tokens/radius.dart';
import 'package:flutter_template/theme/tokens/typography.dart';

/// Today's daily login, on Home: always there, so it is easy to see and a
/// missed day is not hidden behind a popup that was dismissed. Claim while
/// unclaimed; "Claimed today" after; and a plain reason, not a button, when the
/// server would refuse (email not verified, monthly limit reached). Nothing
/// takes room while it loads, when it cannot be reached or when the rule is
/// off, so Home is left as it was.
class DailyLoginCard extends ConsumerStatefulWidget {
  const DailyLoginCard({super.key});

  @override
  ConsumerState<DailyLoginCard> createState() => _DailyLoginCardState();
}

class _DailyLoginCardState extends ConsumerState<DailyLoginCard> {
  bool _busy = false;

  Future<void> _claim() async {
    if (_busy) return;
    setState(() => _busy = true);
    final messenger = ScaffoldMessenger.maybeOf(context);
    final l10n = context.l10n;
    try {
      final result =
          await ref.read(rewardsRepositoryProvider).claimDailyLogin();
      // The balance changed: the status and the wallet are read again.
      ref
        ..invalidate(dailyLoginProvider)
        ..invalidate(walletProvider);
      if (result.claimed && result.coinsAwarded > 0) {
        messenger?.showSnackBar(
          SnackBar(content: Text(l10n.dailyLoginAdded(result.coinsAwarded))),
        );
      }
    } on Object {
      messenger?.showSnackBar(SnackBar(content: Text(l10n.dailyLoginFailed)));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final status = ref.watch(dailyLoginProvider).value;
    if (status == null || status.block == DailyLoginBlock.inactive) {
      return const SizedBox.shrink();
    }
    final l10n = context.l10n;
    final claimable = status.canClaim;
    // The gap below belongs to the card, so Home has none while it is hidden.
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: AppRadius.brLg,
          border: Border.all(
            color: claimable ? AppColors.accentTintBorder : AppColors.border,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    l10n.dailyLoginLabel.toUpperCase(),
                    style: AppTypography.label(
                      color: claimable ? AppColors.accent : AppColors.textMuted,
                    ),
                  ),
                ),
                if (claimable)
                  Text(
                    l10n.dailyLoginClaimBy,
                    style: AppTypography.body(
                      size: 12,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            if (status.claimedToday)
              ..._claimed(l10n, status)
            else if (claimable)
              ..._open(l10n, status)
            else
              Text(
                status.block == DailyLoginBlock.capReached
                    ? l10n.dailyLoginCapReached
                    : l10n.dailyLoginVerifyEmail,
                style: AppTypography.body(),
              ),
          ],
        ),
      ),
    );
  }

  List<Widget> _open(AppLocalizations l10n, DailyLoginStatus status) => [
        Text(
          status.streak > 0
              ? l10n.dailyLoginStreak(status.streak)
              : l10n.dailyLoginStart,
          style: AppTypography.display(size: 20),
        ),
        const SizedBox(height: 14),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _busy ? null : _claim,
            child: _busy
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.onAccent,
                    ),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(coinsIcon, size: 18),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(l10n.dailyLoginClaim(status.amount)),
                      ),
                    ],
                  ),
          ),
        ),
      ];

  List<Widget> _claimed(AppLocalizations l10n, DailyLoginStatus status) => [
        Row(
          children: [
            const Icon(
              Icons.check_rounded,
              size: 20,
              color: AppColors.success,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                l10n.dailyLoginClaimed,
                style: AppTypography.display(size: 18),
              ),
            ),
            if (status.streak > 0)
              Text(
                l10n.dailyLoginStreak(status.streak),
                style: AppTypography.body(
                  size: 12,
                ),
              ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          l10n.dailyLoginComeBack(status.amount),
          style: AppTypography.body(size: 13),
        ),
      ];
}
