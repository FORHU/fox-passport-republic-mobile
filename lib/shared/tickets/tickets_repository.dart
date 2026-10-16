import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_template/core/config/app_config.dart';
import 'package:flutter_template/core/constants/api_endpoints.dart';
import 'package:flutter_template/core/services/api_service.dart';
import 'package:flutter_template/features/auth/presentation/controllers/auth_controller.dart';
import 'package:flutter_template/shared/tickets/cancel_quote.dart';
import 'package:flutter_template/shared/tickets/ticket.dart';

/// The signed-in user's bookings, as [Ticket]s.
class TicketsRepository {
  TicketsRepository(this._api, this._userId);

  final ApiService _api;
  final String? _userId;

  /// Upcoming bookings, soonest first. Demo tickets are only shown when
  /// mock mode is explicitly enabled.
  Future<List<Ticket>> upcoming() async {
    final body = await _api.get(ApiEndpoints.bookingsUpcoming);
    final tickets = _parse(body);
    if (tickets.isEmpty && AppConfig.instance.useMock) {
      return [Ticket.sample()];
    }
    return tickets;
  }

  /// Bookings that have ended or been closed out, newest first.
  Future<List<Ticket>> past() async {
    final id = _userId;
    if (id == null) return const [];
    final body = await _api.get(ApiEndpoints.bookingsOfUser(id));
    final now = DateTime.now();
    final tickets = _parse(body)
        .where(
          (t) =>
              t.endAt.isBefore(now) ||
              t.status == 'completed' ||
              t.status == 'cancelled',
        )
        .toList()
      ..sort((a, b) => b.startAt.compareTo(a.startAt));
    return tickets;
  }

  /// What cancelling this booking would return, before anything happens.
  Future<CancelQuote> cancelQuote(String bookingId) async {
    final body = await _api.post(ApiEndpoints.bookingCancelCheck(bookingId));
    final data = body is Map ? (body['data'] ?? body) : null;
    if (data is! Map) throw const FormatException('No quote in the response');
    return CancelQuote.fromJson(data.cast<String, dynamic>());
  }

  /// Cancels the booking; the API starts any refund.
  Future<void> cancel(String bookingId) async {
    await _api.post(ApiEndpoints.bookingCancel(bookingId));
  }

  static List<Ticket> _parse(Object? body) {
    final list = body is Map ? body['data'] : body;
    if (list is! List) return const [];
    return [
      for (final row in list)
        if (row is Map) Ticket.fromBooking(row.cast<String, dynamic>()),
    ];
  }
}

final ticketsRepositoryProvider = Provider<TicketsRepository>((ref) {
  final userId = ref.watch(authControllerProvider.select((s) => s.user?.id));
  return TicketsRepository(ref.watch(apiServiceProvider), userId);
});

final FutureProvider<List<Ticket>> upcomingTicketsProvider =
    FutureProvider.autoDispose<List<Ticket>>(
  (ref) => ref.watch(ticketsRepositoryProvider).upcoming(),
);

final FutureProvider<List<Ticket>> pastTicketsProvider =
    FutureProvider.autoDispose<List<Ticket>>(
  (ref) => ref.watch(ticketsRepositoryProvider).past(),
);

// The family type is long and adds nothing here, so it is left inferred.
// ignore: specify_nonobvious_property_types
final cancelQuoteProvider =
    FutureProvider.autoDispose.family<CancelQuote, String>(
  (ref, bookingId) =>
      ref.watch(ticketsRepositoryProvider).cancelQuote(bookingId),
);
