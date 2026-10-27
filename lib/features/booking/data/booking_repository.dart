import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_template/core/constants/api_endpoints.dart';
import 'package:flutter_template/core/services/api_service.dart';
import 'package:flutter_template/features/auth/presentation/controllers/auth_controller.dart';
import 'package:flutter_template/features/booking/domain/booking_models.dart';
import 'package:flutter_template/shared/catalog/catalog_item.dart';
import 'package:flutter_template/shared/events/event_package.dart';
import 'package:flutter_template/shared/payments/payments_repository.dart';

// Tests and the booking page reach the gateway through here.
export 'package:flutter_template/shared/payments/payments_repository.dart'
    show
        PaymentCancelled,
        PaymentGateway,
        PaymentsUnavailable,
        StubPaymentGateway;

/// Venue booking: availability, price, the booking itself and its payment.
class BookingRepository {
  BookingRepository(this._api, this._gateway);

  final ApiService _api;
  final PaymentGateway _gateway;

  /// Days that cannot be booked, from [from] for a year.
  Future<Set<DateTime>> unavailableDates(
    CatalogItem venue, {
    required DateTime from,
    String? templateId,
  }) async {
    if (venue.isSample) return _sampleUnavailable(from);
    if (templateId != null) {
      // An event's calendar is the days it is already booked.
      final body = await _api.get(
        ApiEndpoints.bookingsAvailability,
        query: {'templateId': templateId},
      );
      final data = body is Map ? (body['data'] ?? body) : null;
      final booked = data is Map ? data['bookedDates'] : null;
      if (booked is! List) return {};
      return {
        for (final d in booked)
          if (DateTime.tryParse('$d')?.toLocal() case final parsed?)
            DateTime(parsed.year, parsed.month, parsed.day),
      };
    }
    final body = await _api.get(
      ApiEndpoints.venueUnavailableDates(venue.id),
      query: {
        'start': from.toUtc().toIso8601String(),
        'end': from.add(const Duration(days: 366)).toUtc().toIso8601String(),
      },
    );
    final dates = body is Map ? body['dates'] : null;
    if (dates is! List) return {};
    return {
      for (final d in dates)
        if (DateTime.tryParse('$d') case final parsed?)
          DateTime(parsed.year, parsed.month, parsed.day),
    };
  }

  /// Sample venues show the same pattern as the mockup: a few booked days.
  static Set<DateTime> _sampleUnavailable(DateTime from) {
    const days = {6, 7, 13, 24, 25};
    final out = <DateTime>{};
    for (var i = 0; i < 366; i++) {
      final d = DateTime(from.year, from.month, from.day + i);
      if (days.contains(d.day)) out.add(d);
    }
    return out;
  }

  Future<VenuePricing> price(BookingSelection s) async {
    final package = s.package;
    if (package != null) {
      // The server computes the real total when the booking is made; this is
      // the same arithmetic the web shows before that.
      final quote = package.quote(s.excluded);
      return VenuePricing(
        itemsTotal: quote.package,
        platformFeeAmount: quote.fee,
        totalAmount: quote.total,
        isSample: package.isSample,
      );
    }
    final venue = s.venue;
    if (venue.isSample) {
      return VenuePricing.estimate(
        rate: venue.price ?? 0,
        guests: s.guests,
        capacity: venue.capacity,
      );
    }
    final body = await _api.get(
      ApiEndpoints.venuePricePreview,
      query: {
        'venueId': venue.id,
        'startDate': s.startAt!.toUtc().toIso8601String(),
        'endDate': s.endAt!.toUtc().toIso8601String(),
        'guestCount': s.guests,
        if (s.voucherCode.isNotEmpty) 'voucherCode': s.voucherCode,
      },
    );
    final data = body is Map ? body['data'] : null;
    if (data is! Map) throw StateError('No price in the response');
    return VenuePricing.fromJson(data.cast<String, dynamic>());
  }

  /// Creates the booking. When [VenuePricing.needsApproval] it is a request and
  /// nothing is charged; otherwise [pay] follows.
  Future<BookingReceipt> create(BookingSelection s, VenuePricing p) async {
    final package = s.package;
    if (package != null && !package.isSample) return _createFromTemplate(s, p);
    final venue = s.venue;
    if (venue.isSample) {
      return BookingReceipt(
        id: 'sample-booking',
        reference: '#0000SAMPLE',
        totalAmount: p.totalAmount,
        currency: venue.currency,
        needsApproval: p.needsApproval,
        isSample: true,
      );
    }
    final notes = s.notes.trim();
    final body = await _api.post(ApiEndpoints.bookingDraft, {
      'venueId': venue.id,
      'startDate': s.startAt!.toUtc().toIso8601String(),
      'endDate': s.endAt!.toUtc().toIso8601String(),
      'guestCount': s.guests,
      if (notes.isNotEmpty) 'specialRequests': notes,
      if (s.voucherCode.isNotEmpty) 'voucherCode': s.voucherCode,
    });
    final data = body is Map ? body['data'] : null;
    if (data is! Map) throw StateError('No booking in the response');
    final id = '${data['id']}';
    final held = data['status'] == 'pending_provider_confirmation';
    return BookingReceipt(
      id: id,
      reference: '${data['ticketCode'] ?? id}',
      totalAmount: p.totalAmount,
      currency: venue.currency,
      needsApproval: p.needsApproval || held,
    );
  }

  /// Books an event package, as the web does: the date, the guests and the
  /// optional items left out. The total is the server's, not the preview.
  Future<BookingReceipt> _createFromTemplate(
    BookingSelection s,
    VenuePricing p,
  ) async {
    final package = s.package!;
    final day = s.date!;
    // The web books evenings: from 18:00 for six hours.
    final start = DateTime(day.year, day.month, day.day, 18);
    final end = start.add(const Duration(hours: 6));
    final body = await _api.post(ApiEndpoints.bookingFromTemplate, {
      'templateId': package.id,
      'guestCount': s.guests,
      'startAt': start.toUtc().toIso8601String(),
      'endAt': end.toUtc().toIso8601String(),
      'excludedAssetIds': package.excludedOf(PackageItemKind.gear, s.excluded),
      'excludedServiceIds':
          package.excludedOf(PackageItemKind.service, s.excluded),
      'excludedVenueIds': package.excludedOf(PackageItemKind.venue, s.excluded),
    });
    final data = body is Map ? body['data'] : null;
    final booking = data is Map ? data['booking'] : null;
    if (booking is! Map || booking['id'] == null) {
      throw StateError('No booking in the response');
    }
    final id = '${booking['id']}';

    // Charge what the server worked out, not the on-screen preview.
    var total = p.totalAmount;
    var reference = '${booking['ticketCode'] ?? id}';
    try {
      final detail = await _api.get(ApiEndpoints.bookingById(id));
      final row = detail is Map ? (detail['data'] ?? detail) : null;
      if (row is Map) {
        final amount = row['totalAmount'];
        if (amount is num) total = amount;
        if (amount is String && num.tryParse(amount) != null) {
          total = num.parse(amount);
        }
        if (row['ticketCode'] != null) reference = '${row['ticketCode']}';
      }
    } on Object {
      // Keep the preview; payment re-checks the amount server-side.
    }
    return BookingReceipt(
      id: id,
      reference: reference,
      totalAmount: total,
      currency: package.currency,
      needsApproval: false,
    );
  }

  /// Takes the payment for a created booking and confirms it.
  Future<void> pay(BookingReceipt booking) async {
    String? secret;
    String? intentId;
    if (!booking.isSample) {
      final body = await _api.post(ApiEndpoints.createPaymentIntent, {
        'amount': booking.totalAmount,
        'currency': booking.currency,
        'bookingId': booking.id,
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
    await _api.post(ApiEndpoints.bookingConfirm(booking.id), {
      'amount': booking.totalAmount,
      'method': 'stripe',
      'transactionId': intentId ?? paid,
    });
  }
}

final bookingRepositoryProvider = Provider<BookingRepository>(
  (ref) => BookingRepository(
    ref.watch(apiServiceProvider),
    ref.watch(paymentGatewayProvider),
  ),
);
