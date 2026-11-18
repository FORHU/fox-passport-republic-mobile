import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_template/core/errors/exceptions.dart';
import 'package:flutter_template/core/utils/context_extensions.dart';
import 'package:flutter_template/features/perks/data/perks_repository.dart';
import 'package:flutter_template/features/perks/domain/perk.dart';
import 'package:flutter_template/routes/route_names.dart';
import 'package:flutter_template/shared/wallet/refresh_wallet.dart';
import 'package:flutter_template/shared/widgets/buttons.dart';
import 'package:flutter_template/shared/widgets/top_toast.dart';
import 'package:flutter_template/theme/tokens/colors.dart';
import 'package:flutter_template/theme/tokens/radius.dart';
import 'package:flutter_template/theme/tokens/typography.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

/// Asks to spend the Tokens on [perk] for [booking]: what it costs and what is
/// left, then the code.
Future<void> showPerkConfirmSheet(
  BuildContext context, {
  required Perk perk,
  required PerkBooking booking,
  required int balance,
}) =>
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => PerkConfirmSheet(
        perk: perk,
        booking: booking,
        balance: balance,
      ),
    );

class PerkConfirmSheet extends ConsumerStatefulWidget {
  const PerkConfirmSheet({
    required this.perk,
    required this.booking,
    required this.balance,
    super.key,
  });

  final Perk perk;
  final PerkBooking booking;
  final int balance;

  @override
  ConsumerState<PerkConfirmSheet> createState() => _PerkConfirmSheetState();
}

class _PerkConfirmSheetState extends ConsumerState<PerkConfirmSheet> {
  bool _busy = false;

  Future<void> _redeem() async {
    final l10n = context.l10n;
    final router = GoRouter.of(context);
    final navigator = Navigator.of(context);
    setState(() => _busy = true);
    try {
      final done = await ref
          .read(perksRepositoryProvider)
          .redeem(widget.perk.id, widget.booking.id);
      // The balance, the list and the person's perks all changed.
      refreshWallet(ref);
      ref
        ..invalidate(perksProvider)
        ..invalidate(myPerksProvider)
        ..invalidate(perkDetailProvider(widget.perk.id));
      if (!mounted) return;
      navigator.pop();
      unawaited(router.push(RouteNames.perkCode(done.redemptionId)));
    } on Object catch (e) {
      if (!mounted) return;
      setState(() => _busy = false);
      showTopToast(
        context,
        e is AppException ? e.message : l10n.perkRedeemFailed,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final format = NumberFormat.decimalPattern(
      Localizations.localeOf(context).toString(),
    );
    final cost = format.format(widget.perk.tokenCost);
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
            Text(
              l10n.perkUseTokens(cost),
              style: AppTypography.display(size: 22),
            ),
            const SizedBox(height: 6),
            Text(
              l10n.perkUseTokensBody(widget.perk.title),
              style: AppTypography.body(color: AppColors.textMuted),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.surfaceRaised,
                borderRadius: AppRadius.brMd,
              ),
              child: Column(
                children: [
                  _Line(l10n.perkBookingLabel, widget.booking.name),
                  const Divider(height: 20),
                  _Line(l10n.perkCostLabel, l10n.perkPaidTokens(cost)),
                  const Divider(height: 20),
                  _Line(
                    l10n.perkLeftAfter,
                    l10n.perkPaidTokens(
                      format.format(widget.balance - widget.perk.tokenCost),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Text(
              l10n.perkConfirmNote,
              style: AppTypography.body(size: 12, color: AppColors.textMuted),
            ),
            const SizedBox(height: 16),
            PrimaryButton(
              label: l10n.perkConfirmButton(cost),
              isLoading: _busy,
              onPressed: _busy ? null : _redeem,
            ),
            const SizedBox(height: 8),
            SecondaryButton(
              label: l10n.perkCancel,
              onPressed: _busy ? null : () => Navigator.of(context).pop(),
            ),
          ],
        ),
      ),
    );
  }
}

class _Line extends StatelessWidget {
  const _Line(this.label, this.value);

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Row(
        children: [
          Expanded(child: Text(label, style: AppTypography.body())),
          const SizedBox(width: 12),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: AppTypography.display(size: 14),
            ),
          ),
        ],
      );
}
