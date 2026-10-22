import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_template/core/constants/api_endpoints.dart';
import 'package:flutter_template/features/auth/presentation/controllers/auth_controller.dart';

/// Which hat the viewer wears for an entry, as the API names it.
enum CalendarRole {
  /// An event they booked.
  guest,

  /// An event they host.
  host,

  /// An event they organize for someone else.
  organizer,

  /// An event at a venue they run.
  venue,

  /// Gear or a service they supply.
  supplier;

  static CalendarRole? fromName(Object? name) {
    for (final role in values) {
      if (role.name == name) return role;
    }
    return null;
  }
}

/// Where a booking at the viewer's venue stands with the venue, from the
/// venue transaction's status.
enum VenueHold {
  /// Waiting for the venue to reply: the one that needs an answer.
  awaitingReply,

  /// The dates are held, but it is not confirmed or paid yet.
  held,

  /// Confirmed.
  confirmed;

  static VenueHold? parse(Object? raw) => switch (raw) {
        'pending_provider_confirmation' => awaitingReply,
        'pending' => held,
        'approved' => confirmed,
        _ => null,
      };
}

/// One thing on the signed-in person's calendar, from `GET /calendar`.
class CalendarEntry extends Equatable {
  const CalendarEntry({
    required this.id,
    required this.role,
    required this.title,
    required this.start,
    required this.end,
    required this.status,
    this.kind = 'event',
    this.venueId,
    this.venueName,
    this.hold,
  });

  /// Null for a row the app cannot place (no dates, or an unknown role).
  static CalendarEntry? tryParse(Map<String, dynamic> row) {
    final role = CalendarRole.fromName(row['role']);
    final kind = '${row['kind'] ?? 'event'}';
    final rawStart = DateTime.tryParse('${row['start']}');
    if (role == null || rawStart == null) return null;
    // A closed day is a calendar date, sent as midnight UTC. Read as a local
    // instant it would fall on the day before anywhere behind UTC, so take the
    // date as it is written.
    final DateTime start;
    DateTime? end;
    if (kind == 'block') {
      start = DateTime(rawStart.year, rawStart.month, rawStart.day);
      end = DateTime(start.year, start.month, start.day + 1);
    } else {
      start = rawStart.toLocal();
      end = DateTime.tryParse('${row['end']}')?.toLocal();
    }
    String? text(String key) {
      final v = row[key];
      return v is String && v.isNotEmpty ? v : null;
    }

    return CalendarEntry(
      id: '${row['id']}',
      role: role,
      title: '${row['title'] ?? ''}',
      start: start,
      end: end != null && end.isAfter(start) ? end : start,
      status: '${row['status'] ?? ''}',
      kind: kind,
      venueId: text('venueId'),
      venueName: text('venueName'),
      hold: VenueHold.parse(row['venueStatus']),
    );
  }

  final String id;
  final CalendarRole role;
  final String title;
  final DateTime start;
  final DateTime end;
  final String status;

  /// `event`, `asset`, `service`, or `block` (a day a venue's owner closed).
  final String kind;

  /// For an entry at one of the viewer's venues, and for a block: which venue.
  final String? venueId;
  final String? venueName;

  /// For a booking at the viewer's venue: where it stands with the venue.
  final VenueHold? hold;

  /// A day a venue's owner closed, not a booking.
  bool get isBlock => kind == 'block';

  /// Whether any part of the entry falls on [day] (a local calendar day).
  bool coversDay(DateTime day) {
    final from = DateTime(day.year, day.month, day.day);
    final to = from.add(const Duration(days: 1));
    // An entry that ends exactly at midnight does not spill into the next day.
    return start.isBefore(to) && (end.isAfter(from) || start == from);
  }

  @override
  List<Object?> get props => [
        id,
        role,
        title,
        start,
        end,
        status,
        kind,
        venueId,
        venueName,
        hold,
      ];
}

typedef CalendarRange = ({DateTime from, DateTime to});

Future<List<CalendarEntry>> _fetchCalendar(
  Ref ref,
  CalendarRange range, {
  required bool blocks,
}) async {
  final body = await ref.watch(apiServiceProvider).get(
    ApiEndpoints.calendar,
    query: {
      'from': range.from.toUtc().toIso8601String(),
      'to': range.to.toUtc().toIso8601String(),
      // Also the days the person's venues have closed.
      if (blocks) 'blocks': 1,
    },
  );
  final data = body is Map ? body['data'] : null;
  if (data is! List) return const [];
  return [
    for (final row in data)
      if (row is Map)
        if (CalendarEntry.tryParse(row.cast<String, dynamic>())
            case final entry?)
          entry,
  ]..sort((a, b) => a.start.compareTo(b.start));
}

/// The calendar for one date range. Keyed by the range's two ends.
// The family type is long and adds nothing here, so it is left inferred.
// ignore: specify_nonobvious_property_types
final calendarEntriesProvider =
    FutureProvider.autoDispose.family<List<CalendarEntry>, CalendarRange>(
  (ref, range) => _fetchCalendar(ref, range, blocks: false),
);

/// The same calendar with the venue owner's closed days included, for the
/// Venue space.
// ignore: specify_nonobvious_property_types
final venueCalendarProvider =
    FutureProvider.autoDispose.family<List<CalendarEntry>, CalendarRange>(
  (ref, range) => _fetchCalendar(ref, range, blocks: true),
);
