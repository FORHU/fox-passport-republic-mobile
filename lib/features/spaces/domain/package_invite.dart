import 'package:equatable/equatable.dart';
import 'package:flutter_template/features/spaces/domain/space_models.dart';

/// Why a Provider declines a package invite. [api] is what the API stores
/// (api#447); [other] needs a note.
enum InviteDeclineReason {
  unavailableOnDate('unavailable_on_date'),
  priceTooLow('price_too_low'),
  notMyKindOfEvent('not_my_kind_of_event'),
  tooFar('too_far'),
  noCapacity('no_capacity'),
  other('other');

  const InviteDeclineReason(this.api);

  final String api;

  static InviteDeclineReason? fromApi(Object? value) {
    for (final r in values) {
      if (r.api == value) return r;
    }
    return null;
  }
}

/// Where an invite stands.
enum InviteStatus {
  pending,
  accepted,
  declined,
  other;

  /// A line's `matchRequestStatus`; `secured` (booked) counts as accepted.
  static InviteStatus fromApi(Object? value) => switch (value) {
        'pending' => pending,
        'accepted' || 'secured' => accepted,
        'declined' => declined,
        _ => other,
      };
}

/// The Provider's answer to one invited line of the host's own package, as
/// the event studio shows it (api#447): waiting, joined, or declined and why.
class LineInvite extends Equatable {
  const LineInvite({required this.status, this.reason, this.note});

  /// A `templateVenues` / `templateAssets` / `templateServices` row of
  /// `GET /event-templates/:id`; null when the line is not an invite (only a
  /// matched line asks its Provider to join).
  static LineInvite? fromLine(Object? row) {
    if (row is! Map || row['matched'] != true) return null;
    final note = row['declineNote'];
    return LineInvite(
      status: InviteStatus.fromApi(row['matchRequestStatus']),
      reason: InviteDeclineReason.fromApi(row['declineReason']),
      note: note is String && note.trim().isNotEmpty ? note.trim() : null,
    );
  }

  final InviteStatus status;
  final InviteDeclineReason? reason;
  final String? note;

  @override
  List<Object?> get props => [status, reason, note];
}

/// An Event Foxer asking for one of this person's items (a venue, gear or a
/// service) in a package: a matched line of their event template.
class PackageInvite extends Equatable {
  const PackageInvite({
    required this.id,
    required this.type,
    required this.status,
    required this.packageName,
    required this.itemName,
    this.hostName,
    this.city,
    this.date,
    this.price,
    this.currency,
    this.note,
    this.declineReason,
    this.declineNote,
  });

  /// One row of `GET /event-templates/matches/incoming`, or null when it is
  /// not one.
  static PackageInvite? tryParse(Object? raw) {
    if (raw is! Map) return null;
    final id = raw['id'];
    final type = raw['type'];
    if (id is! String || type is! String) return null;
    final template = raw['template'];
    final item = raw['item'];
    final owner = template is Map ? template['owner'] : null;
    String? text(Object? v) =>
        v is String && v.trim().isNotEmpty ? v.trim() : null;
    final price = raw['agreedPrice'];
    return PackageInvite(
      id: id,
      type: type,
      status: InviteStatus.fromApi(raw['matchRequestStatus']),
      packageName: (template is Map ? text(template['name']) : null) ?? '',
      itemName: (item is Map ? text(item['name']) : null) ?? '',
      hostName: owner is Map ? text(owner['name']) : null,
      city: template is Map
          ? [text(template['targetCity']), text(template['targetState'])]
              .whereType<String>()
              .join(', ')
          : null,
      date: raw['date'] is String
          ? DateTime.tryParse(raw['date'] as String)?.toLocal()
          : null,
      price: price is num ? price : num.tryParse('${price ?? ''}'),
      currency: text(raw['currency']),
      note: text(raw['description']),
      declineReason: InviteDeclineReason.fromApi(raw['declineReason']),
      declineNote: text(raw['declineNote']),
    );
  }

  final String id;

  /// `asset`, `service` or `venue`, as the API answers it.
  final String type;

  /// Whether it is for a listing of this kind: each space (Venue, Gear,
  /// Services) answers only its own invites.
  bool isFor(RequestKind kind) => type == kind.name;
  final InviteStatus status;
  final String packageName;
  final String itemName;
  final String? hostName;
  final String? city;

  /// The day it is for, when the line has one.
  final DateTime? date;
  final num? price;
  final String? currency;

  /// What the Event Foxer wrote about the line.
  final String? note;
  final InviteDeclineReason? declineReason;
  final String? declineNote;

  @override
  List<Object?> get props => [id, type, status, declineReason, declineNote];
}
