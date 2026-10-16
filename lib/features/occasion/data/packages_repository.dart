import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_template/core/constants/api_endpoints.dart';
import 'package:flutter_template/features/auth/presentation/controllers/auth_controller.dart';
import 'package:flutter_template/shared/catalog/catalog_item.dart';
import 'package:flutter_template/shared/catalog/catalog_repository.dart';

/// What to look up: the occasion's API name and, optionally, a city.
typedef PackageQuery = ({String category, String? city});

/// Ready-made packages for an occasion: published event templates of that
/// category, in the city when one is chosen. Public, so it works signed out.
// The family type is long and adds nothing here, so it is left inferred.
// ignore: specify_nonobvious_property_types
final packagesProvider = FutureProvider.autoDispose
    .family<List<CatalogItem>, PackageQuery>((ref, query) async {
  final body = await ref.watch(apiServiceProvider).get(
    ApiEndpoints.eventsBrowse,
    query: {
      'category': query.category,
      if (query.city != null && query.city!.isNotEmpty) 'city': query.city,
      'limit': 12,
    },
  );
  final data = body is Map ? body['data'] : null;
  if (data is! List) return const [];
  return [
    for (final row in data)
      if (row is Map)
        if (CatalogRepository.parse(
          CatalogKind.events,
          row.cast<String, dynamic>(),
        )
            case final item?)
          item,
  ];
});
