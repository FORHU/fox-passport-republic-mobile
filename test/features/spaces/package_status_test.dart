import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_template/core/constants/api_endpoints.dart';
import 'package:flutter_template/core/services/api_service.dart';
import 'package:flutter_template/features/spaces/data/spaces_repository.dart';
import 'package:flutter_template/features/spaces/domain/package_standing.dart';
import 'package:flutter_template/features/spaces/domain/space_models.dart';
import 'package:flutter_template/features/spaces/presentation/pages/package_status_page.dart';
import 'package:flutter_template/features/spaces/presentation/widgets/package_status_line.dart';
import 'package:flutter_template/l10n/generated/app_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockApi extends Mock implements ApiService {}

/// A matched line: the Supplier was asked and answered with [status].
Map<String, Object?> _line(
  String itemKey,
  String name, {
  String status = 'accepted',
  bool optional = false,
  bool matched = true,
  String? reason,
  String? note,
  DateTime? requestedAt,
}) =>
    {
      'matched': matched,
      'matchRequestStatus': status,
      'isOptional': optional,
      'declineReason': reason,
      'declineNote': note,
      if (requestedAt != null) 'requestedAt': requestedAt.toIso8601String(),
      itemKey: {
        'id': 'id-$name',
        'name': name,
        if (itemKey == 'venue')
          'mayorId': 'mayor-$name'
        else
          'ownerId': 'o-$name',
      },
    };

Map<String, Object?> _template({
  String status = 'draft',
  List<Map<String, Object?>> venues = const [],
  List<Map<String, Object?>> assets = const [],
  List<Map<String, Object?>> services = const [],
}) =>
    {
      'id': 'e1',
      'name': 'Garden Wedding Package',
      'status': status,
      'templateVenues': venues,
      'templateAssets': assets,
      'templateServices': services,
    };

PackageStanding _standing(Map<String, Object?> row) =>
    PackageStanding.fromTemplate(row)!;

void main() {
  group('PackageStanding', () {
    test('counts required answers and is building while one waits', () {
      final p = _standing(
        _template(
          venues: [_line('venue', 'Sky Hall', status: 'pending')],
          assets: [_line('asset', 'Stage Monitor Pair')],
          services: [
            _line('service', 'Lights', status: 'pending', optional: true),
          ],
        ),
      );

      expect(p.stage, PackageStage.building);
      expect(p.requiredCount, 2);
      expect(p.acceptedCount, 1);
      expect(p.waiting.map((l) => l.name), ['Sky Hall']);
      expect(p.waiting.single.supplierId, 'mayor-Sky Hall');
      expect(p.needsAttention, isTrue);
    });

    test('a line that joined at once counts as accepted', () {
      final p = _standing(
        _template(venues: [_line('venue', 'Own Hall', matched: false)]),
      );

      expect(p.lines.single.invite, isNull);
      expect(p.stage, PackageStage.ready);
    });

    test('declined and expired required lines are to replace', () {
      final p = _standing(
        _template(
          assets: [_line('asset', 'Speakers', status: 'declined')],
          services: [_line('service', 'Photos', status: 'expired')],
        ),
      );

      expect(p.toSwap.map((l) => l.name), ['Speakers', 'Photos']);
      expect(p.stage, PackageStage.building);
    });

    test('the template status sets the stage once sent', () {
      expect(
        _standing(_template(status: 'pending')).stage,
        PackageStage.inReview,
      );
      expect(
        _standing(_template(status: 'published')).stage,
        PackageStage.live,
      );
      expect(
        _standing(_template(status: 'rejected')).stage,
        PackageStage.rejected,
      );
      // An empty draft is still being built and waits on nobody.
      final empty = _standing(_template());
      expect(empty.stage, PackageStage.building);
      expect(empty.needsAttention, isFalse);
    });

    test('soonest days left comes from the waiting Suppliers', () {
      final now = DateTime.utc(2026, 11, 25, 12);
      final p = _standing(
        _template(
          venues: [
            _line(
              'venue',
              'Sky Hall',
              status: 'pending',
              requestedAt: now.subtract(const Duration(days: 2, hours: 1)),
            ),
          ],
          assets: [
            _line(
              'asset',
              'Speakers',
              status: 'pending',
              requestedAt: now.subtract(const Duration(hours: 1)),
            ),
          ],
        ),
      );

      expect(p.soonestDaysLeft(now), 0);
    });

    test('SpaceListing reads the package only from an event template', () {
      final event = SpaceListing.tryParse(
        _template(venues: [_line('venue', 'Sky Hall')]),
        cityKey: 'targetCity',
      );
      final venue = SpaceListing.tryParse({'id': 'v1', 'name': 'Hall'});

      expect(event?.package?.lines, hasLength(1));
      expect(venue?.package, isNull);
    });
  });

  group('status line', () {
    late AppLocalizations l10n;

    setUpAll(() async {
      l10n = await AppLocalizations.delegate.load(const Locale('en'));
    });

    test('a draft says how many agreed and what is left', () {
      final line = packageStatusLine(
        l10n,
        _standing(
          _template(
            venues: [_line('venue', 'Sky Hall', status: 'pending')],
            assets: [_line('asset', 'Speakers')],
            services: [_line('service', 'Photos', status: 'declined')],
          ),
        ),
      );

      expect(line?.text, '1 of 3 Suppliers agreed · 1 to replace · 1 waiting');
    });

    test('ready, in review and live', () {
      expect(
        packageStatusLine(
          l10n,
          _standing(_template(venues: [_line('venue', 'Sky Hall')])),
        )?.text,
        'Every Supplier agreed · ready to send for review',
      );
      expect(
        packageStatusLine(l10n, _standing(_template(status: 'pending')))?.text,
        'Sent · the admin is checking it',
      );
      expect(
        packageStatusLine(
          l10n,
          _standing(
            _template(
              status: 'published',
              venues: [_line('venue', 'Sky Hall')],
              assets: [_line('asset', 'Speakers')],
            ),
          ),
        )?.text,
        '2 Suppliers agreed · live for guests',
      );
    });
  });

  group('PackageStatusPage', () {
    late _MockApi api;
    final messaged = <String>[];

    setUp(() {
      api = _MockApi();
      messaged.clear();
    });

    Future<void> show(WidgetTester tester) async {
      tester.view
        ..physicalSize = const Size(800, 2400)
        ..devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        ProviderScope(
          retry: (_, __) => null,
          overrides: [
            spacesRepositoryProvider.overrideWithValue(
              SpacesRepository(api, 'u1'),
            ),
          ],
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: PackageStatusPage(
              eventId: 'e1',
              onMessage: (_, userId) async => messaged.add(userId),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    void returns(Map<String, Object?> template) {
      when(() => api.get(ApiEndpoints.eventById('e1')))
          .thenAnswer((_) async => {'template': template});
    }

    testWidgets('a draft lists each answer, days left and the reason', (
      tester,
    ) async {
      returns(
        _template(
          venues: [
            _line(
              'venue',
              'Sky Hall',
              status: 'pending',
              requestedAt: DateTime.now().subtract(const Duration(hours: 1)),
            ),
          ],
          assets: [_line('asset', 'Stage Monitor Pair')],
          services: [
            _line(
              'service',
              'Wedding Photography',
              status: 'declined',
              reason: 'price_too_low',
              note: 'Not enough for 150 guests.',
            ),
            _line('service', 'Lights', optional: true),
          ],
        ),
      );
      await show(tester);

      expect(find.text('Garden Wedding Package'), findsOneWidget);
      expect(find.text('BUILDING THE TEAM'), findsOneWidget);
      expect(find.text('1 Supplier to replace'), findsOneWidget);
      expect(find.text('2 days left to answer'), findsOneWidget);
      expect(
        find.text('Price too low: “Not enough for 150 guests.”'),
        findsOneWidget,
      );
      expect(
        find.text('Service · Optional, not needed to publish'),
        findsOneWidget,
      );
      // Nothing to send yet.
      expect(find.text('Send for review'), findsNothing);
      expect(find.text('Open in builder'), findsOneWidget);
    });

    testWidgets('Message opens a chat with the waiting Supplier', (
      tester,
    ) async {
      returns(
        _template(venues: [_line('venue', 'Sky Hall', status: 'pending')]),
      );
      await show(tester);

      await tester.tap(find.text('Message Sky Hall'));
      await tester.pumpAndSettle();

      expect(messaged, ['mayor-Sky Hall']);
    });

    testWidgets('a ready package can be sent for review', (tester) async {
      returns(_template(venues: [_line('venue', 'Sky Hall')]));
      when(() => api.post(ApiEndpoints.eventSubmit('e1')))
          .thenAnswer((_) async => <String, Object?>{});
      await show(tester);

      expect(find.text('Every Supplier agreed'), findsOneWidget);
      // Sent, the package is in review when it reloads.
      returns(_template(status: 'pending'));
      await tester.tap(find.text('Send for review'));
      await tester.pumpAndSettle();

      verify(() => api.post(ApiEndpoints.eventSubmit('e1'))).called(1);
      expect(find.text('The admin is checking it'), findsOneWidget);
    });

    testWidgets('a failed load offers a retry', (tester) async {
      when(() => api.get(ApiEndpoints.eventById('e1')))
          .thenThrow(Exception('offline'));
      await show(tester);

      expect(find.text('We could not load this package.'), findsOneWidget);
      expect(find.text('Try again'), findsOneWidget);
    });
  });
}
