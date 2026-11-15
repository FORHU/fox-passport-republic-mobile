import 'package:flutter_template/core/config/app_config.dart';
import 'package:flutter_template/core/constants/api_endpoints.dart';
import 'package:flutter_template/core/services/api_service.dart';
import 'package:flutter_template/features/favorites/data/favorites_repository.dart';
import 'package:flutter_template/shared/catalog/catalog_item.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockApiService extends Mock implements ApiService {}

void main() {
  late _MockApiService api;
  late FavoritesRepository repository;

  setUp(() {
    AppConfig.instance = const AppConfig.dev();
    api = _MockApiService();
    repository = FavoritesRepository(api, 'user-1');
  });

  test('loads favorited target IDs from the user favorites endpoint', () async {
    when(
      () => api.get(ApiEndpoints.favoritesByUser('user-1')),
    ).thenAnswer(
      (_) async => {
        'success': true,
        'data': [
          {'targetId': 'venue-1', 'type': 'venue'},
        ],
      },
    );

    expect(await repository.loadIds(), {'venue-1'});
  });

  test('uses API event and venue favorite mutations', () async {
    when(
      () => api.post(ApiEndpoints.favoriteAdd, any()),
    ).thenAnswer((_) async => {'success': true});
    when(
      () => api.delete(ApiEndpoints.favoriteRemoveByListing, any()),
    ).thenAnswer((_) async => {'success': true});

    const venue = CatalogItem(
      id: 'venue-1',
      kind: CatalogKind.venues,
      title: 'Sky Hall',
    );
    const event = CatalogItem(
      id: 'event-1',
      kind: CatalogKind.events,
      title: 'Debut Manila',
    );

    await repository.add(venue);
    await repository.remove(event);

    verify(
      () => api.post(
        ApiEndpoints.favoriteAdd,
        {'targetId': 'venue-1', 'type': 'venue'},
      ),
    ).called(1);
    verify(
      () => api.delete(
        ApiEndpoints.favoriteRemoveByListing,
        {'targetId': 'event-1', 'type': 'event'},
      ),
    ).called(1);
  });
}
