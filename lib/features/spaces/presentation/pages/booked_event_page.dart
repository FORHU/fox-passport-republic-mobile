import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_template/core/utils/context_extensions.dart';
import 'package:flutter_template/features/spaces/data/spaces_repository.dart';
import 'package:flutter_template/features/spaces/domain/space_models.dart';
import 'package:flutter_template/l10n/generated/app_localizations.dart';
import 'package:flutter_template/shared/widgets/app_state_view.dart';
import 'package:flutter_template/theme/tokens/colors.dart';
import 'package:flutter_template/theme/tokens/radius.dart';
import 'package:flutter_template/theme/tokens/typography.dart';
import 'package:intl/intl.dart';

/// One booked event of the Event Foxer's: when it is, and every Supplier on it
/// with where each stands. A Supplier that declined, whose day was blocked or
/// whose listing is gone is marked and says why, so it is clear what to
/// replace. It is the place replacing a Supplier will live.
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
          child: _Body(event: e),
        ),
      ),
    );
  }
}

class _Body extends StatelessWidget {
  const _Body({required this.event});

  final BookedEvent event;

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
              child: _SupplierRow(supplier: s),
            ),
      ],
    );
  }
}

class _SupplierRow extends StatelessWidget {
  const _SupplierRow({required this.supplier});

  final BookedSupplier supplier;

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
