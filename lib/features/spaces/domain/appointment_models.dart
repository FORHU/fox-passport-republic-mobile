import 'package:equatable/equatable.dart';
import 'package:flutter_template/features/spaces/domain/team_models.dart';

/// Where an appointment stands, as the API shows it. Anything it adds later
/// reads as [other] and is left out of every list.
enum AppointmentState {
  invited,
  requested,
  active,
  finished,
  other;

  static AppointmentState parse(Object? raw) => switch (raw) {
        'invited' => invited,
        'requested' => requested,
        'active' => active,
        'finished' => finished,
        _ => other,
      };
}

DateTime? _date(Object? raw) =>
    raw is String ? DateTime.tryParse(raw)?.toLocal() : null;

String? _text(Object? raw) {
  final value = raw is String ? raw.trim() : null;
  return value == null || value.isEmpty ? null : value;
}

/// A venue or event the person has been asked to help run, or does: one row of
/// `GET /appointments/mine`.
class MyAppointment extends Equatable {
  const MyAppointment({
    required this.id,
    required this.kind,
    required this.state,
    required this.name,
    this.eventId,
    this.venueId,
    this.startAt,
    this.place,
    this.appointedBy,
  });

  /// Null for a row with no id or an unknown kind.
  static MyAppointment? tryParse(Object? row) {
    if (row is! Map || row['id'] == null) return null;
    final kind = TeamKind.parse(row['kind']);
    if (kind == null) return null;
    final event = row['event'];
    final venue = row['venue'];
    final by = row['appointedBy'];
    return MyAppointment(
      id: '${row['id']}',
      kind: kind,
      state: AppointmentState.parse(row['state']),
      name: (event is Map ? _text(event['name']) : null) ??
          (venue is Map ? _text(venue['name']) : null) ??
          '',
      eventId: event is Map ? '${event['id']}' : null,
      venueId: venue is Map ? '${venue['id']}' : null,
      startAt: event is Map ? _date(event['startAt']) : null,
      place: venue is Map ? _text(venue['city']) : null,
      appointedBy: by is Map ? _text(by['name']) ?? _text(by['email']) : null,
    );
  }

  final String id;
  final TeamKind kind;
  final AppointmentState state;

  /// The event's or venue's name.
  final String name;
  final String? eventId;
  final String? venueId;
  final DateTime? startAt;

  /// The venue's town, when it has one.
  final String? place;

  /// Who named the person, by name or else by email.
  final String? appointedBy;

  bool get isEvent => eventId != null;
  bool get isOrganizer => kind == TeamKind.organizer;

  @override
  List<Object?> get props => [id, kind, state, name, startAt];
}
