import 'package:flutter/material.dart';
import 'package:flutter_template/features/foxer/presentation/widgets/foxer_specialties.dart';
import 'package:flutter_template/l10n/generated/app_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _app(List<String> specialties) => MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(body: FoxerSpecialties(specialties: specialties)),
    );

void main() {
  testWidgets('shows each specialty and the one-booking note', (tester) async {
    await tester.pumpWidget(_app(['Photography', 'Drone photography']));

    expect(find.text('SPECIALTIES'), findsOneWidget);
    expect(find.text('Photography'), findsOneWidget);
    expect(find.text('Drone photography'), findsOneWidget);
    expect(
      find.text('Booked for one thing at a time, across all specialties.'),
      findsOneWidget,
    );
  });

  testWidgets('takes no room without specialties', (tester) async {
    await tester.pumpWidget(_app(const []));

    expect(find.text('SPECIALTIES'), findsNothing);
    expect(find.byType(Container), findsNothing);
  });
}
