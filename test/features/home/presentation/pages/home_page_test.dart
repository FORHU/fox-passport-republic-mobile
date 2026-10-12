import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_template/core/config/app_config.dart';
import 'package:flutter_template/core/errors/failure.dart';
import 'package:flutter_template/core/services/storage_service.dart';
import 'package:flutter_template/features/home/data/globe_stops_provider.dart';
import 'package:flutter_template/features/home/data/repositories/home_repository.dart';
import 'package:flutter_template/features/home/domain/entities/home_item.dart';
import 'package:flutter_template/features/home/presentation/controllers/home_controller.dart';
import 'package:flutter_template/features/home/presentation/pages/home_page.dart';
import 'package:flutter_template/l10n/generated/app_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

class MockHomeRepository extends Mock implements HomeRepository {}

class MockStorageService extends Mock implements StorageService {}

void main() {
  setUp(() {
    // The globe hero reads the Mapbox token from the active config.
    AppConfig.instance = const AppConfig.dev();
  });

  testWidgets(
    'HomePage renders the welcome card and fetched items with no layout errors',
    (tester) async {
      // Tall enough that the globe hero doesn't push the list below the fold.
      tester.view
        ..physicalSize = const Size(800, 2000)
        ..devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      final mockRepository = MockHomeRepository();
      final mockStorage = MockStorageService();
      when(mockStorage.readUserModel).thenReturn(null);
      when(mockRepository.getItems).thenAnswer(
        (_) async => const Right([
          HomeItem(id: '1', name: 'Ada Lovelace'),
          HomeItem(id: '2', name: 'Alan Turing'),
        ]),
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            storageServiceProvider.overrideWithValue(mockStorage),
            homeRepositoryProvider.overrideWithValue(mockRepository),
            // No pins: the globe hero must not reach for the network here.
            globeStopsProvider.overrideWith((ref) async => const []),
          ],
          child: const MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: HomePage(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // The globe hero leads the page (placeholder here: no Mapbox token).
      expect(
        find.textContaining('ANYWHERE.', findRichText: true),
        findsOneWidget,
      );
      expect(find.text('Find events'), findsOneWidget);
      expect(find.byIcon(Icons.public_rounded), findsOneWidget);
      expect(find.text('Ada Lovelace'), findsOneWidget);
      expect(find.text('Alan Turing'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('HomePage shows a retry option when the fetch fails', (
    tester,
  ) async {
    final mockRepository = MockHomeRepository();
    final mockStorage = MockStorageService();
    when(mockStorage.readUserModel).thenReturn(null);
    when(
      mockRepository.getItems,
    ).thenAnswer((_) async => const Left(NetworkFailure()));

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          storageServiceProvider.overrideWithValue(mockStorage),
          homeRepositoryProvider.overrideWithValue(mockRepository),
        ],
        child: const MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: HomePage(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Retry'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
