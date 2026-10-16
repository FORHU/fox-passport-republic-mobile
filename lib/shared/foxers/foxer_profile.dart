import 'package:equatable/equatable.dart';
import 'package:flutter_template/shared/catalog/catalog_item.dart';

/// A Foxer in full, from `GET /users/foxers/:id`: who they are, how they are
/// rated, and what they offer.
class FoxerProfile extends Equatable {
  const FoxerProfile({
    required this.id,
    required this.name,
    this.imageUrl,
    this.roles = const [],
    this.city,
    this.state,
    this.verified = false,
    this.rating,
    this.reviewCount = 0,
    this.offers = const [],
    this.isSample = false,
  });

  factory FoxerProfile.fromJson(Map<String, dynamic> json) {
    String? text(String key) {
      final v = json[key];
      return v is String && v.trim().isNotEmpty ? v.trim() : null;
    }

    num? number(Object? v) => v is num ? v : num.tryParse('$v');

    final id = '${json['id']}';
    final name = text('name') ?? '';
    final city = text('city');

    String? firstImage(Object? images) {
      if (images is! List || images.isEmpty) return null;
      final first = images.first;
      return first is Map ? first['url']?.toString() : first?.toString();
    }

    List<CatalogItem> rows(
      String key,
      CatalogKind kind, {
      bool hasCapacity = false,
    }) {
      final list = json[key];
      if (list is! List) return const [];
      return [
        for (final row in list)
          if (row is Map && row['id'] != null && row['name'] != null)
            CatalogItem(
              id: '${row['id']}',
              kind: kind,
              title: '${row['name']}',
              city: (row['city'] ?? row['targetCity'] ?? city)?.toString(),
              capacity: hasCapacity ? number(row['capacity'])?.toInt() : null,
              price: number(row['price']),
              billingRate: row['billingRate']?.toString(),
              imageUrl: firstImage(row['images']),
              category: (row['category'] as String?)?.trim(),
              host: name,
            ),
      ];
    }

    final roleType = json['roleType'];
    return FoxerProfile(
      id: id,
      name: name,
      imageUrl: text('imgId'),
      roles:
          roleType is List ? roleType.whereType<String>().toList() : const [],
      city: city,
      state: text('state'),
      verified: json['identityVerifiedAt'] != null,
      rating: number(json['avgRating'])?.toDouble(),
      reviewCount: number(json['reviewCount'])?.toInt() ?? 0,
      offers: [
        ...rows('eventTemplates', CatalogKind.events),
        ...rows('venues', CatalogKind.venues, hasCapacity: true),
        ...rows('assets', CatalogKind.gear),
        ...rows('services', CatalogKind.services),
      ],
    );
  }

  /// A sample row has no Foxer behind it; show what it knows.
  factory FoxerProfile.sample(CatalogItem item) => FoxerProfile(
        id: item.id,
        name: item.title,
        roles: item.roles,
        city: item.city,
        verified: item.verified,
        rating: item.rating,
        reviewCount: item.rating == null ? 0 : 12,
        offers: const [
          CatalogItem(
            id: 'sample-offer-1',
            kind: CatalogKind.services,
            title: 'Full event coordination',
            price: 15000,
            billingRate: 'daily',
            isSample: true,
          ),
          CatalogItem(
            id: 'sample-offer-2',
            kind: CatalogKind.services,
            title: 'On-the-day host',
            price: 6000,
            billingRate: 'daily',
            isSample: true,
          ),
        ],
        isSample: true,
      );

  final String id;
  final String name;
  final String? imageUrl;
  final List<String> roles;
  final String? city;
  final String? state;
  final bool verified;
  final double? rating;
  final int reviewCount;

  /// Event packages, venues, gear and services, as catalog rows.
  final List<CatalogItem> offers;
  final bool isSample;

  /// "Davao City, Davao del Sur" from whatever parts there are.
  String get place =>
      [city, state].whereType<String>().where((p) => p.isNotEmpty).join(', ');

  @override
  List<Object?> get props => [
        id,
        name,
        imageUrl,
        roles,
        city,
        state,
        verified,
        rating,
        reviewCount,
        offers,
        isSample,
      ];
}

/// What a citizen asks a Foxer for in a Match request.
class MatchRequest extends Equatable {
  const MatchRequest({
    required this.foxerId,
    required this.date,
    required this.guests,
    this.style = '',
    this.message = '',
  });

  final String foxerId;

  /// The day wanted, as a calendar date.
  final DateTime date;
  final int guests;

  /// The offer chosen, or empty for "my own idea".
  final String style;
  final String message;

  @override
  List<Object?> get props => [foxerId, date, guests, style, message];
}
