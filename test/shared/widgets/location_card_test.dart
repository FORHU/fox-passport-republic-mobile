import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_template/l10n/generated/app_localizations.dart';
import 'package:flutter_template/shared/widgets/location_card.dart';
import 'package:flutter_test/flutter_test.dart';

// A 1 x 1 transparent PNG, so no tile ever goes to the network.
final Uint8List _blankTile = base64Decode(
  'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNkYPhfDwAChwGA'
  '60e6kgAAAABJRU5ErkJggg==',
);

class _BlankTiles extends TileProvider {
  @override
  ImageProvider getImage(TileCoordinates coordinates, TileLayer options) =>
      MemoryImage(_blankTile);
}

Widget _app(Widget child) => MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(body: SingleChildScrollView(child: child)),
    );

void main() {
  testWidgets('with a pin: the heading, the place, a map and the chip', (
    tester,
  ) async {
    await tester.pumpWidget(
      _app(
        LocationCard(
          title: "Where you'll be",
          place: 'Cebu City, Cebu',
          lat: 10.3157,
          lng: 123.8854,
          tileProvider: _BlankTiles(),
        ),
      ),
    );
    await tester.pump();

    expect(find.text("Where you'll be"), findsOneWidget);
    expect(find.text('Cebu City, Cebu'), findsOneWidget);
    expect(find.byType(FlutterMap), findsOneWidget);
    expect(find.byType(MarkerLayer), findsOneWidget);
    expect(find.text('Exact location provided after booking'), findsOneWidget);
    // The exact spot is only given after booking: nothing to open Maps with.
    expect(find.text('Directions'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('without a pin: the place and a placeholder, no map', (
    tester,
  ) async {
    await tester.pumpWidget(
      _app(const LocationCard(title: 'Location', place: 'Baguio, Benguet')),
    );

    expect(find.text('Location'), findsOneWidget);
    expect(find.text('Baguio, Benguet'), findsOneWidget);
    expect(find.byType(FlutterMap), findsNothing);
    expect(find.byIcon(Icons.location_off_outlined), findsOneWidget);
    expect(find.text('Exact location provided after booking'), findsOneWidget);
  });

  testWidgets('a pin alone is enough, with no place to name', (tester) async {
    await tester.pumpWidget(
      _app(
        LocationCard(
          title: 'Location',
          place: '',
          lat: 16.4,
          lng: 120.6,
          tileProvider: _BlankTiles(),
        ),
      ),
    );
    await tester.pump();

    expect(find.byType(FlutterMap), findsOneWidget);
  });

  testWidgets('one coordinate is not a pin', (tester) async {
    await tester.pumpWidget(
      _app(const LocationCard(title: 'Location', place: 'Baguio', lat: 16.4)),
    );

    expect(find.byType(FlutterMap), findsNothing);
  });

  testWidgets('draws nothing with no place and no pin', (tester) async {
    await tester.pumpWidget(
      _app(const LocationCard(title: 'Location', place: '  ')),
    );

    expect(find.text('Location'), findsNothing);
    expect(find.byType(FlutterMap), findsNothing);
  });
}
