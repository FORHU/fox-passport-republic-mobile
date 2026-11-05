import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_template/core/errors/exceptions.dart';
import 'package:flutter_template/core/utils/context_extensions.dart';
import 'package:flutter_template/features/rewards/data/rewards_repository.dart';
import 'package:flutter_template/features/rewards/domain/reward_item.dart';
import 'package:flutter_template/features/rewards/presentation/widgets/reward_label.dart';
import 'package:flutter_template/shared/widgets/buttons.dart';
import 'package:flutter_template/shared/widgets/coins_chip.dart';
import 'package:flutter_template/shared/widgets/top_toast.dart';
import 'package:flutter_template/theme/tokens/colors.dart';
import 'package:flutter_template/theme/tokens/radius.dart';
import 'package:flutter_template/theme/tokens/typography.dart';
import 'package:intl/intl.dart';

/// Asks to spend the Coins for [item]: the balance before and after, one
/// button, and then the voucher that came back.
Future<void> showRedeemSheet(
  BuildContext context, {
  required RewardItem item,
  required int balance,
}) =>
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => RedeemSheet(item: item, balance: balance),
    );

class RedeemSheet extends ConsumerStatefulWidget {
  const RedeemSheet({required this.item, required this.balance, super.key});

  final RewardItem item;
  final int balance;

  @override
  ConsumerState<RedeemSheet> createState() => _RedeemSheetState();
}

class _RedeemSheetState extends ConsumerState<RedeemSheet> {
  bool _busy = false;
  Redemption? _done;

  Future<void> _redeem() async {
    final l10n = context.l10n;
    setState(() => _busy = true);
    try {
      final result =
          await ref.read(rewardsRepositoryProvider).redeem(widget.item.id);
      if (!mounted) return;
      // The balance and what can be afforded both changed.
      ref
        ..invalidate(walletProvider)
        ..invalidate(rewardCatalogProvider);
      setState(() {
        _done = result;
        _busy = false;
      });
    } on Object catch (e) {
      if (!mounted) return;
      setState(() => _busy = false);
      showTopToast(
        context,
        e is AppException ? e.message : l10n.rewardsRedeemFailed,
      );
    }
  }

  Future<void> _copy(String code) async {
    await Clipboard.setData(ClipboardData(text: code));
    if (mounted) showTopToast(context, context.l10n.rewardsCodeCopied);
  }

  @override
  Widget build(BuildContext context) {
    final done = _done;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.borderStrong,
                  borderRadius: AppRadius.brPill,
                ),
              ),
            ),
            const SizedBox(height: 16),
            if (done == null) _confirm(context) else _voucher(context, done),
          ],
        ),
      ),
    );
  }

  Widget _confirm(BuildContext context) {
    final l10n = context.l10n;
    final format = NumberFormat.decimalPattern(
      Localizations.localeOf(context).toString(),
    );
    final cost = widget.item.coinCost;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          l10n.rewardsRedeemSheetTitle.toUpperCase(),
          style: AppTypography.label(),
        ),
        const SizedBox(height: 6),
        Text(
          rewardTitle(l10n, widget.item),
          style: AppTypography.display(size: 22),
        ),
        if (widget.item.description?.isNotEmpty ?? false) ...[
          const SizedBox(height: 6),
          Text(
            widget.item.description!,
            style: AppTypography.body(color: AppColors.textMuted),
          ),
        ],
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.surfaceRaised,
            borderRadius: AppRadius.brMd,
          ),
          child: Column(
            children: [
              _Line(l10n.rewardsYourBalance, format.format(widget.balance)),
              const SizedBox(height: 8),
              _Line(l10n.rewardsThisReward, '−${format.format(cost)}'),
              const Divider(height: 20),
              _Line(
                l10n.rewardsAfterRedeeming,
                format.format(widget.balance - cost),
                strong: true,
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        PrimaryButton(
          label: l10n.rewardsRedeemFor(format.format(cost)),
          isLoading: _busy,
          onPressed: _busy ? null : _redeem,
        ),
        const SizedBox(height: 8),
        SecondaryButton(
          label: l10n.rewardsCancel,
          onPressed: _busy ? null : () => Navigator.of(context).pop(),
        ),
      ],
    );
  }

  Widget _voucher(BuildContext context, Redemption done) {
    final l10n = context.l10n;
    final locale = Localizations.localeOf(context).toString();
    final off = voucherOff(
      l10n,
      php: done.discountPhp,
      percent: done.discountPercentage,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Icon(Icons.check_circle_rounded, size: 40),
        const SizedBox(height: 12),
        Text(
          l10n.rewardsVoucherReady,
          textAlign: TextAlign.center,
          style: AppTypography.display(size: 22),
        ),
        if (off.isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(
            off,
            textAlign: TextAlign.center,
            style: AppTypography.body(),
          ),
        ],
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.surfaceRaised,
            borderRadius: AppRadius.brMd,
          ),
          child: Column(
            children: [
              Text(
                l10n.rewardsVoucherCode.toUpperCase(),
                style: AppTypography.label(),
              ),
              const SizedBox(height: 6),
              SelectableText(
                done.voucherCode,
                textAlign: TextAlign.center,
                style: AppTypography.display(size: 24),
              ),
              if (done.expiresAt != null) ...[
                const SizedBox(height: 6),
                Text(
                  l10n.rewardsValidUntil(
                    DateFormat.yMMMd(locale).format(done.expiresAt!),
                  ),
                  style: AppTypography.body(
                    size: 12,
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 10),
        Text(
          l10n.rewardsVoucherHint,
          textAlign: TextAlign.center,
          style: AppTypography.body(size: 12, color: AppColors.textMuted),
        ),
        const SizedBox(height: 16),
        PrimaryButton(
          label: l10n.rewardsCopyCode,
          icon: Icons.copy_rounded,
          onPressed: () => _copy(done.voucherCode),
        ),
        const SizedBox(height: 8),
        SecondaryButton(
          label: l10n.rewardsDone,
          onPressed: () => Navigator.of(context).pop(),
        ),
      ],
    );
  }
}

class _Line extends StatelessWidget {
  const _Line(this.label, this.value, {this.strong = false});

  final String label;
  final String value;
  final bool strong;

  @override
  Widget build(BuildContext context) => Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: AppTypography.body(),
            ),
          ),
          const Icon(coinsIcon, size: 14),
          const SizedBox(width: 4),
          Text(
            value,
            style: AppTypography.display(size: strong ? 16 : 14),
          ),
        ],
      );
}
