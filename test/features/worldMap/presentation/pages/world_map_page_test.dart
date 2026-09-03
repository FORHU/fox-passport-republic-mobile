import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_template/core/errors/failure.dart';
import 'package:flutter_template/features/worldMap/data/repositories/store_repository.dart';
import 'package:flutter_template/features/worldMap/domain/entities/store_entity.dart';
import 'package:flutter_template/features/worldMap/presentation/controllers/world_map_controller.dart';
import 'package:flutter_template/features/worldMap/presentation/pages/world_map_page.dart';
import 'package:flutter_template/l10n/generated/app_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

class MockStoreRepository extends Mock implements StoreRepository {}

void main() {
  testWidgets(
    'WorldMapPage renders the fetched nearby places with no layout errors',
    (tester) async {
      final mockRepository = MockStoreRepository();
      when(mockRepository.getNearbyStores).thenAnswer(
        (_) async => const Right([
          StoreEntity(
            id: '1',
            name: 'Downtown Market',
            address: '123 Main St',
            distanceKm: 0.8,
            rating: 4.5,
          ),
          StoreEntity(
            id: '2',
            name: 'Riverside Grocers',
            address: '45 River Rd',
            distanceKm: 1.6,
            rating: 4.2,
          ),
        ]),
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            storeRepositoryProvider.overrideWithValue(mockRepository),
          ],
          child: const MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: WorldMapPage(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Downtown Market'), findsOneWidget);
      expect(find.text('Riverside Grocers'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('WorldMapPage shows an empty state with no results', (
    tester,
  ) async {
    final mockRepository = MockStoreRepository();
    when(
      mockRepository.getNearbyStores,
    ).thenAnswer((_) async => const Right([]));

    await tester.pumpWidget(
      ProviderScope(
        overrides: [storeRepositoryProvider.overrideWithValue(mockRepository)],
        child: const MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: WorldMapPage(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('No nearby places'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('WorldMapPage shows a retry option when the fetch fails', (
    tester,
  ) async {
    final mockRepository = MockStoreRepository();
    when(
      mockRepository.getNearbyStores,
    ).thenAnswer((_) async => const Left(NetworkFailure()));

    await tester.pumpWidget(
      ProviderScope(
        overrides: [storeRepositoryProvider.overrideWithValue(mockRepository)],
        child: const MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: WorldMapPage(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Retry'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
