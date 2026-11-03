import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_template/features/occasion/presentation/widgets/packages_row.dart';
import 'package:flutter_template/l10n/generated/app_localizations.dart';
import 'package:flutter_template/shared/catalog/catalog_item.dart';
import 'package:flutter_template/shared/currency/currency_providers.dart';
import 'package:flutter_template/theme/tokens/colors.dart';
import 'package:flutter_test/flutter_test.dart';

const _items = [
  CatalogItem(
    id: 'a',
    kind: CatalogKind.events,
    title: 'Garden Wedding',
    price: 45000,
    capacity: 120,
  ),
  CatalogItem(
    id: 'b',
    kind: CatalogKind.events,
    title: 'Intimate Reception',
    price: 28000,
    capacity: 50,
  ),
];

Widget _app(List<CatalogItem> items) => ProviderScope(
      overrides: [
        displayCurrencyProvider.overrideWithValue('PHP'),
        fxRatesProvider.overrideWith((ref) async => null),
      ],
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(body: PackagesRow(items: items)),
      ),
    );

void main() {
  testWidgets('each card shows its name, guests and a "From" price', (
    tester,
  ) async {
    await tester.pumpWidget(_app(_items));
    await tester.pumpAndSettle();

    expect(find.text('Garden Wedding'), findsOneWidget);
    expect(find.text('Up to 120 guests'), findsOneWidget);
    expect(find.text('From ₱45,000'), findsOneWidget);
    expect(find.text('Intimate Reception'), findsOneWidget);
    expect(find.text('Up to 50 guests'), findsOneWidget);
    expect(find.text('From ₱28,000'), findsOneWidget);
  });

  testWidgets('the price is in the accent colour', (tester) async {
    await tester.pumpWidget(_app(_items));
    await tester.pumpAndSettle();

    final price = tester.widget<Text>(find.text('From ₱45,000'));
    expect(price.style?.color, AppColors.accent);
    expect(price.style?.fontWeight, FontWeight.w700);
  });

  testWidgets('no price says to ask; no guest count leaves that line out', (
    tester,
  ) async {
    await tester.pumpWidget(
      _app(const [
        CatalogItem(id: 'c', kind: CatalogKind.events, title: 'Open Day'),
      ]),
    );
    await tester.pumpAndSettle();

    expect(find.text('Ask for a price'), findsOneWidget);
    expect(find.textContaining('From'), findsNothing);
    expect(find.textContaining('Up to'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('a long name stays on one line and the row does not overflow', (
    tester,
  ) async {
    await tester.pumpWidget(
      _app(const [
        CatalogItem(
          id: 'd',
          kind: CatalogKind.events,
          title: 'An extremely long package name that cannot possibly fit',
          price: 1000,
          capacity: 10,
        ),
      ]),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
  });
}
