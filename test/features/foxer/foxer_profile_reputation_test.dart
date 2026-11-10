import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_template/features/foxer/data/foxer_repository.dart';
import 'package:flutter_template/features/foxer/presentation/pages/foxer_profile_page.dart';
import 'package:flutter_template/l10n/generated/app_localizations.dart';
import 'package:flutter_template/shared/catalog/catalog_item.dart';
import 'package:flutter_template/shared/currency/currency_providers.dart';
import 'package:flutter_template/shared/foxers/foxer_profile.dart';
import 'package:flutter_template/shared/foxers/foxer_reputation.dart';
import 'package:flutter_template/shared/location/area.dart';
import 'package:flutter_test/flutter_test.dart';

const _row = CatalogItem(
  id: 'f1',
  kind: CatalogKind.foxers,
  title: 'Maria Mayor',
  city: 'Davao City',
);

const _reputation = FoxerReputation(
  starRating: 4.8,
  reviewCount: 40,
  isNew: false,
  completedBookings: 62,
  responseRatePercent: 96,
  cancellationRatePercent: 2,
  isIdentityVerified: true,
  labels: ['Top rated', 'Reliable'],
);

Future<List<String>> _show(
  WidgetTester tester,
  FoxerProfile profile,
) async {
  final asked = <String>[];
  tester.view
    ..physicalSize = const Size(800, 2400)
    ..devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ProviderScope(
      retry: (_, __) => null,
      overrides: [
        foxerProfileProvider.overrideWith((ref, item) async => profile),
        foxerReputationProvider.overrideWith((ref, id) async {
          asked.add(id);
          return _reputation;
        }),
        displayCurrencyProvider.overrideWithValue('PHP'),
        fxRatesProvider.overrideWith((ref) async => null),
        profileLocationProvider
            .overrideWith((ref) async => const ProfileLocation()),
      ],
      child: const MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: FoxerProfilePage(item: _row),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return asked;
}

void main() {
  testWidgets('a real Foxer shows how they are doing, under the rating',
      (tester) async {
    final asked = await _show(
      tester,
      FoxerProfile.fromJson(const {
        'id': 'f1',
        'name': 'Maria Mayor',
        'roleType': ['eventFoxer'],
        'avgRating': '4.8',
        'reviewCount': 12,
      }),
    );

    expect(asked, ['f1']);
    expect(find.text('Bookings done'), findsOneWidget);
    expect(find.text('62'), findsOneWidget);
    expect(find.text('Top rated'), findsOneWidget);
    // The rating line is still there.
    expect(find.text('4.8 · 12 reviews'), findsOneWidget);
  });

  testWidgets('a sample row has no account behind it, so nothing is asked',
      (tester) async {
    final asked = await _show(tester, FoxerProfile.sample(_row));

    expect(asked, isEmpty);
    expect(find.text('Bookings done'), findsNothing);
  });
}
