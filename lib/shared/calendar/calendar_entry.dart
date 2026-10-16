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
  });

  /// Null for a row the app cannot place (no dates, or an unknown role).
  static CalendarEntry? tryParse(Map<String, dynamic> row) {
    final role = CalendarRole.fromName(row['role']);
    final start = DateTime.tryParse('${row['start']}')?.toLocal();
    final end = DateTime.tryParse('${row['end']}')?.toLocal();
    if (role == null || start == null) return null;
    return CalendarEntry(
      id: '${row['id']}',
      role: role,
      title: '${row['title'] ?? ''}',
      start: start,
      end: end != null && end.isAfter(start) ? end : start,
      status: '${row['status'] ?? ''}',
      kind: '${row['kind'] ?? 'event'}',
    );
  }

  final String id;
  final CalendarRole role;
  final String title;
  final DateTime start;
  final DateTime end;
  final String status;

  /// `event`, `asset` or `service`.
  final String kind;

  /// Whether any part of the entry falls on [day] (a local calendar day).
  bool coversDay(DateTime day) {
    final from = DateTime(day.year, day.month, day.day);
    final to = from.add(const Duration(days: 1));
    // An entry that ends exactly at midnight does not spill into the next day.
    return start.isBefore(to) && (end.isAfter(from) || start == from);
  }

  @override
  List<Object?> get props => [id, role, title, start, end, status, kind];
}

/// The calendar for one date range. Keyed by the range's two ends.
// The family type is long and adds nothing here, so it is left inferred.
// ignore: specify_nonobvious_property_types
final calendarEntriesProvider = FutureProvider.autoDispose
    .family<List<CalendarEntry>, ({DateTime from, DateTime to})>((
  ref,
  range,
) async {
  final body = await ref.watch(apiServiceProvider).get(
    ApiEndpoints.calendar,
    query: {
      'from': range.from.toUtc().toIso8601String(),
      'to': range.to.toUtc().toIso8601String(),
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
});
