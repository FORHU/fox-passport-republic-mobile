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
    num? minPrice,
    num? maxPrice,
    int? minCapacity,
    DateTime? fromDate,
    DateTime? toDate,
    String? sortBy,
  }) async {
    var page = await _fetch(
      kind,
      query: query.trim(),
      limit: limit,
      city: city,
      lat: lat,
      lng: lng,
      minPrice: minPrice,
      maxPrice: maxPrice,
      minCapacity: minCapacity,
      fromDate: fromDate,
      toDate: toDate,
      sortBy: sortBy,
    );
    // Venues whose service area covers the position. When none do, fall back
    // to the city so "near you" is not empty for no reason.
    if (page.items.isEmpty && lat != null && lng != null && city != null) {
      page = await _fetch(
        kind,
        query: query.trim(),
        limit: limit,
        city: city,
        minPrice: minPrice,
        maxPrice: maxPrice,
        minCapacity: minCapacity,
        fromDate: fromDate,
        toDate: toDate,
        sortBy: sortBy,
      );
    }
    // A narrowed search that finds nothing is an honest answer; only an
    // unfiltered, empty list is padded with samples.
    final narrowed = query.trim().isNotEmpty ||
        city != null ||
        lat != null ||
        minPrice != null ||
        maxPrice != null ||
        minCapacity != null ||
        fromDate != null ||
        toDate != null;
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
    num? minPrice,
    num? maxPrice,
    int? minCapacity,
    DateTime? fromDate,
    DateTime? toDate,
    String? sortBy,
  }) async {
    final byPoint = kind == CatalogKind.venues && lat != null && lng != null;
    final params = <String, dynamic>{
      if (byPoint) ...{'lat': lat, 'lng': lng} else
        'limit': query.isEmpty ? limit : 50,
      if (query.isNotEmpty && kind == CatalogKind.venues) 'search': query,
      if (query.isNotEmpty && kind == CatalogKind.events) 'q': query,
      if (query.isNotEmpty && kind == CatalogKind.foxers) 'q': query,
      if (city != null && !byPoint && query.isEmpty) ...{
        if (kind == CatalogKind.venues || kind == CatalogKind.events)
          'city': city,
        if (kind == CatalogKind.foxers) 'city': city,
      },
      if (city != null &&
          !byPoint &&
          query.isNotEmpty &&
          (kind == CatalogKind.venues || kind == CatalogKind.events))
        'city': city,
      if (minPrice != null &&
          (kind == CatalogKind.venues || kind == CatalogKind.events))
        'minPrice': minPrice,
      if (maxPrice != null &&
          (kind == CatalogKind.venues || kind == CatalogKind.events))
        'maxPrice': maxPrice,
      if (minCapacity != null &&
          (kind == CatalogKind.venues || kind == CatalogKind.events))
        'minCapacity': minCapacity,
      if (fromDate != null && kind == CatalogKind.events)
        'fromDate': fromDate.toUtc().toIso8601String(),
      if (toDate != null && kind == CatalogKind.events)
        'toDate': toDate.toUtc().toIso8601String(),
      if (sortBy != null &&
          (kind == CatalogKind.venues || kind == CatalogKind.events))
        'sortBy': sortBy,
    };

    final path = switch (kind) {
      CatalogKind.venues =>
        byPoint ? ApiEndpoints.venuesNear : ApiEndpoints.venues,
      CatalogKind.events => ApiEndpoints.publicEventsBrowse,
      CatalogKind.foxers => ApiEndpoints.foxers,
      CatalogKind.gear => ApiEndpoints.assetsBrowse,
      CatalogKind.services => ApiEndpoints.servicesBrowse,
    };
    final body = await _api.get(path, query: params);
    final rows = _rows(body);
    final wantedCity = _norm(byPoint ? '' : city ?? '');
    final normalizedQuery = query.toLowerCase();
    final filteredItems = rows
        .map((row) => _item(kind, row))
        .whereType<CatalogItem>()
        .where((item) {
      if (query.isNotEmpty &&
          !item.title.toLowerCase().contains(normalizedQuery) &&
          !(item.city?.toLowerCase().contains(normalizedQuery) ?? false)) {
        return false;
      }
      final itemCity = _norm(item.city ?? '');
      if ((kind == CatalogKind.venues ||
              kind == CatalogKind.events ||
              kind == CatalogKind.foxers) &&
          wantedCity.isNotEmpty &&
          (itemCity.isEmpty ||
              (!itemCity.contains(wantedCity) &&
                  !wantedCity.contains(itemCity)))) {
        return false;
      }
      if ((kind == CatalogKind.venues || kind == CatalogKind.events) &&
          minPrice != null &&
          (item.price == null || item.price! < minPrice)) {
        return false;
      }
      if ((kind == CatalogKind.venues || kind == CatalogKind.events) &&
          maxPrice != null &&
          (item.price == null || item.price! > maxPrice)) {
        return false;
      }
      if ((kind == CatalogKind.venues || kind == CatalogKind.events) &&
          minCapacity != null &&
          (item.capacity == null || item.capacity! < minCapacity)) {
        return false;
      }
      if (kind == CatalogKind.events &&
          fromDate != null &&
          (item.eventStartAt == null ||
              item.eventStartAt!.isBefore(fromDate))) {
        return false;
      }
      if (kind == CatalogKind.events &&
          toDate != null &&
          (item.eventStartAt == null || !item.eventStartAt!.isBefore(toDate))) {
        return false;
      }
      return true;
    }).toList();
    if (sortBy == 'price_asc' || sortBy == 'price_desc') {
      filteredItems.sort((a, b) {
        final comparison = (a.price ?? 0).compareTo(b.price ?? 0);
        return sortBy == 'price_asc' ? comparison : -comparison;
      });
    } else if (sortBy == 'date_asc' || sortBy == 'date_desc') {
      filteredItems.sort((a, b) {
        final comparison = (a.eventStartAt ?? DateTime(9999))
            .compareTo(b.eventStartAt ?? DateTime(9999));
        return sortBy == 'date_asc' ? comparison : -comparison;
      });
    }
    final total = query.isNotEmpty
        ? filteredItems.length
        : body is Map && body['total'] is num
            ? (body['total'] as num).toInt()
            : body is Map && body['pagination'] is Map
                ? ((body['pagination'] as Map)['total'] as num?)?.toInt() ??
                    filteredItems.length
                : filteredItems.length;
    return CatalogPage(items: filteredItems, total: total);
  }

  static String _norm(String s) =>
      s.toLowerCase().replaceAll(RegExp('[^a-z0-9]+'), ' ').trim();

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
    final template = row['template'];
    final templateImages = template is Map ? template['images'] : null;
    if ((image == null || image.isEmpty) &&
        templateImages is List &&
        templateImages.isNotEmpty) {
      final first = templateImages.first;
      image = first is Map ? first['url']?.toString() : null;
    }
    image ??= (row['imageUrl'] ?? row['avatar'] ?? row['image'] ?? row['imgId'])
        ?.toString();

    return CatalogItem(
      id: id,
      kind: kind,
      title: title,
      city: (row['city'] ?? row['targetCity'])?.toString(),
      capacity: ((row['capacity'] ?? row['guestCount']) as num?)?.toInt(),
      price: _num(row['price'] ?? row['estimatedTotal'] ?? row['totalAmount']),
      eventStartAt: DateTime.tryParse('${row['startAt']}')?.toLocal(),
      // Rows without a currency are priced in the platform's own.
      currency: (row['currency'] as String?) ?? kBaseCurrency,
      billingRate: row['billingRate'] as String?,
      imageUrl: image,
      rating: _num(row['rating'] ?? row['averageRating'])?.toDouble(),
      category: ((row['category'] ?? row['eventCategory']) as String?)?.trim(),
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
    this.minPrice,
    this.maxPrice,
    this.minCapacity,
    this.fromDate,
    this.toDate,
    this.sortBy,
  });

  final CatalogKind kind;
  final String query;
  final int limit;

  /// Narrow to this city (venues by search, Foxers by their city filter).
  final String? city;

  /// Narrow venues to those whose service area covers this point.
  final double? lat;
  final double? lng;
  final num? minPrice;
  final num? maxPrice;
  final int? minCapacity;
  final DateTime? fromDate;
  final DateTime? toDate;
  final String? sortBy;

  @override
  List<Object?> get props => [
        kind,
        query,
        limit,
        city,
        lat,
        lng,
        minPrice,
        maxPrice,
        minCapacity,
        fromDate,
        toDate,
        sortBy,
      ];
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
        minPrice: q.minPrice,
        maxPrice: q.maxPrice,
        minCapacity: q.minCapacity,
        fromDate: q.fromDate,
        toDate: q.toDate,
        sortBy: q.sortBy,
      ),
);
