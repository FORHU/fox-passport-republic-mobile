import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_template/core/config/app_config.dart';
import 'package:flutter_template/features/favorites/data/favorites_repository.dart';
import 'package:flutter_template/features/search/presentation/pages/search_page.dart';
import 'package:flutter_template/l10n/generated/app_localizations.dart';
import 'package:flutter_template/shared/catalog/catalog_item.dart';
import 'package:flutter_template/shared/catalog/catalog_repository.dart';
import 'package:flutter_template/shared/widgets/segmented_pills.dart';
import 'package:flutter_test/flutter_test.dart';

const _venues = [
  CatalogItem(
    id: 'v1',
    kind: CatalogKind.venues,
    title: 'Sky Hall',
    city: 'Davao City',
    capacity: 200,
    price: 25000,
    billingRate: 'daily',
  ),
  CatalogItem(
    id: 'v2',
    kind: CatalogKind.venues,
    title: 'averie',
    city: 'Baguio',
    capacity: 150,
    price: 15000,
    billingRate: 'daily',
  ),
];

const _events = [
  CatalogItem(
    id: 'e1',
    kind: CatalogKind.events,
    title: 'Rooftop Launch Night',
    city: 'Manila',
    category: 'corporate',
    host: 'Ivan Dela Cruz',
    price: 0,
  ),
];

const _gear = [
  CatalogItem(
    id: 'g1',
    kind: CatalogKind.gear,
    title: 'Sound system',
    city: 'Davao City',
    price: 3500,
    billingRate: 'daily',
  ),
];

Widget _app({CatalogKind kind = CatalogKind.venues}) {
  return ProviderScope(
    overrides: [
      catalogProvider.overrideWith((ref, q) async {
        final items = switch (q.kind) {
          CatalogKind.events => _events,
          CatalogKind.gear => _gear,
          _ => _venues,
        };
        return CatalogPage(items: items, total: items.length);
      }),
      favoriteIdsProvider.overrideWith((ref) async => {}),
    ],
    child: MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: SearchPage(initialKind: kind),
    ),
  );
}

void main() {
  setUp(() {
    AppConfig.instance = const AppConfig.dev(useMock: true);
  });

  testWidgets('lists venues as large photo cards with price and guests', (
    tester,
  ) async {
    await tester.pumpWidget(_app());
    await tester.pumpAndSettle();

    expect(find.text('2 VENUES'), findsOneWidget);
    expect(find.text('Sky Hall'), findsOneWidget);
    expect(find.text('Davao City · 200 guests'), findsOneWidget);
    expect(find.text('₱25,000/day'), findsOneWidget);
    expect(find.text('Map'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('the switch changes what is listed', (tester) async {
    await tester.pumpWidget(_app());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Events'));
    await tester.pumpAndSettle();

    expect(find.text('1 EVENTS'), findsOneWidget);
    expect(find.text('Rooftop Launch Night'), findsOneWidget);
    expect(find.text('Sky Hall'), findsNothing);
  });

  testWidgets('applies city, price, and capacity search filters',
      (tester) async {
    CatalogQuery? latestQuery;
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          catalogProvider.overrideWith((ref, q) async {
            latestQuery = q;
            return CatalogPage(items: _venues, total: _venues.length);
          }),
          favoriteIdsProvider.overrideWith((ref) async => {}),
        ],
        child: const MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: SearchPage(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Filters'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField).at(1), 'Davao City');
    await tester.enterText(find.byType(TextField).at(2), '10000');
    await tester.enterText(find.byType(TextField).at(4), '80');
    await tester.tap(find.text('Apply'));
    await tester.pumpAndSettle();

    expect(latestQuery?.city, 'Davao City');
    expect(latestQuery?.minPrice, 10000);
    expect(latestQuery?.minCapacity, 80);
    expect(find.text('Sky Hall'), findsOneWidget);
  });

  testWidgets('offers three choices, with gear and services under Foxers', (
    tester,
  ) async {
    await tester.pumpWidget(_app());
    await tester.pumpAndSettle();

    // Cards carry a tag of their own, so look only inside the switch.
    Finder inSwitch(String label) => find.descendant(
          of: find.byType(SegmentedPills<CatalogKind>),
          matching: find.text(label),
        );
    expect(inSwitch('Events'), findsOneWidget);
    expect(inSwitch('Venues'), findsOneWidget);
    expect(inSwitch('Foxers'), findsOneWidget);
    expect(find.text('Gear'), findsNothing);
    expect(find.text('Services'), findsNothing);

    await tester.tap(inSwitch('Foxers'));
    await tester.pumpAndSettle();

    expect(find.text('People'), findsOneWidget);
    expect(find.text('Gear'), findsOneWidget);
    expect(find.text('Services'), findsOneWidget);

    await tester.tap(find.text('Gear'));
    await tester.pumpAndSettle();

    expect(find.text('Sound system'), findsOneWidget);
    expect(find.text('₱3,500/day'), findsOneWidget);
  });

  testWidgets('a deep link to gear opens Foxers on its Gear scope', (
    tester,
  ) async {
    await tester.pumpWidget(_app(kind: CatalogKind.gear));
    await tester.pumpAndSettle();

    expect(find.text('Sound system'), findsOneWidget);
    expect(find.text('People'), findsOneWidget);
  });

  testWidgets('an unpriced event shows its category and host, not ₱0', (
    tester,
  ) async {
    await tester.pumpWidget(_app(kind: CatalogKind.events));
    await tester.pumpAndSettle();

    expect(find.text('Corporate'), findsOneWidget, reason: 'the tag');
    expect(find.text('Manila · by Ivan Dela Cruz'), findsOneWidget);
    expect(find.textContaining('₱0'), findsNothing);
    expect(
      find.descendant(
        of: find.byType(SegmentedPills<CatalogKind>),
        matching: find.text('Events'),
      ),
      findsOneWidget,
    );
    expect(find.text('Events'), findsOneWidget, reason: 'only the chip');
  });

  testWidgets('opens on the kind it was given', (tester) async {
    await tester.pumpWidget(_app(kind: CatalogKind.events));
    await tester.pumpAndSettle();

    expect(find.text('Rooftop Launch Night'), findsOneWidget);
  });

  testWidgets('an empty result with a city offers to clear it', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          catalogProvider.overrideWith((ref, q) async {
            final items = q.city == null ? _venues : <CatalogItem>[];
            return CatalogPage(items: items, total: items.length);
          }),
          favoriteIdsProvider.overrideWith((ref) async => {}),
        ],
        child: const MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: SearchPage(initialCity: 'Atlantis'),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Nothing here yet'), findsOneWidget);
    expect(find.text('Clear filters'), findsOneWidget);

    await tester.tap(find.text('Clear filters'));
    await tester.pumpAndSettle();

    expect(find.text('Sky Hall'), findsOneWidget);
  });

  testWidgets('a failed load says so and can be retried', (tester) async {
    var calls = 0;
    await tester.pumpWidget(
      ProviderScope(
        // Riverpod retries a failed provider by itself; this test wants the
        // error state, then a tap.
        retry: (_, __) => null,
        overrides: [
          catalogProvider.overrideWith((ref, q) async {
            calls++;
            if (calls == 1) throw Exception('offline');
            return CatalogPage(items: _venues, total: _venues.length);
          }),
          favoriteIdsProvider.overrideWith((ref) async => {}),
        ],
        child: const MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: SearchPage(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Try again'), findsOneWidget);

    await tester.tap(find.text('Try again'));
    await tester.pumpAndSettle();

    expect(find.text('Sky Hall'), findsOneWidget);
  });
}
