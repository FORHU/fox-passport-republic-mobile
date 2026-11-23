import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_template/features/roles/data/role_application_repository.dart';
import 'package:flutter_template/features/roles/domain/role_application.dart';
import 'package:flutter_template/features/roles/presentation/controllers/role_application_controller.dart';
import 'package:flutter_template/features/roles/presentation/pages/role_wizard_page.dart';
import 'package:flutter_template/l10n/generated/app_localizations.dart';
import 'package:flutter_template/shared/location/device_locator.dart';
import 'package:flutter_template/shared/photos/photo_picker.dart';
import 'package:flutter_template/theme/app_theme.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

/// The Venue, Event and Event Coordinator applications in the Provider
/// wizard's layout (mobile#487): about, categories, documents, review, sent.

class _MockRepo extends Mock implements RoleApplicationRepository {}

class _FakeLocator implements DeviceLocator {
  LocateResult result = const LocateResult(
    LocateOutcome.ok,
    lat: 10.3157,
    lng: 123.8854,
  );

  @override
  Future<LocateResult> locate({bool prompt = true}) async => result;

  @override
  Future<DevicePlace> placeAt(double lat, double lng) async =>
      const DevicePlace(city: 'Cebu City', province: 'Cebu', countryCode: 'PH');
}

PickedPhoto _photo(String name) =>
    PickedPhoto(bytes: Uint8List.fromList([1, 2]), name: name);

void main() {
  late _MockRepo repo;
  late _FakeLocator locator;
  late ProviderContainer container;

  setUpAll(
    () => registerFallbackValue(
      const RoleApplicationDraft(roleType: 'venueFoxer'),
    ),
  );

  setUp(() {
    repo = _MockRepo();
    locator = _FakeLocator();
    container = ProviderContainer(
      overrides: [
        roleApplicationRepositoryProvider.overrideWithValue(repo),
        deviceLocatorProvider.overrideWithValue(locator),
      ],
    );
    addTearDown(container.dispose);
  });

  RoleApplicationController c(String role) =>
      container.read(roleApplicationProvider(role).notifier);

  Future<void> open(WidgetTester tester, String role) async {
    tester.view
      ..physicalSize = const Size(400, 1600)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          theme: AppTheme.dark,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: RoleWizardPage(roleType: role),
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

  Future<void> fillField(WidgetTester tester, String label, String value) {
    // The field sits under its label in the same column.
    final field = find.descendant(
      of: find
          .ancestor(of: find.text(label), matching: find.byType(Column))
          .first,
      matching: find.byType(TextFormField),
    );
    return tester.enterText(field, value);
  }

  ElevatedButton button(WidgetTester tester, String label) =>
      tester.widget<ElevatedButton>(
        find.widgetWithText(ElevatedButton, label),
      );

  testWidgets('a Venue Foxer goes through every step and sends', (
    tester,
  ) async {
    when(() => repo.submit(any())).thenAnswer((_) async {});
    await open(tester, 'venueFoxer');

    expect(find.text('List your venue for events'), findsOneWidget);
    expect(find.text('Provider Foxer'), findsNothing, reason: 'no switch');
    await tapText(tester, 'Start');
    expect(find.text('STEP 1 OF 3'), findsOneWidget);
    expect(button(tester, 'Next: categories').onPressed, isNull);

    await fillField(tester, 'Business or venue name', 'Garden Hall');
    await fillField(tester, 'Contact number', '09171234567');
    await fillField(tester, 'Complete address', '1 Main St, Cebu City');
    await fillField(tester, 'TIN number', '123456789');
    await tester.pumpAndSettle();
    await tapText(tester, 'Next: categories');

    expect(find.text('STEP 2 OF 3'), findsOneWidget);
    for (final name in ['Indoor', 'Outdoor', 'Hotel', 'Garden']) {
      await tapText(tester, name);
    }
    expect(find.text('3 of 3 picked'), findsOneWidget);
    await tapText(tester, 'Next: documents');

    expect(find.text('5 documents still to add'), findsOneWidget);
    for (final doc in KycDocument.values.take(5)) {
      c('venueFoxer').setDocument(doc, _photo('${doc.name}.jpg'));
    }
    await tester.pumpAndSettle();
    await tapText(tester, 'Review application');

    expect(find.text('Garden Hall'), findsOneWidget);
    expect(find.text('All 5 added'), findsOneWidget);
    expect(button(tester, 'Send application').onPressed, isNull);
    await tester.tap(find.byType(Checkbox));
    await tester.pumpAndSettle();
    await tapText(tester, 'Send application');

    final sent = verify(() => repo.submit(captureAny())).captured.single
        as RoleApplicationDraft;
    expect(sent.specializations, ['indoor', 'outdoor', 'hotel']);
    expect(find.text('Application sent'), findsOneWidget);
    expect(find.text('UNDER REVIEW'), findsOneWidget);
  });

  testWidgets('an Event Foxer can fill the city from the location', (
    tester,
  ) async {
    await open(tester, 'eventFoxer');
    await tapText(tester, 'Start');

    await tester.tap(find.byTooltip('Use my current location'));
    await tester.pumpAndSettle();

    final draft = container.read(roleApplicationProvider('eventFoxer')).draft;
    expect(draft.city, 'Cebu City');
    expect(draft.state, 'Cebu');
    expect(find.text('Cebu City'), findsOneWidget);
    expect(find.text('Cebu'), findsOneWidget);
  });

  testWidgets('a refused location says how to turn it on', (tester) async {
    locator.result = const LocateResult(LocateOutcome.denied);
    await open(tester, 'eventFoxer');
    await tapText(tester, 'Start');

    await tester.tap(find.byTooltip('Use my current location'));
    await tester.pumpAndSettle();

    expect(
      find.text(
        'Location is off for this app. Turn it on in Settings to use it.',
      ),
      findsOneWidget,
    );
  });

  testWidgets('an Event Foxer documents step offers an optional portfolio', (
    tester,
  ) async {
    await open(tester, 'eventFoxer');
    await tapText(tester, 'Start');
    await fillField(
        tester,
        'About you and your event experience',
        'I run '
            'weddings');
    await fillField(tester, 'City', 'Cebu City');
    await fillField(tester, 'Country', 'Philippines');
    await tester.pumpAndSettle();
    await tapText(tester, 'Next: categories');
    await tapText(tester, 'Wedding');
    await tapText(tester, 'Next: documents');

    expect(find.text('Portfolio or resume'), findsOneWidget);
    expect(find.text('Optional'), findsOneWidget);
    expect(find.text('5 documents still to add'), findsOneWidget);
  });

  testWidgets('an Event Coordinator sees the Provider switch and needs years', (
    tester,
  ) async {
    await open(tester, 'organizer');

    expect(find.text('PROVIDER FOXER'), findsNothing);
    expect(find.text('Provider Foxer'), findsOneWidget);
    expect(find.text('Event Coordinator'), findsOneWidget);
    expect(find.text('Run the logistics on event day'), findsOneWidget);

    await tapText(tester, 'Start');
    await fillField(tester, 'About you and your event experience', 'Logistics');
    await fillField(tester, 'City', 'Cebu City');
    await fillField(tester, 'Country', 'Philippines');
    await tester.pumpAndSettle();
    expect(button(tester, 'Next: categories').onPressed, isNull);

    await fillField(tester, 'Years doing events', '4');
    await tester.pumpAndSettle();
    expect(button(tester, 'Next: categories').onPressed, isNotNull);
  });
}
