import 'package:equatable/equatable.dart';

/// A booking the user holds, as the Tickets and Home screens show it.
class Ticket extends Equatable {
  const Ticket({
    required this.id,
    required this.eventName,
    required this.startAt,
    required this.endAt,
    required this.status,
    this.city,
    this.guestCount = 1,
    this.ticketCode,
    this.templateId,
    this.hasReview = false,
    this.isSample = false,
    this.cachedAt,
  });

  /// Reads a booking as `GET /bookings/upcoming` returns it.
  factory Ticket.fromBooking(Map<String, dynamic> json) {
    final event = json['event'];
    final eventMap = event is Map ? event.cast<String, dynamic>() : null;
    final start = DateTime.tryParse('${json['startAt']}')?.toLocal();
    final end = DateTime.tryParse('${json['endAt']}')?.toLocal();
    return Ticket(
      id: '${json['id']}',
      eventName: (eventMap?['name'] ?? json['eventName'] ?? '').toString(),
      startAt: start ?? DateTime.now(),
      endAt: end ?? start ?? DateTime.now(),
      status: (json['status'] ?? 'pending').toString(),
      city: (eventMap?['targetCity'] ?? eventMap?['city'])?.toString(),
      guestCount: (json['guestCount'] as num?)?.toInt() ?? 1,
      ticketCode: json['ticketCode']?.toString(),
      templateId: eventMap?['templateId']?.toString(),
      hasReview: json['hasReview'] == true,
    );
  }

  /// Reads a ticket saved on the phone by [toCache], marked as the saved copy
  /// it is, made at [cachedAt].
  factory Ticket.fromCache(Map<String, dynamic> json, DateTime cachedAt) {
    final start = DateTime.tryParse('${json['startAt']}')?.toLocal();
    final end = DateTime.tryParse('${json['endAt']}')?.toLocal();
    return Ticket(
      id: '${json['id']}',
      eventName: '${json['eventName'] ?? ''}',
      startAt: start ?? cachedAt,
      endAt: end ?? start ?? cachedAt,
      status: '${json['status'] ?? 'pending'}',
      city: json['city'] as String?,
      guestCount: (json['guestCount'] as num?)?.toInt() ?? 1,
      ticketCode: json['ticketCode'] as String?,
      templateId: json['templateId'] as String?,
      hasReview: json['hasReview'] == true,
      cachedAt: cachedAt,
    );
  }

  /// A believable ticket three days out, for when the user has none yet.
  factory Ticket.sample([DateTime? now]) {
    final base = now ?? DateTime.now();
    final day = DateTime(base.year, base.month, base.day + 3, 19);
    return Ticket(
      id: 'sample-ticket',
      eventName: 'Sky Hall',
      startAt: day,
      endAt: day.add(const Duration(hours: 5)),
      status: 'confirmed',
      city: 'Davao City',
      guestCount: 2,
      ticketCode: 'FXP-0000-SAMPLE',
      isSample: true,
    );
  }

  final String id;
  final String eventName;
  final DateTime startAt;
  final DateTime endAt;

  /// `pending` | `confirmed` | `completed` | `cancelled` | …
  final String status;
  final String? city;
  final int guestCount;
  final String? ticketCode;

  /// The event package this booking was made from, so it can be booked again.
  /// Null for a booking made straight on a venue, gear or a service.
  final String? templateId;

  /// The person already reviewed this booking.
  final bool hasReview;
  final bool isSample;

  /// Set when this is the copy saved on the phone, not what the server just
  /// said: when it was saved.
  final DateTime? cachedAt;

  /// What is saved to show this ticket with no signal.
  Map<String, dynamic> toCache() => {
        'id': id,
        'eventName': eventName,
        'startAt': startAt.toUtc().toIso8601String(),
        'endAt': endAt.toUtc().toIso8601String(),
        'status': status,
        'city': city,
        'guestCount': guestCount,
        'ticketCode': ticketCode,
        'templateId': templateId,
        'hasReview': hasReview,
      };

  /// Whole calendar days from [now] to the start; 0 is today.
  int daysUntil([DateTime? now]) {
    final today = now ?? DateTime.now();
    final a = DateTime(today.year, today.month, today.day);
    final b = DateTime(startAt.year, startAt.month, startAt.day);
    return b.difference(a).inDays;
  }

  @override
  List<Object?> get props => [
        id,
        eventName,
        startAt,
        endAt,
        status,
        city,
        guestCount,
        ticketCode,
        templateId,
        hasReview,
        isSample,
        cachedAt,
      ];
}
