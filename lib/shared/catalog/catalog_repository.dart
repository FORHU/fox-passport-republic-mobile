import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_template/core/config/app_config.dart';
import 'package:flutter_template/core/constants/api_endpoints.dart';
import 'package:flutter_template/core/services/api_service.dart';
import 'package:flutter_template/features/auth/presentation/controllers/auth_controller.dart';
import 'package:flutter_template/shared/catalog/catalog_item.dart';
import 'package:flutter_template/shared/currency/currency.dart';

/// Reads the public browse endpoints and returns one shape for all of them.
///
/// Falls back to a short list of sample rows, flagged `isSample`, when the API
/// has nothing to list or can't be reached, so a screen is never blank while
/// the backend is still being filled in.
class CatalogRepository {
  CatalogRepository(this._api);

  final ApiService _api;

  Future<CatalogPage> fetch(
    CatalogKind kind, {
    String query = '',
    int limit = 20,
    String? city,
    double? lat,
    double? lng,
  }) async {
    var page = await _fetch(
      kind,
      query: query.trim(),
      limit: limit,
      city: city,
      lat: lat,
      lng: lng,
    );
    // Venues whose service area covers the position. When none do, fall back
    // to the city so "near you" is not empty for no reason.
    if (page.items.isEmpty && lat != null && lng != null && city != null) {
      page = await _fetch(
        kind,
        query: query.trim(),
        limit: limit,
        city: city,
      );
    }
    // A narrowed search that finds nothing is an honest answer; only an
    // unfiltered, empty list is padded with samples.
    final narrowed = query.trim().isNotEmpty || city != null || lat != null;
    if (page.items.isNotEmpty || narrowed || !AppConfig.instance.useMock) {
      return page;
    }
    final sample = sampleItems(kind);
    return CatalogPage(items: sample, total: sample.length);
  }

  Future<CatalogPage> _fetch(
    CatalogKind kind, {
    required String query,
    required int limit,
    String? city,
    double? lat,
    double? lng,
  }) async {
    final byPoint = kind == CatalogKind.venues && lat != null && lng != null;
    final params = <String, dynamic>{
      if (byPoint) ...{'lat': lat, 'lng': lng} else
        'limit': query.isEmpty ? limit : 50,
      if (query.isNotEmpty && kind == CatalogKind.venues) 'search': query,
      if (query.isNotEmpty &&
          (kind == CatalogKind.events || kind == CatalogKind.foxers))
        'q': query,
      // The venue list has no city filter, but its search matches the city;
      // Foxers filter on a city directly.
      if (city != null && !byPoint && query.isEmpty) ...{
        if (kind == CatalogKind.venues) 'search': city,
        if (kind == CatalogKind.foxers) 'city': city,
      },
    };

    final path = switch (kind) {
      CatalogKind.venues =>
        byPoint ? ApiEndpoints.venuesNear : ApiEndpoints.venues,
      CatalogKind.events => ApiEndpoints.eventsBrowse,
      CatalogKind.foxers => ApiEndpoints.foxers,
      CatalogKind.gear => ApiEndpoints.assetsBrowse,
      CatalogKind.services => ApiEndpoints.servicesBrowse,
    };
    final body = await _api.get(path, query: params);
    final rows = _rows(body);
    final items =
        rows.map((row) => _item(kind, row)).whereType<CatalogItem>().toList();
    final filteredItems = query.isEmpty
        ? items
        : items
            .where(
              (item) =>
                  item.title.toLowerCase().contains(query.toLowerCase()) ||
                  (item.city?.toLowerCase().contains(query.toLowerCase()) ??
                      false),
            )
            .toList();
    final total = query.isNotEmpty
        ? filteredItems.length
        : body is Map && body['total'] is num
            ? (body['total'] as num).toInt()
            : body is Map && body['pagination'] is Map
                ? ((body['pagination'] as Map)['total'] as num?)?.toInt() ??
                    items.length
                : items.length;
    return CatalogPage(items: filteredItems, total: total);
  }

  /// The list inside whichever envelope an endpoint uses.
  static List<Map<String, dynamic>> _rows(Object? body) {
    var list = body;
    if (body is Map) {
      for (final key in const [
        'venues',
        'data',
        'items',
        'assets',
        'users',
        'foxers',
      ]) {
        if (body[key] is List) {
          list = body[key];
          break;
        }
      }
    }
    if (list is! List) return const [];
    return [
      for (final row in list)
        if (row is Map) row.cast<String, dynamic>(),
    ];
  }

  static CatalogItem? _item(CatalogKind kind, Map<String, dynamic> row) {
    final id = row['id']?.toString();
    final title = (row['name'] ?? row['title'])?.toString();
    if (id == null || title == null || title.isEmpty) return null;

    String? image;
    final images = row['images'];
    if (images is List && images.isNotEmpty) {
      final first = images.first;
      image = first is Map ? first['url']?.toString() : first?.toString();
    }
    image ??= (row['imageUrl'] ?? row['avatar'] ?? row['image'] ?? row['imgId'])
        ?.toString();

    return CatalogItem(
      id: id,
      kind: kind,
      title: title,
      city: (row['city'] ?? row['targetCity'])?.toString(),
      capacity: (row['capacity'] as num?)?.toInt(),
      price: _num(row['price'] ?? row['estimatedTotal']),
      // Rows without a currency are priced in the platform's own.
      currency: (row['currency'] as String?) ?? kBaseCurrency,
      billingRate: row['billingRate'] as String?,
      imageUrl: image,
      rating: _num(row['rating'] ?? row['averageRating'])?.toDouble(),
      category: (row['category'] as String?)?.trim(),
      host: row['owner'] is Map
          ? (row['owner'] as Map)['name']?.toString()
          : null,
      tags: _strings(row['spaceType']),
      roles: _strings(row['roleType']),
      verified: row['identityVerifiedAt'] != null,
      online: row['isOnline'] == true,
    );
  }

  static List<String> _strings(Object? value) =>
      value is List ? value.whereType<String>().toList() : const [];

  /// Prisma decimals arrive as strings.
  static num? _num(Object? value) {
    if (value is num) return value;
    if (value is String) return num.tryParse(value);
    return null;
  }

  /// Rows shown when there is nothing real to list.
  static List<CatalogItem> sampleItems(CatalogKind kind) => switch (kind) {
        CatalogKind.venues => const [
            CatalogItem(
              id: 'sample-venue-1',
              kind: CatalogKind.venues,
              title: 'Sky Hall',
              city: 'Davao City',
              capacity: 200,
              price: 25000,
              billingRate: 'daily',
              rating: 5,
              tags: ['indoor'],
              isSample: true,
            ),
            CatalogItem(
              id: 'sample-venue-2',
              kind: CatalogKind.venues,
              title: 'averie',
              city: 'Baguio',
              capacity: 150,
              price: 15000,
              billingRate: 'daily',
              isSample: true,
            ),
          ],
        CatalogKind.events => const [
            CatalogItem(
              id: 'sample-event-1',
              kind: CatalogKind.events,
              title: 'Rooftop Launch Night',
              city: 'Manila',
              isSample: true,
            ),
            CatalogItem(
              id: 'sample-event-2',
              kind: CatalogKind.events,
              title: 'Sunset Beach Party',
              city: 'Boracay',
              isSample: true,
            ),
          ],
        CatalogKind.foxers => const [
            CatalogItem(
              id: 'sample-foxer-1',
              kind: CatalogKind.foxers,
              title: 'Rico Rival',
              city: 'Davao City',
              rating: 5,
              roles: ['eventFoxer'],
              verified: true,
              online: true,
              isSample: true,
            ),
          ],
        CatalogKind.gear => const [
            CatalogItem(
              id: 'sample-gear-1',
              kind: CatalogKind.gear,
              title: 'Sound system',
              city: 'Davao City',
              price: 3500,
              billingRate: 'daily',
              isSample: true,
            ),
          ],
        CatalogKind.services => const [
            CatalogItem(
              id: 'sample-service-1',
              kind: CatalogKind.services,
              title: 'Catering service',
              city: 'Manila',
              price: 1200,
              billingRate: 'one_time',
              isSample: true,
            ),
          ],
      };
}

final catalogRepositoryProvider = Provider<CatalogRepository>(
  (ref) => CatalogRepository(ref.watch(apiServiceProvider)),
);

/// What a results list asks for. Equatable so the provider family caches it.
class CatalogQuery extends Equatable {
  const CatalogQuery(
    this.kind, {
    this.query = '',
    this.limit = 20,
    this.city,
    this.lat,
    this.lng,
  });

  final CatalogKind kind;
  final String query;
  final int limit;

  /// Narrow to this city (venues by search, Foxers by their city filter).
  final String? city;

  /// Narrow venues to those whose service area covers this point.
  final double? lat;
  final double? lng;

  @override
  List<Object?> get props => [kind, query, limit, city, lat, lng];
}

// The family type is long and adds nothing here, so it is left inferred.
// ignore: specify_nonobvious_property_types
final catalogProvider =
    FutureProvider.autoDispose.family<CatalogPage, CatalogQuery>(
  (ref, q) => ref.watch(catalogRepositoryProvider).fetch(
        q.kind,
        query: q.query,
        limit: q.limit,
        city: q.city,
        lat: q.lat,
        lng: q.lng,
      ),
);
