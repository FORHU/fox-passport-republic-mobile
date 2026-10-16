import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_template/core/errors/exceptions.dart';
import 'package:flutter_template/core/utils/context_extensions.dart';
import 'package:flutter_template/shared/currency/currency.dart';
import 'package:flutter_template/shared/formatting/money.dart';
import 'package:flutter_template/shared/tickets/cancel_quote.dart';
import 'package:flutter_template/shared/tickets/ticket.dart';
import 'package:flutter_template/shared/tickets/tickets_repository.dart';
import 'package:flutter_template/shared/widgets/top_toast.dart';
import 'package:flutter_template/theme/tokens/colors.dart';
import 'package:flutter_template/theme/tokens/radius.dart';
import 'package:flutter_template/theme/tokens/typography.dart';

/// Asks what cancelling would return and, if the user agrees, cancels.
/// Resolves to true when the booking was cancelled.
Future<bool> showCancelSheet(BuildContext context, Ticket ticket) async {
  final done = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (_) => _CancelSheet(ticket: ticket),
  );
  return done ?? false;
}

class _CancelSheet extends ConsumerStatefulWidget {
  const _CancelSheet({required this.ticket});

  final Ticket ticket;

  @override
  ConsumerState<_CancelSheet> createState() => _CancelSheetState();
}

class _CancelSheetState extends ConsumerState<_CancelSheet> {
  bool _cancelling = false;

  Future<void> _cancel() async {
    final l10n = context.l10n;
    setState(() => _cancelling = true);
    try {
      await ref.read(ticketsRepositoryProvider).cancel(widget.ticket.id);
      ref
        ..invalidate(upcomingTicketsProvider)
        ..invalidate(pastTicketsProvider);
      if (!mounted) return;
      Navigator.of(context).pop(true);
      showTopToast(context, l10n.cancelDone);
    } on Object catch (e) {
      if (!mounted) return;
      setState(() => _cancelling = false);
      showTopToast(context, e is AppException ? e.message : l10n.cancelFailed);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final locale = Localizations.localeOf(context).toString();
    final quote = ref.watch(cancelQuoteProvider(widget.ticket.id));

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.cancelTitle, style: AppTypography.display(size: 18)),
            const SizedBox(height: 4),
            Text(widget.ticket.eventName, style: AppTypography.body()),
            const SizedBox(height: 16),
            quote.when(
              loading: () => const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Center(
                  child: CircularProgressIndicator(color: AppColors.accent),
                ),
              ),
              error: (e, _) => Text(
                e is AppException ? e.message : l10n.cancelFailed,
                style: AppTypography.body(color: AppColors.error),
              ),
              data: (q) => _Quote(quote: q, locale: locale),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 48,
                    child: OutlinedButton(
                      onPressed: _cancelling
                          ? null
                          : () => Navigator.of(context).pop(false),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(0, 48),
                        side: const BorderSide(color: AppColors.borderStrong),
                        shape: RoundedRectangleBorder(
                          borderRadius: AppRadius.brSm,
                        ),
                      ),
                      child: Text(l10n.cancelKeep),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: SizedBox(
                    height: 48,
                    child: ElevatedButton(
                      onPressed:
                          _cancelling || !(quote.value?.eligible ?? false)
                              ? null
                              : _cancel,
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(0, 48),
                        backgroundColor: AppColors.error,
                        foregroundColor: AppColors.canvas,
                        shape: RoundedRectangleBorder(
                          borderRadius: AppRadius.brSm,
                        ),
                      ),
                      child: _cancelling
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppColors.canvas,
                              ),
                            )
                          : Text(l10n.cancelConfirm),
                    ),
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

class _Quote extends StatelessWidget {
  const _Quote({required this.quote, required this.locale});

  final CancelQuote quote;
  final String locale;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    // What was paid is in the platform currency; the API gives no other.
    String money(num v) => formatMoney(v, kBaseCurrency, locale: locale);

    if (!quote.eligible) {
      return Text(
        quote.message.isEmpty ? l10n.cancelNotEligible : quote.message,
        style: AppTypography.body(color: AppColors.warning),
      );
    }
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.canvas,
        borderRadius: AppRadius.brSm,
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _Line(l10n.cancelPaid, money(quote.totalPaid)),
          const SizedBox(height: 8),
          _Line(
            l10n.cancelRefund,
            quote.hasRefund
                ? '${money(quote.estimatedRefund)} '
                    '(${quote.refundPercent.round()}%)'
                : l10n.cancelNoRefund,
            strong: true,
            accent: quote.hasRefund,
          ),
          if (quote.message.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(quote.message, style: AppTypography.body(size: 12)),
          ],
        ],
      ),
    );
  }
}

class _Line extends StatelessWidget {
  const _Line(
    this.label,
    this.value, {
    this.strong = false,
    this.accent = false,
  });

  final String label;
  final String value;
  final bool strong;
  final bool accent;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: AppTypography.body()),
        Text(
          value,
          style: AppTypography.display(
            size: strong ? 16 : 14,
            color: accent ? AppColors.success : AppColors.textPrimary,
          ),
        ),
      ],
    );
  }
}
