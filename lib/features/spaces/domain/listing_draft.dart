import 'package:equatable/equatable.dart';
import 'package:flutter_template/features/spaces/domain/provider_kind.dart';
import 'package:flutter_template/features/spaces/domain/venue_draft.dart';
import 'package:flutter_template/shared/currency/currency.dart';

/// The categories a provider can list under, as the API names them. The
/// legacy `entertainment` is left out: new listings use the finer ones.
const serviceCategories = <String>[
  'design',
  'catering',
  'service_staff',
  'photography',
  'videography',
  'dj',
  'live_band',
  'mc',
  'other',
];

/// The service categories only a Performer Foxer may list under; the rest
/// need a Service Foxer.
const performerCategories = <String>[
  'photography',
  'videography',
  'dj',
  'live_band',
  'mc',
];

const gearCategories = <String>[
  'furnitures',
  'sound_system',
  'decorations',
  'equipment',
  'other',
];

const gearConditions = <String>['new', 'good', 'fair', 'refurbished'];

const billingRates = <String>[
  'hourly',
  'daily',
  'weekly',
  'monthly',
  'yearly',
  'one_time',
];

/// What a provider fills in while adding or editing a service or a piece of
/// gear. The two share the form: gear adds a quantity and a condition,
/// a service adds whether they will travel.
class ListingDraft extends Equatable {
  const ListingDraft({
    this.category,
    this.name = '',
    this.description = '',
    this.price,
    this.currency = kBaseCurrency,
    this.billingRate = 'hourly',
    this.quantity = 1,
    this.condition = 'good',
    this.willingToTravel = false,
    this.country = '',
    this.state = '',
    this.city = '',
    this.lat,
    this.lng,
    this.photos = const [],
  });

  /// Reads a service or an asset as the API returns it, to edit.
  factory ListingDraft.fromJson(Map<String, dynamic> json) {
    String text(String key) {
      final v = json[key];
      return v is String ? v : '';
    }

    num? number(String key) {
      final v = json[key];
      return v is num ? v : num.tryParse('$v');
    }

    final images = json['images'];
    return ListingDraft(
      category: json['category'] is String ? json['category'] as String : null,
      name: text('name'),
      description: text('description'),
      price: number('price'),
      currency: text('currency').isEmpty ? kBaseCurrency : text('currency'),
      billingRate: text('billingRate').isEmpty ? 'hourly' : text('billingRate'),
      quantity: number('quantity')?.toInt() ?? 1,
      condition: text('condition').isEmpty ? 'good' : text('condition'),
      willingToTravel: json['isWillingToTravel'] == true,
      country: text('country'),
      state: text('state'),
      city: text('city'),
      lat: number('lat')?.toDouble(),
      lng: number('lng')?.toDouble(),
      photos: [
        if (images is List)
          for (final i in images)
            if (i is Map && i['id'] is String && i['url'] is String)
              VenuePhoto(fileId: i['id'] as String, url: i['url'] as String),
      ],
    );
  }

  final String? category;
  final String name;
  final String description;
  final num? price;
  final String currency;
  final String billingRate;

  /// Gear only.
  final int quantity;
  final String condition;

  /// Services only.
  final bool willingToTravel;

  final String country;
  final String state;
  final String city;
  final double? lat;
  final double? lng;
  final List<VenuePhoto> photos;

  /// Whether it has what the API asks for, so it can be saved or sent for
  /// review. A service needs its town; gear's place is optional.
  bool isComplete(ProviderKind kind) =>
      category != null &&
      name.trim().isNotEmpty &&
      description.trim().isNotEmpty &&
      price != null &&
      price! >= 0 &&
      photos.isNotEmpty &&
      (kind.isGear || (city.trim().isNotEmpty && country.trim().isNotEmpty));

  ListingDraft copyWith({
    String? category,
    String? name,
    String? description,
    num? price,
    bool clearPrice = false,
    String? currency,
    String? billingRate,
    int? quantity,
    String? condition,
    bool? willingToTravel,
    String? country,
    String? state,
    String? city,
    double? lat,
    double? lng,
    List<VenuePhoto>? photos,
  }) =>
      ListingDraft(
        category: category ?? this.category,
        name: name ?? this.name,
        description: description ?? this.description,
        price: clearPrice ? null : price ?? this.price,
        currency: currency ?? this.currency,
        billingRate: billingRate ?? this.billingRate,
        quantity: quantity ?? this.quantity,
        condition: condition ?? this.condition,
        willingToTravel: willingToTravel ?? this.willingToTravel,
        country: country ?? this.country,
        state: state ?? this.state,
        city: city ?? this.city,
        lat: lat ?? this.lat,
        lng: lng ?? this.lng,
        photos: photos ?? this.photos,
      );

  /// The body of the create or update call. [status] is left out for a live
  /// listing, so it stays live. Photos go only when creating: the API's
  /// update does not take them.
  Map<String, dynamic> toJson(
    ProviderKind kind, {
    String? status,
    bool withPhotos = true,
  }) =>
      {
        'category': category,
        'name': name.trim(),
        'description': description.trim(),
        'price': price ?? 0,
        'currency': currency,
        'billingRate': billingRate,
        if (city.trim().isNotEmpty) 'city': city.trim(),
        if (state.trim().isNotEmpty) 'state': state.trim(),
        if (country.trim().isNotEmpty) 'country': country.trim(),
        if (lat != null) 'lat': lat,
        if (lng != null) 'lng': lng,
        if (kind.isGear) ...{
          'quantity': quantity,
          'condition': condition,
        } else
          'isWillingToTravel': willingToTravel,
        if (withPhotos) 'imgIds': [for (final p in photos) p.fileId],
        if (status != null) 'status': status,
      };

  @override
  List<Object?> get props => [
        category,
        name,
        description,
        price,
        currency,
        billingRate,
        quantity,
        condition,
        willingToTravel,
        country,
        state,
        city,
        lat,
        lng,
        photos.map((p) => p.fileId).toList(),
      ];
}
