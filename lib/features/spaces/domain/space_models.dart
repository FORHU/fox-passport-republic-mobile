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

/// Someone has put your venue into their event and wants you to confirm it
/// (a row of `GET /event-transactions/provider`).
class VenueRequest extends Equatable {
  const VenueRequest({
    required this.id,
    required this.venueName,
    required this.eventName,
    required this.status,
    this.clientName,
    this.startAt,
    this.price,
    this.replyBy,
    this.imageUrl,
  });

  /// Reads one entry of the response's `venues`; null when it has no id.
  static VenueRequest? tryParse(Object? row) {
    if (row is! Map || row['id'] == null) return null;
    final event = row['event'];
    final venue = row['venue'];
    final client = event is Map ? event['client'] : null;
    final price = row['agreedPrice'];
    return VenueRequest(
      id: '${row['id']}',
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
    );
  }

  final String id;
  final String venueName;
  final String eventName;
  final RequestStatus status;
  final String? clientName;
  final DateTime? startAt;
  final num? price;

  /// When the confirmation is due.
  final DateTime? replyBy;
  final String? imageUrl;

  bool get needsReply => status == RequestStatus.awaitingYou;

  @override
  List<Object?> get props => [
        id,
        venueName,
        eventName,
        status,
        clientName,
        startAt,
        price,
        replyBy,
        imageUrl,
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
        'available' || 'published' => 'live',
        'pending' => 'pending',
        'rejected' => 'rejected',
        'archived' => 'archived',
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
