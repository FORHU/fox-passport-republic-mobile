import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_template/core/errors/exceptions.dart';
import 'package:flutter_template/features/auth/presentation/controllers/auth_controller.dart';
import 'package:flutter_template/features/roles/data/role_application_repository.dart';
import 'package:flutter_template/features/roles/domain/provider_application.dart';
import 'package:flutter_template/features/roles/domain/role_application.dart';
import 'package:flutter_template/features/roles/domain/work_links.dart';
import 'package:flutter_template/features/roles/presentation/controllers/provider_application_controller.dart';
import 'package:flutter_template/features/roles/presentation/pages/provider_application_page.dart';
import 'package:flutter_template/l10n/generated/app_localizations.dart';
import 'package:flutter_template/shared/catalog/provider_specialties.dart';
import 'package:flutter_template/shared/location/device_locator.dart';
import 'package:flutter_template/shared/photos/photo_picker.dart';
import 'package:flutter_template/theme/app_theme.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockRepo extends Mock implements RoleApplicationRepository {}

// A real 1x1 PNG, so Image.memory can decode the thumbnails.
final Uint8List _png = base64Decode(
  'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNkYAAAAAYA'
  'AjCB0C8AAAAASUVORK5CYII=',
);

PickedPhoto _photo(String name) =>
    PickedPhoto(bytes: Uint8List.fromList(_png), name: name);

class _FakePicker implements PhotoPicker {
  @override
  Future<PickedPhoto?> pick() async => _photo('work.png');
}

/// Who is signed in, so a test can sign out.
class _User extends Notifier<String?> {
  @override
  String? build() => 'user-1';

  // A plain setter reads oddly next to the provider API.
  // ignore: use_setters_to_change_properties
  void set(String? id) => state = id;
}

final NotifierProvider<_User, String?> _signedIn =
    NotifierProvider<_User, String?>(_User.new);

class _FakeLocator implements DeviceLocator {
  LocateResult result = const LocateResult(
    LocateOutcome.ok,
    lat: 10.3157,
    lng: 123.8854,
  );
  DevicePlace place = const DevicePlace(
    city: 'Cebu City',
    province: 'Cebu',
    countryCode: 'PH',
  );

  @override
  Future<LocateResult> locate({bool prompt = true}) async => result;

  @override
  Future<DevicePlace> placeAt(double lat, double lng) async => place;
}

const _catalog = [
  ProviderSpecialty(slug: 'sound_system', name: 'Sound systems'),
  ProviderSpecialty(slug: 'lighting', name: 'Lighting'),
  ProviderSpecialty(slug: 'dj', name: 'DJ'),
];

void main() {
  late _MockRepo repo;
  late _FakeLocator locator;
  late ProviderContainer container;

  setUpAll(() => registerFallbackValue(const ProviderApplicationDraft()));

  setUp(() {
    repo = _MockRepo();
    locator = _FakeLocator();
    container = ProviderContainer(
      overrides: [
        roleApplicationRepositoryProvider.overrideWithValue(repo),
        deviceLocatorProvider.overrideWithValue(locator),
        currentUserIdProvider.overrideWith((ref) => ref.watch(_signedIn)),
        providerSpecialtiesProvider.overrideWith((ref) async => _catalog),
        photoPickerProvider.overrideWithValue(_FakePicker()),
      ],
    );
    addTearDown(container.dispose);
  });

  ProviderApplicationController c() =>
      container.read(providerApplicationProvider.notifier);
  ProviderApplicationDraft draft() =>
      container.read(providerApplicationProvider).draft;

  /// Everything but the agreement, ready for review.
  void fillAll() {
    c()
      ..edit(
        (d) => d.copyWith(
          businessName: 'Sound Gear Co.',
          basedIn: 'Cebu City, Cebu',
          travelRange: TravelRange.province,
          experience: '6',
        ),
      )
      ..toggle('sound_system')
      ..toggle('dj')
      ..setDescription('sound_system', 'PA systems for 50 to 500 guests')
      ..addPhoto('sound_system', _photo('a.png'))
      ..setDescription('dj', 'Weddings and parties')
      ..addPhoto('dj', _photo('b.png'));
    for (final doc in ProviderApplicationDraft.requiredDocuments) {
      c().setDocument(doc, _photo('${doc.name}.png'));
    }
  }

  group('ProviderApplicationController', () {
    test('the first category picked is the main one until another is starred',
        () {
      c()
        ..toggle('sound_system')
        ..toggle('dj');
      expect(draft().mainSpecialty, 'sound_system');

      c().makeMain('dj');
      expect(draft().mainSpecialty, 'dj');
      expect(draft().orderedSpecializations, ['dj', 'sound_system']);
    });

    test('dropping the main category passes it on; dropping all clears it', () {
      c()
        ..toggle('sound_system')
        ..toggle('dj')
        ..toggle('sound_system');
      expect(draft().specializations, ['dj']);
      expect(draft().mainSpecialty, 'dj');

      c().toggle('dj');
      expect(draft().specializations, isEmpty);
      expect(draft().mainSpecialty, isNull);
    });

    test('the location fills in city and province and keeps the position',
        () async {
      await c().useMyLocation();

      expect(draft().basedIn, 'Cebu City, Cebu');
      expect(draft().basedInPoint, (lat: 10.3157, lng: 123.8854));
      final data = draft().toData(const {});
      expect(data['basedInLat'], 10.3157);
      expect(data['basedInLng'], 123.8854);
      expect(container.read(providerApplicationProvider).locatedCount, 1);
    });

    test('typing the place afterwards drops the located position', () async {
      await c().useMyLocation();
      c().setBasedIn('Mandaue City, Cebu');

      expect(draft().basedIn, 'Mandaue City, Cebu');
      expect(draft().basedInPoint, isNull);
      expect(draft().toData(const {}).containsKey('basedInLat'), isFalse);
    });

    test('a refused or failed location says why and leaves the field alone',
        () async {
      c().setBasedIn('Cebu');
      locator.result = const LocateResult(LocateOutcome.denied);
      await c().useMyLocation();
      var state = container.read(providerApplicationProvider);
      expect(state.locateProblem, LocateOutcome.denied);
      expect(state.locating, isFalse);
      expect(draft().basedIn, 'Cebu');

      locator
        ..result = const LocateResult(LocateOutcome.ok, lat: 1, lng: 2)
        ..place = const DevicePlace();
      await c().useMyLocation();
      state = container.read(providerApplicationProvider);
      expect(state.locateProblem, LocateOutcome.failed);
      expect(draft().basedInPoint, isNull);
    });

    test('signing out clears the draft, ID photos included', () {
      fillAll();
      expect(draft().documents, isNotEmpty);

      container.read(_signedIn.notifier).set(null);

      expect(draft().documents, isEmpty);
      expect(draft().businessName, isEmpty);
      expect(
        container.read(providerApplicationProvider).step,
        ProviderApplyStep.intro,
      );
    });

    test('a category takes at most six photos', () {
      c().toggle('dj');
      for (var i = 0; i < 8; i++) {
        c().addPhoto('dj', _photo('$i.png'));
      }
      expect(draft().detailFor('dj').photos, hasLength(6));
    });

    test('each step is done only when its answers are', () {
      expect(draft().businessDone, isFalse);
      c().edit((d) => d.copyWith(businessName: 'X', basedIn: 'Cebu'));
      expect(draft().businessDone, isTrue);
      c().edit((d) => d.copyWith(experience: '101'));
      expect(draft().businessDone, isFalse);

      c().toggle('dj');
      expect(draft().categoriesDone, isTrue);
      expect(draft().detailsDone, isFalse);
      c().setDescription('dj', 'Weddings');
      expect(draft().detailsDone, isFalse, reason: 'needs a photo too');
      c().addPhoto('dj', _photo('a.png'));
      expect(draft().detailsDone, isTrue);
      expect(draft().documentsMissing, 5);
    });

    test('sends the wizard answers the API reads', () {
      fillAll();
      final data = draft().toData({
        'sound_system': ['f1'],
        'dj': ['f2'],
      });
      expect(data, {
        'businessName': 'Sound Gear Co.',
        'basedIn': 'Cebu City, Cebu',
        'travelRange': 'province',
        'experience': 6,
        'specializations': ['sound_system', 'dj'],
        'mainSpecialty': 'sound_system',
        'specialtyDetails': [
          {
            'slug': 'sound_system',
            'description': 'PA systems for 50 to 500 guests',
            'photoFileIds': ['f1'],
          },
          {
            'slug': 'dj',
            'description': 'Weddings and parties',
            'photoFileIds': ['f2'],
          },
        ],
      });
    });

    test('will not send before the terms are agreed', () async {
      fillAll();
      expect(await c().submit(), isFalse);
      verifyNever(() => repo.submitProvider(any()));
    });

    test('a sent application moves to the sent screen', () async {
      when(() => repo.submitProvider(any())).thenAnswer((_) async {});
      fillAll();
      c().edit((d) => d.copyWith(agreed: true));

      expect(await c().submit(), isTrue);
      verify(() => repo.submitProvider(any())).called(1);
      final state = container.read(providerApplicationProvider);
      expect(state.step, ProviderApplyStep.sent);
      expect(state.sentAt, isNotNull);
    });

    test('a refused application keeps the API message', () async {
      when(() => repo.submitProvider(any())).thenThrow(
        const ServerException('An application is already pending'),
      );
      fillAll();
      c().edit((d) => d.copyWith(agreed: true));

      expect(await c().submit(), isFalse);
      final state = container.read(providerApplicationProvider);
      expect(state.error, 'An application is already pending');
      expect(state.step, ProviderApplyStep.intro);
    });
  });

  group('the wizard', () {
    Future<void> open(WidgetTester tester) async {
      tester.view
        ..physicalSize = const Size(400, 1400)
        ..devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            theme: AppTheme.dark,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: const ProviderApplicationPage(),
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    Future<void> tapText(WidgetTester tester, String text) async {
      final f = find.text(text);
      await tester.ensureVisible(f);
      await tester.tap(f);
      await tester.pumpAndSettle();
    }

    testWidgets('starts with the four steps and goes to step 1', (
      tester,
    ) async {
      await open(tester);
      expect(
        find.text('Rent out gear or offer a service at events'),
        findsOneWidget,
      );
      for (final step in [
        'Your business',
        'Your categories',
        'About each category',
        'Documents',
      ]) {
        expect(find.text(step), findsOneWidget);
      }

      await tapText(tester, 'Start');
      expect(find.text('STEP 1 OF 4'), findsOneWidget);
    });

    testWidgets('step 1 waits for a name and where they are based', (
      tester,
    ) async {
      c().goTo(ProviderApplyStep.business);
      await open(tester);

      ElevatedButton next() => tester.widget<ElevatedButton>(
            find.widgetWithText(ElevatedButton, 'Next: categories'),
          );
      expect(next().onPressed, isNull);

      final fields = find.byType(TextFormField);
      await tester.enterText(fields.at(0), 'Sound Gear Co.');
      await tester.enterText(fields.at(1), 'Cebu City, Cebu');
      await tapText(tester, 'My province');
      await tester.pumpAndSettle();

      expect(next().onPressed, isNotNull);
      expect(draft().travelRange, TravelRange.province);
    });

    testWidgets('step 1 has a field per link and flags one in the wrong place',
        (tester) async {
      c().goTo(ProviderApplyStep.business);
      c().edit((d) => d.copyWith(businessName: 'X', basedIn: 'Cebu'));
      await open(tester);

      expect(find.textContaining('separated by commas'), findsNothing);
      for (final kind in WorkLinkKind.values) {
        expect(find.byKey(Key('work-link-${kind.name}')), findsOneWidget);
      }

      final instagram = find.byKey(const Key('work-link-instagram'));
      await tester.ensureVisible(instagram);
      await tester.enterText(instagram, 'facebook.com/soundgear');
      await tester.pumpAndSettle();
      expect(find.text("That link isn't on Instagram"), findsOneWidget);
      expect(
        tester
            .widget<ElevatedButton>(
              find.widgetWithText(ElevatedButton, 'Next: categories'),
            )
            .onPressed,
        isNull,
      );

      await tester.enterText(instagram, 'instagram.com/soundgear');
      await tester.pumpAndSettle();
      expect(find.text("That link isn't on Instagram"), findsNothing);
      expect(draft().portfolioLinks, ['https://instagram.com/soundgear']);
    });

    testWidgets('the location button fills where they are based', (
      tester,
    ) async {
      c().goTo(ProviderApplyStep.business);
      await open(tester);

      await tester.tap(find.byTooltip('Use my current location'));
      await tester.pumpAndSettle();

      expect(find.text('Cebu City, Cebu'), findsOneWidget);
      expect(draft().basedInPoint, isNotNull);
    });

    testWidgets('a refused location tells them how to turn it on', (
      tester,
    ) async {
      locator.result = const LocateResult(LocateOutcome.denied);
      c().goTo(ProviderApplyStep.business);
      await open(tester);

      await tester.tap(find.byTooltip('Use my current location'));
      await tester.pumpAndSettle();

      expect(
        find.text(
          'Location is off for this app. Turn it on in Settings to use it.',
        ),
        findsOneWidget,
      );
    });

    testWidgets('step 2 picks categories and stars the main one', (
      tester,
    ) async {
      c().goTo(ProviderApplyStep.categories);
      await open(tester);
      expect(find.text('Pick at least one'), findsOneWidget);

      await tapText(tester, 'Sound systems');
      await tapText(tester, 'DJ');
      expect(find.text('2 picked · Sound systems is your main'), findsOne);

      await tester.tap(find.byTooltip('Make DJ your main category'));
      await tester.pumpAndSettle();
      expect(find.text('2 picked · DJ is your main'), findsOne);
      expect(find.byTooltip('DJ is your main category'), findsOneWidget);
      expect(find.text('Next: about each one'), findsOneWidget);
    });

    testWidgets('step 3 needs a line and a photo for each category', (
      tester,
    ) async {
      c()
        ..toggle('sound_system')
        ..toggle('dj')
        ..goTo(ProviderApplyStep.details);
      await open(tester);

      expect(find.text('MAIN'), findsOneWidget);
      expect(find.text('Add a line and at least 1 photo'), findsOneWidget);

      await tester.enterText(find.byType(TextFormField), 'PA systems');
      await tester.tap(find.byTooltip('Add a photo'));
      await tester.pumpAndSettle();
      expect(draft().detailFor('sound_system').isDone, isTrue);

      await tapText(tester, 'DJ');
      await tester.enterText(find.byType(TextFormField), 'Weddings');
      await tester.tap(find.byTooltip('Add a photo'));
      await tester.pumpAndSettle();

      expect(find.text('Done · 1 photo'), findsOneWidget);
      expect(
        tester
            .widget<ElevatedButton>(
              find.widgetWithText(ElevatedButton, 'Next: documents'),
            )
            .onPressed,
        isNotNull,
      );
    });

    testWidgets('step 4 counts the documents still to add', (tester) async {
      c().goTo(ProviderApplyStep.documents);
      await open(tester);
      expect(find.text('5 documents still to add'), findsOneWidget);
      expect(find.text('Take'), findsOneWidget);
      expect(find.text('Upload'), findsNWidgets(4));

      c().setDocument(KycDocument.validId, _photo('id.png'));
      await tester.pumpAndSettle();
      expect(find.text('4 documents still to add'), findsOneWidget);
      expect(find.text('Replace'), findsOneWidget);
    });

    testWidgets('review sends once the terms are agreed, then shows it sent', (
      tester,
    ) async {
      when(() => repo.submitProvider(any())).thenAnswer((_) async {});
      fillAll();
      c().goTo(ProviderApplyStep.review);
      await open(tester);

      expect(find.text('Sound Gear Co.'), findsOneWidget);
      expect(find.text('Cebu City, Cebu · My province · 6 years'), findsOne);
      expect(find.text('All 5 added'), findsOneWidget);
      ElevatedButton send() => tester.widget<ElevatedButton>(
            find.widgetWithText(ElevatedButton, 'Send application'),
          );
      expect(send().onPressed, isNull);

      await tester.tap(find.byType(Checkbox));
      await tester.pumpAndSettle();
      await tapText(tester, 'Send application');

      verify(() => repo.submitProvider(any())).called(1);
      expect(find.text('Application sent'), findsOneWidget);
      expect(find.text('UNDER REVIEW'), findsOneWidget);
      expect(find.text('Sound systems'), findsOneWidget);
    });

    testWidgets('Edit on the review screen jumps back to that step', (
      tester,
    ) async {
      fillAll();
      c().goTo(ProviderApplyStep.review);
      await open(tester);

      await tester.tap(find.bySemanticsLabel('Edit Categories'));
      await tester.pumpAndSettle();
      expect(find.text('STEP 2 OF 4'), findsOneWidget);
    });
  });
}
