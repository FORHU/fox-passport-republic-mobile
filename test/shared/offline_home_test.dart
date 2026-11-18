import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_template/core/errors/exceptions.dart';
import 'package:flutter_template/core/services/api_service.dart';
import 'package:flutter_template/core/services/storage_service.dart';
import 'package:flutter_template/shared/catalog/catalog_item.dart';
import 'package:flutter_template/shared/catalog/catalog_repository.dart';
import 'package:flutter_template/shared/offline/response_cache.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _MockApi extends Mock implements ApiService {}

class _MockSecure extends Mock implements FlutterSecureStorage {}

Map<String, dynamic> _events() => {
      'data': [
        {
          'id': 'e1',
          'name': 'Garden wedding',
          'city': 'Davao City',
          'price': 5000,
        },
      ],
      'total': 1,
    };

void main() {
  late _MockApi api;
  late StorageService storage;
  late ResponseCache cache;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final secure = _MockSecure();
    when(
      () => secure.delete(key: any(named: 'key')),
    ).thenAnswer((_) async {});
    storage = StorageService(prefs, secure: secure);
    cache = ResponseCache(storage);
    api = _MockApi();
  });

  void answers(Object? body) => when(
        () => api.get(any(), query: any(named: 'query')),
      ).thenAnswer((_) async => body);

  void fails(Object error) => when(
        () => api.get(any(), query: any(named: 'query')),
      ).thenThrow(error);

  group('ResponseCache', () {
    test('the key does not depend on the order of the parameters', () {
      expect(
        ResponseCache.keyFor('/x', {'a': 1, 'b': 2}),
        ResponseCache.keyFor('/x', {'b': 2, 'a': 1}),
      );
      expect(
        ResponseCache.keyFor('/x', {'city': 'A'}),
        isNot(ResponseCache.keyFor('/x', {'city': 'B'})),
      );
    });

    test('a saved answer reads back with when it was saved', () async {
      final at = DateTime(2026, 11, 18, 9);
      await cache.save('k', {'n': 1}, now: at);

      final saved = cache.read('k', now: at.add(const Duration(hours: 1)));

      expect(saved!.body, {'n': 1});
      expect(saved.savedAt, at);
    });

    test('an answer older than three days is not shown', () async {
      final at = DateTime(2026, 11, 18);
      await cache.save('k', {'n': 1}, now: at);

      expect(cache.read('k', now: at.add(const Duration(days: 4))), isNull);
    });

    test('nothing saved, or something unreadable, reads as nothing', () {
      expect(cache.read('missing'), isNull);
    });

    test('a fresh answer is saved and has no saved-at', () async {
      answers({'n': 2});

      final got = await ResponseCache.get(api, cache, '/x');

      expect(got.body, {'n': 2});
      expect(got.savedAt, isNull);
      expect(cache.read(ResponseCache.keyFor('/x', null))!.body, {'n': 2});
    });

    test('with no connection the saved answer is returned, dated', () async {
      answers({'n': 2});
      await ResponseCache.get(api, cache, '/x');
      fails(const NetworkException());

      final got = await ResponseCache.get(api, cache, '/x');

      expect(got.body, {'n': 2});
      expect(got.savedAt, isNotNull);
    });

    test('a server failure also falls back to the saved answer', () async {
      answers({'n': 2});
      await ResponseCache.get(api, cache, '/x');
      fails(const ServerException('down', statusCode: 503));

      final got = await ResponseCache.get(api, cache, '/x');

      expect(got.savedAt, isNotNull);
    });

    test('being signed out is not hidden behind the saved answer', () async {
      answers({'n': 2});
      await ResponseCache.get(api, cache, '/x');
      fails(const UnauthorizedException('signed out', statusCode: 401));

      expect(
        ResponseCache.get(api, cache, '/x'),
        throwsA(isA<UnauthorizedException>()),
      );
    });

    test('with no connection and nothing saved the failure is raised', () {
      fails(const NetworkException());

      expect(
        ResponseCache.get(api, cache, '/x'),
        throwsA(isA<NetworkException>()),
      );
    });

    test('signing out removes the saved answers', () async {
      await cache.save('${ResponseCache.keyPrefix}one', {'n': 1});

      await storage.clearSession();

      expect(cache.read('${ResponseCache.keyPrefix}one'), isNull);
    });
  });

  group('Home catalog rows', () {
    test('a plain browse with no connection shows the saved page', () async {
      final repo = CatalogRepository(api, cache);
      answers(_events());
      final fresh = await repo.fetch(CatalogKind.events, limit: 6);
      expect(fresh.savedAt, isNull);
      expect(fresh.items, hasLength(1));

      fails(const NetworkException());
      final offline = await repo.fetch(CatalogKind.events, limit: 6);

      expect(offline.items.map((i) => i.id), ['e1']);
      expect(offline.savedAt, isNotNull);
    });

    test('a search is not saved', () async {
      final repo = CatalogRepository(api, cache);
      answers(_events());
      await repo.fetch(CatalogKind.events, query: 'wedding');

      fails(const NetworkException());

      expect(
        repo.fetch(CatalogKind.events, query: 'wedding'),
        throwsA(isA<NetworkException>()),
      );
    });
  });
}
