import 'package:flutter/material.dart';
import 'package:flutter_template/l10n/generated/app_localizations.dart';
import 'package:flutter_template/shared/location/map_link.dart';
import 'package:flutter_template/shared/widgets/location_card.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _app(Widget child) => MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(body: child),
    );

void main() {
  group('mapsUri', () {
    test('opens the pin when there are coordinates', () {
      final uri = mapsUri(lat: 16.4023, lng: 120.596, query: 'Sky Hall');
      expect(uri!.host, 'www.google.com');
      expect(uri.queryParameters['query'], '16.4023,120.596');
    });

    test('searches the text when there is no pin', () {
      final uri = mapsUri(query: ' Sky Hall, Baguio ');
      expect(uri!.queryParameters['query'], 'Sky Hall, Baguio');
    });

    test('a pin with only one coordinate falls back to the text', () {
      final uri = mapsUri(lat: 16.4, query: 'Sky Hall');
      expect(uri!.queryParameters['query'], 'Sky Hall');
    });

    test('has nothing to open without a pin or text', () {
      expect(mapsUri(), isNull);
      expect(mapsUri(query: '  '), isNull);
    });
  });

  group('LocationCard', () {
    testWidgets('shows the place and a Directions button', (tester) async {
      await tester.pumpWidget(
        _app(
          const LocationCard(
            lines: ['Sky Hall', '12 Session Road', 'Baguio, Benguet'],
            query: 'Sky Hall, Baguio',
          ),
        ),
      );

      expect(find.text('Location'), findsOneWidget);
      expect(find.text('Sky Hall'), findsOneWidget);
      expect(find.text('12 Session Road'), findsOneWidget);
      expect(find.text('Directions'), findsOneWidget);
    });

    testWidgets('skips blank lines', (tester) async {
      await tester.pumpWidget(
        _app(const LocationCard(lines: ['Sky Hall', '  ', ''], query: 'Sky')),
      );

      expect(find.text('Sky Hall'), findsOneWidget);
      expect(find.byType(Text), findsNWidgets(3)); // title, line, button
    });

    testWidgets('draws nothing when there is no place', (tester) async {
      await tester.pumpWidget(
        _app(const LocationCard(lines: [''], query: '')),
      );

      expect(find.text('Location'), findsNothing);
      expect(find.text('Directions'), findsNothing);
    });
  });
}
