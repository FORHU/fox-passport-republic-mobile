import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_template/features/spaces/data/spaces_repository.dart';
import 'package:flutter_template/features/spaces/domain/event_detail.dart';
import 'package:flutter_template/features/spaces/domain/event_draft.dart';
import 'package:flutter_template/features/spaces/domain/partner_models.dart';
import 'package:flutter_template/features/spaces/domain/space_models.dart';
import 'package:flutter_template/features/spaces/domain/venue_detail.dart';
import 'package:flutter_template/features/spaces/presentation/pages/event_studio_page.dart';
import 'package:flutter_template/l10n/generated/app_localizations.dart';
import 'package:flutter_template/shared/location/device_locator.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';

class _MockRepo extends Mock implements SpacesRepository {}

class _FakeLocator implements DeviceLocator {
  @override
  Future<LocateResult> locate({bool prompt = true}) async =>
      const LocateResult(LocateOutcome.failed);

  @override
  Future<DevicePlace> placeAt(double lat, double lng) async =>
      const DevicePlace();
}

const _skyHall = PackageItem(
  id: 'v1',
  name: 'Sky Hall',
  kind: PackageKind.venue,
  cost: 50000,
  icon: 'location_city',
  city: 'Baguio',
  state: 'Benguet',
  country: 'Philippines',
);

const _barn = PackageItem(
  id: 'v2',
  name: 'Old Barn',
  kind: PackageKind.venue,
  cost: 20000,
  icon: 'location_city',
  city: 'Sagada',
);

const _hotel = PackageItem(
  id: 'v3',
  name: 'Grand Hotel',
  kind: PackageKind.venue,
  cost: 90000,
  icon: 'location_city',
);

const _sound = PackageItem(
  id: 'a1',
  name: 'Sound system',
  kind: PackageKind.asset,
  cost: 5000,
  icon: 'speaker',
);

const _band = PackageItem(
  id: 'a2',
  name: 'Live band',
  kind: PackageKind.talent,
  cost: 12000,
  icon: 'music_note',
);

const _cake = PackageItem(
  id: 's2',
  name: 'Cake catering',
  kind: PackageKind.service,
  cost: 3000,
  icon: 'restaurant',
  savedAsService: true,
);

Partner _partner(String venueId, String status) => Partner.tryParse(
      {
        'id': 'p-$venueId',
        'status': status,
        'initiatedBy': 'eventFoxer',
        'venue': {'id': venueId, 'name': venueId},
        'eventFoxer': {'id': 'e1', 'name': 'Ada'},
      },
      PartnerSide.eventFoxer,
    )!;

String _words(int n) => List.filled(n, 'word').join(' ');

void main() {
  late _MockRepo repo;
  var owned = <SpaceListing>[];
  var partners = const PartnerLists();

  setUpAll(() {
    registerFallbackValue(const EventDraft());
    registerFallbackValue(<PackageItem>[]);
  });

  setUp(() {
    repo = _MockRepo();
    owned = const [
      SpaceListing(id: 'v1', name: 'Sky Hall', status: 'available'),
    ];
    partners = PartnerLists(asEventFoxer: [_partner('v3', 'pending')]);

    when(() => repo.cancellationPolicies()).thenAnswer(
      (_) async => const [CancellationPolicyOption(id: 'p1', name: 'Flexible')],
    );
    when(() => repo.countries()).thenAnswer((_) async => const []);
    when(() => repo.createEvent(any())).thenAnswer((_) async => 't1');
    when(() => repo.updateEvent(any(), any())).thenAnswer((_) async {});
    when(() => repo.submitEvent(any())).thenAnswer((_) async {});
    when(
      () => repo.syncEventPackage(any(), any(), before: any(named: 'before')),
    ).thenAnswer((_) async => const <PackageProblem>[]);
    // The first page is asked for by number.
    // ignore: avoid_redundant_argument_values
    when(() => repo.venueChoices(query: any(named: 'query'), page: 1))
        .thenAnswer(
      (_) async => (items: const [_skyHall, _barn, _hotel], total: 3),
    );
    // The first page is asked for by number.
    // ignore: avoid_redundant_argument_values
    when(() => repo.assetChoices(page: 1)).thenAnswer(
      (_) async => (items: const [_sound, _band], total: 2),
    );
    // The first page is asked for by number.
    // ignore: avoid_redundant_argument_values
    when(() => repo.serviceChoices(page: 1)).thenAnswer(
      (_) async => (items: const [_cake], total: 1),
    );
  });

  Future<void> pump(WidgetTester tester, {String? eventId}) async {
    tester.view
      ..physicalSize = const Size(900, 2600)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (_, __) => const Scaffold(body: Text('HOME')),
        ),
        GoRoute(
          path: '/studio',
          builder: (_, __) => EventStudioPage(eventId: eventId),
        ),
      ],
    );
    await tester.pumpWidget(
      ProviderScope(
        retry: (_, __) => null,
        overrides: [
          spacesRepositoryProvider.overrideWithValue(repo),
          deviceLocatorProvider.overrideWithValue(_FakeLocator()),
          myVenuesProvider.overrideWith((ref) async => owned),
          myEventsProvider.overrideWith((ref) async => const []),
          partnersProvider.overrideWith((ref) async => partners),
        ],
        child: MaterialApp.router(
          routerConfig: router,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
        ),
      ),
    );
    unawaited(router.push('/studio'));
    await tester.pumpAndSettle();
  }

  Future<void> goToStep(WidgetTester tester, String label) async {
    await tester.tap(find.textContaining(label).first);
    await tester.pumpAndSettle();
  }

  Future<void> title(WidgetTester tester, String text) async {
    await tester.enterText(find.widgetWithText(TextField, 'Event title'), text);
    await tester.pump();
  }

  group('the basics', () {
    testWidgets('a new event starts with the web defaults', (tester) async {
      await pump(tester);

      expect(find.text('New event'), findsOneWidget);
      expect(find.text('Event title'), findsWidgets);
      for (final c in ['Corporate', 'Birthday', 'Wedding', 'Social', 'Other']) {
        expect(find.text(c), findsOneWidget);
      }
      expect(find.text('0 / 500 words'), findsOneWidget);
      expect(
        tester
            .widget<TextField>(find.widgetWithText(TextField, 'Max attendees'))
            .controller!
            .text,
        '100',
      );
      expect(find.text('Back'), findsNothing);
    });

    testWidgets('the word counter follows what is typed', (tester) async {
      await pump(tester);

      await tester.enterText(
        find.widgetWithText(TextField, 'Description'),
        _words(40),
      );
      await tester.pump();

      expect(find.textContaining('40 / 500 words'), findsOneWidget);
      expect(find.textContaining('60 more to reach 100'), findsOneWidget);

      await tester.enterText(
        find.widgetWithText(TextField, 'Description'),
        _words(120),
      );
      await tester.pump();
      expect(find.text('120 / 500 words'), findsOneWidget);
      expect(find.textContaining('more to reach'), findsNothing);
    });

    testWidgets('Other asks for its own label', (tester) async {
      await pump(tester);
      expect(find.text('Please specify the event category'), findsNothing);

      await tester.tap(find.text('Other'));
      await tester.pumpAndSettle();

      expect(find.text('Please specify the event category'), findsOneWidget);
    });

    testWidgets('a cancellation policy can be chosen', (tester) async {
      await pump(tester);

      expect(find.text('Cancellation policy'), findsOneWidget);
      await tester.tap(find.text('Flexible'));
      await tester.pumpAndSettle();

      expect(
        tester
            .widget<ChoiceChip>(find.widgetWithText(ChoiceChip, 'Flexible'))
            .selected,
        isTrue,
      );
    });
  });

  group('the word limit', () {
    TextEditingValue value(String text) => TextEditingValue(text: text);

    test('lets a text up to 500 words through', () {
      const formatter = WordLimitFormatter(500);
      final ok = value(_words(500));

      expect(formatter.formatEditUpdate(value(_words(499)), ok), ok);
    });

    test('refuses typing that would pass 500 words', () {
      const formatter = WordLimitFormatter(500);
      final before = value(_words(500));

      expect(
        formatter.formatEditUpdate(before, value('${_words(500)} more')),
        before,
      );
    });
  });

  group('the package', () {
    Future<void> openPackage(WidgetTester tester) =>
        goToStep(tester, 'Package');

    testWidgets('starts with no venue and nothing else', (tester) async {
      await pump(tester);
      await openPackage(tester);

      expect(find.text('Core package'), findsOneWidget);
      expect(find.text('Choose a venue'), findsOneWidget);
      expect(find.text('Nothing else added yet.'), findsOneWidget);
      expect(find.text('Package cost'), findsOneWidget);
    });

    testWidgets('a venue the host runs can be added, and shows its price', (
      tester,
    ) async {
      await pump(tester);
      await openPackage(tester);

      await tester.tap(find.text('Choose a venue'));
      await tester.pumpAndSettle();
      expect(find.text('Sky Hall'), findsOneWidget);
      expect(find.text('Approved'), findsOneWidget);

      await tester.tap(find.text('Sky Hall'));
      await tester.pumpAndSettle();
      expect(find.text('Added Sky Hall to your package'), findsOneWidget);
    });

    testWidgets('a venue with no affiliation says to apply first', (
      tester,
    ) async {
      await pump(tester);
      await openPackage(tester);
      await tester.tap(find.text('Choose a venue'));
      await tester.pumpAndSettle();

      expect(find.text('Apply first'), findsOneWidget);
      await tester.tap(find.text('Old Barn'));
      await tester.pumpAndSettle();

      expect(
        find.text(
          'Apply to this venue first. '
          'You need an approved affiliation to host here.',
        ),
        findsOneWidget,
      );
    });

    testWidgets('a venue still pending says so', (tester) async {
      await pump(tester);
      await openPackage(tester);
      await tester.tap(find.text('Choose a venue'));
      await tester.pumpAndSettle();

      expect(find.text('Pending'), findsOneWidget);
      await tester.tap(find.text('Grand Hotel'));
      await tester.pumpAndSettle();

      expect(
        find.text(
          'Your affiliation with this venue is still pending approval.',
        ),
        findsOneWidget,
      );
    });

    testWidgets('only live venues the API sent are listed, with their town', (
      tester,
    ) async {
      await pump(tester);
      await openPackage(tester);
      await tester.tap(find.text('Choose a venue'));
      await tester.pumpAndSettle();

      expect(find.text('Baguio, Benguet'), findsOneWidget);
      expect(find.text('Sagada'), findsOneWidget);
    });

    testWidgets('talent, services and equipment are listed apart', (
      tester,
    ) async {
      await pump(tester);
      await openPackage(tester);
      await tester.tap(find.text('Add to package'));
      await tester.pumpAndSettle();

      // Opens on Talent.
      expect(find.text('Live band'), findsOneWidget);
      expect(find.text('Sound system'), findsNothing);

      await tester.tap(find.widgetWithText(ChoiceChip, 'Equipment'));
      await tester.pumpAndSettle();
      expect(find.text('Sound system'), findsOneWidget);
      expect(find.text('Live band'), findsNothing);

      await tester.tap(find.widgetWithText(ChoiceChip, 'Services'));
      await tester.pumpAndSettle();
      expect(find.text('Cake catering'), findsOneWidget);
    });

    testWidgets('a supply list can be searched', (tester) async {
      await pump(tester);
      await openPackage(tester);
      await tester.tap(find.text('Add to package'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(ChoiceChip, 'Services'));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField).last, 'zzz');
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pumpAndSettle();

      expect(find.text('Cake catering'), findsNothing);
      expect(find.text('Nothing found.'), findsOneWidget);
    });

    testWidgets(
        'an item added shows in the package, with the same price on the cost', (
      tester,
    ) async {
      await pump(tester);
      await openPackage(tester);
      await tester.tap(find.text('Choose a venue'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Sky Hall'));
      await tester.pumpAndSettle();
      await tester.tapAt(const Offset(10, 10));
      await tester.pumpAndSettle();

      expect(find.text('Sky Hall'), findsOneWidget);
      // The venue is the whole cost so far.
      expect(find.text('₱50,000'), findsWidgets);
      // 20% on top is the web's starting margin.
      expect(find.text('₱60,000'), findsOneWidget);
    });

    testWidgets('an agreed price replaces the listed one', (tester) async {
      await pump(tester);
      await openPackage(tester);
      await tester.tap(find.text('Choose a venue'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Sky Hall'));
      await tester.pumpAndSettle();
      await tester.tapAt(const Offset(10, 10));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Sky Hall'));
      await tester.pumpAndSettle();
      expect(find.text('Edit Sky Hall'), findsOneWidget);
      await tester.enterText(
        find.widgetWithText(TextField, 'Agreed price'),
        '40000',
      );
      await tester.pump();
      await tester.tap(find.text('Done'));
      await tester.pumpAndSettle();

      expect(find.text('₱40,000'), findsWidgets);
      expect(find.text('Listed: ₱50,000'), findsOneWidget);
      // 20% on 40,000.
      expect(find.text('₱48,000'), findsOneWidget);
    });

    testWidgets('an item can be marked optional, and taken out', (
      tester,
    ) async {
      await pump(tester);
      await openPackage(tester);
      await tester.tap(find.text('Add to package'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Live band'));
      await tester.pumpAndSettle();
      await tester.tapAt(const Offset(10, 10));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Live band'));
      await tester.pumpAndSettle();
      await tester.tap(find.byType(Switch));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Done'));
      await tester.pumpAndSettle();
      expect(find.text('Optional'), findsOneWidget);

      await tester.tap(find.text('Live band'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Remove from package'));
      await tester.pumpAndSettle();
      expect(find.text('Live band'), findsNothing);
      expect(find.text('Nothing else added yet.'), findsOneWidget);
    });

    testWidgets('the margin changes the suggested price', (tester) async {
      await pump(tester);
      await openPackage(tester);
      await tester.tap(find.text('Choose a venue'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Sky Hall'));
      await tester.pumpAndSettle();
      await tester.tapAt(const Offset(10, 10));
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(ChoiceChip, '40%'));
      await tester.pumpAndSettle();

      expect(find.text('₱70,000'), findsOneWidget);
    });
  });

  group('the review', () {
    Future<void> fillIn(WidgetTester tester) async {
      await title(tester, 'Bonfire');
      await tester.tap(find.text('Social'));
      await tester.pumpAndSettle();
      await goToStep(tester, 'Package');
      await tester.tap(find.text('Choose a venue'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Sky Hall'));
      await tester.pumpAndSettle();
      await tester.tapAt(const Offset(10, 10));
      await tester.pumpAndSettle();
      await goToStep(tester, 'Review');
    }

    testWidgets('lists what is required and what is only recommended', (
      tester,
    ) async {
      await pump(tester);
      await goToStep(tester, 'Review');

      expect(find.text('Event title'), findsOneWidget);
      expect(find.text('Category selected'), findsOneWidget);
      expect(find.text('Approved venue attached'), findsOneWidget);
      expect(find.text('5 photos'), findsOneWidget);
      expect(find.text('100+ word description'), findsOneWidget);
      expect(find.text('Required'), findsNWidgets(3));
      expect(find.text('Recommended'), findsNWidgets(2));
      expect(find.text('0% ready'), findsOneWidget);
    });

    testWidgets('cannot be sent for review until it is ready', (tester) async {
      await pump(tester);
      await goToStep(tester, 'Review');

      final send = tester.widget<ElevatedButton>(
        find.widgetWithText(ElevatedButton, 'Send for review'),
      );
      expect(send.onPressed, isNull);
      expect(find.text('Save as draft'), findsOneWidget);
    });

    testWidgets('can be sent once it has a title, a category and a venue', (
      tester,
    ) async {
      await pump(tester);
      await fillIn(tester);

      expect(find.text('60% ready'), findsOneWidget);
      final send = tester.widget<ElevatedButton>(
        find.widgetWithText(ElevatedButton, 'Send for review'),
      );
      expect(send.onPressed, isNotNull);

      await tester.tap(find.text('Send for review'));
      await tester.pumpAndSettle();

      verify(() => repo.createEvent(any())).called(1);
      verify(() => repo.submitEvent('t1')).called(1);
      // Sent for review: back out of the studio.
      expect(find.text('HOME'), findsOneWidget);
    });

    testWidgets('saving a draft stays on the page and says so', (tester) async {
      await pump(tester);
      await fillIn(tester);

      await tester.tap(find.text('Save as draft'));
      await tester.pumpAndSettle();

      verify(() => repo.createEvent(any())).called(1);
      verifyNever(() => repo.submitEvent(any()));
      expect(find.text('Draft saved.'), findsOneWidget);
      expect(find.textContaining('Review'), findsWidgets);
    });

    testWidgets('a draft needs a title even to be saved', (tester) async {
      await pump(tester);
      await goToStep(tester, 'Review');

      await tester.tap(find.text('Save as draft'));
      await tester.pumpAndSettle();

      expect(find.text('Add an event title before saving.'), findsOneWidget);
      verifyNever(() => repo.createEvent(any()));
    });

    testWidgets('Other must say what it is before it can be sent', (
      tester,
    ) async {
      await pump(tester);
      await title(tester, 'Market');
      await tester.tap(find.text('Other'));
      await tester.pumpAndSettle();
      await goToStep(tester, 'Package');
      await tester.tap(find.text('Choose a venue'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Sky Hall'));
      await tester.pumpAndSettle();
      await tester.tapAt(const Offset(10, 10));
      await tester.pumpAndSettle();
      await goToStep(tester, 'Review');

      expect(find.text('Say what kind of event it is'), findsOneWidget);
      expect(
        tester
            .widget<ElevatedButton>(
              find.widgetWithText(ElevatedButton, 'Send for review'),
            )
            .onPressed,
        isNull,
      );
    });

    testWidgets('an item the API refused is listed, and nothing is sent', (
      tester,
    ) async {
      when(
        () => repo.syncEventPackage(any(), any(), before: any(named: 'before')),
      ).thenAnswer(
        (_) async => const [
          PackageProblem('Sky Hall', 'you need an approved affiliation'),
        ],
      );
      await pump(tester);
      await fillIn(tester);

      await tester.tap(find.text('Send for review'));
      await tester.pumpAndSettle();

      verifyNever(() => repo.submitEvent(any()));
      expect(
        find.text('Sky Hall: you need an approved affiliation'),
        findsOneWidget,
      );
      expect(
        find.textContaining('Saved, but some items could not be added'),
        findsWidgets,
      );
    });

    testWidgets('a refusal from the API is shown in its own words', (
      tester,
    ) async {
      when(() => repo.createEvent(any())).thenThrow(Exception('boom'));
      await pump(tester);
      await fillIn(tester);

      await tester.tap(find.text('Save as draft'));
      await tester.pumpAndSettle();

      expect(find.text("We couldn't save that. Try again."), findsOneWidget);
    });
  });

  group('editing a saved event', () {
    EventDetail saved(String status) => EventDetail(
          id: 't1',
          status: status,
          draft: const EventDraft(
            title: 'Bonfire',
            category: 'Social',
            description: 'A fun night',
            maxAttendees: 80,
            items: [_skyHall],
          ),
        );

    testWidgets('opens filled in', (tester) async {
      when(() => repo.eventDetail('t1'))
          .thenAnswer((_) async => saved('draft'));
      await pump(tester, eventId: 't1');

      expect(find.text('Edit event'), findsOneWidget);
      expect(
        tester
            .widget<TextField>(find.widgetWithText(TextField, 'Event title'))
            .controller!
            .text,
        'Bonfire',
      );
      expect(
        tester
            .widget<TextField>(find.widgetWithText(TextField, 'Max attendees'))
            .controller!
            .text,
        '80',
      );
    });

    testWidgets('a draft can be sent for review', (tester) async {
      when(() => repo.eventDetail('t1'))
          .thenAnswer((_) async => saved('draft'));
      await pump(tester, eventId: 't1');
      await goToStep(tester, 'Review');

      await tester.tap(find.text('Send for review'));
      await tester.pumpAndSettle();

      verify(() => repo.updateEvent('t1', any())).called(1);
      verify(() => repo.submitEvent('t1')).called(1);
      verifyNever(() => repo.createEvent(any()));
    });

    testWidgets('an event already sent can only have its changes saved', (
      tester,
    ) async {
      when(() => repo.eventDetail('t1'))
          .thenAnswer((_) async => saved('pending'));
      await pump(tester, eventId: 't1');
      await goToStep(tester, 'Review');

      expect(find.text('Send for review'), findsNothing);
      expect(find.text('Save as draft'), findsNothing);
      expect(
        find.text(
          'This event has already been sent for review, '
          'so you can only save changes.',
        ),
        findsOneWidget,
      );

      await tester.tap(find.text('Save changes'));
      await tester.pumpAndSettle();

      verify(() => repo.updateEvent('t1', any())).called(1);
      verifyNever(() => repo.submitEvent(any()));
      expect(find.text('Changes saved.'), findsOneWidget);
    });

    testWidgets('says so when the event will not load', (tester) async {
      when(() => repo.eventDetail('t1')).thenThrow(Exception('down'));
      await pump(tester, eventId: 't1');

      expect(find.text('Try again'), findsOneWidget);
      expect(find.text('Next'), findsNothing);
    });
  });

  group('the photos', () {
    testWidgets('say up to five, and offer a way to add', (tester) async {
      await pump(tester);
      await goToStep(tester, 'Photos');

      expect(find.text('Up to 5 photos. Five is recommended.'), findsOneWidget);
      expect(find.text('Add photo'), findsOneWidget);
    });
  });

  group('the steps', () {
    testWidgets('Next walks to the review and Back returns', (tester) async {
      await pump(tester);

      for (var i = 0; i < 4; i++) {
        await tester.tap(find.text('Next'));
        await tester.pumpAndSettle();
      }
      expect(find.text('0% ready'), findsOneWidget);
      expect(find.text('Next'), findsNothing);

      await tester.tap(find.text('Back'));
      await tester.pumpAndSettle();
      expect(find.text('Core package'), findsOneWidget);
    });

    testWidgets('the location step explains that a venue fills it in', (
      tester,
    ) async {
      await pump(tester);
      await goToStep(tester, 'Location');

      expect(
        find.text(
          'Where the event takes place. '
          'Choosing a venue fills this in for you.',
        ),
        findsOneWidget,
      );
    });

    testWidgets('adding a venue fills in the place', (tester) async {
      await pump(tester);
      await goToStep(tester, 'Package');
      await tester.tap(find.text('Choose a venue'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Sky Hall'));
      await tester.pumpAndSettle();
      await tester.tapAt(const Offset(10, 10));
      await tester.pumpAndSettle();

      await goToStep(tester, 'Location');

      // The lists did not load in this test, so the place is plain fields.
      expect(
        tester
            .widget<TextField>(find.widgetWithText(TextField, 'City'))
            .controller!
            .text,
        'Baguio',
      );
    });
  });

  test('the clipboard is not used', () {
    // Guards against a paste being able to slip past the word limit.
    expect(const WordLimitFormatter(500), isA<TextInputFormatter>());
  });
}
