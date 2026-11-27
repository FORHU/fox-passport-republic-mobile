import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_template/features/spaces/data/active_space.dart';
import 'package:flutter_template/features/spaces/data/spaces_repository.dart';
import 'package:flutter_template/features/spaces/domain/listing_draft.dart';
import 'package:flutter_template/features/spaces/domain/provider_kind.dart';
import 'package:flutter_template/features/spaces/domain/venue_draft.dart';
import 'package:flutter_template/features/spaces/presentation/pages/listing_preview_page.dart';
import 'package:flutter_template/features/spaces/presentation/pages/listing_studio_page.dart';
import 'package:flutter_template/l10n/generated/app_localizations.dart';
import 'package:flutter_template/shared/catalog/provider_specialties.dart';
import 'package:flutter_template/shared/location/device_locator.dart';
import 'package:flutter_template/shared/photos/photo_picker.dart';
import 'package:flutter_template/theme/app_theme.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockRepo extends Mock implements SpacesRepository {}

class _FakePicker implements PhotoPicker {
  @override
  Future<PickedPhoto?> pick() async =>
      PickedPhoto(bytes: Uint8List.fromList([1]), name: 'a.jpg');
}

class _NoLocator implements DeviceLocator {
  @override
  Future<LocateResult> locate({bool prompt = true}) async =>
      const LocateResult(LocateOutcome.denied);

  @override
  Future<DevicePlace> placeAt(double lat, double lng) async =>
      const DevicePlace();
}

const _photo = VenuePhoto(fileId: 'f1', url: 'https://x.test/a.png');
const _photo2 = VenuePhoto(fileId: 'f2', url: 'https://x.test/b.png');

const _service = ListingDraft(
  category: 'dj',
  name: 'Night DJ',
  description: 'Sets for any crowd',
  price: 2500,
  city: 'Manila',
  state: 'Metro Manila',
  country: 'Philippines',
  willingToTravel: true,
  photos: [_photo, _photo2],
);

const _gear = ListingDraft(
  category: 'sound_system',
  name: 'PA system',
  description: 'Two speakers and a mixer',
  price: 800,
  billingRate: 'daily',
  quantity: 4,
  condition: 'fair',
  photos: [_photo],
);

void main() {
  late _MockRepo repo;

  setUp(() {
    repo = _MockRepo();
    when(() => repo.countries()).thenAnswer((_) async => const []);
  });

  Future<void> pump(WidgetTester tester, Widget home) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          spacesRepositoryProvider.overrideWithValue(repo),
          photoPickerProvider.overrideWithValue(_FakePicker()),
          deviceLocatorProvider.overrideWithValue(_NoLocator()),
          heldRolesProvider.overrideWithValue(const ['providerFoxer']),
          providerSpecialtiesProvider.overrideWith(
            (ref) async => const <ProviderSpecialty>[],
          ),
        ],
        child: MaterialApp(
          theme: AppTheme.dark,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: home,
        ),
      ),
    );
    await tester.pump();
    await tester.pump();
  }

  Finder bookButton() => find.widgetWithText(ElevatedButton, 'Book');

  group('ListingPreviewPage', () {
    testWidgets('shows a service as guests will see it, and books nothing', (
      tester,
    ) async {
      await pump(
        tester,
        const ListingPreviewPage(kind: ProviderKind.services, draft: _service),
      );

      expect(find.textContaining('not yet published'), findsOneWidget);
      expect(find.text('DJ'), findsOneWidget);
      expect(find.text('Night DJ'), findsOneWidget);
      expect(find.textContaining('Manila ·'), findsOneWidget);
      expect(find.textContaining('/hr'), findsOneWidget);
      expect(find.text('Sets for any crowd'), findsOneWidget);
      expect(find.text('Manila, Metro Manila, Philippines'), findsOneWidget);
      expect(find.text('Willing to travel to the event'), findsOneWidget);
      // The cover is in the header; the rest are listed under Photos.
      expect(find.text('Photos'), findsOneWidget);
      expect(tester.widget<ElevatedButton>(bookButton()).onPressed, isNull);
      expect(find.text('Condition'), findsNothing);
    });

    testWidgets('an empty draft shows placeholders', (tester) async {
      await pump(
        tester,
        const ListingPreviewPage(
          kind: ProviderKind.services,
          draft: ListingDraft(),
        ),
      );

      expect(find.text('Untitled listing'), findsOneWidget);
      expect(find.text('No description yet.'), findsOneWidget);
      expect(find.text('No place yet.'), findsOneWidget);
      expect(find.text('Photos'), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('gear shows its condition and how many, not travel', (
      tester,
    ) async {
      await pump(
        tester,
        const ListingPreviewPage(kind: ProviderKind.gear, draft: _gear),
      );

      expect(find.text('SOUND SYSTEM'), findsOneWidget);
      expect(find.text('Fair · 4 available'), findsOneWidget);
      expect(find.textContaining('/day'), findsOneWidget);
      expect(find.text('Willing to travel to the event'), findsNothing);
    });

    testWidgets('fits a narrow screen', (tester) async {
      tester.view
        ..physicalSize = const Size(320, 640)
        ..devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await pump(
        tester,
        const ListingPreviewPage(kind: ProviderKind.services, draft: _service),
      );

      expect(tester.takeException(), isNull);
    });
  });

  group('the form', () {
    testWidgets('Preview opens what is typed, and Back keeps it', (
      tester,
    ) async {
      await pump(tester, const ListingStudioPage(kind: ProviderKind.services));

      await tester.enterText(
        find.widgetWithText(TextField, 'Name'),
        'Sunset Sounds',
      );
      await tester.tap(find.byKey(const ValueKey('listing-preview')));
      await tester.pumpAndSettle();

      expect(find.byType(ListingPreviewPage), findsOneWidget);
      expect(find.text('Sunset Sounds'), findsOneWidget);

      await tester.tap(find.byTooltip('Back'));
      await tester.pumpAndSettle();

      expect(find.byType(ListingPreviewPage), findsNothing);
      expect(find.text('Sunset Sounds'), findsOneWidget);
    });
  });
}
