import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_template/core/services/storage_service.dart';
import 'package:flutter_template/features/passport/data/passport_repository.dart';
import 'package:flutter_template/features/passport/domain/entities/passport_summary.dart';
import 'package:flutter_template/features/passport/presentation/pages/passport_page.dart';
import 'package:flutter_template/l10n/generated/app_localizations.dart';
import 'package:flutter_template/routes/route_names.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';

class _MockStorage extends Mock implements StorageService {}

void main() {
  testWidgets('the Saved pill opens the saved posts, and stays out of the tabs',
      (tester) async {
    tester.view
      ..physicalSize = const Size(800, 2400)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final storage = _MockStorage();
    when(storage.readUserModel).thenReturn(null);
    final router = GoRouter(
      routes: [
        GoRoute(path: '/', builder: (_, __) => const PassportPage()),
        GoRoute(
          path: RouteNames.republicSaved,
          builder: (_, __) => const Scaffold(body: Text('SAVED SCREEN')),
        ),
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          storageServiceProvider.overrideWithValue(storage),
          passportProvider.overrideWith(
            (ref) async => PassportSummary.sample(),
          ),
        ],
        child: MaterialApp.router(
          routerConfig: router,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Saved'));
    await tester.pumpAndSettle();

    expect(find.text('SAVED SCREEN'), findsOneWidget);

    // Back on the Passport, the tab it came from is still the one showing.
    router.pop();
    await tester.pumpAndSettle();
    expect(find.text('SAVED SCREEN'), findsNothing);
    expect(find.text('2 OF 8'), findsOneWidget);
  });
}
