import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_template/core/errors/failure.dart';
import 'package:flutter_template/core/services/storage_service.dart';
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
  testWidgets(
    'HomePage renders the welcome card and fetched items with no layout errors',
    (tester) async {
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
          ],
          child: const MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: HomePage(),
          ),
        ),
      );
      await tester.pumpAndSettle();

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
