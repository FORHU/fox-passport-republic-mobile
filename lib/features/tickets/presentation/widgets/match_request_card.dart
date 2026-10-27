import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_template/core/errors/exceptions.dart';
import 'package:flutter_template/core/utils/context_extensions.dart';
import 'package:flutter_template/features/tickets/presentation/widgets/cancel_sheet.dart';
import 'package:flutter_template/l10n/generated/app_localizations.dart';
import 'package:flutter_template/routes/route_names.dart';
import 'package:flutter_template/shared/catalog/catalog_item.dart';
import 'package:flutter_template/shared/currency/currency.dart';
import 'package:flutter_template/shared/formatting/money.dart';
import 'package:flutter_template/shared/matches/match_request_item.dart';
import 'package:flutter_template/shared/payments/payments_repository.dart';
import 'package:flutter_template/shared/tickets/ticket.dart';
import 'package:flutter_template/shared/widgets/top_toast.dart';
import 'package:flutter_template/theme/tokens/colors.dart';
import 'package:flutter_template/theme/tokens/radius.dart';
import 'package:flutter_template/theme/tokens/typography.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

/// One Match request: what was asked, of whom, and where it stands, with the
/// next thing to do (pay once accepted, or withdraw).
class MatchRequestCard extends ConsumerStatefulWidget {
  const MatchRequestCard({required this.item, super.key});

  final MatchRequestItem item;

  @override
  ConsumerState<MatchRequestCard> createState() => _MatchRequestCardState();
}

class _MatchRequestCardState extends ConsumerState<MatchRequestCard> {
  bool _paying = false;

  Future<void> _pay() async {
    final l10n = context.l10n;
    final item = widget.item;
    setState(() => _paying = true);
    try {
      await ref.read(paymentsRepositoryProvider).payBooking(
            bookingId: item.bookingId,
            amount: item.total,
            currency: kBaseCurrency,
          );
      ref.invalidate(myMatchRequestsProvider);
    } on PaymentsUnavailable {
      if (mounted) showTopToast(context, l10n.bookPaymentsSoon);
    } on PaymentCancelled {
      if (mounted) showTopToast(context, l10n.bookPaymentCancelled);
    } on Object catch (e) {
      if (mounted) {
        showTopToast(context, e is AppException ? e.message : l10n.bookFailed);
      }
    } finally {
      if (mounted) setState(() => _paying = false);
    }
  }

  Future<void> _withdraw() async {
    final item = widget.item;
    // The cancel sheet works on a booking, which is what a request is.
    final done = await showCancelSheet(
      context,
      Ticket(
        id: item.bookingId,
        eventName: item.style,
        startAt: item.startAt,
        endAt: item.startAt.add(const Duration(hours: 4)),
        status: item.bookingStatus,
        guestCount: item.guests,
      ),
    );
    if (done) ref.invalidate(myMatchRequestsProvider);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final locale = Localizations.localeOf(context).toString();
    final item = widget.item;
    final (label, color) = _status(l10n, item.state);
    final title = item.style == 'Own idea' ? l10n.matchOwnIdea : item.style;
    final when = DateFormat('EEE d MMM', locale).format(item.startAt);

    return InkWell(
      onTap: item.foxerId == null
          ? null
          : () => unawaited(
                context.push(
                  RouteNames.foxer,
                  extra: CatalogItem(
                    id: item.foxerId!,
                    kind: CatalogKind.foxers,
                    title: item.foxerName,
                    imageUrl: item.foxerImageUrl,
                  ),
                ),
              ),
      borderRadius: AppRadius.brMd,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: AppRadius.brMd,
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label.toUpperCase(), style: AppTypography.label(color: color)),
            const SizedBox(height: 8),
            Text(title, style: AppTypography.display(size: 18)),
            const SizedBox(height: 4),
            Text(
              [
                if (item.foxerName.isNotEmpty) item.foxerName,
                when,
                l10n.guestsCount(item.guests),
              ].join(' · '),
              style: AppTypography.body(size: 13),
            ),
            if (item.total > 0) ...[
              const SizedBox(height: 8),
              Text(
                formatMoney(item.total, kBaseCurrency, locale: locale),
                style: AppTypography.display(),
              ),
            ],
            if (item.state == MatchState.waiting) ...[
              const SizedBox(height: 8),
              Text(
                l10n.matchWaitingNote(
                  item.foxerName.isEmpty ? l10n.matchTheFoxer : item.foxerName,
                ),
                style: AppTypography.body(size: 12),
              ),
            ],
            if (item.needsPayment || item.canWithdraw) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  if (item.needsPayment)
                    Expanded(
                      child: SizedBox(
                        height: 48,
                        child: ElevatedButton(
                          onPressed: _paying ? null : _pay,
                          style: ElevatedButton.styleFrom(
                            minimumSize: const Size(0, 48),
                            backgroundColor: AppColors.accent,
                            foregroundColor: AppColors.onAccent,
                            shape: RoundedRectangleBorder(
                              borderRadius: AppRadius.brSm,
                            ),
                          ),
                          child: _paying
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: AppColors.onAccent,
                                  ),
                                )
                              : Text(l10n.matchPayNow),
                        ),
                      ),
                    ),
                  if (item.needsPayment && item.canWithdraw)
                    const SizedBox(width: 12),
                  if (item.canWithdraw)
                    TextButton(
                      onPressed: _withdraw,
                      style: TextButton.styleFrom(
                        minimumSize: const Size(0, 48),
                      ),
                      child: Text(
                        l10n.matchWithdraw,
                        style: AppTypography.body(
                          color: AppColors.error,
                          weight: FontWeight.w600,
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  static (String, Color) _status(AppLocalizations l10n, MatchState state) =>
      switch (state) {
        MatchState.waiting => (l10n.matchStateWaiting, AppColors.warning),
        MatchState.accepted => (l10n.matchStateAccepted, AppColors.accent),
        MatchState.confirmed => (l10n.matchStateConfirmed, AppColors.success),
        MatchState.declined => (l10n.matchStateDeclined, AppColors.error),
      };
}
