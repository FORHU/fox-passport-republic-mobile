import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_template/core/services/storage_service.dart';
import 'package:flutter_template/features/passport/data/passport_repository.dart';
import 'package:flutter_template/features/passport/domain/entities/passport_summary.dart';
import 'package:flutter_template/features/passport/presentation/pages/passport_page.dart';
import 'package:flutter_template/features/spaces/data/active_space.dart';
import 'package:flutter_template/features/spaces/domain/app_space.dart';
import 'package:flutter_template/l10n/generated/app_localizations.dart';
import 'package:flutter_template/shared/matches/match_request_item.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockStorage extends Mock implements StorageService {}

/// A phone-sized screen, like the one that showed "BOTTOM OVERFLOWED BY 339
/// PIXELS". The other Passport test uses a tall one, which hides the overflow.
void _phone(WidgetTester tester) {
  tester.view
    ..physicalSize = const Size(360, 640)
    ..devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}

Future<void> _open(WidgetTester tester, {void Function()? onLoad}) async {
  final storage = _MockStorage();
  when(storage.readUserModel).thenReturn(null);
  await tester.pumpWidget(
    ProviderScope(
      retry: (_, __) => null,
      overrides: [
        availableSpacesProvider.overrideWithValue(const [AppSpace.citizen]),
        storageServiceProvider.overrideWithValue(storage),
        passportProvider.overrideWith((ref) async {
          onLoad?.call();
          return PassportSummary.sample();
        }),
        myMatchRequestsProvider.overrideWith(
          (ref) async => <MatchRequestItem>[],
        ),
      ],
      child: const MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: PassportPage(),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('the Progress tab fits a phone and scrolls to the bottom', (
    tester,
  ) async {
    _phone(tester);
    await _open(tester);

    // Before the fix this threw a RenderFlex overflow.
    expect(tester.takeException(), isNull);

    // The last thing on the tab, below the badges, can be scrolled to.
    await tester.scrollUntilVisible(
      find.text('Republic'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Republic'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('every other tab fits a phone too', (tester) async {
    _phone(tester);
    await _open(tester);

    for (final tab in ['Stamps', 'Matches', 'Saved', 'Earn', 'Progress']) {
      // The segmented pills scroll sideways on a narrow screen.
      await tester.ensureVisible(find.text(tab).first);
      await tester.tap(find.text(tab).first);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull, reason: 'the $tab tab overflowed');
    }
  });

  testWidgets('pulling down on a tab reloads the passport', (tester) async {
    _phone(tester);
    var loads = 0;
    await _open(tester, onLoad: () => loads++);
    final before = loads;

    await tester.fling(
      find.byType(Scrollable).first,
      const Offset(0, 400),
      800,
    );
    await tester.pumpAndSettle();

    expect(loads, greaterThan(before));
  });
}
