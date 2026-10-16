import 'package:equatable/equatable.dart';
import 'package:flutter_template/shared/currency/currency.dart';

/// What Search lists, and what Home's "Picked for you" draws from.
enum CatalogKind {
  events,
  venues,
  foxers,
  gear,
  services;

  /// Reads the `kind` query parameter of a deep link; unknown values fall back
  /// to venues.
  static CatalogKind fromParam(String? value) => CatalogKind.values.firstWhere(
        (k) => k.name == value,
        orElse: () => CatalogKind.venues,
      );
}

/// One row in a results list: a venue, event, Foxer or piece of gear.
///
/// Kept as raw fields (a price and a currency code, not a formatted string) so
/// the screen decides how to word it for the user's locale.
class CatalogItem extends Equatable {
  const CatalogItem({
    required this.id,
    required this.kind,
    required this.title,
    this.city,
    this.capacity,
    this.price,
    this.currency = kBaseCurrency,
    this.billingRate,
    this.imageUrl,
    this.rating,
    this.category,
    this.host,
    this.tags = const [],
    this.roles = const [],
    this.verified = false,
    this.online = false,
    this.isSample = false,
  });

  final String id;
  final CatalogKind kind;
  final String title;
  final String? city;

  /// Guests a venue holds.
  final int? capacity;
  final num? price;

  /// ISO 4217 code the [price] is in.
  final String currency;

  /// `hourly` | `daily` | `weekly` | `monthly` | `yearly` | `one_time`.
  final String? billingRate;
  final String? imageUrl;
  final double? rating;

  /// What kind of event or space it is: `birthday`, `wedding`, `indoor`...
  final String? category;

  /// Who put an event together (its EventFoxer).
  final String? host;

  /// Venue space types, such as `indoor` or `outdoor`.
  final List<String> tags;

  /// A Foxer's role types, such as `eventFoxer`.
  final List<String> roles;

  /// A Foxer whose identity has been verified.
  final bool verified;
  final bool online;

  /// Placeholder content shown while the API has nothing to list.
  final bool isSample;

  @override
  List<Object?> get props => [
        id,
        kind,
        title,
        city,
        capacity,
        price,
        currency,
        billingRate,
        imageUrl,
        rating,
        category,
        host,
        tags,
        roles,
        verified,
        online,
        isSample,
      ];
}

/// A page of results and how many there are in total.
class CatalogPage extends Equatable {
  const CatalogPage({required this.items, required this.total});

  final List<CatalogItem> items;
  final int total;

  bool get isSample => items.isNotEmpty && items.every((i) => i.isSample);

  @override
  List<Object?> get props => [items, total];
}
