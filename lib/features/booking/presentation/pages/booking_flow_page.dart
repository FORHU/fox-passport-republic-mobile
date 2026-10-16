import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_template/core/errors/exceptions.dart';
import 'package:flutter_template/core/utils/context_extensions.dart';
import 'package:flutter_template/features/booking/data/booking_repository.dart';
import 'package:flutter_template/features/booking/domain/booking_models.dart';
import 'package:flutter_template/features/booking/presentation/widgets/booking_calendar.dart';
import 'package:flutter_template/features/booking/presentation/widgets/booking_result_views.dart';
import 'package:flutter_template/features/messages/data/messages_repository.dart';
import 'package:flutter_template/l10n/generated/app_localizations.dart';
import 'package:flutter_template/routes/route_names.dart';
import 'package:flutter_template/shared/catalog/catalog_item.dart';
import 'package:flutter_template/shared/currency/currency.dart';
import 'package:flutter_template/shared/currency/currency_providers.dart';
import 'package:flutter_template/shared/events/event_package.dart';
import 'package:flutter_template/shared/formatting/money.dart';
import 'package:flutter_template/shared/widgets/photo_box.dart';
import 'package:flutter_template/shared/widgets/top_toast.dart';
import 'package:flutter_template/theme/tokens/colors.dart';
import 'package:flutter_template/theme/tokens/radius.dart';
import 'package:flutter_template/theme/tokens/typography.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

enum _Step { dates, guests, review, pay, done }

/// Venue booking, full screen: dates, guests, review, pay, then the ticket or
/// the "request sent" notice. The selection and the next action stay pinned
/// to the bottom of every step.
class BookingFlowPage extends ConsumerStatefulWidget {
  const BookingFlowPage({
    required this.venue,
    this.package,
    this.excluded = const {},
    super.key,
  });

  /// The venue being booked, or the event when [package] is set.
  final CatalogItem venue;
  final EventPackage? package;
  final Set<String> excluded;

  @override
  ConsumerState<BookingFlowPage> createState() => _BookingFlowPageState();
}

class _BookingFlowPageState extends ConsumerState<BookingFlowPage> {
  static const _maxGuests = 100000;

  late BookingSelection _selection = BookingSelection(
    venue: widget.venue,
    package: widget.package,
    excluded: widget.excluded,
    // An event starts at two guests, as on the web; a venue at what it holds.
    guests: widget.package != null
        ? math.min(2, widget.package!.spotsLeft ?? 2).clamp(1, 2)
        : math.max(1, widget.venue.capacity ?? 1),
  );
  final _today = DateTime.now();
  late DateTime _month = DateTime(_today.year, _today.month);
  final _notes = TextEditingController();

  _Step _step = _Step.dates;
  Set<DateTime> _unavailable = {};

  VenuePricing? _pricing;
  String? _priceError;
  bool _priceLoading = false;

  BookingReceipt? _receipt;
  bool _paying = false;

  @override
  void initState() {
    super.initState();
    unawaited(_loadUnavailable());
  }

  @override
  void dispose() {
    _notes.dispose();
    super.dispose();
  }

  Future<void> _loadUnavailable() async {
    try {
      final days = await ref.read(bookingRepositoryProvider).unavailableDates(
            widget.venue,
            templateId: widget.package?.id,
            from: DateTime(_today.year, _today.month, _today.day),
          );
      if (mounted) setState(() => _unavailable = days);
    } on Object {
      // Without the list every day is offered; the server still refuses a
      // day that is taken.
    }
  }

  Future<void> _loadPrice() async {
    setState(() {
      _priceLoading = true;
      _priceError = null;
      _pricing = null;
    });
    final l10n = context.l10n;
    try {
      final price = await ref.read(bookingRepositoryProvider).price(_selection);
      if (mounted) setState(() => _pricing = price);
    } on AppException catch (e) {
      if (mounted) setState(() => _priceError = e.message);
    } on Object {
      if (mounted) setState(() => _priceError = l10n.bookPriceFailed);
    } finally {
      if (mounted) setState(() => _priceLoading = false);
    }
  }

  void _go(_Step step) {
    setState(() => _step = step);
    if (step == _Step.review) unawaited(_loadPrice());
  }

  void _back() {
    switch (_step) {
      case _Step.dates:
      case _Step.done:
        context.pop();
      case _Step.guests:
        _go(_Step.dates);
      case _Step.review:
        _go(_Step.guests);
      case _Step.pay:
        _go(_Step.review);
    }
  }

  /// Review's button: a request is sent as is; otherwise on to payment.
  Future<void> _continueFromReview() async {
    final price = _pricing;
    if (price == null) return;
    if (!price.needsApproval) {
      _go(_Step.pay);
      return;
    }
    setState(() => _paying = true);
    try {
      final receipt =
          await ref.read(bookingRepositoryProvider).create(_selection, price);
      if (!mounted) return;
      setState(() {
        _receipt = receipt;
        _step = _Step.done;
      });
    } on Object catch (e) {
      if (mounted) {
        showTopToast(
          context,
          e is AppException ? e.message : context.l10n.bookFailed,
        );
      }
    } finally {
      if (mounted) setState(() => _paying = false);
    }
  }

  /// Opens the venue's inbox chat, where the owner answers.
  Future<void> _messageOwner() async {
    final l10n = context.l10n;
    final venue = _selection.venue;
    if (venue.isSample) {
      showTopToast(context, l10n.messageOwnerSample);
      return;
    }
    try {
      final id = await ref.read(messagesRepositoryProvider).startVenueInbox(
            venue.id,
          );
      ref.invalidate(conversationsProvider);
      if (mounted) unawaited(context.push(RouteNames.chat(id)));
    } on Object catch (e) {
      if (mounted) {
        showTopToast(
          context,
          e is AppException ? e.message : l10n.messageStartFailed,
        );
      }
    }
  }

  Future<void> _pay() async {
    final price = _pricing;
    if (price == null || _paying) return;
    final l10n = context.l10n;
    final repo = ref.read(bookingRepositoryProvider);
    setState(() => _paying = true);
    try {
      // Create the booking once; a retry after a failed payment reuses it.
      final receipt = _receipt ?? await repo.create(_selection, price);
      _receipt = receipt;
      await repo.pay(receipt);
      if (mounted) setState(() => _step = _Step.done);
    } on PaymentsUnavailable {
      if (mounted) showTopToast(context, l10n.bookPaymentsSoon);
    } on Object catch (e) {
      if (mounted) {
        showTopToast(context, e is AppException ? e.message : l10n.bookFailed);
      }
    } finally {
      if (mounted) setState(() => _paying = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final locale = Localizations.localeOf(context).toString();

    return PopScope(
      canPop: _step == _Step.dates || _step == _Step.done,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _back();
      },
      child: Scaffold(
        backgroundColor: AppColors.canvas,
        body: SafeArea(
          child: switch (_step) {
            _Step.done => _receipt == null
                ? const SizedBox.shrink()
                : _receipt!.needsApproval
                    ? BookingRequestSentView(
                        selection: _selection,
                        receipt: _receipt!,
                        onMessageOwner: _messageOwner,
                        onBackHome: () => context.go(RouteNames.home),
                      )
                    : BookingConfirmedView(
                        selection: _selection,
                        receipt: _receipt!,
                        onViewTicket: () => context.go(RouteNames.tickets),
                        onMessageOwner: _messageOwner,
                      ),
            _ => Column(
                children: [
                  _Header(
                    title: _step == _Step.pay
                        ? l10n.bookPayTitle
                        : _selection.venue.title,
                    leadingIcon: _step == _Step.dates
                        ? Icons.close_rounded
                        : Icons.arrow_back_rounded,
                    leadingLabel:
                        _step == _Step.dates ? l10n.bookClose : l10n.bookBack,
                    onLeading: _back,
                    counter: switch (_step) {
                      _Step.dates => l10n.bookStepCounter(1, 3),
                      _Step.guests => l10n.bookStepCounter(2, 3),
                      _Step.review => l10n.bookStepCounter(3, 3),
                      _ => null,
                    },
                    filled: switch (_step) {
                      _Step.dates => 1,
                      _Step.guests => 2,
                      _Step.review => 3,
                      _ => 0,
                    },
                    title2: _step == _Step.review ? l10n.bookReviewTitle : null,
                  ),
                  Expanded(child: _body(l10n, locale)),
                  _bottomBar(l10n, locale),
                ],
              ),
          },
        ),
      ),
    );
  }

  Widget _body(AppLocalizations l10n, String locale) {
    return switch (_step) {
      _Step.dates => ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
          children: [
            Text(l10n.bookWhenTitle, style: AppTypography.display(size: 24)),
            const SizedBox(height: 16),
            BookingCalendar(
              month: _month,
              today: _today,
              selected: _selection.date,
              unavailable: _unavailable,
              onSelect: (d) =>
                  setState(() => _selection = _selection.copyWith(date: d)),
              onMonthChanged: (m) => setState(() => _month = m),
            ),
          ],
        ),
      _Step.guests => ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
          children: [
            Text(l10n.bookGuestsTitle, style: AppTypography.display(size: 24)),
            const SizedBox(height: 16),
            _GuestStepper(
              count: _selection.guests,
              capacity: _selection.venue.capacity,
              max: _selection.package?.spotsLeft ?? _maxGuests,
              onChanged: (n) =>
                  setState(() => _selection = _selection.copyWith(guests: n)),
            ),
            if (_selection.isOverCapacity) ...[
              const SizedBox(height: 12),
              _Notice(
                text: l10n.bookOverCapacity(_selection.overCapacity),
              ),
            ],
            const SizedBox(height: 24),
            Text(l10n.bookNotesTitle, style: AppTypography.display(size: 15)),
            const SizedBox(height: 10),
            _NotesField(
              controller: _notes,
              hint: l10n.bookNotesHint,
              onChanged: (v) => _selection = _selection.copyWith(notes: v),
            ),
          ],
        ),
      _Step.review => _Review(
          selection: _selection,
          pricing: _pricing,
          loading: _priceLoading,
          error: _priceError,
          locale: locale,
          formatter: ref.watch(moneyFormatterProvider),
          onEditDate: () => _go(_Step.dates),
          onEditGuests: () => _go(_Step.guests),
          onVoucher: () => showTopToast(context, l10n.comingSoonVoucher),
        ),
      _Step.pay => _Pay(
          total: _pricing?.totalAmount ?? 0,
          currency: _selection.venue.currency,
          venue: _selection.venue.title,
          date: _selection.date,
          locale: locale,
          formatter: ref.watch(moneyFormatterProvider),
          onTap: _pay,
        ),
      _Step.done => const SizedBox.shrink(),
    };
  }

  Widget _bottomBar(AppLocalizations l10n, String locale) {
    final date = _selection.date;
    final shortDate =
        date == null ? null : DateFormat('EEE d MMM', locale).format(date);

    Widget wide(String label, VoidCallback? onTap, {bool loading = false}) =>
        _PillButton(label: label, onTap: onTap, loading: loading, wide: true);

    final body = switch (_step) {
      _Step.dates => _SummaryRow(
          title: shortDate ?? l10n.bookPickDate,
          subtitle: date == null ? null : l10n.bookDayCount(1),
          button: _PillButton(
            label: l10n.bookNext,
            onTap: date == null ? null : () => _go(_Step.guests),
          ),
        ),
      _Step.guests => _SummaryRow(
          title: shortDate ?? '',
          subtitle: l10n.guestsCount(_selection.guests),
          button: _PillButton(
            label: l10n.bookNext,
            onTap: () => _go(_Step.review),
          ),
        ),
      _Step.review => wide(
          (_pricing?.needsApproval ?? _selection.isOverCapacity)
              ? l10n.bookRequestToBook
              : l10n.bookContinuePay,
          _pricing == null ? null : _continueFromReview,
          loading: _paying,
        ),
      _Step.pay => wide(
          l10n.bookPayAmount(
            formatMoney(
              _pricing?.totalAmount ?? 0,
              _selection.venue.currency,
              locale: locale,
            ),
          ),
          _pay,
          loading: _paying,
        ),
      _Step.done => const SizedBox.shrink(),
    };

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: body,
    );
  }
}

// ── Header ─────────────────────────────────────────────────────────────────

class _Header extends StatelessWidget {
  const _Header({
    required this.title,
    required this.leadingIcon,
    required this.leadingLabel,
    required this.onLeading,
    required this.filled,
    this.counter,
    this.title2,
  });

  final String title;
  final String? title2;
  final IconData leadingIcon;
  final String leadingLabel;
  final VoidCallback onLeading;
  final String? counter;
  final int filled;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 4, 16, 0),
      child: Column(
        children: [
          SizedBox(
            height: 48,
            child: Row(
              children: [
                IconButton(
                  tooltip: leadingLabel,
                  onPressed: onLeading,
                  constraints:
                      const BoxConstraints(minWidth: 44, minHeight: 44),
                  icon: Icon(leadingIcon, size: 22),
                ),
                Expanded(
                  child: Text(
                    title2 ?? title,
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.display(size: 15),
                  ),
                ),
                SizedBox(
                  width: 56,
                  child: counter == null
                      ? null
                      : Text(
                          counter!.toUpperCase(),
                          textAlign: TextAlign.end,
                          style: AppTypography.label(),
                        ),
                ),
              ],
            ),
          ),
          if (filled > 0)
            Padding(
              padding: const EdgeInsets.only(left: 12, top: 4),
              child: Row(
                children: [
                  for (var i = 0; i < 3; i++) ...[
                    if (i > 0) const SizedBox(width: 6),
                    Expanded(
                      child: Container(
                        height: 3,
                        decoration: BoxDecoration(
                          color: i < filled
                              ? AppColors.accent
                              : AppColors.borderStrong,
                          borderRadius: AppRadius.brPill,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
        ],
      ),
    );
  }
}

// ── Bottom bar pieces ──────────────────────────────────────────────────────

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({
    required this.title,
    required this.button,
    this.subtitle,
  });

  final String title;
  final String? subtitle;
  final Widget button;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.display(),
              ),
              if (subtitle != null)
                Text(subtitle!, style: AppTypography.body(size: 13)),
            ],
          ),
        ),
        const SizedBox(width: 12),
        button,
      ],
    );
  }
}

class _PillButton extends StatelessWidget {
  const _PillButton({
    required this.label,
    required this.onTap,
    this.loading = false,
    this.wide = false,
  });

  final String label;
  final VoidCallback? onTap;
  final bool loading;
  final bool wide;

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null && !loading;
    return SizedBox(
      width: wide ? double.infinity : 112,
      height: 52,
      child: ElevatedButton(
        onPressed: enabled ? onTap : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.accent,
          foregroundColor: AppColors.onAccent,
          disabledBackgroundColor: AppColors.accent.withValues(alpha: 0.35),
          disabledForegroundColor: AppColors.onAccent.withValues(alpha: 0.6),
          shape: RoundedRectangleBorder(
            borderRadius: wide ? AppRadius.brSm : AppRadius.brPill,
          ),
        ),
        child: loading
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.onAccent,
                ),
              )
            : Text(
                label,
                style: AppTypography.display(color: AppColors.onAccent),
              ),
      ),
    );
  }
}

// ── Guests ─────────────────────────────────────────────────────────────────

class _GuestStepper extends StatefulWidget {
  const _GuestStepper({
    required this.count,
    required this.capacity,
    required this.max,
    required this.onChanged,
  });

  final int count;
  final int? capacity;
  final int max;
  final ValueChanged<int> onChanged;

  @override
  State<_GuestStepper> createState() => _GuestStepperState();
}

class _GuestStepperState extends State<_GuestStepper> {
  Timer? _repeat;

  void _step(int delta) {
    final next = (widget.count + delta).clamp(1, widget.max);
    if (next != widget.count) widget.onChanged(next);
  }

  /// Holding a button keeps counting, so 1 to 200 is not 200 taps.
  void _hold(int delta) {
    _repeat?.cancel();
    _repeat = Timer.periodic(
      const Duration(milliseconds: 70),
      (_) => _step(delta),
    );
  }

  void _release() {
    _repeat?.cancel();
    _repeat = null;
  }

  @override
  void dispose() {
    _repeat?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final capacity = widget.capacity;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.brMd,
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          _RoundButton(
            icon: Icons.remove_rounded,
            semantic: '-',
            onTap: () => _step(-1),
            onHold: () => _hold(-1),
            onRelease: _release,
          ),
          Expanded(
            child: Column(
              children: [
                Text(
                  '${widget.count}',
                  style: AppTypography.display(size: 32),
                ),
                if (capacity != null)
                  Text(
                    l10n.bookFitsUpTo(capacity),
                    style: AppTypography.body(size: 12),
                  ),
              ],
            ),
          ),
          _RoundButton(
            icon: Icons.add_rounded,
            semantic: '+',
            onTap: () => _step(1),
            onHold: () => _hold(1),
            onRelease: _release,
          ),
        ],
      ),
    );
  }
}

class _RoundButton extends StatelessWidget {
  const _RoundButton({
    required this.icon,
    required this.semantic,
    required this.onTap,
    required this.onHold,
    required this.onRelease,
  });

  final IconData icon;
  final String semantic;
  final VoidCallback onTap;
  final VoidCallback onHold;
  final VoidCallback onRelease;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: semantic,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        onLongPressStart: (_) => onHold(),
        onLongPressEnd: (_) => onRelease(),
        onLongPressCancel: onRelease,
        child: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.borderStrong),
          ),
          child: Icon(icon, size: 20),
        ),
      ),
    );
  }
}

class _Notice extends StatelessWidget {
  const _Notice({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.warning.withValues(alpha: 0.12),
        borderRadius: AppRadius.brSm,
        border: Border.all(color: AppColors.warning.withValues(alpha: 0.4)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.warning_amber_rounded,
            size: 18,
            color: AppColors.warning,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: AppTypography.body(
                size: 13,
                color: AppColors.warning,
                weight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _NotesField extends StatelessWidget {
  const _NotesField({
    required this.controller,
    required this.hint,
    required this.onChanged,
  });

  final TextEditingController controller;
  final String hint;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      onChanged: onChanged,
      minLines: 4,
      maxLines: 6,
      maxLength: 500,
      cursorColor: AppColors.accent,
      style: AppTypography.body(color: AppColors.textPrimary),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: AppTypography.body(color: AppColors.textMuted),
        counterText: '',
        filled: true,
        fillColor: AppColors.surface,
        contentPadding: const EdgeInsets.all(14),
        border: OutlineInputBorder(
          borderRadius: AppRadius.brMd,
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: AppRadius.brMd,
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: AppRadius.brMd,
          borderSide: const BorderSide(color: AppColors.accent),
        ),
      ),
    );
  }
}

// ── Review ─────────────────────────────────────────────────────────────────

class _Review extends StatelessWidget {
  const _Review({
    required this.selection,
    required this.pricing,
    required this.loading,
    required this.error,
    required this.locale,
    required this.formatter,
    required this.onEditDate,
    required this.onEditGuests,
    required this.onVoucher,
  });

  final BookingSelection selection;
  final VenuePricing? pricing;
  final bool loading;
  final String? error;
  final String locale;
  final MoneyFormatter formatter;
  final VoidCallback onEditDate;
  final VoidCallback onEditGuests;
  final VoidCallback onVoucher;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final venue = selection.venue;
    final date = selection.date;
    final price = pricing;
    final currency = venue.currency;
    String money(num v) => formatter.format(v, currency, locale: locale);
    String charged(num v) => formatMoney(v, currency, locale: locale);

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      children: [
        _Card(
          child: Row(
            children: [
              PhotoBox(url: venue.imageUrl, width: 56, height: 56),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      venue.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.display(),
                    ),
                    if (venue.city != null)
                      Text(venue.city!, style: AppTypography.body()),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        _Card(
          child: Column(
            children: [
              _EditRow(
                label: l10n.bookDate,
                value: date == null
                    ? ''
                    : DateFormat('EEE d MMM y', locale).format(date),
                onEdit: onEditDate,
              ),
              const SizedBox(height: 4),
              _EditRow(
                label: l10n.bookGuests,
                value: '${selection.guests}',
                onEdit: onEditGuests,
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        _Card(
          child: loading
              ? const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Center(
                    child: CircularProgressIndicator(color: AppColors.accent),
                  ),
                )
              : price == null
                  ? Text(
                      error ?? l10n.bookPriceFailed,
                      style: AppTypography.body(color: AppColors.error),
                    )
                  : Column(
                      children: [
                        _PriceLine(
                          label: selection.package != null
                              ? l10n.bookPackage
                              : l10n.bookRateLine(
                                  money(venue.price ?? price.itemsTotal),
                                  l10n.bookDayCount(price.days),
                                ),
                          value: money(price.itemsTotal),
                        ),
                        const SizedBox(height: 10),
                        _PriceLine(
                          label: l10n.bookServiceFee,
                          value: money(price.platformFeeAmount),
                        ),
                        const SizedBox(height: 10),
                        if (price.discountAmount > 0)
                          _PriceLine(
                            label: l10n.bookDiscount,
                            value: '-${money(price.discountAmount)}',
                            accent: true,
                          )
                        else
                          GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onTap: onVoucher,
                            child: _PriceLine(
                              label: l10n.bookVoucher,
                              value: l10n.bookAddCode,
                              accent: true,
                            ),
                          ),
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 12),
                          child: Divider(
                            color: AppColors.borderStrong,
                            height: 1,
                          ),
                        ),
                        _PriceLine(
                          label: l10n.bookTotal,
                          value: money(price.totalAmount),
                          strong: true,
                        ),
                      ],
                    ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            const Icon(
              Icons.shield_outlined,
              size: 14,
              color: AppColors.textMuted,
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                l10n.bookCancelPolicy,
                style: AppTypography.body(size: 12),
              ),
            ),
          ],
        ),
        if (price != null && formatter.converts(currency)) ...[
          const SizedBox(height: 8),
          Text(
            l10n.currencyChargedIn(charged(price.totalAmount)),
            style: AppTypography.body(size: 12),
          ),
        ],
        if (price?.isSample ?? false) ...[
          const SizedBox(height: 12),
          Text(
            l10n.bookSampleAmounts.toUpperCase(),
            style: AppTypography.label(),
          ),
        ],
      ],
    );
  }
}

class _Card extends StatelessWidget {
  const _Card({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.brMd,
        border: Border.all(color: AppColors.border),
      ),
      child: child,
    );
  }
}

class _EditRow extends StatelessWidget {
  const _EditRow({
    required this.label,
    required this.value,
    required this.onEdit,
  });

  final String label;
  final String value;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onEdit,
      borderRadius: AppRadius.brSm,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 40),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: AppTypography.body()),
            Row(
              children: [
                Text(value, style: AppTypography.display(size: 14)),
                const SizedBox(width: 6),
                const Icon(
                  Icons.edit_outlined,
                  size: 14,
                  color: AppColors.textMuted,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _PriceLine extends StatelessWidget {
  const _PriceLine({
    required this.label,
    required this.value,
    this.accent = false,
    this.strong = false,
  });

  final String label;
  final String value;
  final bool accent;
  final bool strong;

  @override
  Widget build(BuildContext context) {
    final color = accent ? AppColors.success : AppColors.textPrimary;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Flexible(
          child: Text(
            label,
            style: accent
                ? AppTypography.body(color: AppColors.success)
                : strong
                    ? AppTypography.display()
                    : AppTypography.body(),
          ),
        ),
        const SizedBox(width: 12),
        Text(
          value,
          style: AppTypography.display(size: strong ? 18 : 14, color: color),
        ),
      ],
    );
  }
}

// ── Pay ────────────────────────────────────────────────────────────────────

/// Wallets first, card as the fallback. The card tiles are a preview of the
/// layout: card numbers are never typed into our own fields, they belong to
/// Stripe's payment sheet, so every tile here opens the same payment action.
class _Pay extends StatelessWidget {
  const _Pay({
    required this.total,
    required this.currency,
    required this.venue,
    required this.date,
    required this.locale,
    required this.formatter,
    required this.onTap,
  });

  final MoneyFormatter formatter;
  final num total;
  final String currency;
  final String venue;
  final DateTime? date;
  final String locale;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final when = date == null ? '' : DateFormat('d MMM', locale).format(date!);

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
      children: [
        Center(
          child: Text(
            l10n.bookTotal.toUpperCase(),
            style: AppTypography.label(),
          ),
        ),
        const SizedBox(height: 4),
        Center(
          child: Text(
            formatMoney(total, currency, locale: locale),
            style: AppTypography.display(size: 36),
          ),
        ),
        if (formatter.converts(currency)) ...[
          const SizedBox(height: 2),
          Center(
            child: Text(
              l10n.currencyApprox(
                formatter.format(total, currency, locale: locale),
              ),
              style: AppTypography.body(size: 13),
            ),
          ),
        ],
        const SizedBox(height: 4),
        Center(
          child: Text(
            when.isEmpty ? venue : '$venue · $when',
            style: AppTypography.body(),
          ),
        ),
        const SizedBox(height: 24),
        _WalletButton(
          label: 'Pay',
          icon: Icons.apple,
          light: true,
          onTap: onTap,
        ),
        const SizedBox(height: 10),
        _WalletButton(
          label: 'Pay',
          icon: Icons.g_mobiledata_rounded,
          onTap: onTap,
        ),
        const SizedBox(height: 18),
        Center(
          child: Text(
            l10n.bookOrPayByCard.toUpperCase(),
            style: AppTypography.label(color: AppColors.roleTalent),
          ),
        ),
        const SizedBox(height: 14),
        _FieldTile(
          icon: Icons.credit_card_rounded,
          text: l10n.bookCardNumber,
          onTap: onTap,
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(child: _FieldTile(text: l10n.bookExpiry, onTap: onTap)),
            const SizedBox(width: 10),
            Expanded(child: _FieldTile(text: l10n.bookCvc, onTap: onTap)),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            const Icon(
              Icons.lock_outline_rounded,
              size: 14,
              color: AppColors.textMuted,
            ),
            const SizedBox(width: 6),
            Text(l10n.bookStripeNote, style: AppTypography.body(size: 12)),
          ],
        ),
      ],
    );
  }
}

class _WalletButton extends StatelessWidget {
  const _WalletButton({
    required this.label,
    required this.icon,
    required this.onTap,
    this.light = false,
  });

  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final bool light;

  @override
  Widget build(BuildContext context) {
    final fg = light ? AppColors.onLightSurface : AppColors.textPrimary;
    return SizedBox(
      height: 52,
      width: double.infinity,
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: light ? AppColors.lightSurface : AppColors.canvas,
          foregroundColor: fg,
          elevation: 0,
          side: light ? null : const BorderSide(color: AppColors.borderStrong),
          shape: RoundedRectangleBorder(borderRadius: AppRadius.brSm),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 22, color: fg),
            const SizedBox(width: 4),
            Text(label, style: AppTypography.display(color: fg)),
          ],
        ),
      ),
    );
  }
}

class _FieldTile extends StatelessWidget {
  const _FieldTile({required this.text, required this.onTap, this.icon});

  final String text;
  final IconData? icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: AppRadius.brSm,
      child: Container(
        height: 52,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: AppRadius.brSm,
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            if (icon != null) ...[
              Icon(icon, size: 16, color: AppColors.textMuted),
              const SizedBox(width: 8),
            ],
            Text(text, style: AppTypography.body(color: AppColors.textMuted)),
          ],
        ),
      ),
    );
  }
}
