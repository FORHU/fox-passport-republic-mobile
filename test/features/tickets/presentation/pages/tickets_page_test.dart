import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_template/features/tickets/presentation/pages/tickets_page.dart';
import 'package:flutter_template/l10n/generated/app_localizations.dart';
import 'package:flutter_template/shared/tickets/ticket.dart';
import 'package:flutter_template/shared/tickets/tickets_repository.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _app({List<Ticket> upcoming = const [], List<Ticket> past = const []}) {
  return ProviderScope(
    overrides: [
      upcomingTicketsProvider.overrideWith((ref) async => upcoming),
      pastTicketsProvider.overrideWith((ref) async => past),
    ],
    child: const MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: TicketsPage(),
    ),
  );
}

void main() {
  testWidgets('shows a ticket with its facts, code and actions', (
    tester,
  ) async {
    tester.view
      ..physicalSize = const Size(800, 1800)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(_app(upcoming: [Ticket.sample()]));
    await tester.pumpAndSettle();

    expect(find.text('Tickets'), findsOneWidget);
    expect(find.text('CONFIRMED'), findsOneWidget);
    expect(find.text('Sky Hall'), findsOneWidget);
    expect(find.text('DATE'), findsOneWidget);
    expect(find.text('DOORS'), findsOneWidget);
    expect(find.text('GUESTS'), findsOneWidget);
    expect(find.text('FXP-0000-SAMPLE'), findsOneWidget);
    expect(find.text('Add to wallet'), findsOneWidget);
    expect(find.text('Directions'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('the Past switch shows an empty message when there are none', (
    tester,
  ) async {
    await tester.pumpWidget(_app(upcoming: [Ticket.sample()]));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Past'));
    await tester.pumpAndSettle();

    expect(find.text('No past tickets yet'), findsOneWidget);
    expect(find.text('Sky Hall'), findsNothing);
  });
}
