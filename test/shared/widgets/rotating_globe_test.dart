import 'package:flutter/material.dart';
import 'package:flutter_template/core/config/app_config.dart';
import 'package:flutter_template/shared/widgets/rotating_globe/globe_html.dart';
import 'package:flutter_template/shared/widgets/rotating_globe/rotating_globe.dart';
import 'package:flutter_template/theme/tokens/colors.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  hostileAndStopTests();
  group('buildGlobeHtml', () {
    test('draws a Mapbox GL JS globe, spinning at the web hero speed', () {
      final html = buildGlobeHtml(token: 'pk.test');

      expect(html, contains("projection: 'globe'"));
      expect(html, contains('mapbox-gl-js/v$mapboxGlVersion/mapbox-gl.js'));
      expect(html, contains('"token":"pk.test"'));
      expect(html, contains('"spin":true'));
      expect(html, contains('"speed":5.0'));
      expect(html, contains('interactive: false'));
    });

    test('is still when spin is off (reduced motion)', () {
      final html = buildGlobeHtml(token: 'pk.test', spin: false);

      expect(html, contains('"spin":false'));
    });

    test('cannot be broken out of by hostile values', () {
      final html = buildGlobeHtml(
        token: '</script><script>alert(1)</script>',
        background: '#000";alert(1);"',
      );

      // Neither value can close the script tag or the string it sits in.
      expect(html, isNot(contains('</script><script>alert(1)')));
      final escapedLt = '${String.fromCharCode(0x5c)}u003c';
      expect(html, contains('$escapedLt/script>'));
      // Exactly the page's own script tags remain: two <script> openers.
      expect('<script'.allMatches(html).length, 2);
    });
  });

  group('RotatingGlobe', () {
    Future<void> pump(WidgetTester tester, {double size = 200}) =>
        tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              backgroundColor: AppColors.canvas,
              body: Center(child: RotatingGlobe(size: size)),
            ),
          ),
        );

    testWidgets('shows a static placeholder when no token is configured',
        (tester) async {
      AppConfig.instance = const AppConfig.dev(); // mapboxToken is empty

      await pump(tester);

      expect(find.byIcon(Icons.public_rounded), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('is labelled for screen readers and ignores touches',
        (tester) async {
      AppConfig.instance = const AppConfig.dev();

      await pump(tester);

      expect(find.bySemanticsLabel('Rotating globe'), findsOneWidget);
      expect(
        find.descendant(
          of: find.byType(RotatingGlobe),
          matching: find.byType(IgnorePointer),
        ),
        findsWidgets,
      );
    });

    testWidgets('takes the requested size', (tester) async {
      AppConfig.instance = const AppConfig.dev();

      await pump(tester, size: 150);

      final box = tester.getSize(
        find
            .descendant(
              of: find.byType(RotatingGlobe),
              matching: find.byType(SizedBox),
            )
            .first,
      );
      expect(box, const Size.square(150));
    });
  });
}

void hostileAndStopTests() {
  group('buildGlobeHtml stops and layers', () {
    test('embeds the pins and caps the cards', () {
      final html = buildGlobeHtml(
        token: 'pk.test',
        stops: const [
          GlobeStop(
            city: 'Manila',
            lat: 14.6,
            lng: 121,
            eventCount: 38,
            title: 'Debut Manila',
          ),
        ],
      );

      expect(html, contains('"city":"Manila"'));
      expect(html, contains('"count":38'));
      expect(html, contains('"maxCards":2'));
    });

    test('adds the NASA city-lights layer unless switched off', () {
      expect(
        buildGlobeHtml(token: 'pk.test'),
        contains('VIIRS_CityLights_2012'),
      );
      expect(
        buildGlobeHtml(token: 'pk.test', nightLights: false),
        contains('"night":false'),
      );
    });

    test('event names cannot break out of the page script', () {
      final html = buildGlobeHtml(
        token: 'pk.test',
        stops: const [
          GlobeStop(
            city: '</script><img src=x onerror=alert(1)>',
            lat: 0,
            lng: 0,
            eventCount: 1,
            title: '</script>',
          ),
        ],
      );

      expect('<script'.allMatches(html).length, 2);
      expect(html, isNot(contains('</script><img')));
    });
  });
}
