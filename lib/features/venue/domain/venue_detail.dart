import 'package:equatable/equatable.dart';
import 'package:flutter_template/shared/catalog/catalog_item.dart';
import 'package:flutter_template/shared/currency/currency.dart';

/// Everything the venue page shows, from `GET /venues/:id`.
class VenueDetail extends Equatable {
  const VenueDetail({
    required this.id,
    required this.name,
    this.description,
    this.category,
    this.address,
    this.city,
    this.state,
    this.country,
    this.capacity,
    this.recommendedCapacity,
    this.price,
    this.currency = kBaseCurrency,
    this.billingRate,
    this.imageUrls = const [],
    this.hostName,
    this.spaceTypes = const [],
    this.inclusions = const [],
    this.techAv = const [],
    this.staffing = const [],
    this.amenities = const [],
    this.facilities = const [],
    this.policies = const [],
    this.parking,
    this.accessibility,
    this.entrance,
    this.isSample = false,
  });

  factory VenueDetail.fromJson(Map<String, dynamic> json) {
    String? text(String key) {
      final v = json[key];
      return v is String && v.trim().isNotEmpty ? v.trim() : null;
    }

    List<String> strings(String key) {
      final v = json[key];
      if (v is! List) return const [];
      return [
        for (final e in v)
          if (e is String && e.trim().isNotEmpty) e.trim(),
      ];
    }

    num? number(Object? v) => v is num ? v : num.tryParse('$v');

    final images = json['images'];
    final inclusions = json['inclusions'];
    final mayor = json['mayor'];

    return VenueDetail(
      id: '${json['id']}',
      name: text('name') ?? '',
      description: text('description'),
      category: text('category'),
      address: text('address'),
      city: text('city'),
      state: text('state'),
      country: text('country'),
      capacity: number(json['capacity'])?.toInt(),
      recommendedCapacity: number(json['recommendedCapacity'])?.toInt(),
      price: number(json['price']),
      billingRate: text('billingRate'),
      imageUrls: [
        if (images is List)
          for (final i in images)
            if (i is Map && i['url'] is String) i['url'] as String,
      ],
      hostName: mayor is Map ? mayor['name']?.toString() : null,
      spaceTypes: strings('spaceType'),
      inclusions: [
        if (inclusions is List)
          for (final i in inclusions)
            if (i is Map && i['name'] is String) i['name'] as String,
      ],
      techAv: strings('techAv'),
      staffing: strings('staffing'),
      amenities: strings('amenities'),
      facilities: strings('facilities'),
      policies: strings('policies'),
      parking: text('parkingInformation'),
      accessibility: text('accessibilityInformation'),
      entrance: text('entranceInstructions'),
    );
  }

  /// A sample row has no venue behind it; show what it knows.
  factory VenueDetail.sample(CatalogItem item) => VenueDetail(
        id: item.id,
        name: item.title,
        description: 'A sample venue, shown while there are no real ones.',
        category: item.tags.isEmpty ? item.category : item.tags.first,
        city: item.city,
        capacity: item.capacity,
        price: item.price,
        currency: item.currency,
        billingRate: item.billingRate,
        imageUrls: [if (item.imageUrl != null) item.imageUrl!],
        techAv: const ['PA sound system', 'LED screen'],
        staffing: const ['Security guard'],
        isSample: true,
      );

  final String id;
  final String name;
  final String? description;
  final String? category;
  final String? address;
  final String? city;
  final String? state;
  final String? country;
  final int? capacity;
  final int? recommendedCapacity;
  final num? price;
  final String currency;
  final String? billingRate;
  final List<String> imageUrls;
  final String? hostName;
  final List<String> spaceTypes;
  final List<String> inclusions;
  final List<String> techAv;
  final List<String> staffing;
  final List<String> amenities;
  final List<String> facilities;
  final List<String> policies;
  final String? parking;
  final String? accessibility;
  final String? entrance;
  final bool isSample;

  /// "Baguio, Benguet" from whatever parts the venue has.
  String get place =>
      [city, state].whereType<String>().where((p) => p.isNotEmpty).join(', ');

  /// Whether there is anything to show under "Good to know".
  bool get hasGoodToKnow =>
      parking != null || accessibility != null || entrance != null;

  @override
  List<Object?> get props => [
        id,
        name,
        description,
        category,
        address,
        city,
        state,
        country,
        capacity,
        recommendedCapacity,
        price,
        currency,
        billingRate,
        imageUrls,
        hostName,
        spaceTypes,
        inclusions,
        techAv,
        staffing,
        amenities,
        facilities,
        policies,
        parking,
        accessibility,
        entrance,
        isSample,
      ];
}
