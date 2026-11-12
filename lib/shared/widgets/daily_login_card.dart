import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_template/core/utils/context_extensions.dart';
import 'package:flutter_template/features/rewards/data/rewards_repository.dart';
import 'package:flutter_template/features/rewards/domain/daily_login.dart';
import 'package:flutter_template/shared/widgets/coins_chip.dart';
import 'package:flutter_template/theme/tokens/colors.dart';
import 'package:flutter_template/theme/tokens/radius.dart';
import 'package:flutter_template/theme/tokens/typography.dart';

/// Today's daily login, on Home: always there, so it is easy to see and a
/// missed day is not hidden behind a popup that was dismissed. One slim row: a
/// coin, "Daily login" over what it pays, and a Claim button; once claimed the
/// same row reads "Claimed today" and goes quiet; and it gives a plain reason,
/// not a button, when the server would refuse (email not verified, monthly
/// limit reached). Nothing takes room while it loads, when it cannot be reached
/// or when the rule is off, so Home is left as it was.
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
    final claimed = status.claimedToday;
    // The gap below belongs to the card, so Home has none while it is hidden.
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: AppRadius.brLg,
          border: Border.all(
            color: claimable ? AppColors.accentTintBorder : AppColors.border,
          ),
        ),
        child: Row(
          children: [
            _Badge(claimed: claimed, claimable: claimable),
            const SizedBox(width: 12),
            Expanded(child: _Words(status: status)),
            if (claimable) ...[
              const SizedBox(width: 12),
              _ClaimButton(
                label: l10n.dailyLoginClaimShort,
                semanticLabel: l10n.dailyLoginClaim(status.amount),
                busy: _busy,
                onPressed: _claim,
              ),
            ] else if (claimed && status.streak > 0) ...[
              const SizedBox(width: 12),
              Text(
                l10n.dailyLoginStreak(status.streak),
                style: AppTypography.body(size: 12),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// The coin, lime while there is something to claim; a check once claimed.
class _Badge extends StatelessWidget {
  const _Badge({required this.claimed, required this.claimable});

  final bool claimed;
  final bool claimable;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: claimable ? AppColors.accentTintBg : AppColors.surfaceRaised,
        border: Border.all(
          color: claimable ? AppColors.accentTintBorder : AppColors.border,
        ),
      ),
      child: Icon(
        claimed ? Icons.check_rounded : coinsIcon,
        size: 20,
        color: claimed
            ? AppColors.success
            : claimable
                ? AppColors.accent
                : AppColors.textMuted,
      ),
    );
  }
}

/// "Daily login" over what is on offer, what comes next, or why it is not.
class _Words extends StatelessWidget {
  const _Words({required this.status});

  final DailyLoginStatus status;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final String title;
    final String subtitle;
    if (status.claimedToday) {
      title = l10n.dailyLoginClaimed;
      subtitle = l10n.dailyLoginComeBack(status.amount);
    } else if (status.canClaim) {
      title = l10n.dailyLoginLabel;
      subtitle = status.streak > 0
          ? '${l10n.dailyLoginReward(status.amount)} · '
              '${l10n.dailyLoginStreak(status.streak)}'
          : l10n.dailyLoginReward(status.amount);
    } else {
      title = l10n.dailyLoginLabel;
      subtitle = status.block == DailyLoginBlock.capReached
          ? l10n.dailyLoginCapReached
          : l10n.dailyLoginVerifyEmail;
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: AppTypography.display(size: 15)),
        const SizedBox(height: 2),
        Text(
          subtitle,
          maxLines: 3,
          overflow: TextOverflow.ellipsis,
          style: AppTypography.body(size: 12),
        ),
      ],
    );
  }
}

/// The small Claim button. The theme's buttons fill the width they are given,
/// so it sets its own size to sit at the end of a row.
class _ClaimButton extends StatelessWidget {
  const _ClaimButton({
    required this.label,
    required this.semanticLabel,
    required this.busy,
    required this.onPressed,
  });

  final String label;
  final String semanticLabel;
  final bool busy;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: semanticLabel,
      excludeSemantics: true,
      child: ElevatedButton(
        onPressed: busy ? null : onPressed,
        style: ElevatedButton.styleFrom(
          minimumSize: const Size(84, 44),
          padding: const EdgeInsets.symmetric(horizontal: 20),
        ),
        child: busy
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.onAccent,
                ),
              )
            : Text(label),
      ),
    );
  }
}
