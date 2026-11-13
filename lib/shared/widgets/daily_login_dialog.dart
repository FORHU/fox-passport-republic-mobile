import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_template/core/utils/context_extensions.dart';
import 'package:flutter_template/features/rewards/data/rewards_repository.dart';
import 'package:flutter_template/features/rewards/domain/daily_login.dart';
import 'package:flutter_template/l10n/generated/app_localizations.dart';
import 'package:flutter_template/shared/widgets/brand_logo.dart';
import 'package:flutter_template/shared/widgets/coins_chip.dart';
import 'package:flutter_template/theme/tokens/colors.dart';
import 'package:flutter_template/theme/tokens/radius.dart';
import 'package:flutter_template/theme/tokens/typography.dart';
import 'package:intl/intl.dart';

/// Opens the daily login as a modal: "Day 3 of 7" with the week drawn out and a
/// Claim button while today is unclaimed, "Day 3 done" with the new balance
/// once it is claimed. Pass [justClaimed] to open it straight on the result of
/// a claim made just now (its chip shows what was paid); without it, it opens
/// on where today stands.
Future<void> showDailyLoginDialog(
  BuildContext context, {
  DailyLoginClaim? justClaimed,
}) =>
    showDialog<void>(
      context: context,
      builder: (_) => DailyLoginDialog(justClaimed: justClaimed),
    );

class DailyLoginDialog extends ConsumerStatefulWidget {
  const DailyLoginDialog({this.justClaimed, super.key});

  final DailyLoginClaim? justClaimed;

  @override
  ConsumerState<DailyLoginDialog> createState() => _DailyLoginDialogState();
}

class _DailyLoginDialogState extends ConsumerState<DailyLoginDialog> {
  /// The claim made here or passed in; null while only looking.
  late DailyLoginClaim? _claim = widget.justClaimed;
  bool _busy = false;
  int? _balance;

  @override
  void initState() {
    super.initState();
    // Opened on a day already claimed, from the card, the status is loaded.
    final status = _claim?.status ?? ref.read(dailyLoginProvider).value;
    if (status?.claimedToday ?? false) unawaited(_loadBalance());
  }

  Future<void> _loadBalance() async {
    try {
      final wallet = await ref.read(walletProvider.future);
      if (mounted) setState(() => _balance = wallet.coins);
    } on Object {
      // Without a balance the box is simply left out.
    }
  }

  Future<void> _claimNow() async {
    if (_busy) return;
    setState(() => _busy = true);
    final messenger = ScaffoldMessenger.maybeOf(context);
    final failed = context.l10n.dailyLoginFailed;
    try {
      final result =
          await ref.read(rewardsRepositoryProvider).claimDailyLogin();
      // The balance changed: the status and the wallet are read again.
      ref
        ..invalidate(dailyLoginProvider)
        ..invalidate(walletProvider);
      if (mounted) setState(() => _claim = result);
      await _loadBalance();
    } on Object {
      messenger?.showSnackBar(SnackBar(content: Text(failed)));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final status = _claim?.status ?? ref.watch(dailyLoginProvider).value;
    return Dialog(
      backgroundColor: AppColors.surface,
      insetPadding: const EdgeInsets.all(20),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(28),
        side: const BorderSide(color: AppColors.borderStrong),
      ),
      child: status == null
          ? const Padding(
              padding: EdgeInsets.all(48),
              child: Center(
                child: CircularProgressIndicator(color: AppColors.accent),
              ),
            )
          : Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _Header(status: status, justNow: _claim?.claimed ?? false),
                    if (status.cycle.length == 7) ...[
                      const SizedBox(height: 20),
                      _WeekTrack(status: status),
                    ],
                    if (status.claimedToday && _balance != null) ...[
                      const SizedBox(height: 16),
                      _BalanceBox(
                        balance: _balance!,
                        paid: (_claim?.claimed ?? false)
                            ? _claim?.coinsAwarded
                            : null,
                      ),
                    ],
                    const SizedBox(height: 20),
                    _Actions(
                      status: status,
                      busy: _busy,
                      onClaim: _claimNow,
                      l10n: l10n,
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}

/// The label, the title and what to say under it, and the close button.
class _Header extends StatelessWidget {
  const _Header({required this.status, required this.justNow});

  final DailyLoginStatus status;
  final bool justNow;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final claimed = status.claimedToday;
    final String title;
    var body = '';
    if (claimed) {
      title = l10n.dailyLoginDayDone(status.cycleDay);
      body = l10n.dailyLoginComeBack(status.tomorrow);
    } else if (status.canClaim) {
      title = l10n.dailyLoginDayOf(status.cycleDay, 7);
      body = l10n.dailyLoginExplain;
    } else {
      title = l10n.dailyLoginLabel;
      body = status.block == DailyLoginBlock.capReached
          ? l10n.dailyLoginCapReached
          : l10n.dailyLoginVerifyEmail;
    }
    // Day 7 is worth saying only when it pays more than the other days.
    final extra = status.cycle.isNotEmpty && status.day7Amount > status.cycle[0]
        ? ' ${l10n.dailyLoginDay7(status.day7Amount)}'
        : '';
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (claimed)
                Row(
                  children: [
                    const Icon(
                      Icons.check_rounded,
                      size: 14,
                      color: AppColors.success,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      l10n.dailyLoginClaimedBadge.toUpperCase(),
                      style: AppTypography.label(color: AppColors.success),
                    ),
                  ],
                )
              else
                Text(
                  l10n.dailyLoginLabel.toUpperCase(),
                  style: AppTypography.label(color: AppColors.accent),
                ),
              const SizedBox(height: 6),
              Text(title, style: AppTypography.display(size: 28)),
              const SizedBox(height: 6),
              Text(
                '$body$extra',
                style: AppTypography.body(),
              ),
            ],
          ),
        ),
        // A real button, at least 48 px, pulled out to the corner.
        Transform.translate(
          offset: const Offset(10, -8),
          child: IconButton(
            tooltip: MaterialLocalizations.of(context).closeButtonTooltip,
            onPressed: () => Navigator.of(context).pop(),
            icon:
                const Icon(Icons.close_rounded, color: AppColors.textSecondary),
          ),
        ),
      ],
    );
  }
}

/// The seven days of the cycle in a row: days done are white with a check,
/// today is the lime fox, days to come are numbered, and day 7 is the coin.
class _WeekTrack extends StatelessWidget {
  const _WeekTrack({required this.status});

  final DailyLoginStatus status;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        for (var i = 0; i < 7; i++) Expanded(child: _Day(status: status, i: i)),
      ],
    );
  }
}

class _Day extends StatelessWidget {
  const _Day({required this.status, required this.i});

  final DailyLoginStatus status;
  final int i;

  @override
  Widget build(BuildContext context) {
    final day = i + 1;
    final amount = status.cycle[i];
    final reached = day < status.cycleDay ||
        (day == status.cycleDay && status.claimedToday);
    final isToday = day == status.cycleDay && !status.claimedToday;
    final isLast = day == 7;
    final highlight = !reached && (isToday || isLast);

    final Widget mark;
    if (reached) {
      mark = _circle(
        36,
        fill: AppColors.textPrimary,
        child: const Icon(
          Icons.check_rounded,
          size: 18,
          color: AppColors.canvas,
        ),
      );
    } else if (isToday) {
      mark = _circle(
        44,
        fill: AppColors.accentTintBg,
        border: AppColors.accent,
        child: const ColorFiltered(
          colorFilter: ColorFilter.mode(AppColors.accent, BlendMode.srcIn),
          child: FoxLogo(size: 26),
        ),
      );
    } else if (isLast) {
      mark = Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: AppRadius.brMd,
          border: Border.all(color: AppColors.accentTintBorder, width: 2),
        ),
        child: const Icon(coinsIcon, size: 22, color: AppColors.accent),
      );
    } else {
      mark = _circle(
        36,
        border: AppColors.borderStrong,
        child: Text(
          '$day',
          style: AppTypography.body(size: 12),
        ),
      );
    }
    return Semantics(
      label: context.l10n.dailyLoginDayLabel(day, amount),
      excludeSemantics: true,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          mark,
          const SizedBox(height: 8),
          Text(
            '+$amount',
            style: AppTypography.body(
              size: 12,
              color: highlight ? AppColors.accent : AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  static Widget _circle(
    double size, {
    required Widget child,
    Color? fill,
    Color? border,
  }) =>
      Container(
        width: size,
        height: size,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: fill,
          border: border == null ? null : Border.all(color: border, width: 2),
        ),
        child: child,
      );
}

/// "New balance 1,245 Tokens", with what was just paid when a claim was made.
class _BalanceBox extends StatelessWidget {
  const _BalanceBox({required this.balance, required this.paid});

  final int balance;

  /// What this claim paid; null when only looking at the day.
  final int? paid;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final formatted =
        NumberFormat.decimalPattern(Localizations.localeOf(context).toString())
            .format(balance);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.canvas,
        borderRadius: AppRadius.brMd,
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  paid == null
                      ? l10n.dailyLoginBalance
                      : l10n.dailyLoginNewBalance,
                  style: AppTypography.body(size: 12),
                ),
                const SizedBox(height: 2),
                Text(
                  l10n.dailyLoginBalanceTokens(formatted),
                  style: AppTypography.display(size: 20),
                ),
              ],
            ),
          ),
          if (paid != null && paid! > 0)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
              decoration: BoxDecoration(
                color: AppColors.accentTintBg,
                borderRadius: AppRadius.brPill,
                border: Border.all(color: AppColors.accentTintBorder),
              ),
              child: Text(
                l10n.dailyLoginReward(paid!),
                style: AppTypography.display(size: 13, color: AppColors.accent),
              ),
            ),
        ],
      ),
    );
  }
}

/// Claim and Not now while there is something to claim; Done otherwise.
class _Actions extends StatelessWidget {
  const _Actions({
    required this.status,
    required this.busy,
    required this.onClaim,
    required this.l10n,
  });

  final DailyLoginStatus status;
  final bool busy;
  final VoidCallback onClaim;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    if (status.canClaim) {
      return Column(
        children: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: busy ? null : onClaim,
              child: busy
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
          TextButton(
            onPressed: busy ? null : () => Navigator.of(context).pop(),
            child: Text(l10n.dailyLoginNotNow),
          ),
        ],
      );
    }
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: () => Navigator.of(context).pop(),
        child: Text(l10n.dailyLoginDone),
      ),
    );
  }
}
