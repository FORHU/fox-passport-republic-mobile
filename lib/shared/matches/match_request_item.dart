import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_template/core/constants/api_endpoints.dart';
import 'package:flutter_template/features/auth/presentation/controllers/auth_controller.dart';

/// Where a Match request stands, from the citizen's side.
enum MatchState {
  /// Sent; the Foxer has not answered.
  waiting,

  /// The Foxer said yes. If there is something to pay, the booking is not
  /// confirmed until it is paid.
  accepted,

  /// Accepted and paid, or otherwise confirmed.
  confirmed,

  /// The Foxer declined, or the booking was cancelled.
  declined,
}

/// One Match request the citizen made, read from `GET /matches/my`.
class MatchRequestItem extends Equatable {
  const MatchRequestItem({
    required this.bookingId,
    required this.eventId,
    required this.style,
    required this.startAt,
    required this.guests,
    required this.total,
    required this.requestStatus,
    required this.bookingStatus,
    required this.paid,
    this.foxerId,
    this.foxerName = '',
    this.foxerImageUrl,
  });

  /// The server names a Match event "Match with <style>". `GET /matches/my`
  /// returns every booking the user has, so this is how requests are told
  /// apart from ordinary bookings. Null for those.
  static MatchRequestItem? tryParse(Map<String, dynamic> row) {
    final event = row['event'];
    if (event is! Map) return null;
    final name = '${event['name'] ?? ''}';
    const prefix = 'Match with ';
    if (!name.startsWith(prefix)) return null;

    num n(Object? v) => v is num ? v : num.tryParse('$v') ?? 0;
    final host = event['host'];
    final payments = row['payments'];

    return MatchRequestItem(
      bookingId: '${row['id']}',
      eventId: '${event['id'] ?? ''}',
      style: name.substring(prefix.length),
      startAt: DateTime.tryParse('${row['startAt'] ?? event['startAt']}')
              ?.toLocal() ??
          DateTime.now(),
      guests: n(row['guestCount'] ?? event['guestCount']).toInt(),
      total: n(row['totalAmount'] ?? event['totalAmount']),
      requestStatus: '${event['requestStatus'] ?? 'pending'}',
      bookingStatus: '${row['status'] ?? 'pending'}',
      paid: payments is List &&
          payments.any((p) => p is Map && p['status'] == 'paid'),
      foxerId: host is Map ? host['id']?.toString() : null,
      foxerName: host is Map ? '${host['name'] ?? ''}' : '',
      foxerImageUrl: host is Map ? host['imgId']?.toString() : null,
    );
  }

  final String bookingId;
  final String eventId;

  /// What was asked for: an offer's name, or "Own idea".
  final String style;
  final DateTime startAt;
  final int guests;
  final num total;
  final String requestStatus;
  final String bookingStatus;
  final bool paid;
  final String? foxerId;
  final String foxerName;
  final String? foxerImageUrl;

  MatchState get state {
    if (requestStatus == 'rejected' || bookingStatus == 'cancelled') {
      return MatchState.declined;
    }
    if (paid ||
        const {'confirmed', 'active', 'completed'}.contains(bookingStatus)) {
      return MatchState.confirmed;
    }
    if (requestStatus == 'approved') return MatchState.accepted;
    return MatchState.waiting;
  }

  /// Accepted, with money to pay before it is confirmed.
  bool get needsPayment => state == MatchState.accepted && total > 0;

  /// The request can still be withdrawn.
  bool get canWithdraw =>
      state == MatchState.waiting || state == MatchState.accepted;

  @override
  List<Object?> get props => [
        bookingId,
        eventId,
        style,
        startAt,
        guests,
        total,
        requestStatus,
        bookingStatus,
        paid,
        foxerId,
        foxerName,
        foxerImageUrl,
      ];
}

/// The citizen's Match requests, newest first.
final FutureProvider<List<MatchRequestItem>> myMatchRequestsProvider =
    FutureProvider.autoDispose<List<MatchRequestItem>>((ref) async {
  final body =
      await ref.watch(apiServiceProvider).get(ApiEndpoints.matchesMine);
  final data = body is Map ? body['data'] : null;
  if (data is! List) return const [];
  return [
    for (final row in data)
      if (row is Map)
        if (MatchRequestItem.tryParse(row.cast<String, dynamic>())
            case final item?)
          item,
  ];
});
