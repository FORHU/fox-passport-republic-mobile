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

Map<KycDocument, PickedPhoto> _allDocuments() => {
      for (final d in KycDocument.values) d: _photo('${d.name}.jpg'),
    };

void main() {
  late _MockRepo repo;

  setUpAll(() {
    registerFallbackValue(const RoleApplicationDraft(roleType: 'gearFoxer'));
  });

  setUp(() => repo = _MockRepo());

  group('RoleApplicationDraft', () {
    test('a service application is sent the way the web sends it', () {
      final draft = RoleApplicationDraft(
        roleType: 'serviceFoxer',
        types: 'Catering, Cakes ,',
        portfolio: 'https://a.test, https://b.test',
        experience: '7',
        nbiNumber: '123456',
        tinNumber: '99',
        specializations: const ['catering'],
        documents: _allDocuments(),
      );

      expect(draft.toData(), {
        'experience': 7,
        'nbiClearanceIdNumber': '123456',
        'serviceTypes': ['Catering', 'Cakes'],
        'portfolioUrls': ['https://a.test', 'https://b.test'],
        'tinNumber': '99',
        'specializations': ['catering'],
      });
    });

    test('a performer names what they perform; gear its business', () {
      final performer = const RoleApplicationDraft(
        roleType: 'performerFoxer',
        types: 'DJ',
        experience: '2',
        nbiNumber: '1',
      ).toData();
      expect(performer['performerTypes'], ['DJ']);
      expect(performer.containsKey('serviceTypes'), isFalse);

      final gear = const RoleApplicationDraft(
        roleType: 'gearFoxer',
        businessName: ' Loud Co ',
        types: 'Speakers, Lights',
      ).toData();
      expect(gear['businessName'], 'Loud Co');
      expect(gear['assetTypes'], ['Speakers', 'Lights']);
      expect(gear.containsKey('experience'), isFalse);
      expect(gear.containsKey('tinNumber'), isFalse);
    });

    test('each document goes under the name the API reads', () {
      final form = RoleApplicationDraft(
        roleType: 'gearFoxer',
        documents: _allDocuments(),
      ).toForm();

      expect(form.fields.map((f) => f.key), containsAll(['roleType', 'data']));
      expect(
        form.files.map((f) => f.key).toSet(),
        {'validId1', 'nbiFile', 'tinIdFile', 'birPermitFile', 'selfieFile'},
      );
    });

    test('is complete only with the details and every document', () {
      final service = RoleApplicationDraft(
        roleType: 'serviceFoxer',
        types: 'Catering',
        experience: '3',
        nbiNumber: '1',
        documents: _allDocuments(),
      );
      expect(service.isComplete, isTrue);
      expect(service.copyWith(experience: '').isComplete, isFalse);
      expect(service.copyWith(experience: '101').isComplete, isFalse);
      expect(service.copyWith(nbiNumber: '').isComplete, isFalse);
      expect(service.copyWith(types: ' , ').isComplete, isFalse);
      expect(
        service
            .copyWith(
              documents: {...service.documents}..remove(KycDocument.selfie),
            )
            .isComplete,
        isFalse,
      );

      final gear = RoleApplicationDraft(
        roleType: 'gearFoxer',
        types: 'Speakers',
        businessName: 'Loud Co',
        documents: _allDocuments(),
      );
      // Gear is not asked for experience or an NBI number.
      expect(gear.isComplete, isTrue);
      expect(gear.copyWith(businessName: '').isComplete, isFalse);
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

    test('the provider roles and the venue apply from the phone', () {
      expect(
        appliesInApp,
        {'serviceFoxer', 'performerFoxer', 'gearFoxer', 'venueFoxer'},
      );
      expect(RouteNames.roleApply('gearFoxer'), '/roles/apply/gearFoxer');
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

    test('keeps to three specializations and lets one go', () {
      final c = container('serviceFoxer');
      final app = c.read(roleApplicationProvider('serviceFoxer').notifier)
        ..toggleSpecialization('design')
        ..toggleSpecialization('catering')
        ..toggleSpecialization('service_staff')
        ..toggleSpecialization('other');

      List<String> picked() =>
          c.read(roleApplicationProvider('serviceFoxer')).draft.specializations;
      expect(picked(), ['design', 'catering', 'service_staff']);

      app.toggleSpecialization('catering');
      expect(picked(), ['design', 'service_staff']);
    });

    test('will not send an incomplete application', () async {
      final c = container('gearFoxer');

      final ok =
          await c.read(roleApplicationProvider('gearFoxer').notifier).submit();

      expect(ok, isFalse);
      verifyNever(() => repo.submit(any()));
    });

    test('sends it, and shows what the API said when it refuses', () async {
      final c = container('gearFoxer');
      final app = c.read(roleApplicationProvider('gearFoxer').notifier)
        ..edit(
          (d) => d.copyWith(
            businessName: 'Loud Co',
            types: 'Speakers',
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
        c.read(roleApplicationProvider('gearFoxer')).error,
        'You already have a pending application',
      );
    });
  });

  group('the form', () {
    Future<void> open(WidgetTester tester, String role) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
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

    testWidgets('gear asks for a business name, not experience', (
      tester,
    ) async {
      await open(tester, 'gearFoxer');

      expect(find.text('Gear Foxer'), findsOneWidget);
      expect(find.text('Business or trade name'), findsOneWidget);
      expect(find.text('Years of experience'), findsNothing);
      expect(find.text('NBI clearance ID number'), findsNothing);
    });

    testWidgets('a service asks for experience and an NBI number', (
      tester,
    ) async {
      await open(tester, 'serviceFoxer');

      expect(find.text('Years of experience'), findsOneWidget);
      expect(find.text('NBI clearance ID number'), findsOneWidget);
      expect(find.text('Business or trade name'), findsNothing);
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

    testWidgets('Send waits until it is complete', (tester) async {
      await open(tester, 'serviceFoxer');

      final send = find.widgetWithText(ElevatedButton, 'Send application');
      expect(tester.widget<ElevatedButton>(send).onPressed, isNull);
    });

    testWidgets('fits a narrow screen', (tester) async {
      tester.view
        ..physicalSize = const Size(320, 700)
        ..devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await open(tester, 'serviceFoxer');
      await tester.drag(find.byType(ListView), const Offset(0, -600));
      await tester.pump();

      expect(tester.takeException(), isNull);
    });
  });
}
