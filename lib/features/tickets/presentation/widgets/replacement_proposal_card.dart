import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_template/core/errors/exceptions.dart';
import 'package:flutter_template/core/utils/context_extensions.dart';
import 'package:flutter_template/shared/currency/currency.dart';
import 'package:flutter_template/shared/formatting/money.dart';
import 'package:flutter_template/shared/tickets/event_edit_proposal.dart';
import 'package:flutter_template/shared/tickets/event_edit_proposals_repository.dart';
import 'package:flutter_template/shared/tickets/replacement_status.dart';
import 'package:flutter_template/shared/tickets/tickets_repository.dart';
import 'package:flutter_template/shared/widgets/top_toast.dart';
import 'package:flutter_template/theme/tokens/colors.dart';
import 'package:flutter_template/theme/tokens/radius.dart';
import 'package:flutter_template/theme/tokens/typography.dart';
import 'package:intl/intl.dart';

/// A booked event that lost a Supplier: the host's proposed replacement for
/// the citizen to accept or decline, or, with none waiting, by when the host
/// must replace it before a full-refund cancel opens. Shows nothing when
/// nothing needs replacing, and stays out of the way while it loads or if it
/// can't be read.
class ReplacementProposalCard extends ConsumerStatefulWidget {
  const ReplacementProposalCard({required this.bookingId, super.key});

  final String bookingId;

  @override
  ConsumerState<ReplacementProposalCard> createState() =>
      _ReplacementProposalCardState();
}

class _ReplacementProposalCardState
    extends ConsumerState<ReplacementProposalCard> {
  bool _busy = false;

  Future<void> _answer(EventEditProposal p, {required bool accept}) async {
    final l10n = context.l10n;
    final repo = ref.read(eventEditProposalsRepositoryProvider);
    setState(() => _busy = true);
    try {
      if (accept) {
        await repo.accept(p.id);
      } else {
        await repo.decline(p.id);
      }
      ref
        ..invalidate(openProposalProvider(widget.bookingId))
        ..invalidate(replacementStatusProvider(widget.bookingId))
        ..invalidate(upcomingTicketsProvider);
      if (!mounted) return;
      showTopToast(
        context,
        accept ? l10n.proposalAccepted : l10n.proposalDeclined,
      );
    } on Object catch (e) {
      // It may have expired or been withdrawn meanwhile; show it as it is now.
      ref
        ..invalidate(openProposalProvider(widget.bookingId))
        ..invalidate(replacementStatusProvider(widget.bookingId));
      if (!mounted) return;
      showTopToast(
        context,
        e is AppException && e.message.isNotEmpty
            ? e.message
            : l10n.requestActionFailed,
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final status = ref.watch(replacementStatusProvider(widget.bookingId)).value;
    if (status == null || !status.needsReplacement) {
      return const SizedBox.shrink();
    }
    // Proposals are only asked for when the status says one is waiting.
    final proposal = status.hasProposal
        ? ref.watch(openProposalProvider(widget.bookingId)).value
        : null;
    if (proposal == null) return _ReplacementNotice(status: status);

    final l10n = context.l10n;
    final locale = Localizations.localeOf(context).toString();
    final delta = proposal.priceDelta;
    final amount = formatMoney(delta.abs(), kBaseCurrency, locale: locale);
    final price = delta > 0
        ? l10n.proposalPriceUp(amount)
        : delta < 0
            ? l10n.proposalPriceDown(amount)
            : l10n.proposalPriceSame;

    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: AppRadius.brMd,
          border: Border.all(color: AppColors.warning),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.swap_horiz_rounded,
                  size: 20,
                  color: AppColors.warning,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    l10n.proposalTitle,
                    style: AppTypography.display(size: 15),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              l10n.proposalBody(proposal.replacesName, proposal.itemName),
              style: AppTypography.body(),
            ),
            if (proposal.note != null) ...[
              const SizedBox(height: 6),
              Text(
                '"${proposal.note}"',
                style: AppTypography.body(
                  size: 13,
                  color: AppColors.textMuted,
                ),
              ),
            ],
            const SizedBox(height: 6),
            Text(
              price,
              style: AppTypography.body(size: 13, color: AppColors.textMuted),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _busy
                        ? null
                        : () => unawaited(_answer(proposal, accept: false)),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(0, 44),
                    ),
                    child: Text(l10n.proposalDecline),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: FilledButton(
                    onPressed: _busy
                        ? null
                        : () => unawaited(_answer(proposal, accept: true)),
                    style: FilledButton.styleFrom(
                      minimumSize: const Size(0, 44),
                      backgroundColor: AppColors.accent,
                      foregroundColor: AppColors.canvas,
                    ),
                    child: Text(l10n.proposalAccept),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// A Supplier dropped out and no proposal is waiting: says by when the host
/// must replace it, or that the citizen may now cancel for a full refund.
class _ReplacementNotice extends StatelessWidget {
  const _ReplacementNotice({required this.status});

  final ReplacementStatus status;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final locale = Localizations.localeOf(context).toString();
    final items = status.items.map((i) => i.itemName).join(', ');
    final when = status.replaceBy == null
        ? null
        : DateFormat('EEE d MMM, h:mm a', locale).format(status.replaceBy!);
    final color = status.fullRefund ? AppColors.error : AppColors.warning;

    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: AppRadius.brMd,
          border: Border.all(color: color),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.schedule_rounded, size: 20, color: color),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.replacementNoticeTitle,
                    style: AppTypography.display(size: 15),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    status.fullRefund || when == null
                        ? l10n.replacementNoticeFullRefund
                        : l10n.replacementNoticeBody(items, when),
                    style: AppTypography.body(
                      size: 13,
                      color: AppColors.textMuted,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
