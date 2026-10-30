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
      expect(html, contains('"interactive":false'));
    });

    test('lets a finger turn the globe when interactive', () {
      final html = buildGlobeHtml(token: 'pk.test', interactive: true);

      expect(html, contains('"interactive":true'));
      expect(html, contains('interactive: cfg.interactive'));
    });

    test('keeps the web hero look unless asked for the neon one', () {
      final standard = buildGlobeHtml(token: 'pk.test');
      final neon = buildGlobeHtml(token: 'pk.test', look: GlobeLook.neon);

      expect(standard, contains('"look":"standard"'));
      expect(neon, contains('"look":"neon"'));
      // Both pages carry the same script; only the config tells them apart.
      expect(neon, contains("addLayer({ id: 'graticule'"));
      expect(neon, contains("cfg.look === 'neon'"));
    });

    test('colours a pin from the stop, in 0xRRGGBB', () {
      final html = buildGlobeHtml(
        token: 'pk.test',
        look: GlobeLook.neon,
        stops: const [
          GlobeStop(
            city: 'Manila',
            lat: 14.6,
            lng: 121,
            eventCount: 0,
            rgb: 0x00D2FF,
          ),
        ],
      );

      // 0x00D2FF is 54015.
      expect(html, contains('"rgb":54015'));
      expect(html, contains("'circle-color': ['get', 'color']"));
    });

    test('lets the host freeze it and says when the map has drawn', () {
      final html = buildGlobeHtml(token: 'pk.test');

      // Pause and resume reach the page without reloading it...
      expect(html, contains('window.foxSetRunning'));
      expect(html, contains("m.fox === 'run'"));
      expect(html, contains('if (running && cfg.spin && !touched)'));
      // ...and the page reports back on a phone and on Flutter web.
      expect(html, contains("map.once('load'"));
      expect(html, contains("window.FoxGlobe.postMessage('ready')"));
      expect(html, contains("JSON.stringify({ fox: 'ready' })"));
    });

    test('the neon look draws routes from the first stop and names pins', () {
      final html = buildGlobeHtml(token: 'pk.test', look: GlobeLook.neon);

      expect(html, contains("id: 'routes'"));
      expect(html, contains('var hub = cfg.stops[0];'));
      expect(html, contains("id: 'stop-label'"));
    });

    test('turns at the speed it is given and flows the route dashes', () {
      final html = buildGlobeHtml(
        token: 'pk.test',
        look: GlobeLook.neon,
        degreesPerSecond: 2,
      );

      expect(html, contains('"speed":2.0'));
      expect(html, contains('"spin":true'));
      expect(html, contains("'line-dasharray', DASHES[step]"));
      // Nothing in the page sways the globe by itself any more.
      expect(html, isNot(contains('drift')));
    });

    test('keeps the pins pulsing unless animation is off', () {
      expect(buildGlobeHtml(token: 'pk.test'), contains('"animate":true'));
      expect(
        buildGlobeHtml(token: 'pk.test', animate: false),
        contains('"animate":false'),
      );
      // Not turning is a separate choice from not pulsing.
      expect(
        buildGlobeHtml(token: 'pk.test', spin: false),
        allOf(contains('"spin":false'), contains('"animate":true')),
      );
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

    testWidgets('shows the still picture instead of the placeholder when given',
        (tester) async {
      AppConfig.instance = const AppConfig.dev(); // mapboxToken is empty

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            backgroundColor: AppColors.canvas,
            body: SizedBox(
              width: 200,
              height: 200,
              child: RotatingGlobe(still: Text('a still picture')),
            ),
          ),
        ),
      );

      // No token, so a slow or missing map is never a blank space.
      expect(find.text('a still picture'), findsOneWidget);
      expect(find.byIcon(Icons.public_rounded), findsNothing);
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
