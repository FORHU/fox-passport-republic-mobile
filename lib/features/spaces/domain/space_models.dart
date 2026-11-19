import 'package:equatable/equatable.dart';

/// How a request for your venue stands, as the API's `TransactionStatus`.
enum RequestStatus {
  /// Waiting for the supplier to confirm: the one that needs a reply.
  awaitingYou,
  pending,
  approved,
  rejected,
  cancelled,
  other;

  static RequestStatus parse(Object? raw) => switch (raw) {
        'pending_provider_confirmation' => awaitingYou,
        'pending' => pending,
        'approved' => approved,
        'rejected' => rejected,
        'cancelled' => cancelled,
        _ => other,
      };
}

/// What a request is for. The API names the nested record the same way.
enum RequestKind { venue, asset, service }

/// Someone has put your venue into their event and wants you to confirm it
/// (a row of `GET /event-transactions/provider`).
class VenueRequest extends Equatable {
  const VenueRequest({
    required this.id,
    required this.venueName,
    required this.eventName,
    required this.status,
    this.kind = RequestKind.venue,
    this.clientName,
    this.startAt,
    this.price,
    this.replyBy,
    this.imageUrl,
    this.bookingStatus,
    this.declinedBySupplier = false,
  });

  /// Reads one entry of the response's `venues`; null when it has no id.
  static VenueRequest? tryParse(
    Object? row, {
    RequestKind kind = RequestKind.venue,
  }) {
    if (row is! Map || row['id'] == null) return null;
    final event = row['event'];
    final venue = row[kind.name];
    final client = event is Map ? event['client'] : null;
    final price = row['agreedPrice'];
    final booking = row['booking'];
    return VenueRequest(
      id: '${row['id']}',
      kind: kind,
      venueName: venue is Map ? '${venue['name'] ?? ''}' : '',
      eventName: event is Map ? '${event['name'] ?? ''}' : '',
      status: RequestStatus.parse(row['status']),
      clientName: client is Map ? client['name'] as String? : null,
      startAt: event is Map
          ? DateTime.tryParse('${event['startAt'] ?? ''}')?.toLocal()
          : null,
      price: price is num ? price : num.tryParse('$price'),
      replyBy:
          DateTime.tryParse('${row['confirmationDeadline'] ?? ''}')?.toLocal(),
      imageUrl: _firstImage(venue is Map ? venue['images'] : null),
      bookingStatus: booking is Map ? booking['status'] as String? : null,
      declinedBySupplier: row['rejectionReason'] == 'supplier_declined',
    );
  }

  final String id;

  /// A venue, a piece of gear or a service.
  final RequestKind kind;

  /// The name of the venue, asset or service asked for.
  final String venueName;
  final String eventName;
  final RequestStatus status;
  final String? clientName;
  final DateTime? startAt;
  final num? price;

  /// When the confirmation is due.
  final DateTime? replyBy;
  final String? imageUrl;

  /// The booking's own status (`pending` until it is paid); null when the item
  /// is not attached to a booking yet.
  final String? bookingStatus;

  /// This Supplier left the event after taking it (not a turned-down request).
  final bool declinedBySupplier;

  bool get needsReply => status == RequestStatus.awaitingYou;

  /// A booked item can be declined until its booking is paid: while it is
  /// still pending or approved and nobody has paid. After payment the way out
  /// is the cancellation policy.
  bool get canDecline =>
      (status == RequestStatus.pending || status == RequestStatus.approved) &&
      (bookingStatus == null || bookingStatus == 'pending');

  @override
  List<Object?> get props => [
        id,
        kind,
        venueName,
        eventName,
        status,
        clientName,
        startAt,
        price,
        replyBy,
        imageUrl,
        bookingStatus,
        declinedBySupplier,
      ];
}

/// Why a booked event needs a replacement Supplier.
/// Why a Supplier leaves a booked event.
enum DeclineCause {
  /// It has another booking at that time.
  busy,

  /// Any other reason.
  other,
}

enum AttentionReason {
  /// The Supplier declined the booked event.
  declined,

  /// The Mayor blocked a day the event falls on.
  dateBlocked,

  /// The gear or service was paused, archived or removed.
  unavailable;

  static AttentionReason parse(Object? raw) => switch (raw) {
        'declined' => declined,
        'date_blocked' => dateBlocked,
        _ => unavailable,
      };
}

/// One Supplier of a booked event that needs replacing, and why.
class AttentionIssue extends Equatable {
  const AttentionIssue({
    required this.kind,
    required this.supplierName,
    required this.itemName,
    required this.reason,
    this.busy = false,
  });

  final RequestKind kind;
  final String supplierName;
  final String itemName;
  final AttentionReason reason;

  /// A declining Supplier said it has another booking at that time.
  final bool busy;

  @override
  List<Object?> get props => [kind, supplierName, itemName, reason, busy];
}

/// A booked event of the person's that has lost a Supplier (a row of
/// `GET /event-transactions/needs-attention`).
class EventNeedingAttention extends Equatable {
  const EventNeedingAttention({
    required this.eventId,
    required this.eventName,
    required this.issues,
    this.startAt,
  });

  /// Reads one event of the response; null when it has no id or no issue.
  static EventNeedingAttention? tryParse(Object? row) {
    if (row is! Map || row['id'] == null && row['eventId'] == null) return null;
    final raw = row['issues'];
    final issues = [
      if (raw is List)
        for (final i in raw)
          if (i is Map)
            AttentionIssue(
              kind: RequestKind.values.firstWhere(
                (k) => k.name == i['kind'],
                orElse: () => RequestKind.venue,
              ),
              supplierName: '${i['supplierName'] ?? ''}',
              itemName: '${i['itemName'] ?? ''}',
              reason: AttentionReason.parse(i['reason']),
              busy: i['cause'] == 'busy',
            ),
    ];
    if (issues.isEmpty) return null;
    return EventNeedingAttention(
      eventId: '${row['eventId'] ?? row['id']}',
      eventName: '${row['eventName'] ?? ''}',
      startAt: DateTime.tryParse('${row['startAt']}')?.toLocal(),
      issues: issues,
    );
  }

  final String eventId;
  final String eventName;
  final DateTime? startAt;
  final List<AttentionIssue> issues;

  @override
  List<Object?> get props => [eventId, eventName, startAt, issues];
}

/// One Supplier of a booked event: what it is, who provides it, where it
/// stands, and why it needs replacing if it does.
class BookedSupplier extends Equatable {
  const BookedSupplier({
    required this.kind,
    required this.supplierName,
    required this.itemName,
    required this.status,
    this.transactionId = '',
    this.problem,
    this.busy = false,
    this.pendingProposalId,
    this.replaceBy,
  });

  final RequestKind kind;

  /// The event's line for this Supplier; what a replacement replaces.
  final String transactionId;
  final String supplierName;
  final String itemName;
  final RequestStatus status;

  /// Set when this Supplier needs replacing.
  final AttentionReason? problem;

  /// It declined because it has another booking at that time.
  final bool busy;

  /// A replacement the host proposed, waiting for the citizen's answer.
  final String? pendingProposalId;

  /// Past this, the citizen may cancel for a full refund unless it is replaced.
  final DateTime? replaceBy;

  @override
  List<Object?> get props => [
        kind,
        transactionId,
        supplierName,
        itemName,
        status,
        problem,
        busy,
        pendingProposalId,
        replaceBy,
      ];
}

/// A listing that could take the place of a Supplier on a booked event (the
/// answer of `GET /event-transactions/:id/replacements`), cheapest first with
/// the venues the host works with ahead.
class ReplacementCandidate extends Equatable {
  const ReplacementCandidate({
    required this.itemId,
    required this.name,
    required this.supplierName,
    required this.price,
    this.partner = false,
  });

  /// Reads one row; null when it has no listing in it.
  static ReplacementCandidate? tryParse(Object? row) {
    if (row is! Map || row['itemId'] == null) return null;
    return ReplacementCandidate(
      itemId: '${row['itemId']}',
      name: '${row['name'] ?? ''}',
      supplierName: '${row['supplierName'] ?? ''}',
      price: num.tryParse('${row['price']}') ?? 0,
      partner: row['partner'] == true,
    );
  }

  final String itemId;
  final String name;
  final String supplierName;

  /// The Supplier's price for the line, before the host's commission and fees.
  final num price;

  /// A venue whose Mayor works with this host.
  final bool partner;

  @override
  List<Object?> get props => [itemId, name, supplierName, price, partner];
}

/// A booked event of the person's with every Supplier on it (the answer of
/// `GET /event-transactions/event/:id`).
class BookedEvent extends Equatable {
  const BookedEvent({
    required this.eventId,
    required this.eventName,
    required this.suppliers,
    this.declinableBookingId,
    this.startAt,
    this.endAt,
  });

  /// Reads the answer; null when it has no event in it.
  static BookedEvent? tryParse(Object? data) {
    if (data is! Map || data['eventId'] == null) return null;
    final raw = data['suppliers'];
    return BookedEvent(
      eventId: '${data['eventId']}',
      eventName: '${data['eventName'] ?? ''}',
      startAt: DateTime.tryParse('${data['startAt']}')?.toLocal(),
      endAt: DateTime.tryParse('${data['endAt']}')?.toLocal(),
      declinableBookingId: data['declinableBookingId'] is String
          ? data['declinableBookingId'] as String
          : null,
      suppliers: [
        if (raw is List)
          for (final s in raw)
            if (s is Map)
              BookedSupplier(
                kind: RequestKind.values.firstWhere(
                  (k) => k.name == s['kind'],
                  orElse: () => RequestKind.venue,
                ),
                supplierName: '${s['supplierName'] ?? ''}',
                itemName: '${s['itemName'] ?? ''}',
                status: RequestStatus.parse(s['status']),
                problem: s['reason'] == null
                    ? null
                    : AttentionReason.parse(s['reason']),
                busy: s['cause'] == 'busy',
                transactionId: '${s['transactionId'] ?? ''}',
                pendingProposalId: s['pendingProposalId'] is String
                    ? s['pendingProposalId'] as String
                    : null,
                replaceBy: DateTime.tryParse('${s['replaceBy']}')?.toLocal(),
              ),
      ],
    );
  }

  final String eventId;
  final String eventName;
  final DateTime? startAt;
  final DateTime? endAt;
  final List<BookedSupplier> suppliers;

  /// The unpaid booking the host may still decline; null once it is paid.
  final String? declinableBookingId;

  bool get needsReplacement => suppliers.any((s) => s.problem != null);

  @override
  List<Object?> get props => [
        eventId,
        eventName,
        startAt,
        endAt,
        suppliers,
        declinableBookingId,
      ];
}

/// One of your listings: a venue or an event template.
class SpaceListing extends Equatable {
  const SpaceListing({
    required this.id,
    required this.name,
    required this.status,
    this.city,
    this.imageUrl,
  });

  /// Reads one row of a venues or event-templates list; null when it has no
  /// id. [cityKey] is where the place is: `city` on a venue, `targetCity` on
  /// an event template.
  static SpaceListing? tryParse(Object? row, {String cityKey = 'city'}) {
    if (row is! Map || row['id'] == null) return null;
    String? text(String key) {
      final v = row[key];
      return v is String && v.trim().isNotEmpty ? v.trim() : null;
    }

    return SpaceListing(
      id: '${row['id']}',
      name: text('name') ?? '',
      status: text('status') ?? '',
      city: text(cityKey),
      imageUrl: _firstImage(row['images']),
    );
  }

  final String id;
  final String name;

  /// The API's status word (`available`, `pending`, `published`, ...).
  final String status;
  final String? city;
  final String? imageUrl;

  /// Which filter group the status belongs to: `live`, `pending`, `draft`,
  /// `rejected` or `archived`. Anything unknown counts as a draft.
  String get group => switch (status) {
        'available' || 'published' || 'reserved' => 'live',
        'pending' => 'pending',
        'rejected' => 'rejected',
        'archived' || 'paused' => 'archived',
        _ => 'draft',
      };

  /// Whether the name or town contains [query], ignoring case. A blank query
  /// matches everything.
  bool matches(String query) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return true;
    return name.toLowerCase().contains(q) ||
        (city?.toLowerCase().contains(q) ?? false);
  }

  @override
  List<Object?> get props => [id, name, status, city, imageUrl];
}

/// What checking a guest in came back with.
class CheckInResult extends Equatable {
  const CheckInResult({this.message, this.payoutTriggered = false});

  factory CheckInResult.fromJson(Object? json) {
    final data =
        json is Map && json['data'] is Map ? json['data'] as Map : json;
    if (data is! Map) return const CheckInResult();
    final message = data['message'];
    return CheckInResult(
      message: message is String && message.trim().isNotEmpty
          ? message.trim()
          : null,
      payoutTriggered: data['payoutTriggered'] == true,
    );
  }

  final String? message;
  final bool payoutTriggered;

  @override
  List<Object?> get props => [message, payoutTriggered];
}

/// What a supplier has been paid and is still owed, from `GET /payouts/me`.
class PayoutTotals extends Equatable {
  const PayoutTotals({this.pending = 0, this.paid = 0});

  final num pending;
  final num paid;

  @override
  List<Object?> get props => [pending, paid];
}

/// One payout, with what it was for.
class PayoutRow extends Equatable {
  const PayoutRow({
    required this.id,
    required this.amount,
    required this.status,
    required this.source,
    this.createdAt,
    this.paidAt,
  });

  /// Null for a row with no id.
  static PayoutRow? tryParse(Object? row) {
    if (row is! Map || row['id'] == null) return null;
    final amount = row['payoutAmount'];
    return PayoutRow(
      id: '${row['id']}',
      // A decimal column comes back as a string.
      amount: amount is num ? amount : num.tryParse('$amount') ?? 0,
      status: '${row['status'] ?? ''}',
      source: '${row['sourceType'] ?? ''}',
      createdAt: DateTime.tryParse('${row['createdAt']}')?.toLocal(),
      paidAt: DateTime.tryParse('${row['paidAt']}')?.toLocal(),
    );
  }

  final String id;
  final num amount;

  /// `pending`, `paid` or `failed`.
  final String status;

  /// What it was for, as the API names it (`event_venue_transaction`, ...).
  final String source;
  final DateTime? createdAt;
  final DateTime? paidAt;

  @override
  List<Object?> get props => [id, amount, status, source, createdAt, paidAt];
}

class PayoutSummary extends Equatable {
  const PayoutSummary({
    this.totals = const PayoutTotals(),
    this.rows = const [],
  });

  /// Reads `{ data: [...], totals: { pending, paid } }`.
  factory PayoutSummary.fromJson(Object? body) {
    if (body is! Map) return const PayoutSummary();
    final totals = body['totals'];
    num n(Object? v) => v is num ? v : num.tryParse('$v') ?? 0;
    final data = body['data'];
    return PayoutSummary(
      totals: totals is Map
          ? PayoutTotals(pending: n(totals['pending']), paid: n(totals['paid']))
          : const PayoutTotals(),
      rows: [
        if (data is List)
          for (final row in data)
            if (PayoutRow.tryParse(row) case final r?) r,
      ],
    );
  }

  final PayoutTotals totals;
  final List<PayoutRow> rows;

  @override
  List<Object?> get props => [totals, rows];
}

/// How far the person's payout account (Stripe) is set up.
class StripeStatus extends Equatable {
  const StripeStatus({
    this.hasAccount = false,
    this.onboardingComplete = false,
    this.payoutsEnabled = false,
  });

  /// Reads `{ data: { hasStripeAccount, ... } }`.
  factory StripeStatus.fromJson(Object? body) {
    final data =
        body is Map && body['data'] is Map ? body['data'] as Map : body;
    if (data is! Map) return const StripeStatus();
    return StripeStatus(
      hasAccount: data['hasStripeAccount'] == true,
      onboardingComplete: data['stripeOnboardingComplete'] == true,
      payoutsEnabled: data['stripePayoutsEnabled'] == true,
    );
  }

  final bool hasAccount;
  final bool onboardingComplete;

  /// They can be paid out.
  final bool payoutsEnabled;

  @override
  List<Object?> get props => [hasAccount, onboardingComplete, payoutsEnabled];
}

String? _firstImage(Object? images) {
  if (images is! List || images.isEmpty) return null;
  final first = images.first;
  final url = first is Map ? first['url'] : first;
  return url is String && url.isNotEmpty ? url : null;
}
