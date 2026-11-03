import 'package:equatable/equatable.dart';

/// What a person on a team does. An Organizer helps run the venue or event and
/// must accept an invitation; a Check-in Helper only checks guests in and is
/// added at once.
enum TeamKind {
  organizer('organizer'),
  checkInHelper('check_in_helper');

  const TeamKind(this.api);

  /// The API's word for it.
  final String api;

  static TeamKind? parse(Object? raw) {
    for (final kind in values) {
      if (kind.api == raw) return kind;
    }
    return null;
  }
}

/// A venue or event whose team the person manages.
class TeamTarget extends Equatable {
  const TeamTarget({
    required this.isEvent,
    required this.id,
    required this.name,
    this.detail = '',
  });

  final bool isEvent;
  final String id;
  final String name;

  /// A line under the name: where and when, or the venue's status.
  final String detail;

  @override
  List<Object?> get props => [isEvent, id];
}

DateTime? _date(Object? raw) =>
    raw is String ? DateTime.tryParse(raw)?.toLocal() : null;

String? _text(Object? raw) {
  final value = raw is String ? raw.trim() : null;
  return value == null || value.isEmpty ? null : value;
}

/// An event the person organizes, as the team list shows it. Cancelled and
/// completed events are left out: the API refuses to appoint to them.
TeamTarget? teamTargetFromEvent(Object? row) {
  if (row is! Map || row['id'] == null) return null;
  final status = '${row['eventStatus'] ?? ''}';
  if (status == 'cancelled' || status == 'completed') return null;
  return TeamTarget(
    isEvent: true,
    id: '${row['id']}',
    name: _text(row['name']) ?? '',
    detail: _text(row['targetCity']) ?? '',
  );
}

/// One person on a team, or invited, or asking to join.
class TeamMember extends Equatable {
  const TeamMember({
    required this.id,
    required this.userId,
    required this.kind,
    required this.state,
    required this.name,
    required this.email,
    this.expiresAt,
    this.respondedAt,
    this.endReason,
  });

  final String id;

  /// The person's account, to tell who is already on the team.
  final String userId;
  final TeamKind kind;

  /// `invited`, `requested`, `active`, `expired`, `declined`, `finished` or
  /// `ended`, as the API works it out.
  final String state;
  final String name;
  final String email;
  final DateTime? expiresAt;
  final DateTime? respondedAt;

  /// Why it ended: `removed`, `left`, `role_revoked` or `owner_role_revoked`.
  final String? endReason;

  bool get isActive => state == 'active';
  bool get isInvited => state == 'invited';
  bool get isRequest => state == 'requested';

  /// Gone from the team, and listed only as history.
  bool get isPast => !isActive && !isInvited && !isRequest;

  /// What to call them: their name, or their email when they have none.
  String get title => name.isEmpty ? email : name;

  static TeamMember? tryParse(Object? raw) {
    if (raw is! Map || raw['id'] is! String) return null;
    final kind = TeamKind.parse(raw['kind']);
    final user = raw['user'];
    if (kind == null || user is! Map) return null;
    return TeamMember(
      id: raw['id'] as String,
      userId: '${raw['userId'] ?? user['id'] ?? ''}',
      kind: kind,
      state: '${raw['state'] ?? raw['status'] ?? ''}',
      name: _text(user['name']) ?? '',
      email: _text(user['email']) ?? '',
      expiresAt: _date(raw['expiresAt']),
      respondedAt: _date(raw['respondedAt']),
      endReason: _text(raw['endReason']),
    );
  }

  @override
  List<Object?> get props => [id, state];
}

/// A team sorted the way the screen shows it.
class TeamRoster {
  TeamRoster(List<TeamMember> all)
      : active = [
          for (final m in all)
            if (m.isActive) m,
        ],
        invited = [
          for (final m in all)
            if (m.isInvited) m,
        ],
        requests = [
          for (final m in all)
            if (m.isRequest) m,
        ],
        past = [
          for (final m in all)
            if (m.isPast) m,
        ];

  final List<TeamMember> active;
  final List<TeamMember> invited;
  final List<TeamMember> requests;
  final List<TeamMember> past;

  /// Nobody is on the team or invited.
  bool get isEmpty => active.isEmpty && invited.isEmpty;

  /// Everyone who is on the team, invited or asking: they cannot be invited
  /// again.
  Set<String> get memberIds => {
        for (final m in [...active, ...invited, ...requests]) m.userId,
      };
}

/// An approved Organizer found by the search. The API gives no email.
class OrganizerCard extends Equatable {
  const OrganizerCard({
    required this.id,
    required this.name,
    required this.level,
    this.city,
    this.specializations = const [],
  });

  final String id;
  final String name;
  final int level;
  final String? city;
  final List<String> specializations;

  static OrganizerCard? tryParse(Object? raw) {
    if (raw is! Map || raw['id'] is! String) return null;
    final level = raw['level'];
    final specs = raw['specializations'];
    return OrganizerCard(
      id: raw['id'] as String,
      name: _text(raw['name']) ?? '',
      level: level is num ? level.toInt() : 1,
      city: _text(raw['city']),
      specializations: [
        if (specs is List)
          for (final s in specs)
            if (s is String && s.isNotEmpty) s,
      ],
    );
  }

  @override
  List<Object?> get props => [id];
}
