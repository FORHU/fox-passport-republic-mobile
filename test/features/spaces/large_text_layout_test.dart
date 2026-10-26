import 'package:flutter/material.dart';
import 'package:flutter_template/features/spaces/domain/space_models.dart';
import 'package:flutter_template/features/spaces/presentation/widgets/listing_card.dart';
import 'package:flutter_template/l10n/generated/app_localizations.dart';
import 'package:flutter_template/theme/app_theme.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets(
      'a listing keeps its town and status on a narrow, large-text '
      'screen', (tester) async {
    tester.view
      ..physicalSize = const Size(320, 800)
      ..devicePixelRatio = 1;
    tester.platformDispatcher.textScaleFactorTestValue = 1.5;
    addTearDown(() {
      tester.view.reset();
      tester.platformDispatcher.clearAllTestValues();
    });

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: ListingCard(
            listing: const SpaceListing(
              id: 'e1',
              name: 'A very long event name that needs more than one line',
              status: 'pending',
              city: 'San Pedro de Macoris',
            ),
            onTap: () {},
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('San Pedro de Macoris'), findsOneWidget);
    expect(find.text('In review'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
