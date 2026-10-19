import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_template/core/errors/exceptions.dart';
import 'package:flutter_template/core/utils/context_extensions.dart';
import 'package:flutter_template/features/auth/presentation/controllers/auth_controller.dart';
import 'package:flutter_template/features/booking/data/item_booking_repository.dart';
import 'package:flutter_template/features/booking/domain/booking_models.dart';
import 'package:flutter_template/features/home/presentation/widgets/category_labels.dart';
import 'package:flutter_template/l10n/generated/app_localizations.dart';
import 'package:flutter_template/shared/catalog/catalog_item.dart';
import 'package:flutter_template/shared/catalog/catalog_labels.dart'
    show catalogPriceLabel;
import 'package:flutter_template/shared/currency/currency.dart';
import 'package:flutter_template/shared/currency/currency_providers.dart';
import 'package:flutter_template/shared/formatting/money.dart';
import 'package:flutter_template/shared/widgets/booking_calendar.dart';
import 'package:flutter_template/shared/widgets/photo_box.dart';
import 'package:flutter_template/shared/widgets/top_toast.dart';
import 'package:flutter_template/theme/tokens/colors.dart';
import 'package:flutter_template/theme/tokens/radius.dart';
import 'package:flutter_template/theme/tokens/typography.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

/// One piece of gear or one service: what it is and costs, the days, and the
/// price as you choose, with "Book" pinned to the bottom.
class ItemBookingPage extends ConsumerStatefulWidget {
  const ItemBookingPage({required this.item, super.key});

  final CatalogItem item;

  @override
  ConsumerState<ItemBookingPage> createState() => _ItemBookingPageState();
}

class _ItemBookingPageState extends ConsumerState<ItemBookingPage> {
  final _today = DateTime.now();
  late DateTime _month = DateTime(_today.year, _today.month);
  final _address = TextEditingController();
  final _location = TextEditingController();
  final _notes = TextEditingController();

  DateTime? _start;
  int _days = 1;
  int _quantity = 1;
  bool _delivery = false;

  Set<DateTime> _blocked = {};
  VenuePricing? _pricing;
  bool _priceLoading = false;
  String? _priceError;
  int _priceToken = 0;

  BookingReceipt? _receipt;

  /// What [_receipt] was created for. It is reused only while the choices are
  /// unchanged; after any edit the old booking holds the old dates and amount.
  ItemBookingRequest? _receiptFor;
  bool _busy = false;

  bool get _isGear => widget.item.kind == CatalogKind.gear;

  @override
  void initState() {
    super.initState();
    unawaited(_loadBlocked());
  }

  @override
  void dispose() {
    _address.dispose();
    _location.dispose();
    _notes.dispose();
    super.dispose();
  }

  ItemBookingRequest get _request => ItemBookingRequest(
        item: widget.item,
        start: _start ?? _today,
        days: _days,
        quantity: _quantity,
        delivery: _delivery,
        address: _address.text,
        location: _location.text,
        notes: _notes.text,
      );

  Future<void> _loadBlocked() async {
    try {
      final days = await ref
          .read(itemBookingRepositoryProvider)
          .blockedDays(widget.item, location: _location.text);
      if (mounted) setState(() => _blocked = days);
    } on Object {
      // Every day is offered; the server still refuses a taken one.
    }
  }

  /// Re-prices after any choice that changes the total. A slower earlier
  /// answer never replaces a newer one.
  Future<void> _reprice() async {
    if (_start == null) {
      setState(() {
        _pricing = null;
        _priceError = null;
      });
      return;
    }
    final token = ++_priceToken;
    final l10n = context.l10n;
    setState(() {
      _priceLoading = true;
      _priceError = null;
    });
    try {
      final price =
          await ref.read(itemBookingRepositoryProvider).price(_request);
      if (mounted && token == _priceToken) setState(() => _pricing = price);
    } on AppException catch (e) {
      if (mounted && token == _priceToken) {
        setState(() {
          _pricing = null;
          _priceError = e.message;
        });
      }
    } on Object {
      if (mounted && token == _priceToken) {
        setState(() {
          _pricing = null;
          _priceError = l10n.bookPriceFailed;
        });
      }
    } finally {
      if (mounted && token == _priceToken) {
        setState(() => _priceLoading = false);
      }
    }
  }

  void _change(VoidCallback change) {
    setState(change);
    unawaited(_reprice());
  }

  String? _missing(AppLocalizations l10n) {
    if (_start == null) return l10n.itemBookNeedDate;
    if (_isGear && _delivery && _address.text.trim().isEmpty) {
      return l10n.itemBookNeedAddress;
    }
    if (!_isGear && _location.text.trim().isEmpty) {
      return l10n.itemBookNeedLocation;
    }
    return null;
  }

  Future<void> _book() async {
    final l10n = context.l10n;
    if (ref.read(authControllerProvider).user == null) {
      showTopToast(context, l10n.itemBookSignIn);
      return;
    }
    final missing = _missing(l10n);
    if (missing != null) {
      showTopToast(context, missing);
      return;
    }
    final price = _pricing;
    if (price == null || _busy) return;
    final repo = ref.read(itemBookingRepositoryProvider);
    setState(() => _busy = true);
    try {
      // Create once; a retry after a failed payment reuses the booking, but
      // only while nothing was changed since.
      final request = _request;
      final existing = _receipt;
      final receipt = existing != null && _receiptFor == request
          ? existing
          : await repo.create(request, price);
      _receipt = receipt;
      _receiptFor = request;
      await repo.pay(request, receipt);
      if (mounted) setState(() => _paid = true);
    } on PaymentsUnavailable {
      if (mounted) showTopToast(context, l10n.bookPaymentsSoon);
    } on Object catch (e) {
      if (mounted) {
        showTopToast(context, e is AppException ? e.message : l10n.bookFailed);
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final locale = Localizations.localeOf(context).toString();
    final money = ref.watch(moneyFormatterProvider);
    final item = widget.item;

    if (_receipt != null && !_busy && _paid) {
      return _Done(receipt: _receipt!, l10n: l10n, locale: locale);
    }

    final rate = catalogPriceLabel(
      l10n,
      item,
      locale: locale,
      formatter: money,
    );
    final price = _pricing;

    return Scaffold(
      backgroundColor: AppColors.canvas,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  Stack(
                    children: [
                      PhotoBox(
                        url: item.imageUrl,
                        height: 220,
                        width: double.infinity,
                        radius: 0,
                      ),
                      Positioned(
                        left: 8,
                        top: 8,
                        child: IconButton.filled(
                          tooltip: MaterialLocalizations.of(context)
                              .backButtonTooltip,
                          style: IconButton.styleFrom(
                            backgroundColor: AppColors.canvas.withAlpha(180),
                            foregroundColor: AppColors.textPrimary,
                          ),
                          onPressed: () => context.pop(),
                          icon: const Icon(Icons.arrow_back_rounded),
                        ),
                      ),
                    ],
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (item.category != null)
                          Text(
                            categoryLabel(l10n, item.category!).toUpperCase(),
                            style: AppTypography.label(color: AppColors.accent),
                          ),
                        const SizedBox(height: 4),
                        Text(
                          item.title,
                          style: AppTypography.display(size: 26),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          [
                            if (item.city != null) item.city!,
                            if (rate != null) rate,
                          ].join(' · '),
                          style: AppTypography.body(color: AppColors.textMuted),
                        ),
                        const SizedBox(height: 24),
                        _Section(l10n.bookWhenTitle),
                        BookingCalendar(
                          month: _month,
                          today: _today,
                          selected: _start,
                          unavailable: _blocked,
                          onSelect: (d) => _change(() => _start = d),
                          onMonthChanged: (m) => setState(() => _month = m),
                        ),
                        const SizedBox(height: 20),
                        _Stepper(
                          label: l10n.itemBookDays,
                          value: l10n.bookDayCount(_days),
                          onMinus:
                              _days > 1 ? () => _change(() => _days--) : null,
                          onPlus:
                              _days < 60 ? () => _change(() => _days++) : null,
                        ),
                        if (_isGear) ...[
                          const SizedBox(height: 12),
                          _Stepper(
                            label: l10n.itemBookQuantity,
                            value: '$_quantity',
                            onMinus: _quantity > 1
                                ? () => _change(() => _quantity--)
                                : null,
                            onPlus: _quantity < 99
                                ? () => _change(() => _quantity++)
                                : null,
                          ),
                          const SizedBox(height: 20),
                          SegmentedButton<bool>(
                            showSelectedIcon: false,
                            segments: [
                              ButtonSegment(
                                value: false,
                                label: Text(l10n.itemBookPickup),
                              ),
                              ButtonSegment(
                                value: true,
                                label: Text(l10n.itemBookDelivery),
                              ),
                            ],
                            selected: {_delivery},
                            onSelectionChanged: (s) =>
                                setState(() => _delivery = s.first),
                          ),
                          if (_delivery) ...[
                            const SizedBox(height: 12),
                            TextField(
                              controller: _address,
                              decoration: InputDecoration(
                                hintText: l10n.itemBookAddress,
                              ),
                            ),
                          ],
                        ] else ...[
                          const SizedBox(height: 20),
                          TextField(
                            controller: _location,
                            onSubmitted: (_) => unawaited(_loadBlocked()),
                            decoration: InputDecoration(
                              hintText: l10n.itemBookLocation,
                              prefixIcon: const Icon(Icons.place_outlined),
                            ),
                          ),
                        ],
                        const SizedBox(height: 20),
                        _Section(l10n.bookNotesTitle),
                        TextField(
                          controller: _notes,
                          maxLines: 3,
                          decoration: InputDecoration(
                            hintText: l10n.bookNotesHint,
                          ),
                        ),
                        const SizedBox(height: 24),
                        _PriceBox(
                          pricing: price,
                          loading: _priceLoading,
                          error: _priceError,
                          currency: item.currency,
                          start: _start,
                          days: _days,
                          locale: locale,
                          l10n: l10n,
                          formatter: money,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              decoration: const BoxDecoration(
                border: Border(top: BorderSide(color: AppColors.border)),
              ),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed:
                      _busy || (_start != null && price == null) ? null : _book,
                  child: _busy
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(
                          price == null
                              ? l10n.itemBookBook
                              : l10n.bookPayAmount(
                                  money.format(
                                    price.totalAmount,
                                    item.currency,
                                    locale: locale,
                                  ),
                                ),
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// True once payment went through (the receipt is only shown then).
  bool _paid = false;
}

class _Section extends StatelessWidget {
  const _Section(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Text(text, style: AppTypography.display(size: 18)),
      );
}

class _Stepper extends StatelessWidget {
  const _Stepper({
    required this.label,
    required this.value,
    required this.onMinus,
    required this.onPlus,
  });

  final String label;
  final String value;
  final VoidCallback? onMinus;
  final VoidCallback? onPlus;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: Text(label, style: AppTypography.body())),
        IconButton.outlined(
          tooltip: context.l10n.a11yDecrease(label),
          onPressed: onMinus,
          icon: const Icon(Icons.remove_rounded),
        ),
        SizedBox(
          width: 72,
          child: Text(
            value,
            textAlign: TextAlign.center,
            style: AppTypography.display(),
          ),
        ),
        IconButton.outlined(
          tooltip: context.l10n.a11yIncrease(label),
          onPressed: onPlus,
          icon: const Icon(Icons.add_rounded),
        ),
      ],
    );
  }
}

class _PriceBox extends StatelessWidget {
  const _PriceBox({
    required this.pricing,
    required this.loading,
    required this.error,
    required this.currency,
    required this.start,
    required this.days,
    required this.locale,
    required this.l10n,
    required this.formatter,
  });

  final VenuePricing? pricing;
  final bool loading;
  final String? error;
  final String currency;
  final DateTime? start;
  final int days;
  final String locale;
  final AppLocalizations l10n;
  final MoneyFormatter formatter;

  @override
  Widget build(BuildContext context) {
    final p = pricing;
    String m(num n) => formatter.format(n, currency, locale: locale);

    Widget row(String label, String value, {bool strong = false}) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: strong
                      ? AppTypography.display()
                      : AppTypography.body(color: AppColors.textMuted),
                ),
              ),
              Text(
                value,
                style: strong ? AppTypography.display() : AppTypography.body(),
              ),
            ],
          ),
        );

    final Widget content;
    if (start == null) {
      content = Text(
        l10n.itemBookNeedDate,
        style: AppTypography.body(color: AppColors.textMuted),
      );
    } else if (loading && p == null) {
      content = const Center(
        child: SizedBox(
          width: 22,
          height: 22,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      );
    } else if (error != null) {
      content = Text(
        error!,
        style: AppTypography.body(color: AppColors.error),
      );
    } else if (p != null) {
      content = Column(
        children: [
          row(
            DateFormat('EEE d MMM', locale).format(start!),
            l10n.bookDayCount(days),
          ),
          row(l10n.bookPackage, m(p.itemsTotal)),
          if (p.discountAmount > 0)
            row(l10n.bookDiscount, '-${m(p.discountAmount)}'),
          row(l10n.bookServiceFee, m(p.platformFeeAmount)),
          const Divider(color: AppColors.border),
          row(l10n.bookTotal, m(p.totalAmount), strong: true),
          if (p.isSample)
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                l10n.bookSampleAmounts,
                style: AppTypography.body(color: AppColors.textMuted),
              ),
            ),
        ],
      );
    } else {
      content = const SizedBox.shrink();
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.brMd,
        border: Border.all(color: AppColors.border),
      ),
      child: content,
    );
  }
}

class _Done extends StatelessWidget {
  const _Done({
    required this.receipt,
    required this.l10n,
    required this.locale,
  });

  final BookingReceipt receipt;
  final AppLocalizations l10n;
  final String locale;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.canvas,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircleAvatar(
                radius: 36,
                backgroundColor: AppColors.accent,
                child: Icon(
                  Icons.check_rounded,
                  size: 38,
                  color: AppColors.onAccent,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                l10n.bookBookedTitle,
                style: AppTypography.display(size: 26),
              ),
              const SizedBox(height: 8),
              Text(
                l10n.itemBookedSub,
                textAlign: TextAlign.center,
                style: AppTypography.body(color: AppColors.textMuted),
              ),
              const SizedBox(height: 16),
              Text(
                '${l10n.bookReference}: ${receipt.reference}',
                style: AppTypography.body(),
              ),
              Text(
                formatMoney(
                  receipt.totalAmount,
                  receipt.currency,
                  locale: locale,
                ),
                style: AppTypography.display(size: 20),
              ),
              const SizedBox(height: 28),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => context.pop(),
                  child: Text(l10n.itemBookDone),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
