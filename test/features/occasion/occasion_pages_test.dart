import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_template/core/services/storage_service.dart';
import 'package:flutter_template/features/occasion/data/packages_repository.dart';
import 'package:flutter_template/features/occasion/presentation/pages/all_categories_page.dart';
import 'package:flutter_template/features/occasion/presentation/pages/occasion_page.dart';
import 'package:flutter_template/l10n/generated/app_localizations.dart';
import 'package:flutter_template/shared/catalog/catalog_item.dart';
import 'package:flutter_template/shared/categories/category_summary.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _categories = [
  CategorySummary(name: 'wedding', count: 28, isEventCategory: true),
  CategorySummary(
    name: 'photography',
    count: 15,
    isEventCategory: false,
    services: 15,
  ),
  CategorySummary(
    name: 'sound_system',
    count: 11,
    isEventCategory: false,
    assets: 11,
  ),
  CategorySummary(name: 'garden', count: 5, isEventCategory: false, venues: 5),
];

class _MockStorage extends Mock implements StorageService {}

Future<Widget> _app(
  Widget home, {
  List<CatalogItem> packages = const [],
}) async {
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  final storage = _MockStorage();
  when(storage.readUserModel).thenReturn(null);
  when(() => storage.getString(any())).thenReturn(null);

  return ProviderScope(
    retry: (_, __) => null,
    overrides: [
      sharedPreferencesProvider.overrideWithValue(prefs),
      storageServiceProvider.overrideWithValue(storage),
      categoriesProvider.overrideWith((ref) async => _categories),
      packagesProvider.overrideWith((ref, q) async => packages),
    ],
    child: MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: home,
    ),
  );
}

void _phone(WidgetTester tester) {
  tester.view
    ..physicalSize = const Size(800, 2400)
    ..devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}

void main() {
  setUp(TestWidgetsFlutterBinding.ensureInitialized);

  group('OccasionPage', () {
    testWidgets('shows packages, the planner and plan-it-yourself in order', (
      tester,
    ) async {
      _phone(tester);
      await tester.pumpWidget(
        await _app(
          const OccasionPage(occasion: Occasion.wedding),
          packages: const [
            CatalogItem(
              id: 't1',
              kind: CatalogKind.events,
              title: 'Intimate Garden Wedding',
              price: 80000,
            ),
            CatalogItem(
              id: 't2',
              kind: CatalogKind.events,
              title: 'Beach Ceremony',
            ),
          ],
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Wedding ideas'), findsOneWidget);
      expect(find.text('Ready-made packages'), findsOneWidget);
      expect(find.text('Intimate Garden Wedding'), findsOneWidget);
      expect(find.text('Ask for a price'), findsOneWidget);
      expect(find.text('Have a Foxer plan it'), findsOneWidget);
      expect(find.text('Plan it yourself'), findsOneWidget);

      final packages = tester.getTopLeft(find.text('Ready-made packages')).dy;
      final planner = tester.getTopLeft(find.text('Have a Foxer plan it')).dy;
      final yourself = tester.getTopLeft(find.text('Plan it yourself')).dy;
      expect(packages, lessThan(planner));
      expect(planner, lessThan(yourself));
    });

    testWidgets('says so in one line when there are no packages', (
      tester,
    ) async {
      _phone(tester);
      await tester.pumpWidget(
        await _app(const OccasionPage(occasion: Occasion.wedding)),
      );
      await tester.pumpAndSettle();

      expect(find.text('Ready-made packages'), findsNothing);
      expect(
        find.textContaining('No ready-made wedding packages'),
        findsOneWidget,
      );
      // The other two ways are still there.
      expect(find.text('Have a Foxer plan it'), findsOneWidget);
      expect(find.text('Plan it yourself'), findsOneWidget);
    });

    testWidgets('lists the things you can book yourself, with counts', (
      tester,
    ) async {
      _phone(tester);
      await tester.pumpWidget(
        await _app(const OccasionPage(occasion: Occasion.wedding)),
      );
      await tester.pumpAndSettle();

      expect(find.text('Venues'), findsOneWidget);
      expect(find.text('Photos'), findsOneWidget);
      expect(find.text('15'), findsOneWidget);
    });

    testWidgets('Add date and Guests open one sheet', (tester) async {
      _phone(tester);
      await tester.pumpWidget(
        await _app(const OccasionPage(occasion: Occasion.wedding)),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Guests'));
      await tester.pumpAndSettle();

      expect(find.text('Up to 20'), findsOneWidget);
      expect(find.text('100+'), findsOneWidget);

      await tester.tap(find.text('50–100'));
      await tester.tap(find.text('Done'));
      await tester.pumpAndSettle();

      // The chip now shows the choice.
      expect(find.text('50–100'), findsOneWidget);
    });
  });

  group('AllCategoriesPage', () {
    testWidgets('groups every category and searches them', (tester) async {
      _phone(tester);
      await tester.pumpWidget(await _app(const AllCategoriesPage()));
      await tester.pumpAndSettle();

      expect(find.text('Everything you can book'), findsOneWidget);
      for (final heading in ['OCCASIONS', 'PEOPLE', 'GEAR', 'VENUES']) {
        expect(find.text(heading), findsOneWidget, reason: heading);
      }
      // An occasion with no data yet still lists, as "None yet".
      expect(find.text('None yet'), findsWidgets);

      await tester.enterText(find.byType(TextField), 'photo');
      await tester.pumpAndSettle();

      expect(find.text('Photos'), findsOneWidget);
      expect(find.text('Sound'), findsNothing);
    });
  });
}
