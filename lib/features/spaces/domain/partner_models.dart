/// Where a venue partnership stands.
enum PartnerStatus {
  pending,
  approved,
  rejected,
  revoked;

  static PartnerStatus? parse(Object? raw) {
    for (final status in values) {
      if (status.name == raw) return status;
    }
    return null;
  }
}

/// Which side the person is on: the Mayor of the venue, or the Event Foxer
/// who runs events there.
enum PartnerSide { mayor, eventFoxer }

/// A partnership between a venue and an Event Foxer: an application the Event
/// Foxer made, or an invitation the Mayor sent.
class Partner {
  const Partner({
    required this.id,
    required this.venueId,
    required this.venueName,
    required this.partnerName,
    required this.status,
    required this.startedByEventFoxer,
    required this.side,
    this.venueImageUrl,
    this.partnerImageUrl,
    this.agreedPrice,
    this.rejectionReason,
  });

  final String id;
  final String venueId;
  final String venueName;

  /// The Event Foxer, as the Mayor sees them.
  final String partnerName;
  final PartnerStatus status;

  /// An application from the Event Foxer; otherwise an invitation.
  final bool startedByEventFoxer;
  final PartnerSide side;
  final String? venueImageUrl;
  final String? partnerImageUrl;

  /// A price agreed up front; only the Mayor can approve such an application.
  final double? agreedPrice;
  final String? rejectionReason;

  bool get isPending => status == PartnerStatus.pending;

  /// The other side has to answer: an application waits for the Mayor, an
  /// invitation for the Event Foxer.
  bool get awaitingMe =>
      isPending && startedByEventFoxer == (side == PartnerSide.mayor);

  /// The person started it, so can only take it back.
  bool get startedByMe => isPending && !awaitingMe;

  /// Approved partnerships can be ended by the Mayor only.
  bool get canRevoke =>
      status == PartnerStatus.approved && side == PartnerSide.mayor;

  static Partner? tryParse(Object? raw, PartnerSide side) {
    if (raw is! Map || raw['id'] is! String) return null;
    final status = PartnerStatus.parse(raw['status']);
    final venue = raw['venue'];
    if (status == null || venue is! Map || venue['id'] is! String) return null;
    final foxer = raw['eventFoxer'];
    final images = venue['images'];
    return Partner(
      id: raw['id'] as String,
      venueId: venue['id'] as String,
      venueName: '${venue['name'] ?? ''}',
      partnerName: foxer is Map ? '${foxer['name'] ?? ''}' : '',
      status: status,
      startedByEventFoxer: raw['initiatedBy'] == 'eventFoxer',
      side: side,
      venueImageUrl: images is List && images.isNotEmpty && images.first is Map
          ? (images.first as Map)['url'] as String?
          : null,
      partnerImageUrl: foxer is Map ? foxer['imgId'] as String? : null,
      agreedPrice: raw['agreedPrice'] == null
          ? null
          : double.tryParse('${raw['agreedPrice']}'),
      rejectionReason: raw['rejectionReason'] as String?,
    );
  }
}

/// Every partnership the person is part of, from either side.
class PartnerLists {
  const PartnerLists({this.asMayor = const [], this.asEventFoxer = const []});
  factory PartnerLists.fromJson(Object? body) {
    final data = body is Map ? body['data'] : null;
    if (data is! Map) {
      throw const FormatException('Partners response has no data');
    }
    List<Partner> read(Object? rows, PartnerSide side) => [
          if (rows is List)
            for (final row in rows)
              if (Partner.tryParse(row, side) case final p?) p,
        ];
    return PartnerLists(
      asMayor: read(data['asVenueMayor'], PartnerSide.mayor),
      asEventFoxer: read(data['asEventFoxer'], PartnerSide.eventFoxer),
    );
  }

  final List<Partner> asMayor;
  final List<Partner> asEventFoxer;

  List<Partner> forSide(PartnerSide side) =>
      side == PartnerSide.mayor ? asMayor : asEventFoxer;
}
