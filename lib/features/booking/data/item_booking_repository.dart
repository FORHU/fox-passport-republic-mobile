import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_template/core/config/app_config.dart';
import 'package:flutter_template/core/constants/api_endpoints.dart';
import 'package:flutter_template/core/services/api_service.dart';
import 'package:flutter_template/features/auth/presentation/controllers/auth_controller.dart';
import 'package:flutter_template/features/booking/domain/booking_models.dart';
import 'package:flutter_template/shared/catalog/catalog_item.dart';
import 'package:flutter_template/shared/payments/payments_repository.dart';

/// What the citizen chose for a piece of gear or a service.
class ItemBookingRequest {
  const ItemBookingRequest({
    required this.item,
    required this.start,
    required this.days,
    this.quantity = 1,
    this.delivery = false,
    this.address = '',
    this.location = '',
    this.notes = '',
    this.voucherCode = '',
  });

  final CatalogItem item;

  /// The first day, as a calendar date.
  final DateTime start;

  /// How many days it runs, at least one.
  final int days;
  final int quantity;

  /// Gear only: delivered to [address] rather than picked up.
  final bool delivery;
  final String address;

  /// Services only: where the event is.
  final String location;
  final String notes;
  final String voucherCode;

  bool get isGear => item.kind == CatalogKind.gear;

  DateTime get startAt => DateTime(start.year, start.month, start.day);

  /// The end of the last day, so a one-day booking covers the whole day.
  DateTime get endAt =>
      DateTime(start.year, start.month, start.day + days - 1, 23, 59, 59);
}

/// Booking one piece of gear or one service: which days are free, the price,
/// the booking and its payment.
class ItemBookingRepository {
  ItemBookingRepository(this._api, this._gateway);

  final ApiService _api;
  final PaymentGateway _gateway;

  /// Sample rows and the mock backend have no server to ask.
  bool _offline(CatalogItem item) =>
      item.isSample || AppConfig.instance.useMock;

  static DateTime _day(DateTime d) => DateTime(d.year, d.month, d.day);

  /// Days that cannot be booked. A service names the days its owner is
  /// engaged or travelling; gear is blocked once every unit is out.
  Future<Set<DateTime>> blockedDays(
    CatalogItem item, {
    String location = '',
  }) async {
    if (_offline(item)) return {};
    if (item.kind == CatalogKind.gear) {
      final body = await _api.get(
        '${ApiEndpoints.assetBookings}/availability',
        query: {'assetId': item.id},
      );
      final data = body is Map ? (body['data'] ?? body) : null;
      if (data is! Map) return {};
      final total = (data['totalQty'] as num?)?.toInt() ?? 1;
      final used = <DateTime, int>{};
      for (final r in data['bookedRanges'] as List? ?? const []) {
        if (r is! Map) continue;
        final from = DateTime.tryParse('${r['startDate']}');
        final to = DateTime.tryParse('${r['endDate']}');
        if (from == null || to == null) continue;
        final qty = (r['bookedQty'] as num?)?.toInt() ?? 1;
        for (var d = _day(from);
            !d.isAfter(_day(to));
            d = DateTime(d.year, d.month, d.day + 1)) {
          used[d] = (used[d] ?? 0) + qty;
        }
      }
      return {
        for (final e in used.entries)
          if (e.value >= total) e.key,
      };
    }
    final body = await _api.get(
      '${ApiEndpoints.serviceBookings}/availability',
      query: {
        'serviceId': item.id,
        if (location.trim().isNotEmpty) 'location': location.trim(),
      },
    );
    final data = body is Map ? (body['data'] ?? body) : null;
    if (data is! Map) return {};
    return {
      for (final key in const ['bookedDates', 'travelBlockedDates'])
        for (final d in data[key] as List? ?? const [])
          if (DateTime.tryParse('$d') case final parsed?) _day(parsed),
    };
  }

  Future<VenuePricing> price(ItemBookingRequest r) async {
    if (_offline(r.item)) {
      final rate = r.item.price ?? 0;
      final items = rate * r.days * r.quantity;
      final fee = (items * 0.05).roundToDouble();
      return VenuePricing(
        itemsTotal: items,
        platformFeeAmount: fee,
        totalAmount: items + fee,
        days: r.days,
        isSample: true,
      );
    }
    final body = await _api.get(
      r.isGear
          ? ApiEndpoints.assetPricePreview
          : ApiEndpoints.servicePricePreview,
      query: {
        if (r.isGear) ...{
          'assetId': r.item.id,
          'startDate': r.startAt.toUtc().toIso8601String(),
          'endDate': r.endAt.toUtc().toIso8601String(),
          'quantity': r.quantity,
        } else ...{
          'serviceId': r.item.id,
          'scheduledDate': r.startAt.toUtc().toIso8601String(),
          if (r.days > 1) 'endDate': r.endAt.toUtc().toIso8601String(),
        },
        if (r.voucherCode.isNotEmpty) 'voucherCode': r.voucherCode,
      },
    );
    final data = body is Map ? body['data'] : null;
    if (data is! Map) throw StateError('No price in the response');
    return VenuePricing.fromJson(data.cast<String, dynamic>(), days: r.days);
  }

  /// Creates the booking. Nothing is charged until [pay].
  Future<BookingReceipt> create(ItemBookingRequest r, VenuePricing p) async {
    if (_offline(r.item)) {
      return BookingReceipt(
        id: 'sample-item-booking',
        reference: '#0000SAMPLE',
        totalAmount: p.totalAmount,
        currency: r.item.currency,
        needsApproval: false,
        isSample: true,
      );
    }
    final notes = r.notes.trim();
    final body = await _api.post(
      r.isGear ? ApiEndpoints.assetBookings : ApiEndpoints.serviceBookings,
      {
        if (r.isGear) ...{
          'assetId': r.item.id,
          'startDate': r.startAt.toUtc().toIso8601String(),
          'endDate': r.endAt.toUtc().toIso8601String(),
          'quantity': r.quantity,
          'fulfillmentType': r.delivery ? 'delivery' : 'pickup',
          if (r.delivery) 'deliveryAddress': r.address.trim(),
        } else ...{
          'serviceId': r.item.id,
          'scheduledDate': r.startAt.toUtc().toIso8601String(),
          if (r.days > 1) 'endDate': r.endAt.toUtc().toIso8601String(),
          'location': r.location.trim(),
        },
        if (notes.isNotEmpty) 'notes': notes,
        if (r.voucherCode.isNotEmpty) 'voucherCode': r.voucherCode,
      },
    );
    final data = body is Map ? body['data'] : null;
    if (data is! Map || data['id'] == null) {
      throw StateError('No booking in the response');
    }
    final id = '${data['id']}';
    final total = data['totalAmount'];
    return BookingReceipt(
      id: id,
      reference: '${data['ticketCode'] ?? id}',
      totalAmount:
          total is num ? total : num.tryParse('$total') ?? p.totalAmount,
      currency: r.item.currency,
      needsApproval: false,
    );
  }

  /// Takes the payment for a created booking and confirms it.
  Future<void> pay(ItemBookingRequest r, BookingReceipt booking) async {
    String? secret;
    String? intentId;
    if (!booking.isSample) {
      final body = await _api.post(ApiEndpoints.createPaymentIntent, {
        'amount': booking.totalAmount,
        'currency': booking.currency,
        'bookingId': booking.id,
        'description': r.item.title,
      });
      final data = body is Map ? body['data'] : null;
      if (data is Map) {
        secret = data['clientSecret']?.toString();
        intentId = data['paymentIntentId']?.toString();
      }
    }
    final paid = await _gateway.pay(
      clientSecret: secret,
      amount: booking.totalAmount,
      currency: booking.currency,
    );
    if (booking.isSample) return;
    await _api.post(
      r.isGear
          ? ApiEndpoints.assetBookingConfirm(booking.id)
          : ApiEndpoints.serviceBookingConfirm(booking.id),
      {
        'amount': booking.totalAmount,
        'method': 'stripe',
        'transactionId': intentId ?? paid,
      },
    );
  }
}

final itemBookingRepositoryProvider = Provider<ItemBookingRepository>(
  (ref) => ItemBookingRepository(
    ref.watch(apiServiceProvider),
    ref.watch(paymentGatewayProvider),
  ),
);
