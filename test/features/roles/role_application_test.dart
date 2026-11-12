import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_template/core/errors/exceptions.dart';
import 'package:flutter_template/features/roles/data/role_application_repository.dart';
import 'package:flutter_template/features/roles/domain/role_application.dart';
import 'package:flutter_template/features/roles/presentation/controllers/role_application_controller.dart';
import 'package:flutter_template/features/roles/presentation/pages/role_application_page.dart';
import 'package:flutter_template/l10n/generated/app_localizations.dart';
import 'package:flutter_template/routes/route_names.dart';
import 'package:flutter_template/shared/catalog/provider_specialties.dart';
import 'package:flutter_template/shared/photos/photo_picker.dart';
import 'package:flutter_template/theme/app_theme.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockRepo extends Mock implements RoleApplicationRepository {}

class _FakePicker implements PhotoPicker {
  @override
  Future<PickedPhoto?> pick() async =>
      PickedPhoto(bytes: Uint8List.fromList([1]), name: 'scan.jpg');
}

PickedPhoto _photo(String name) =>
    PickedPhoto(bytes: Uint8List.fromList([1, 2]), name: name);

// The five documents a Foxer gives.
Map<KycDocument, PickedPhoto> _allDocuments() => {
      for (final d in KycDocument.values)
        if (d != KycDocument.backgroundClearance) d: _photo('${d.name}.jpg'),
    };

// The three documents an Organizer gives.
Map<KycDocument, PickedPhoto> _organizerDocuments() => {
      for (final d in const [
        KycDocument.validId,
        KycDocument.backgroundClearance,
        KycDocument.selfie,
      ])
        d: _photo('${d.name}.jpg'),
    };

const _catalog = [
  ProviderSpecialty(slug: 'photography', name: 'Photography'),
  ProviderSpecialty(slug: 'sound_system', name: 'Sound system'),
];

void main() {
  late _MockRepo repo;

  setUpAll(() {
    registerFallbackValue(
      const RoleApplicationDraft(roleType: 'providerFoxer'),
    );
  });

  setUp(() => repo = _MockRepo());

  group('RoleApplicationDraft', () {
    test(
        'a provider application sends business name, asset/service types, and options',
        () {
      final provider = RoleApplicationDraft(
        roleType: 'providerFoxer',
        businessName: 'Apex Audio & Staging',
        types: 'Speakers, DJ Sets',
        experience: '5',
        nbiNumber: '987654',
        portfolio: 'https://apex.test',
        tinNumber: '123456789',
        specializations: const ['sound_system', 'dj'],
        documents: _allDocuments(),
      );
      expect(provider.toData(), {
        'businessName': 'Apex Audio & Staging',
        'assetTypes': ['Speakers', 'DJ Sets'],
        'serviceTypes': ['Speakers', 'DJ Sets'],
        'experience': 5,
        'nbiClearanceIdNumber': '987654',
        'portfolioUrls': ['https://apex.test'],
        'tinNumber': '123456789',
        'specializations': ['sound_system', 'dj'],
      });
      expect(provider.isComplete, isTrue);
      expect(provider.copyWith(businessName: '').isComplete, isFalse);
      expect(provider.copyWith(types: '').isComplete, isFalse);
    });

    test('each document goes under the name the API reads', () {
      final form = RoleApplicationDraft(
        roleType: 'providerFoxer',
        documents: _allDocuments(),
      ).toForm();

      expect(form.fields.map((f) => f.key), containsAll(['roleType', 'data']));
      expect(
        form.files.map((f) => f.key).toSet(),
        {'validId1', 'nbiFile', 'tinIdFile', 'birPermitFile', 'selfieFile'},
      );
    });

    test('is complete only with the details and every document', () {
      final provider = RoleApplicationDraft(
        roleType: 'providerFoxer',
        types: 'Speakers',
        businessName: 'Loud Co',
        specializations: const ['dj'],
        documents: _allDocuments(),
      );
      // Experience and an NBI number are optional for a Provider.
      expect(provider.isComplete, isTrue);
      expect(provider.copyWith(businessName: '').isComplete, isFalse);
      expect(provider.copyWith(types: ' , ').isComplete, isFalse);
      expect(
        provider.copyWith(specializations: const []).isComplete,
        isFalse,
      );
      expect(
        RoleApplicationDraft.maxSpecializationsFor('providerFoxer'),
        isNull,
      );
      expect(RoleApplicationDraft.maxSpecializationsFor('venueFoxer'), 3);
      expect(
        provider
            .copyWith(
              documents: {...provider.documents}..remove(KycDocument.selfie),
            )
            .isComplete,
        isFalse,
      );
    });

    test('numbers keep their digits and no more than the API takes', () {
      expect(RoleApplicationDraft.digits('12-34 56', 18), '123456');
      expect(RoleApplicationDraft.digits('1234567890123', 9), '123456789');
    });

    test('a venue is sent its name, contact, address and categories', () {
      final venue = RoleApplicationDraft(
        roleType: 'venueFoxer',
        businessName: ' The Neon Lounge ',
        contactNumber: ' 0917 000 0000 ',
        address: ' 123 Makati Ave ',
        tinNumber: '123',
        specializations: const ['hotel', 'garden'],
        documents: _allDocuments(),
      );
      expect(venue.toData(), {
        'businessName': 'The Neon Lounge',
        'contactNumber': '0917 000 0000',
        'address': '123 Makati Ave',
        'tinNumber': '123',
        'specializations': ['hotel', 'garden'],
      });
      expect(
        venue.copyWith(description: ' Rooftop ').toData()['description'],
        'Rooftop',
      );
      expect(specializationOptions('venueFoxer'), contains('beach_resort'));
    });

    test('a venue needs a name, contact, address, TIN and every document', () {
      final venue = RoleApplicationDraft(
        roleType: 'venueFoxer',
        businessName: 'Lounge',
        contactNumber: '1',
        address: 'Makati',
        tinNumber: '1',
        documents: _allDocuments(),
      );
      // No services, experience or NBI number are asked of a venue.
      expect(venue.isComplete, isTrue);
      expect(venue.copyWith(businessName: ' ').isComplete, isFalse);
      expect(venue.copyWith(contactNumber: '').isComplete, isFalse);
      expect(venue.copyWith(address: '').isComplete, isFalse);
      expect(venue.copyWith(tinNumber: '').isComplete, isFalse);
      expect(venue.copyWith(documents: const {}).isComplete, isFalse);
    });

    test('an event application is sent the way the web sends it', () {
      final event = RoleApplicationDraft(
        roleType: 'eventFoxer',
        bio: ' Ten years of weddings ',
        city: ' Makati ',
        state: 'Metro Manila',
        country: 'Philippines',
        experience: '10',
        specializations: const ['wedding', 'corporate'],
        documents: _allDocuments(),
      );
      expect(event.toData(), {
        'bio': 'Ten years of weddings',
        'location': 'Makati, Metro Manila, Philippines',
        'experience': '10',
        'specializations': ['wedding', 'corporate'],
      });
      // Experience is optional and left out when blank; a blank state is
      // skipped in the location.
      final bare = event.copyWith(experience: '', state: '');
      expect(bare.toData().containsKey('experience'), isFalse);
      expect(bare.toData()['location'], 'Makati, Philippines');
      expect(specializationOptions('eventFoxer'), contains('birthday'));
    });

    test('an event needs a bio, a city, a country and every document', () {
      final event = RoleApplicationDraft(
        roleType: 'eventFoxer',
        bio: 'Planner',
        city: 'Cebu',
        country: 'Philippines',
        documents: _allDocuments(),
      );
      // No services, NBI number or TIN are asked of an event application.
      expect(event.isComplete, isTrue);
      expect(event.copyWith(bio: ' ').isComplete, isFalse);
      expect(event.copyWith(city: '').isComplete, isFalse);
      expect(event.copyWith(country: '').isComplete, isFalse);
      expect(event.copyWith(documents: const {}).isComplete, isFalse);
    });

    test('the portfolio file is optional and goes under its own name', () {
      final event = RoleApplicationDraft(
        roleType: 'eventFoxer',
        documents: _allDocuments(),
      );
      expect(
        event.toForm().files.map((f) => f.key),
        isNot(contains('portfolioFile')),
      );
      final withPortfolio = event.copyWith(portfolioFile: _photo('cv.jpg'));
      expect(
        withPortfolio.toForm().files.map((f) => f.key),
        contains('portfolioFile'),
      );
      expect(
        withPortfolio.copyWith(clearPortfolioFile: true).portfolioFile,
        isNull,
      );
    });

    test('an organizer application is sent the way the web sends it', () {
      final organizer = RoleApplicationDraft(
        roleType: 'organizer',
        bio: ' Ran 40 weddings ',
        city: 'Makati',
        state: 'Metro Manila',
        country: 'Philippines',
        experience: '6',
        specializations: const ['wedding', 'hotel'],
        documents: _organizerDocuments(),
      );
      expect(organizer.toData(), {
        'bio': 'Ran 40 weddings',
        'location': 'Makati, Metro Manila, Philippines',
        'experience': 6,
        'specializations': ['wedding', 'hotel'],
      });
      expect(specializationOptions('organizer'), contains('beach_resort'));
      expect(specializationOptions('organizer'), contains('corporate'));
    });

    test('an organizer needs a bio, a place, experience and three documents',
        () {
      final organizer = RoleApplicationDraft(
        roleType: 'organizer',
        bio: 'Planner',
        city: 'Cebu',
        country: 'Philippines',
        experience: '0',
        documents: _organizerDocuments(),
      );
      // No NBI number, TIN, BIR permit or services are asked of an organizer,
      // and none of those documents is needed.
      expect(organizer.isComplete, isTrue);
      expect(organizer.requiredDocuments, [
        KycDocument.validId,
        KycDocument.backgroundClearance,
        KycDocument.selfie,
      ]);
      expect(organizer.copyWith(bio: ' ').isComplete, isFalse);
      expect(organizer.copyWith(city: '').isComplete, isFalse);
      expect(organizer.copyWith(country: '').isComplete, isFalse);
      expect(organizer.copyWith(experience: '').isComplete, isFalse);
      expect(organizer.copyWith(experience: '101').isComplete, isFalse);
      expect(
        organizer
            .copyWith(
              documents: {...organizer.documents}
                ..remove(KycDocument.backgroundClearance),
            )
            .isComplete,
        isFalse,
      );
    });

    test('an organizer sends the background clearance under its own name', () {
      final form = RoleApplicationDraft(
        roleType: 'organizer',
        documents: _organizerDocuments(),
      ).toForm();

      expect(
        form.files.map((f) => f.key).toSet(),
        {'validId1', 'backgroundClearanceFile', 'selfieFile'},
      );
    });

    test('provider, venue, event and organizer apply from the phone', () {
      expect(
        appliesInApp,
        {'providerFoxer', 'venueFoxer', 'eventFoxer', 'organizer'},
      );
      expect(
        RouteNames.roleApply('providerFoxer'),
        '/roles/apply/providerFoxer',
      );
    });
  });

  group('the controller', () {
    ProviderContainer container(String role) {
      final c = ProviderContainer(
        overrides: [
          roleApplicationRepositoryProvider.overrideWithValue(repo),
        ],
      );
      addTearDown(c.dispose);
      c.listen(roleApplicationProvider(role), (_, __) {});
      return c;
    }

    test('a Provider can pick any number and lets one go', () {
      final c = container('providerFoxer');
      final app = c.read(roleApplicationProvider('providerFoxer').notifier)
        ..toggleSpecialization('design')
        ..toggleSpecialization('catering')
        ..toggleSpecialization('service_staff')
        ..toggleSpecialization('other');

      List<String> picked() => c
          .read(roleApplicationProvider('providerFoxer'))
          .draft
          .specializations;
      expect(picked(), ['design', 'catering', 'service_staff', 'other']);

      app.toggleSpecialization('catering');
      expect(picked(), ['design', 'service_staff', 'other']);
    });

    test('other roles keep to three', () {
      final c = container('venueFoxer');
      final app = c.read(roleApplicationProvider('venueFoxer').notifier)
        ..toggleSpecialization('a')
        ..toggleSpecialization('b')
        ..toggleSpecialization('c')
        ..toggleSpecialization('d');

      expect(
        c.read(roleApplicationProvider('venueFoxer')).draft.specializations,
        ['a', 'b', 'c'],
      );
      app.toggleSpecialization('a');
    });

    test('will not send an incomplete application', () async {
      final c = container('providerFoxer');

      final ok = await c
          .read(roleApplicationProvider('providerFoxer').notifier)
          .submit();

      expect(ok, isFalse);
      verifyNever(() => repo.submit(any()));
    });

    test('sends it, and shows what the API said when it refuses', () async {
      final c = container('providerFoxer');
      final app = c.read(roleApplicationProvider('providerFoxer').notifier)
        ..edit(
          (d) => d.copyWith(
            businessName: 'Loud Co',
            types: 'Speakers',
            specializations: const ['dj'],
            documents: _allDocuments(),
          ),
        );

      when(() => repo.submit(any())).thenAnswer((_) async {});
      expect(await app.submit(), isTrue);

      when(() => repo.submit(any())).thenThrow(
        const ServerException('You already have a pending application'),
      );
      expect(await app.submit(), isFalse);
      expect(
        c.read(roleApplicationProvider('providerFoxer')).error,
        'You already have a pending application',
      );
    });
  });

  group('the form', () {
    Future<void> open(
      WidgetTester tester,
      String role, {
      Future<List<ProviderSpecialty>> Function()? specialties,
    }) async {
      await tester.pumpWidget(
        ProviderScope(
          retry: (_, __) => null,
          overrides: [
            providerSpecialtiesProvider.overrideWith(
              (ref) => (specialties ?? () async => _catalog)(),
            ),
            roleApplicationRepositoryProvider.overrideWithValue(repo),
            photoPickerProvider.overrideWithValue(_FakePicker()),
          ],
          child: MaterialApp(
            theme: AppTheme.dark,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: RoleApplicationPage(roleType: role),
          ),
        ),
      );
      await tester.pump();
    }

    testWidgets('a Provider is offered the catalog specialties, by name', (
      tester,
    ) async {
      await open(tester, 'providerFoxer');
      await tester.pumpAndSettle();

      expect(find.text('Photography'), findsOneWidget);
      expect(find.text('Sound system'), findsOneWidget);
      expect(find.text('Specializations (choose at least one)'), findsOne);
    });

    testWidgets('a Provider whose specialties cannot load can try again', (
      tester,
    ) async {
      var calls = 0;
      tester.view
        ..physicalSize = const Size(800, 2400)
        ..devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await open(
        tester,
        'providerFoxer',
        specialties: () async {
          calls++;
          if (calls == 1) throw Exception('offline');
          return _catalog;
        },
      );
      await tester.pumpAndSettle();
      expect(find.text('Photography'), findsNothing);

      await tester.tap(find.text('Try again'));
      await tester.pumpAndSettle();

      expect(calls, 2);
      expect(
        find.text('Photography', skipOffstage: false),
        findsOneWidget,
      );
    });

    testWidgets('a Provider is asked for a business name and experience', (
      tester,
    ) async {
      await open(tester, 'providerFoxer');

      expect(find.text('Provider'), findsOneWidget);
      expect(find.text('Business or trade name'), findsOneWidget);
      expect(find.text('Years of experience'), findsOneWidget);
    });

    testWidgets('a venue asks for contact and address, not services', (
      tester,
    ) async {
      await open(tester, 'venueFoxer');

      expect(find.text('Venue Foxer'), findsOneWidget);
      expect(find.text('Business or venue name'), findsOneWidget);
      expect(find.text('Contact number'), findsOneWidget);
      expect(find.text('Complete address'), findsOneWidget);
      await tester.scrollUntilVisible(
        find.text('TIN number'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text('TIN number'), findsOneWidget);
      expect(find.text('Hotel'), findsOneWidget);
      expect(find.text('Years of experience'), findsNothing);
      expect(find.text('NBI clearance ID number'), findsNothing);
      expect(find.text('Services you offer'), findsNothing);
    });

    testWidgets('an organizer asks for a bio, a place and experience', (
      tester,
    ) async {
      await open(tester, 'organizer');

      expect(find.text('Organizer'), findsOneWidget);
      expect(find.text('About you and your event experience'), findsOneWidget);
      expect(find.text('Country'), findsOneWidget);
      expect(find.text('City'), findsOneWidget);
      expect(find.text('Years of experience'), findsOneWidget);
      expect(find.text('Weddings'), findsNothing);
      expect(find.text('Wedding'), findsOneWidget);
      expect(find.text('Services you offer'), findsNothing);
      expect(find.text('Links to your work'), findsNothing);
      await tester.scrollUntilVisible(
        find.text('Police or background clearance'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text('Police or background clearance'), findsOneWidget);
      expect(find.text('NBI clearance ID number'), findsNothing);
      expect(find.text('NBI clearance'), findsNothing);
      expect(find.text('TIN number (optional)'), findsNothing);
    });

    testWidgets('an event asks for a bio and a place, not services', (
      tester,
    ) async {
      await open(tester, 'eventFoxer');

      expect(find.text('Event Foxer'), findsOneWidget);
      expect(find.text('About you and your event experience'), findsOneWidget);
      expect(find.text('Country'), findsOneWidget);
      expect(find.text('City'), findsOneWidget);
      expect(find.text('Wedding'), findsOneWidget);
      expect(find.text('Services you offer'), findsNothing);
      expect(find.text('Links to your work'), findsNothing);
      expect(find.text('NBI clearance ID number'), findsNothing);
      await tester.scrollUntilVisible(
        find.text('Portfolio or resume (optional)'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text('Portfolio or resume (optional)'), findsOneWidget);
      expect(find.text('TIN number (optional)'), findsNothing);
    });

    testWidgets('Send waits until it is complete', (tester) async {
      await open(tester, 'providerFoxer');

      final send = find.widgetWithText(ElevatedButton, 'Send application');
      expect(tester.widget<ElevatedButton>(send).onPressed, isNull);
    });

    testWidgets('fits a narrow screen', (tester) async {
      tester.view
        ..physicalSize = const Size(320, 700)
        ..devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await open(tester, 'providerFoxer');
      await tester.drag(find.byType(ListView), const Offset(0, -600));
      await tester.pump();

      expect(tester.takeException(), isNull);
    });
  });
}
