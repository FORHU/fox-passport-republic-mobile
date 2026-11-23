import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_template/core/errors/exceptions.dart';
import 'package:flutter_template/core/utils/context_extensions.dart';
import 'package:flutter_template/features/spaces/data/spaces_repository.dart';
import 'package:flutter_template/features/spaces/domain/space_models.dart';
import 'package:flutter_template/l10n/generated/app_localizations.dart';
import 'package:flutter_template/shared/currency/currency.dart';
import 'package:flutter_template/shared/formatting/money.dart';
import 'package:flutter_template/shared/widgets/app_state_view.dart';
import 'package:flutter_template/shared/widgets/top_toast.dart';
import 'package:flutter_template/theme/tokens/colors.dart';
import 'package:flutter_template/theme/tokens/radius.dart';
import 'package:flutter_template/theme/tokens/typography.dart';
import 'package:intl/intl.dart';

/// One booked event of the Event Foxer's: when it is, and every Supplier on it
/// with where each stands. A Supplier that declined, whose day was blocked or
/// whose listing is gone is marked and says why, so it is clear what to
/// replace, and the host can propose a replacement there for the citizen to
/// accept (unpaid, or paid and still to come).
class BookedEventPage extends ConsumerWidget {
  const BookedEventPage({required this.eventId, super.key});

  final String eventId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final event = ref.watch(bookedEventProvider(eventId));

    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: AppBar(
        backgroundColor: AppColors.canvas,
        title: Text(
          l10n.bookedEventTitle,
          style: AppTypography.display(size: 20),
        ),
      ),
      body: event.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.accent),
        ),
        error: (_, __) => AppStateView(
          kind: AppStateKind.error,
          title: l10n.bookedEventNotFound,
          actionLabel: l10n.retry,
          onAction: () => ref.invalidate(bookedEventProvider(eventId)),
        ),
        data: (e) => RefreshIndicator(
          color: AppColors.accent,
          backgroundColor: AppColors.surface,
          onRefresh: () async {
            ref
              ..invalidate(bookedEventProvider(eventId))
              ..invalidate(eventsNeedingAttentionProvider);
            await ref.read(bookedEventProvider(eventId).future);
          },
          child: _Body(
            event: e,
            // Unpaid, or paid and to come: a paid booking settles the
            // difference when the citizen accepts.
            onReplace: e.editableBookingId == null
                ? null
                : (s) => _findReplacement(context, ref, s, eventId),
            onWithdraw: (proposalId) =>
                _withdrawProposal(context, ref, proposalId, eventId),
            onDecline: e.declinableBookingId == null
                ? null
                : () => _declineAsHost(
                      context,
                      ref,
                      e.declinableBookingId!,
                      eventId,
                    ),
          ),
        ),
      ),
    );
  }
}

/// The host leaves a booking they cannot attend: asks why first, then the
/// citizen and the Suppliers are told. Only offered while the booking is not
/// paid; if it was paid since, the API refuses and its reason is shown.
Future<void> _declineAsHost(
  BuildContext context,
  WidgetRef ref,
  String bookingId,
  String eventId,
) async {
  final l10n = context.l10n;
  final cause = await showDialog<DeclineCause>(
    context: context,
    builder: (_) => AlertDialog(
      backgroundColor: AppColors.surface,
      title: Text(l10n.hostDeclineTitle),
      content: Text(l10n.hostDeclineBody),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.messageCancel),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(DeclineCause.busy),
          child: Text(l10n.requestDeclineBusy),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(DeclineCause.other),
          child: Text(
            l10n.hostDeclineAction,
            style: const TextStyle(color: AppColors.error),
          ),
        ),
      ],
    ),
  );
  if (cause == null || !context.mounted) return;
  try {
    await ref
        .read(spacesRepositoryProvider)
        .declineAsHost(bookingId, cause: cause);
    ref
      ..invalidate(bookedEventProvider(eventId))
      ..invalidate(eventsNeedingAttentionProvider)
      ..invalidate(myEventsProvider);
    if (!context.mounted) return;
    showTopToast(context, l10n.hostDeclineDone);
  } on Object catch (e) {
    if (!context.mounted) return;
    showTopToast(
      context,
      e is AppException && e.message.isNotEmpty
          ? e.message
          : l10n.requestActionFailed,
    );
  }
}

/// Shows what could replace [supplier], then sends the one picked as a
/// proposal once the host confirms. The citizen is told and answers.
Future<void> _findReplacement(
  BuildContext context,
  WidgetRef ref,
  BookedSupplier supplier,
  String eventId,
) async {
  final l10n = context.l10n;
  final picked = await showModalBottomSheet<ReplacementCandidate>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.surface,
    builder: (_) => _ReplacementSheet(supplier: supplier),
  );
  if (picked == null || !context.mounted) return;
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      backgroundColor: AppColors.surface,
      title: Text(l10n.replacementConfirmTitle(picked.name)),
      content: Text(l10n.replacementConfirmBody),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(false),
          child: Text(l10n.messageCancel),
        ),
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(true),
          child: Text(l10n.replacementPropose),
        ),
      ],
    ),
  );
  if (confirmed != true || !context.mounted) return;
  await _run(
    context,
    ref,
    eventId,
    () => ref.read(spacesRepositoryProvider).proposeReplacement(
          supplier.transactionId,
          kind: supplier.kind,
          itemId: picked.itemId,
        ),
    done: l10n.replacementProposed,
  );
}

Future<void> _withdrawProposal(
  BuildContext context,
  WidgetRef ref,
  String proposalId,
  String eventId,
) =>
    _run(
      context,
      ref,
      eventId,
      () => ref.read(spacesRepositoryProvider).withdrawProposal(proposalId),
      done: context.l10n.replacementWithdrawn,
    );

/// Runs a change to the event, refreshes it, and says how it went; the API's
/// reason is shown when it refuses.
Future<void> _run(
  BuildContext context,
  WidgetRef ref,
  String eventId,
  Future<void> Function() action, {
  required String done,
}) async {
  final l10n = context.l10n;
  try {
    await action();
    ref
      ..invalidate(bookedEventProvider(eventId))
      ..invalidate(eventsNeedingAttentionProvider);
    if (!context.mounted) return;
    showTopToast(context, done);
  } on Object catch (e) {
    if (!context.mounted) return;
    showTopToast(
      context,
      e is AppException && e.message.isNotEmpty
          ? e.message
          : l10n.requestActionFailed,
    );
  }
}

/// Listings like [supplier]'s that are free on the event's dates; tapping one
/// returns it.
class _ReplacementSheet extends ConsumerWidget {
  const _ReplacementSheet({required this.supplier});

  final BookedSupplier supplier;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final key = (supplier.transactionId, supplier.kind);
    final candidates = ref.watch(replacementsProvider(key));

    return SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.75,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 4),
              child: Text(
                l10n.replacementPickTitle(supplier.itemName),
                style: AppTypography.display(size: 20),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: Text(
                l10n.replacementPickBody,
                style: AppTypography.body(
                  size: 13,
                  color: AppColors.textMuted,
                ),
              ),
            ),
            Flexible(
              child: candidates.when(
                loading: () => const Padding(
                  padding: EdgeInsets.all(24),
                  child: Center(
                    child: CircularProgressIndicator(color: AppColors.accent),
                  ),
                ),
                error: (_, __) => AppStateView(
                  kind: AppStateKind.error,
                  title: l10n.requestActionFailed,
                  actionLabel: l10n.retry,
                  onAction: () => ref.invalidate(replacementsProvider(key)),
                ),
                data: (list) => list.isEmpty
                    ? Padding(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                        child: Text(
                          l10n.replacementNone,
                          style: AppTypography.body(
                            color: AppColors.textMuted,
                          ),
                        ),
                      )
                    : ListView.separated(
                        shrinkWrap: true,
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                        itemCount: list.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemBuilder: (_, i) => _CandidateTile(
                          candidate: list[i],
                          onTap: () => Navigator.of(context).pop(list[i]),
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CandidateTile extends StatelessWidget {
  const _CandidateTile({required this.candidate, required this.onTap});

  final ReplacementCandidate candidate;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final locale = Localizations.localeOf(context).toString();
    final price = formatMoney(candidate.price, kBaseCurrency, locale: locale);

    return Material(
      color: AppColors.canvas,
      borderRadius: AppRadius.brMd,
      child: InkWell(
        borderRadius: AppRadius.brMd,
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(candidate.name, style: AppTypography.display()),
                    Text(
                      candidate.supplierName,
                      style: AppTypography.body(
                        size: 13,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    l10n.replacementPriceBeforeFees(price),
                    style: AppTypography.body(size: 13),
                  ),
                  if (candidate.partner)
                    Text(
                      l10n.replacementPartner.toUpperCase(),
                      style: AppTypography.label(color: AppColors.accent),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Body extends StatelessWidget {
  const _Body({
    required this.event,
    required this.onWithdraw,
    this.onReplace,
    this.onDecline,
  });

  final BookedEvent event;

  /// Set while the booking is unpaid and a Supplier may still be replaced.
  final void Function(BookedSupplier)? onReplace;

  /// Takes back a replacement still waiting for the citizen.
  final void Function(String proposalId) onWithdraw;

  /// Set while the booking is unpaid and the host may still leave it.
  final VoidCallback? onDecline;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final locale = Localizations.localeOf(context).toString();
    final when = event.startAt == null
        ? null
        : DateFormat.yMMMEd(locale).add_jm().format(event.startAt!);

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
      children: [
        Text(event.eventName, style: AppTypography.display(size: 24)),
        if (when != null) ...[
          const SizedBox(height: 4),
          Text(
            when,
            style: AppTypography.body(color: AppColors.textMuted),
          ),
        ],
        if (event.needsReplacement) ...[
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: AppRadius.brMd,
              border: Border.all(color: AppColors.error),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.swap_horiz_rounded,
                  size: 20,
                  color: AppColors.error,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.bookedEventNeeds,
                        style: AppTypography.display(size: 15),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        l10n.bookedEventNeedsBody,
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
        ],
        const SizedBox(height: 20),
        Text(
          l10n.bookedEventSuppliers.toUpperCase(),
          style: AppTypography.label(),
        ),
        const SizedBox(height: 8),
        if (event.suppliers.isEmpty)
          Text(
            l10n.bookedEventNone,
            style: AppTypography.body(color: AppColors.textMuted),
          )
        else
          for (final s in event.suppliers)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _SupplierRow(
                supplier: s,
                onReplace: onReplace == null ||
                        s.problem == null ||
                        s.transactionId.isEmpty
                    ? null
                    : () => onReplace!(s),
                onWithdraw: s.pendingProposalId == null
                    ? null
                    : () => onWithdraw(s.pendingProposalId!),
              ),
            ),
        if (onDecline != null) ...[
          const SizedBox(height: 24),
          OutlinedButton(
            onPressed: onDecline,
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.error,
              side: const BorderSide(color: AppColors.error),
            ),
            child: Text(l10n.hostDeclineButton),
          ),
        ],
      ],
    );
  }
}

class _SupplierRow extends StatelessWidget {
  const _SupplierRow({required this.supplier, this.onReplace, this.onWithdraw});

  final BookedSupplier supplier;

  /// Offered on a Supplier that needs replacing, while the booking is unpaid.
  final VoidCallback? onReplace;

  /// Set while a proposed replacement waits for the citizen.
  final VoidCallback? onWithdraw;

  static String _status(AppLocalizations l10n, RequestStatus s) => switch (s) {
        RequestStatus.awaitingYou => l10n.requestStatusAwaiting,
        RequestStatus.pending => l10n.requestStatusPending,
        RequestStatus.approved => l10n.requestStatusApproved,
        RequestStatus.rejected => l10n.requestStatusRejected,
        RequestStatus.cancelled => l10n.requestStatusCancelled,
        RequestStatus.other => '',
      };

  static String _reason(
    AppLocalizations l10n,
    AttentionReason r, {
    required bool busy,
  }) =>
      switch (r) {
        AttentionReason.declined when busy => l10n.bookedReasonBusy,
        AttentionReason.declined => l10n.bookedReasonDeclined,
        AttentionReason.dateBlocked => l10n.bookedReasonDateBlocked,
        AttentionReason.unavailable => l10n.bookedReasonUnavailable,
      };

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final problem = supplier.problem;
    final status = _status(l10n, supplier.status);
    final icon = switch (supplier.kind) {
      RequestKind.venue => Icons.apartment_rounded,
      RequestKind.asset => Icons.speaker_outlined,
      RequestKind.service => Icons.camera_alt_outlined,
    };

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.brMd,
        border: Border.all(
          color: problem != null ? AppColors.error : AppColors.border,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: AppColors.textPrimary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(supplier.itemName, style: AppTypography.display()),
                Text(
                  supplier.supplierName,
                  style: AppTypography.body(
                    size: 13,
                    color: AppColors.textMuted,
                  ),
                ),
                if (problem != null) ...[
                  const SizedBox(height: 6),
                  Text(
                    _reason(l10n, problem, busy: supplier.busy),
                    style: AppTypography.body(
                      size: 13,
                      color: AppColors.error,
                    ),
                  ),
                  if (supplier.replaceBy case final due?) ...[
                    const SizedBox(height: 4),
                    Text(
                      due.isAfter(DateTime.now())
                          ? l10n.bookedReplaceBy(
                              DateFormat(
                                'EEE d MMM, h:mm a',
                                Localizations.localeOf(context).toString(),
                              ).format(due),
                            )
                          : l10n.bookedReplacePast,
                      style: AppTypography.body(
                        size: 12,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                  if (onWithdraw != null) ...[
                    const SizedBox(height: 6),
                    Text(
                      l10n.replacementWaiting,
                      style: AppTypography.body(
                        size: 13,
                        color: AppColors.textMuted,
                      ),
                    ),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: TextButton(
                        onPressed: onWithdraw,
                        style: TextButton.styleFrom(
                          minimumSize: const Size(0, 44),
                          padding: EdgeInsets.zero,
                        ),
                        child: Text(l10n.replacementWithdraw),
                      ),
                    ),
                  ] else if (onReplace != null)
                    Align(
                      alignment: Alignment.centerLeft,
                      child: TextButton.icon(
                        onPressed: onReplace,
                        style: TextButton.styleFrom(
                          minimumSize: const Size(0, 44),
                          padding: EdgeInsets.zero,
                        ),
                        icon: const Icon(Icons.swap_horiz_rounded, size: 18),
                        label: Text(l10n.replacementFind),
                      ),
                    ),
                ],
              ],
            ),
          ),
          if (status.isNotEmpty && problem == null) ...[
            const SizedBox(width: 8),
            Text(
              status,
              style: AppTypography.body(size: 12, color: AppColors.textMuted),
            ),
          ],
        ],
      ),
    );
  }
}
