import 'package:equatable/equatable.dart';
import 'package:flutter_template/shared/catalog/catalog_item.dart';
import 'package:flutter_template/shared/currency/currency.dart';

enum PackageItemKind { gear, service, venue }

/// One thing in an event package: a venue, a piece of gear or a service.
class PackageItem extends Equatable {
  const PackageItem({
    required this.id,
    required this.kind,
    required this.name,
    required this.price,
    required this.isOptional,
  });

  /// The id of the link between the event and the item, which is what an
  /// exclusion refers to.
  final String id;
  final PackageItemKind kind;
  final String name;
  final num price;

  /// An optional item can be left out of the booking.
  final bool isOptional;

  @override
  List<Object?> get props => [id, kind, name, price, isOptional];
}

/// What the citizen pays for a package once some optional items are left out.
class PackageQuote extends Equatable {
  const PackageQuote({
    required this.package,
    required this.fee,
    required this.total,
  });

  final num package;
  final num fee;
  final num total;

  @override
  List<Object?> get props => [package, fee, total];
}

/// An event an EventFoxer has put together (venue, gear and services) that a
/// citizen can book as it is, or with its optional items left out.
class EventPackage extends Equatable {
  const EventPackage({
    required this.id,
    required this.name,
    required this.estimatedTotal,
    required this.platformFeeAmount,
    this.description,
    this.category,
    this.city,
    this.state,
    this.lat,
    this.lng,
    this.imageUrl,
    this.hostName,
    this.maxAttendees,
    this.currentAttendees = 0,
    this.items = const [],
    this.currency = kBaseCurrency,
    this.isSample = false,
  });

  /// Reads `GET /event-templates/browse/:id`.
  factory EventPackage.fromJson(Map<String, dynamic> json) {
    num n(Object? v) => v is num ? v : num.tryParse('$v') ?? 0;

    List<PackageItem> read(String key, String nested, PackageItemKind kind) {
      final rows = json[key];
      if (rows is! List) return const [];
      return [
        for (final row in rows)
          if (row is Map && row['id'] != null)
            PackageItem(
              id: '${row['id']}',
              kind: kind,
              name: (row[nested] is Map ? (row[nested] as Map)['name'] : null)
                      ?.toString() ??
                  '',
              price: n(row['agreedPrice']),
              isOptional: row['isOptional'] == true,
            ),
      ];
    }

    String? text(String key) {
      final v = json[key];
      return v is String && v.trim().isNotEmpty ? v.trim() : null;
    }

    // A missing pin stays null; `n` would turn it into 0, 0.
    double? coordinate(Object? v) => v is num ? v.toDouble() : null;

    final images = json['images'];
    String? image;
    if (images is List && images.isNotEmpty) {
      final first = images.first;
      image = first is Map ? first['url']?.toString() : first?.toString();
    }
    final owner = json['owner'];

    return EventPackage(
      id: '${json['id']}',
      name: text('name') ?? '',
      description: text('description'),
      category: text('category'),
      city: text('targetCity'),
      state: text('targetState'),
      lat: coordinate(json['lat']),
      lng: coordinate(json['lng']),
      imageUrl: image,
      hostName: owner is Map ? owner['name']?.toString() : null,
      maxAttendees: (json['maxAttendees'] as num?)?.toInt(),
      currentAttendees: (json['currentAttendees'] as num?)?.toInt() ?? 0,
      estimatedTotal: n(json['estimatedTotal']),
      platformFeeAmount: n(json['platformFeeAmount']),
      items: [
        ...read('templateVenues', 'venue', PackageItemKind.venue),
        ...read('templateAssets', 'asset', PackageItemKind.gear),
        ...read('templateServices', 'service', PackageItemKind.service),
      ],
    );
  }

  /// Placeholder content for a sample catalog row, so the screen can show
  /// how a package works while the API has none.
  factory EventPackage.sample(CatalogItem item) => EventPackage(
        id: item.id,
        name: item.title,
        description: 'A sample package: a hall, sound and a photographer.',
        category: item.category,
        city: item.city,
        hostName: item.host,
        estimatedTotal: 40950,
        platformFeeAmount: 1950,
        items: const [
          PackageItem(
            id: 'sample-venue',
            kind: PackageItemKind.venue,
            name: 'Sky Hall',
            price: 25000,
            isOptional: false,
          ),
          PackageItem(
            id: 'sample-gear',
            kind: PackageItemKind.gear,
            name: 'Sound system',
            price: 8000,
            isOptional: true,
          ),
          PackageItem(
            id: 'sample-service',
            kind: PackageItemKind.service,
            name: 'Photographer',
            price: 6000,
            isOptional: true,
          ),
        ],
        isSample: true,
      );

  final String id;
  final String name;
  final String? description;
  final String? category;
  final String? city;
  final String? state;

  /// The event's pin, when the EventFoxer has set one.
  final double? lat;
  final double? lng;
  final String? imageUrl;
  final String? hostName;
  final int? maxAttendees;
  final int currentAttendees;

  /// The API's estimate for the whole package, platform fee included.
  final num estimatedTotal;
  final num platformFeeAmount;
  final List<PackageItem> items;
  final String currency;
  final bool isSample;

  List<PackageItem> get optionalItems =>
      items.where((i) => i.isOptional).toList(growable: false);

  bool get isFull => maxAttendees != null && currentAttendees >= maxAttendees!;

  /// Spots left, or null when the event has no limit.
  int? get spotsLeft =>
      maxAttendees == null ? null : (maxAttendees! - currentAttendees);

  /// Whether the API gave this package a price at all. One without is not
  /// bookable yet.
  bool get isPriced => estimatedTotal > 0;

  /// The package price and fee with [excluded] item ids left out.
  ///
  /// Follows the web app: the API's estimate already carries the fee, so it is
  /// split out, the savings from left-out items come off the package, and the
  /// fee is taken again at the same rate. The server computes the real total
  /// when the booking is made; this is the preview.
  PackageQuote quote(Set<String> excluded) {
    final base = estimatedTotal - platformFeeAmount;
    final rate =
        platformFeeAmount > 0 && base > 0 ? platformFeeAmount / base : null;
    final saved = items
        .where((i) => i.isOptional && excluded.contains(i.id))
        .fold<num>(0, (sum, i) => sum + i.price);
    final package = (platformFeeAmount > 0 ? base : estimatedTotal) - saved;
    final clamped = package < 0 ? 0 : package;
    final fee = rate == null ? 0 : clamped * rate;
    return PackageQuote(package: clamped, fee: fee, total: clamped + fee);
  }

  /// Ids of the left-out items of one kind, as the booking request wants.
  List<String> excludedOf(PackageItemKind kind, Set<String> excluded) => [
        for (final item in items)
          if (item.kind == kind &&
              item.isOptional &&
              excluded.contains(item.id))
            item.id,
      ];

  @override
  List<Object?> get props => [
        id,
        name,
        description,
        category,
        city,
        state,
        lat,
        lng,
        imageUrl,
        hostName,
        maxAttendees,
        currentAttendees,
        estimatedTotal,
        platformFeeAmount,
        items,
        currency,
        isSample,
      ];
}

/// What the event screen hands to the booking flow.
class EventBookingArgs extends Equatable {
  const EventBookingArgs({
    required this.item,
    required this.package,
    this.excluded = const {},
  });

  final CatalogItem item;
  final EventPackage package;
  final Set<String> excluded;

  @override
  List<Object?> get props => [item, package, excluded];
}
