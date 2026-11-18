import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_template/core/errors/exceptions.dart';
import 'package:flutter_template/core/services/api_service.dart';
import 'package:flutter_template/l10n/generated/app_localizations.dart';
import 'package:flutter_template/routes/route_names.dart';
import 'package:flutter_template/shared/catalog/catalog_item.dart';
import 'package:flutter_template/shared/catalog/catalog_repository.dart';
import 'package:flutter_template/shared/catalog/open_by_id_page.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';

class _MockApi extends Mock implements ApiService {}

const _venue = CatalogItem(
  id: 'v1',
  kind: CatalogKind.venues,
  title: 'Sky Hall',
);

Future<void> _pump(
  WidgetTester tester,
  Future<CatalogItem?> Function() load,
) async {
  final router = GoRouter(
    routes: [
      GoRoute(
        path: '/',
        builder: (_, __) => OpenByIdPage(
          kind: CatalogKind.venues,
          id: 'v1',
          builder: (item) => Text('page for ${item.title}'),
        ),
      ),
      GoRoute(
        path: RouteNames.search,
        builder: (_, __) => const Text('search screen'),
      ),
    ],
  );
  await tester.pumpWidget(
    ProviderScope(
      // Riverpod retries a failed read on its own; the error state is what is
      // under test here.
      retry: (_, __) => null,
      overrides: [
        catalogItemByIdProvider.overrideWith((ref, r) => load()),
      ],
      child: MaterialApp.router(
        routerConfig: router,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
      ),
    ),
  );
}

void main() {
  group('OpenByIdPage', () {
    testWidgets('shows the page once the row has loaded', (tester) async {
      await _pump(tester, () async => _venue);
      await tester.pumpAndSettle();

      expect(find.text('page for Sky Hall'), findsOneWidget);
    });

    testWidgets('shows a spinner while it loads', (tester) async {
      final never = Completer<CatalogItem?>();
      await _pump(tester, () => never.future);
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('says so when the item is not there, and leads to Search',
        (tester) async {
      await _pump(tester, () async => null);
      await tester.pumpAndSettle();

      expect(find.text('That page is not available any more.'), findsOneWidget);
      await tester.tap(find.text('Go to Search'));
      await tester.pumpAndSettle();
      expect(find.text('search screen'), findsOneWidget);
    });

    testWidgets('offers a retry when it cannot be read', (tester) async {
      var calls = 0;
      await _pump(tester, () async {
        calls++;
        if (calls == 1) throw const NetworkException();
        return _venue;
      });
      await tester.pumpAndSettle();
      expect(find.text('Try again'), findsOneWidget);

      await tester.tap(find.text('Try again'));
      await tester.pumpAndSettle();

      expect(find.text('page for Sky Hall'), findsOneWidget);
    });
  });

  group('CatalogRepository.byId', () {
    late _MockApi api;
    late CatalogRepository repo;

    setUp(() {
      api = _MockApi();
      repo = CatalogRepository(api);
    });

    test('reads a venue by id and encodes the id from the link', () async {
      when(() => api.get(any())).thenAnswer(
        (_) async => {
          'venue': {'id': 'v 1', 'name': 'Sky Hall', 'city': 'Davao City'},
        },
      );

      final item = await repo.byId(CatalogKind.venues, 'v 1');

      expect(item!.title, 'Sky Hall');
      expect(
        verify(() => api.get(captureAny())).captured.single,
        '/venues/v%201',
      );
    });

    test('an answer with no name is not an item', () async {
      when(() => api.get(any())).thenAnswer(
        (_) async => {
          'data': {'id': 'x'},
        },
      );

      expect(await repo.byId(CatalogKind.foxers, 'x'), isNull);
    });

    test('gear and services have no page by id', () {
      expect(
        () => repo.byId(CatalogKind.gear, 'g1'),
        throwsA(isA<ArgumentError>()),
      );
    });
  });

  test('the id routes sit next to the ones that take the row', () {
    expect(RouteNames.venueById('a b'), '/venue/a%20b');
    expect(RouteNames.eventById('e1'), '/event/e1');
    expect(RouteNames.foxerById('f1'), '/foxer/f1');
  });
}
