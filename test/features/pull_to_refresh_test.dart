import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_template/core/config/app_config.dart';
import 'package:flutter_template/core/services/storage_service.dart';
import 'package:flutter_template/features/calendar/presentation/pages/calendar_page.dart';
import 'package:flutter_template/features/favorites/data/favorites_repository.dart';
import 'package:flutter_template/features/occasion/data/packages_repository.dart';
import 'package:flutter_template/features/occasion/presentation/pages/all_categories_page.dart';
import 'package:flutter_template/features/occasion/presentation/pages/occasion_page.dart';
import 'package:flutter_template/features/search/presentation/pages/search_page.dart';
import 'package:flutter_template/l10n/generated/app_localizations.dart';
import 'package:flutter_template/shared/calendar/calendar_entry.dart';
import 'package:flutter_template/shared/catalog/catalog_item.dart';
import 'package:flutter_template/shared/catalog/catalog_repository.dart';
import 'package:flutter_template/shared/categories/category_summary.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _MockStorage extends Mock implements StorageService {}

const _categories = [
  CategorySummary(name: 'wedding', count: 28, isEventCategory: true),
  CategorySummary(
    name: 'photography',
    count: 15,
    isEventCategory: false,
    services: 15,
  ),
];

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
];

/// A phone-sized screen.
void _phone(WidgetTester tester) {
  tester.view
    ..physicalSize = const Size(400, 800)
    ..devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}

/// Pulls the first vertical scroll view on screen down, like a finger would.
Future<void> _pullDown(WidgetTester tester) async {
  final list = find.byWidgetPredicate(
    (w) => w is Scrollable && w.axis == Axis.vertical,
  );
  await tester.fling(list.first, const Offset(0, 400), 800);
  await tester.pumpAndSettle();
}

Widget _app(Widget home, List<Override> overrides) => ProviderScope(
      retry: (_, __) => null,
      overrides: overrides,
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: home,
      ),
    );

void main() {
  setUp(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    AppConfig.instance = const AppConfig.dev(useMock: true);
  });

  testWidgets('Calendar reloads its entries when pulled down', (tester) async {
    _phone(tester);
    var loads = 0;
    await tester.pumpWidget(
      // Calendar is a Bookings switch now (CalendarView, no page of its own).
      _app(Scaffold(body: CalendarView(onOpenTickets: () {})), [
        calendarEntriesProvider.overrideWith((ref, range) async {
          loads++;
          return <CalendarEntry>[];
        }),
      ]),
    );
    await tester.pumpAndSettle();
    final before = loads;

    await _pullDown(tester);

    expect(loads, greaterThan(before));
    expect(tester.takeException(), isNull);
  });

  testWidgets('All categories reloads when pulled down', (tester) async {
    _phone(tester);
    var loads = 0;
    await tester.pumpWidget(
      _app(const AllCategoriesPage(), [
        categoriesProvider.overrideWith((ref) async {
          loads++;
          return _categories;
        }),
      ]),
    );
    await tester.pumpAndSettle();
    final before = loads;

    await _pullDown(tester);

    expect(loads, greaterThan(before));
    expect(tester.takeException(), isNull);
  });

  testWidgets('Occasion reloads its packages when pulled down', (
    tester,
  ) async {
    _phone(tester);
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final storage = _MockStorage();
    when(storage.readUserModel).thenReturn(null);
    when(() => storage.getString(any())).thenReturn(null);
    var loads = 0;
    await tester.pumpWidget(
      _app(const OccasionPage(occasion: Occasion.wedding), [
        sharedPreferencesProvider.overrideWithValue(prefs),
        storageServiceProvider.overrideWithValue(storage),
        categoriesProvider.overrideWith((ref) async => _categories),
        packagesProvider.overrideWith((ref, q) async {
          loads++;
          return <CatalogItem>[];
        }),
      ]),
    );
    await tester.pumpAndSettle();
    final before = loads;

    await _pullDown(tester);

    expect(loads, greaterThan(before));
    expect(tester.takeException(), isNull);
  });

  testWidgets('Search reloads its results when pulled down', (tester) async {
    _phone(tester);
    var loads = 0;
    await tester.pumpWidget(
      _app(const SearchPage(), [
        catalogProvider.overrideWith((ref, q) async {
          loads++;
          return CatalogPage(items: _venues, total: _venues.length);
        }),
        favoriteIdsProvider.overrideWith((ref) async => {}),
      ]),
    );
    await tester.pumpAndSettle();
    expect(find.text('Sky Hall'), findsOneWidget);
    final before = loads;

    await _pullDown(tester);

    expect(loads, greaterThan(before));
    expect(find.text('Sky Hall'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
