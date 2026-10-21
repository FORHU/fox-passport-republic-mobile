import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_template/core/constants/api_endpoints.dart';
import 'package:flutter_template/core/errors/exceptions.dart';
import 'package:flutter_template/core/services/api_service.dart';
import 'package:flutter_template/features/calendar/presentation/pages/calendar_page.dart';
import 'package:flutter_template/features/spaces/data/spaces_repository.dart';
import 'package:flutter_template/features/spaces/domain/space_models.dart';
import 'package:flutter_template/l10n/generated/app_localizations.dart';
import 'package:flutter_template/shared/calendar/calendar_entry.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockApi extends Mock implements ApiService {}

const _skyHall = SpaceListing(id: 'v1', name: 'Sky Hall', status: 'available');
const _oldBarn = SpaceListing(id: 'v2', name: 'Old Barn', status: 'available');

String _today() {
  final n = DateTime.now();
  return '${n.year}-${n.month.toString().padLeft(2, '0')}-'
      '${n.day.toString().padLeft(2, '0')}';
}

CalendarEntry _booking(
  String id,
  String title,
  VenueHold hold, {
  SpaceListing venue = _skyHall,
}) {
  final now = DateTime.now();
  return CalendarEntry(
    id: id,
    role: CalendarRole.venue,
    title: title,
    start: DateTime(now.year, now.month, now.day, 18),
    end: DateTime(now.year, now.month, now.day, 23),
    status: 'approved',
    venueId: venue.id,
    venueName: venue.name,
    hold: hold,
  );
}

CalendarEntry _block(SpaceListing venue) {
  final now = DateTime.now();
  final day = DateTime(now.year, now.month, now.day);
  return CalendarEntry(
    id: 'venue-block:${venue.id}:${_today()}',
    role: CalendarRole.venue,
    title: 'Blocked · ${venue.name}',
    start: day,
    end: DateTime(now.year, now.month, now.day + 1),
    status: 'blocked',
    kind: 'block',
    venueId: venue.id,
    venueName: venue.name,
  );
}

void main() {
  group('CalendarEntry for a venue', () {
    test('reads which venue and where the booking stands', () {
      final e = CalendarEntry.tryParse({
        'id': 'venue-event:e1',
        'kind': 'event',
        'role': 'venue',
        'title': 'Garden Party · Sky Hall',
        'start': '2026-12-20T10:00:00.000Z',
        'end': '2026-12-20T14:00:00.000Z',
        'status': 'approved',
        'venueId': 'v1',
        'venueName': 'Sky Hall',
        'venueStatus': 'pending_provider_confirmation',
      })!;

      expect(e.venueId, 'v1');
      expect(e.venueName, 'Sky Hall');
      expect(e.hold, VenueHold.awaitingReply);
      expect(e.isBlock, isFalse);
    });

    test('knows each way a booking can stand', () {
      expect(
        VenueHold.parse('pending_provider_confirmation'),
        VenueHold.awaitingReply,
      );
      expect(VenueHold.parse('pending'), VenueHold.held);
      expect(VenueHold.parse('approved'), VenueHold.confirmed);
      expect(VenueHold.parse('rejected'), isNull);
      expect(VenueHold.parse(null), isNull);
    });

    test('a closed day is the date as written, whatever the time zone', () {
      final e = CalendarEntry.tryParse({
        'id': 'venue-block:v1:2026-12-24',
        'kind': 'block',
        'role': 'venue',
        'title': 'Blocked · Sky Hall',
        'start': '2026-12-24T00:00:00.000Z',
        'end': '2026-12-25T00:00:00.000Z',
        'status': 'blocked',
        'venueId': 'v1',
      })!;

      expect(e.isBlock, isTrue);
      // Local midnight of the 24th: never the 23rd behind UTC.
      expect(e.start, DateTime(2026, 12, 24));
      expect(e.end, DateTime(2026, 12, 25));
      expect(e.coversDay(DateTime(2026, 12, 24)), isTrue);
      expect(e.coversDay(DateTime(2026, 12, 25)), isFalse);
      expect(e.coversDay(DateTime(2026, 12, 23)), isFalse);
    });

    test('rows from before the venue fields still read', () {
      final e = CalendarEntry.tryParse({
        'id': 'booking:b1',
        'role': 'guest',
        'title': 'Garden Party',
        'start': '2026-12-20T10:00:00.000Z',
        'end': '2026-12-20T14:00:00.000Z',
        'status': 'confirmed',
      })!;

      expect(e.venueId, isNull);
      expect(e.hold, isNull);
    });
  });

  group('the Venue space calendar', () {
    late _MockApi api;

    setUp(() {
      api = _MockApi();
      when(() => api.post(any(), any())).thenAnswer((_) async => {});
      when(() => api.delete(any())).thenAnswer((_) async => {});
    });

    Widget app(
      List<CalendarEntry> entries, {
      List<SpaceListing> venues = const [_skyHall],
      bool manage = true,
    }) {
      return ProviderScope(
        retry: (_, __) => null,
        overrides: [
          venueCalendarProvider.overrideWith((ref, range) async => entries),
          calendarEntriesProvider.overrideWith((ref, range) async => entries),
          myVenuesProvider.overrideWith((ref) async => venues),
          spacesRepositoryProvider
              .overrideWithValue(SpacesRepository(api, 'u1')),
        ],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: CalendarView(onOpenTickets: () {}, manageVenues: manage),
          ),
        ),
      );
    }

    testWidgets('says where each booking at the venue stands', (tester) async {
      _tall(tester);
      await tester.pumpWidget(
        app([
          _booking('a', 'Wedding', VenueHold.confirmed),
          _booking('b', 'Birthday', VenueHold.held),
          _booking('c', 'Reunion', VenueHold.awaitingReply),
        ]),
      );
      await tester.pumpAndSettle();

      expect(find.text('Confirmed'), findsOneWidget);
      expect(find.text('Held'), findsOneWidget);
      expect(find.text('Needs your reply'), findsOneWidget);
    });

    testWidgets('shows a closed day, and opens it again', (tester) async {
      _tall(tester);
      await tester.pumpWidget(app([_block(_skyHall)]));
      await tester.pumpAndSettle();

      expect(find.text('Blocked · Sky Hall'), findsOneWidget);
      expect(find.text('Open this day'), findsOneWidget);

      await tester.tap(find.text('Open this day'));
      await tester.pumpAndSettle();

      verify(
        () => api.delete(ApiEndpoints.venueBlockedDate('v1', _today())),
      ).called(1);
    });

    testWidgets('closing a day sends that date for that venue', (tester) async {
      _tall(tester);
      await tester.pumpWidget(app(const []));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Open or close this day'));
      await tester.pumpAndSettle();
      expect(find.text('Sky Hall'), findsOneWidget);
      expect(find.text('Open'), findsOneWidget);

      await tester.tap(find.byType(Switch));
      await tester.pumpAndSettle();

      verify(
        () => api.post(
          ApiEndpoints.venueBlockedDates('v1'),
          {'date': _today()},
        ),
      ).called(1);
    });

    testWidgets('a booked day cannot be closed', (tester) async {
      _tall(tester);
      await tester.pumpWidget(
        app([_booking('a', 'Wedding', VenueHold.confirmed)]),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Open or close this day'));
      await tester.pumpAndSettle();

      expect(find.text("Booked, so it can't be closed"), findsOneWidget);
      expect(tester.widget<Switch>(find.byType(Switch)).onChanged, isNull);
    });

    testWidgets('a closed day shows Closed, and its switch opens it', (
      tester,
    ) async {
      _tall(tester);
      await tester.pumpWidget(app([_block(_skyHall)]));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Open or close this day'));
      await tester.pumpAndSettle();
      expect(find.text('Closed'), findsOneWidget);

      await tester.tap(find.byType(Switch));
      await tester.pumpAndSettle();

      verify(
        () => api.delete(ApiEndpoints.venueBlockedDate('v1', _today())),
      ).called(1);
    });

    testWidgets('says so when the day could not be changed', (tester) async {
      when(() => api.post(any(), any()))
          .thenThrow(const ServerException('Unauthorized'));
      _tall(tester);
      await tester.pumpWidget(app(const []));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Open or close this day'));
      await tester.pumpAndSettle();
      await tester.tap(find.byType(Switch));
      await tester.pumpAndSettle();

      expect(
        find.text("We couldn't update that day. Try again."),
        findsOneWidget,
      );
    });

    testWidgets('with several venues, one can be shown on its own', (
      tester,
    ) async {
      _tall(tester);
      await tester.pumpWidget(
        app(
          [
            _booking('a', 'Wedding', VenueHold.confirmed),
            _booking(
              'b',
              'Reunion',
              VenueHold.confirmed,
              venue: _oldBarn,
            ),
          ],
          venues: const [_skyHall, _oldBarn],
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('All venues'), findsOneWidget);
      expect(find.text('Wedding'), findsOneWidget);
      expect(find.text('Reunion'), findsOneWidget);

      await tester.tap(find.widgetWithText(ChoiceChip, 'Sky Hall'));
      await tester.pumpAndSettle();

      expect(find.text('Wedding'), findsOneWidget);
      expect(find.text('Reunion'), findsNothing);

      await tester.tap(find.text('All venues'));
      await tester.pumpAndSettle();
      expect(find.text('Reunion'), findsOneWidget);
    });

    testWidgets('with one venue there is no filter to choose', (tester) async {
      _tall(tester);
      await tester.pumpWidget(app(const []));
      await tester.pumpAndSettle();

      expect(find.text('All venues'), findsNothing);
    });

    testWidgets('the Citizen calendar has none of the venue controls', (
      tester,
    ) async {
      _tall(tester);
      await tester.pumpWidget(app(const [], manage: false));
      await tester.pumpAndSettle();

      expect(find.text('Open or close this day'), findsNothing);
      expect(find.text('All venues'), findsNothing);
    });
  });
}

/// A tall screen, so the day's list below the month grid is built and tappable.
void _tall(WidgetTester tester) {
  tester.view
    ..physicalSize = const Size(800, 1800)
    ..devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}
