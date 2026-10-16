import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_template/core/services/storage_service.dart';
import 'package:flutter_template/l10n/generated/app_localizations.dart';
import 'package:flutter_template/shared/location/area.dart';
import 'package:flutter_template/shared/location/area_sheet.dart';
import 'package:flutter_template/theme/app_theme.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockStorage extends Mock implements StorageService {}

void main() {
  testWidgets('the sheet lays out with the app theme without exceptions', (
    tester,
  ) async {
    final storage = _MockStorage();
    when(() => storage.getString(any())).thenReturn(null);
    when(() => storage.setString(any(), any())).thenAnswer((_) async {});
    tester.view
      ..physicalSize = const Size(800, 1800)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          storageServiceProvider.overrideWithValue(storage),
          profileCityProvider.overrideWith((ref) async => 'Baguio'),
        ],
        child: MaterialApp(
          theme: AppTheme.dark,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Builder(
            builder: (context) => Scaffold(
              body: TextButton(
                onPressed: () => showAreaSheet(context),
                child: const Text('open'),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    expect(find.text('Where are you?'), findsOneWidget);
    expect(find.text('Show'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
