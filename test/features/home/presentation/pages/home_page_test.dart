import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_template/core/services/storage_service.dart';
import 'package:flutter_template/features/home/data/last_occasion.dart';
import 'package:flutter_template/features/home/presentation/pages/home_page.dart';
import 'package:flutter_template/features/home/presentation/widgets/occasion_showcase.dart';
import 'package:flutter_template/features/notifications/data/notifications_repository.dart';
import 'package:flutter_template/features/occasion/data/packages_repository.dart';
import 'package:flutter_template/l10n/generated/app_localizations.dart';
import 'package:flutter_template/shared/catalog/catalog_item.dart';
import 'package:flutter_template/shared/catalog/catalog_repository.dart';
import 'package:flutter_template/shared/categories/category_summary.dart';
import 'package:flutter_template/shared/location/area.dart';
import 'package:flutter_template/shared/tickets/ticket.dart';
import 'package:flutter_template/shared/tickets/tickets_repository.dart';
import 'package:flutter_template/shared/widgets/network_image_box.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';

class MockStorageService extends Mock implements StorageService {}

/// A person who last opened one occasion.
class _FixedLast extends LastOccasion {
  _FixedLast(this._occasion);

  final Occasion _occasion;

  @override
  Occasion? build() => _occasion;
}

const _categories = [
  CategorySummary(name: 'birthday', count: 34, isEventCategory: true),
  CategorySummary(name: 'wedding', count: 28, isEventCategory: true),
  CategorySummary(name: 'corporate', count: 19, isEventCategory: true),
  CategorySummary(name: 'social', count: 12, isEventCategory: true),
  CategorySummary(name: 'other', count: 7, isEventCategory: true),
  CategorySummary(
    name: 'photography',
    count: 15,
    isEventCategory: false,
    services: 15,
  ),
  CategorySummary(name: 'dj', count: 9, isEventCategory: false, services: 9),
  CategorySummary(name: 'garden', count: 5, isEventCategory: false, venues: 5),
];

Widget _app({
  List<Ticket> tickets = const [],
  Future<List<CategorySummary>> Function()? categories,
  List<CatalogItem> soon = const [],
  bool soonFails = false,
  int unread = 0,
  Occasion? last,
  Map<String, String> covers = const {},
  GoRouter? router,
  List<CatalogItem> packages = const [],
  List<CatalogItem> elsewhere = const [],
  String? city,
}) {
  final storage = MockStorageService();
  when(storage.readUserModel).thenReturn(null);
  when(() => storage.getString(any())).thenReturn(null);
  when(() => storage.setString(any(), any())).thenAnswer((_) async {});

  return ProviderScope(
    // A failed section stays failed here; Riverpod would retry it itself.
    retry: (_, __) => null,
    overrides: [
      storageServiceProvider.overrideWithValue(storage),
      upcomingTicketsProvider.overrideWith((ref) async => tickets),
      categoriesProvider.overrideWith(
        (ref) => (categories ?? () async => _categories)(),
      ),
      notificationInboxProvider.overrideWith(
        (ref) async => NotificationInbox(
          notifications: const [],
          unreadCount: unread,
        ),
      ),
      // The city's own events, or (no city in the query) events anywhere.
      catalogProvider.overrideWith((ref, q) async {
        if (soonFails) throw Exception('offline');
        final items = city != null && q.city == null ? elsewhere : soon;
        return CatalogPage(items: items, total: items.length);
      }),
      if (city != null)
        areaFilterProvider
            .overrideWithValue(AreaFilter(city: city, label: city)),
      packagesProvider.overrideWith((ref, q) async => packages),
      // No network in tests: a photo is whatever [covers] says, else none.
      occasionCoverProvider.overrideWith((ref, q) async => covers[q.category]),
      if (last != null)
        lastOccasionProvider.overrideWith(() => _FixedLast(last)),
    ],
    child: router == null
        ? const MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: HomePage(),
          )
        : MaterialApp.router(
            routerConfig: router,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
          ),
  );
}

void _phone(WidgetTester tester, {Size size = const Size(800, 2000)}) {
  tester.view
    ..physicalSize = size
    ..devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}

void main() {
  setUp(TestWidgetsFlutterBinding.ensureInitialized);

  testWidgets('shows the occasions with live counts, most bookable first', (
    tester,
  ) async {
    _phone(tester);
    await tester.pumpWidget(_app());
    await tester.pumpAndSettle();

    expect(find.text('What are you planning?'), findsOneWidget);
    for (final name in [
      'Birthday',
      'Wedding',
      'Corporate',
      'Social',
      'Other',
    ]) {
      expect(find.text(name), findsOneWidget, reason: name);
    }
    expect(find.text('34 ideas'), findsOneWidget);
    expect(find.text('7 ideas'), findsOneWidget);
    // photography, dj and garden: three categories behind "All".
    expect(find.text('3 more'), findsOneWidget);

    // Birthday (34) is the large card; Wedding (28) is first in the row below.
    final birthday = tester.getTopLeft(find.text('Birthday'));
    final wedding = tester.getTopLeft(find.text('Wedding'));
    expect(birthday.dy, lessThan(wedding.dy));
  });

  group('photo-led occasions', () {
    GoRouter routerFor() => GoRouter(
          routes: [
            GoRoute(path: '/', builder: (_, __) => const HomePage()),
            GoRoute(
              path: '/search',
              builder: (_, __) => const Scaffold(body: Text('SEARCH SCREEN')),
            ),
            GoRoute(
              path: '/event',
              builder: (_, s) => Scaffold(
                body: Text('EVENT ${(s.extra! as CatalogItem).title}'),
              ),
            ),
            GoRoute(
              path: '/occasion/:name',
              builder: (_, s) => Scaffold(
                body: Text('OCCASION ${s.pathParameters['name']}'),
              ),
            ),
          ],
        );

    testWidgets('the most bookable occasion is the large card to start', (
      tester,
    ) async {
      _phone(tester);
      await tester.pumpWidget(_app());
      await tester.pumpAndSettle();

      expect(find.text('Start planning'), findsOneWidget);
      expect(find.text('Continue planning'), findsNothing);
      // Birthday has the most (34): its card carries the button.
      final pill = tester.getTopLeft(find.text('Start planning'));
      final birthday = tester.getTopLeft(find.text('Birthday'));
      expect((pill.dy - birthday.dy).abs(), lessThan(60));
    });

    testWidgets('what the person last opened is the large card, to continue', (
      tester,
    ) async {
      _phone(tester);
      await tester.pumpWidget(_app(last: Occasion.wedding));
      await tester.pumpAndSettle();

      expect(find.text('Continue planning'), findsOneWidget);
      expect(find.text('Start planning'), findsNothing);
      final pill = tester.getTopLeft(find.text('Continue planning'));
      final wedding = tester.getTopLeft(find.text('Wedding'));
      expect((pill.dy - wedding.dy).abs(), lessThan(60));
      // The old separate "Continue" card is gone: one place says it.
      expect(find.textContaining('Continue:'), findsNothing);
    });

    testWidgets('tapping the large card opens that occasion', (tester) async {
      _phone(tester);
      await tester.pumpWidget(_app(router: routerFor()));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Start planning'));
      await tester.pumpAndSettle();

      expect(find.text('OCCASION birthday'), findsOneWidget);
    });

    testWidgets('an occasion shows its photo when it has one, colours if not', (
      tester,
    ) async {
      _phone(tester);
      await tester.pumpWidget(_app(covers: {'birthday': 'https://x/b.jpg'}));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      // Only Birthday has a photo; the rest are drawn from their colours.
      expect(find.byType(NetworkImageBox), findsOneWidget);
      expect(find.byIcon(Icons.favorite_border_rounded), findsOneWidget);
    });

    testWidgets('a search bar opens Search', (tester) async {
      _phone(tester);
      await tester.pumpWidget(_app(router: routerFor()));
      await tester.pumpAndSettle();

      expect(find.text('Search venues, Foxers and events'), findsOneWidget);
      await tester.tap(find.text('Search venues, Foxers and events'));
      await tester.pumpAndSettle();

      expect(find.text('SEARCH SCREEN'), findsOneWidget);
    });

    testWidgets('packages for the big card are listed, in the city', (
      tester,
    ) async {
      _phone(tester, size: const Size(800, 3000));
      await tester.pumpWidget(
        _app(
          city: 'Baguio',
          packages: const [
            CatalogItem(
              id: 't1',
              kind: CatalogKind.events,
              title: 'Garden Birthday',
              price: 12000,
            ),
          ],
        ),
      );
      await tester.pumpAndSettle();

      // Birthday is the big card (most bookable), so its packages are shown.
      expect(find.text('Popular birthday packages in Baguio'), findsOneWidget);
      expect(find.text('Garden Birthday'), findsOneWidget);
    });

    testWidgets('without a city the packages heading has no city', (
      tester,
    ) async {
      _phone(tester, size: const Size(800, 3000));
      await tester.pumpWidget(
        _app(
          packages: const [
            CatalogItem(id: 't1', kind: CatalogKind.events, title: 'Garden'),
          ],
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Popular birthday packages'), findsOneWidget);
    });

    testWidgets('a package opens its page', (tester) async {
      _phone(tester, size: const Size(800, 3000));
      await tester.pumpWidget(
        _app(
          router: routerFor(),
          packages: const [
            CatalogItem(
              id: 't1',
              kind: CatalogKind.events,
              title: 'Garden Birthday',
            ),
          ],
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Garden Birthday'));
      await tester.pumpAndSettle();

      expect(find.text('EVENT Garden Birthday'), findsOneWidget);
    });

    testWidgets('no packages: no heading and no empty box', (tester) async {
      _phone(tester, size: const Size(800, 3000));
      await tester.pumpWidget(_app(city: 'Baguio'));
      await tester.pumpAndSettle();

      expect(find.textContaining('Popular'), findsNothing);
    });

    testWidgets('Coming up falls back to events elsewhere, and says so', (
      tester,
    ) async {
      _phone(tester, size: const Size(800, 3000));
      await tester.pumpWidget(
        _app(
          city: 'Baguio',
          elsewhere: [
            CatalogItem(
              id: 'e1',
              kind: CatalogKind.events,
              title: 'Night Market',
              city: 'Manila',
              eventStartAt: DateTime(2026, 10, 24, 19),
            ),
          ],
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Coming up'), findsOneWidget);
      expect(
        find.text('Nothing in Baguio yet, so here is what is on elsewhere.'),
        findsOneWidget,
      );
      expect(find.text('Night Market'), findsOneWidget);
      expect(find.text('Manila'), findsOneWidget);
      expect(find.text('Happening soon near you'), findsNothing);
    });

    testWidgets('when the city has events, it is Happening soon, not Coming up',
        (
      tester,
    ) async {
      _phone(tester, size: const Size(800, 3000));
      await tester.pumpWidget(
        _app(
          city: 'Baguio',
          soon: [
            CatalogItem(
              id: 'e1',
              kind: CatalogKind.events,
              title: 'Local Night',
              eventStartAt: DateTime(2026, 10, 24, 19),
            ),
          ],
          elsewhere: [
            CatalogItem(
              id: 'e2',
              kind: CatalogKind.events,
              title: 'Far Away Night',
              eventStartAt: DateTime(2026, 10, 25, 19),
            ),
          ],
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Happening soon near you'), findsOneWidget);
      expect(find.text('Local Night'), findsOneWidget);
      expect(find.text('Coming up'), findsNothing);
      expect(find.text('Far Away Night'), findsNothing);
    });

    testWidgets('nothing anywhere: neither row, and no error', (tester) async {
      _phone(tester, size: const Size(800, 3000));
      await tester.pumpWidget(_app(city: 'Baguio'));
      await tester.pumpAndSettle();

      expect(find.text('Coming up'), findsNothing);
      expect(find.text('Happening soon near you'), findsNothing);
      expect(find.text('Try again'), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('a short Home can still be pulled down to refresh', (
      tester,
    ) async {
      _phone(tester, size: const Size(800, 3000));
      var loads = 0;
      await tester.pumpWidget(
        _app(
          categories: () async {
            loads++;
            return _categories;
          },
        ),
      );
      await tester.pumpAndSettle();
      final before = loads;

      // A refresh starts after a pull of a quarter of the screen (750 here).
      await tester.flingFrom(
        const Offset(400, 300),
        const Offset(0, 1500),
        1500,
      );
      await tester.pumpAndSettle();

      expect(loads, greaterThan(before));
    });

    testWidgets('happening soon comes before "book just one thing"', (
      tester,
    ) async {
      _phone(tester, size: const Size(800, 3000));
      await tester.pumpWidget(
        _app(
          soon: [
            CatalogItem(
              id: 'e1',
              kind: CatalogKind.events,
              title: 'Night Market',
              eventStartAt: DateTime(2026, 10, 24, 19),
            ),
          ],
        ),
      );
      await tester.pumpAndSettle();

      final soon = tester.getTopLeft(find.text('Happening soon near you'));
      final oneThing = tester.getTopLeft(find.text('Or book just one thing'));
      expect(soon.dy, lessThan(oneThing.dy));
    });
  });

  testWidgets(
      'draws the occasions at once, without counts, when the call '
      'fails', (tester) async {
    _phone(tester);
    await tester.pumpWidget(
      _app(categories: () async => throw Exception('offline')),
    );
    await tester.pumpAndSettle();

    expect(find.text('Wedding'), findsOneWidget);
    expect(find.textContaining('ideas'), findsNothing);
    // No error box, no apology.
    expect(find.text('Try again'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('"book just one thing" lists venues then the busiest services', (
    tester,
  ) async {
    _phone(tester);
    await tester.pumpWidget(_app());
    await tester.pumpAndSettle();

    expect(find.text('Or book just one thing'), findsOneWidget);
    expect(find.text('Venues'), findsOneWidget);
    expect(find.text('Photos'), findsOneWidget);
    expect(find.text('DJ'), findsOneWidget);
  });

  testWidgets('leaves "book just one thing" out when there is nothing', (
    tester,
  ) async {
    _phone(tester);
    await tester.pumpWidget(_app(categories: () async => const []));
    await tester.pumpAndSettle();

    expect(find.text('Or book just one thing'), findsNothing);
  });

  testWidgets('shows happening soon with a date badge', (tester) async {
    _phone(tester);
    await tester.pumpWidget(
      _app(
        soon: [
          CatalogItem(
            id: 'e1',
            kind: CatalogKind.events,
            title: 'Night Market',
            city: 'Baguio',
            eventStartAt: DateTime(2099, 10, 24, 18),
          ),
        ],
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Happening soon near you'), findsOneWidget);
    expect(find.text('Night Market'), findsOneWidget);
    expect(find.text('OCT'), findsOneWidget);
    expect(find.text('24'), findsOneWidget);
  });

  testWidgets('leaves happening soon out when there are no events', (
    tester,
  ) async {
    _phone(tester);
    await tester.pumpWidget(_app());
    await tester.pumpAndSettle();

    expect(find.text('Happening soon near you'), findsNothing);
  });

  testWidgets('hides happening soon, heading included, when it fails', (
    tester,
  ) async {
    _phone(tester);
    await tester.pumpWidget(_app(soonFails: true));
    await tester.pumpAndSettle();

    expect(find.text('Happening soon near you'), findsNothing);
    expect(find.text('Try again'), findsNothing);
  });

  testWidgets('shows the strip for an upcoming booking and badges the bell', (
    tester,
  ) async {
    _phone(tester);
    await tester.pumpWidget(_app(tickets: [Ticket.sample()], unread: 3));
    await tester.pumpAndSettle();

    expect(find.text('IN 3 DAYS'), findsOneWidget);
    expect(find.text('Open ticket'), findsOneWidget);
    expect(find.text('3'), findsOneWidget);
  });

  testWidgets('no strip and no error without a booking', (tester) async {
    _phone(tester);
    await tester.pumpWidget(_app());
    await tester.pumpAndSettle();

    expect(find.text('Open ticket'), findsNothing);
  });

  testWidgets('has no Foxer pitch or empty boxes', (tester) async {
    _phone(tester);
    await tester.pumpWidget(_app(categories: () async => const []));
    await tester.pumpAndSettle();

    expect(find.text('Become one'), findsNothing);
    expect(find.textContaining('No Foxers'), findsNothing);
    expect(find.text('Venues near you'), findsNothing);
  });

  testWidgets('lays out on a small phone without overflow', (tester) async {
    _phone(tester, size: const Size(360, 640));
    await tester.pumpWidget(_app(tickets: [Ticket.sample()]));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
  });
}
