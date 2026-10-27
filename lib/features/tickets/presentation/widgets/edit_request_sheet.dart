import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_template/core/errors/exceptions.dart';
import 'package:flutter_template/core/utils/context_extensions.dart';
import 'package:flutter_template/l10n/generated/app_localizations.dart';
import 'package:flutter_template/shared/currency/currency.dart';
import 'package:flutter_template/shared/currency/currency_providers.dart';
import 'package:flutter_template/shared/tickets/edit_request.dart';
import 'package:flutter_template/shared/tickets/edit_requests_repository.dart';
import 'package:flutter_template/shared/tickets/ticket.dart';
import 'package:flutter_template/shared/widgets/top_toast.dart';
import 'package:flutter_template/theme/tokens/colors.dart';
import 'package:flutter_template/theme/tokens/radius.dart';
import 'package:flutter_template/theme/tokens/typography.dart';
import 'package:intl/intl.dart';

/// Asks the venue to change a booking's guests or dates, or shows how the
/// request already sent is doing and lets you withdraw it.
Future<void> showEditRequestSheet(BuildContext context, Ticket ticket) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (_) => _EditRequestSheet(ticket: ticket),
  );
}

class _EditRequestSheet extends ConsumerStatefulWidget {
  const _EditRequestSheet({required this.ticket});

  final Ticket ticket;

  @override
  ConsumerState<_EditRequestSheet> createState() => _EditRequestSheetState();
}

class _EditRequestSheetState extends ConsumerState<_EditRequestSheet> {
  late int _guests = widget.ticket.guestCount;
  DateTimeRange? _range;
  final _reason = TextEditingController();
  bool _busy = false;

  @override
  void dispose() {
    _reason.dispose();
    super.dispose();
  }

  bool get _changed => _guests != widget.ticket.guestCount || _range != null;

  Future<void> _pickDates() async {
    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(now.year, now.month, now.day),
      lastDate: DateTime(now.year + 2),
      initialDateRange: _range ??
          DateTimeRange(
            start: widget.ticket.startAt,
            end: widget.ticket.endAt,
          ),
    );
    if (picked != null && mounted) setState(() => _range = picked);
  }

  /// A picked day keeps the booking's own time of day.
  DateTime _withTime(DateTime day, DateTime time) =>
      DateTime(day.year, day.month, day.day, time.hour, time.minute);

  Future<void> _send() async {
    final l10n = context.l10n;
    final ticket = widget.ticket;
    final range = _range;
    setState(() => _busy = true);
    try {
      await ref.read(editRequestsRepositoryProvider).create(
            ticket.id,
            guests: _guests == ticket.guestCount ? null : _guests,
            start:
                range == null ? null : _withTime(range.start, ticket.startAt),
            end: range == null ? null : _withTime(range.end, ticket.endAt),
            reason: _reason.text,
          );
      ref.invalidate(editRequestProvider(ticket.id));
      if (!mounted) return;
      setState(() => _busy = false);
      showTopToast(context, l10n.editRequestSent);
    } on Object catch (e) {
      if (!mounted) return;
      setState(() => _busy = false);
      showTopToast(
        context,
        e is AppException ? e.message : l10n.editRequestFailed,
      );
    }
  }

  Future<void> _withdraw(EditRequest request) async {
    final l10n = context.l10n;
    setState(() => _busy = true);
    try {
      await ref.read(editRequestsRepositoryProvider).withdraw(request.id);
      ref.invalidate(editRequestProvider(widget.ticket.id));
      if (!mounted) return;
      setState(() => _busy = false);
      showTopToast(context, l10n.editRequestWithdrawn);
    } on Object catch (e) {
      if (!mounted) return;
      setState(() => _busy = false);
      showTopToast(
        context,
        e is AppException ? e.message : l10n.editRequestFailed,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final async = ref.watch(editRequestProvider(widget.ticket.id));

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          16,
          16,
          16,
          16 + MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.editRequestTitle,
                style: AppTypography.display(size: 18),
              ),
              const SizedBox(height: 4),
              Text(widget.ticket.eventName, style: AppTypography.body()),
              const SizedBox(height: 16),
              async.when(
                loading: () => const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Center(
                    child: CircularProgressIndicator(color: AppColors.accent),
                  ),
                ),
                error: (e, _) => Text(
                  e is AppException ? e.message : l10n.editRequestFailed,
                  style: AppTypography.body(color: AppColors.error),
                ),
                data: (request) => request != null && request.isPending
                    ? _Pending(
                        request: request,
                        busy: _busy,
                        onWithdraw: () => _withdraw(request),
                      )
                    : _form(l10n, request),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _form(AppLocalizations l10n, EditRequest? last) {
    final locale = Localizations.localeOf(context).toString();
    final fmt = DateFormat.MMMd(locale);
    final range = _range;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (last != null) ...[
          _Outcome(request: last),
          const SizedBox(height: 16),
        ],
        Row(
          children: [
            Expanded(
              child: Text(
                l10n.editRequestGuests,
                style: AppTypography.body(color: AppColors.textPrimary),
              ),
            ),
            IconButton(
              onPressed: _guests > 1 ? () => setState(() => _guests--) : null,
              icon: const Icon(Icons.remove_circle_outline_rounded),
            ),
            Text('$_guests', style: AppTypography.display(size: 18)),
            IconButton(
              onPressed: () => setState(() => _guests++),
              icon: const Icon(Icons.add_circle_outline_rounded),
            ),
          ],
        ),
        OutlinedButton.icon(
          onPressed: _busy ? null : _pickDates,
          icon: const Icon(Icons.calendar_today_outlined, size: 18),
          label: Text(
            range == null
                ? l10n.editRequestDates
                : '${fmt.format(range.start)} – ${fmt.format(range.end)}',
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _reason,
          maxLines: 2,
          decoration: InputDecoration(hintText: l10n.editRequestReason),
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          height: 48,
          child: ElevatedButton(
            onPressed: _busy || !_changed ? null : _send,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.accent,
              foregroundColor: AppColors.onAccent,
              shape: RoundedRectangleBorder(borderRadius: AppRadius.brSm),
            ),
            child: Text(l10n.editRequestSend),
          ),
        ),
      ],
    );
  }
}

class _Pending extends StatelessWidget {
  const _Pending({
    required this.request,
    required this.busy,
    required this.onWithdraw,
  });

  final EditRequest request;
  final bool busy;
  final VoidCallback onWithdraw;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _Outcome(request: request),
        if (request.canWithdraw) ...[
          const SizedBox(height: 12),
          OutlinedButton(
            onPressed: busy ? null : onWithdraw,
            child: Text(l10n.editRequestWithdraw),
          ),
        ],
      ],
    );
  }
}

/// How the request stands, with what it would cost.
class _Outcome extends ConsumerWidget {
  const _Outcome({required this.request});

  final EditRequest request;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final locale = Localizations.localeOf(context).toString();
    final formatter = ref.watch(moneyFormatterProvider);
    String money(num v) => formatter.format(v, kBaseCurrency, locale: locale);
    final delta = request.proposedTotal - request.currentTotal;

    final label = switch (request.status) {
      'pending' => l10n.editRequestPending,
      'approved' => request.awaitsPayment
          ? l10n.editRequestPayOnWeb
          : l10n.editRequestApplied,
      'declined' => l10n.editRequestDeclined,
      'withdrawn' => l10n.editRequestWithdrawnStatus,
      _ => l10n.editRequestExpired,
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTypography.body(
            color: AppColors.textPrimary,
            weight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '${money(request.currentTotal)} → ${money(request.proposedTotal)}'
          ' (${delta >= 0 ? '+' : '−'}${money(delta.abs())})',
          style: AppTypography.body(),
        ),
        if (request.declineReason != null) ...[
          const SizedBox(height: 4),
          Text(request.declineReason!, style: AppTypography.body()),
        ],
      ],
    );
  }
}
