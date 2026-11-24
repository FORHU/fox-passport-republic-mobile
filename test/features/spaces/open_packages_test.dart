import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_template/features/spaces/data/open_packages_repository.dart';
import 'package:flutter_template/features/spaces/domain/open_package.dart';
import 'package:flutter_template/features/spaces/domain/package_invite.dart';
import 'package:flutter_template/features/spaces/presentation/widgets/open_packages.dart';
import 'package:flutter_template/l10n/generated/app_localizations.dart';
import 'package:flutter_template/theme/app_theme.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

/// mobile#494 (api#460): open packages, applying with a listing (a taken
/// spot can't be chosen), and the Event Foxer answering applications.

class _MockRepo extends Mock implements OpenPackagesRepository {}

final List<OpenPackage> _list = [
  OpenPackage.tryParse({
    'id': 'tpl-1',
    'name': 'Garden Wedding Package',
    'targetCity': 'Cebu City',
    'maxAttendees': 150,
    'owner': {'id': 'ef-1', 'name': 'Ivan Dela Cruz'},
    'takenSpots': ['venue', 'asset:sound_system'],
    'myApplications': <Object>[],
  })!,
  OpenPackage.tryParse({
    'id': 'tpl-2',
    'name': 'Beach Debut Mactan',
    'owner': {'id': 'ef-2', 'name': 'Ana Reyes'},
    'takenSpots': <Object>[],
    'myApplications': [
      {'id': 'app-9', 'listingId': 's-1', 'status': 'pending'},
    ],
  })!,
];

final OpenPackageDetail _detail = OpenPackageDetail.tryParse({
  'data': {
    'id': 'tpl-1',
    'name': 'Garden Wedding Package',
    'owner': {'id': 'ef-1', 'name': 'Ivan Dela Cruz'},
    'lines': [
      {'name': 'Sky Hall', 'spot': 'venue', 'status': 'pending'},
      {
        'name': 'Monitors',
        'spot': 'asset:sound_system',
        'status': 'accepted',
      },
    ],
    'myListings': [
      {
        'kind': 'venue',
        'id': 'v-2',
        'name': 'Old Barn',
        'spot': 'venue',
        'price': 20000,
        'canApply': false,
        'why': 'spot_taken',
      },
      {
        'kind': 'service',
        'id': 's-1',
        'name': 'Lens Studio',
        'spot': 'service:photography',
        'price': '18000',
        'canApply': true,
        'why': null,
      },
    ],
    'myApplications': <Object>[],
  },
})!;

final List<PackageApplication> _applications = [
  PackageApplication.tryParse({
    'id': 'app-1',
    'status': 'pending',
    'listingName': 'Lens Studio',
    'applicant': {'name': 'Lea Santos'},
    'spot': 'service:photography',
    'price': 18000,
    'message': 'Two shooters',
  })!,
];

void main() {
  late _MockRepo repo;

  setUpAll(() {
    registerFallbackValue(_detail.choices.last);
    registerFallbackValue(InviteDeclineReason.other);
  });

  setUp(() {
    repo = _MockRepo();
    when(() => repo.list()).thenAnswer((_) async => _list);
    when(() => repo.detail(any())).thenAnswer((_) async => _detail);
    when(() => repo.applications(any())).thenAnswer((_) async => _applications);
    when(
      () => repo.apply(any(), any(), message: any(named: 'message')),
    ).thenAnswer((_) async {});
    when(
      () => repo.answer(
        any(),
        any(),
        accept: any(named: 'accept'),
        reason: any(named: 'reason'),
        note: any(named: 'note'),
      ),
    ).thenAnswer((_) async {});
  });

  Future<void> pump(WidgetTester tester, Widget home) async {
    tester.view
      ..physicalSize = const Size(400, 1400)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [openPackagesRepositoryProvider.overrideWithValue(repo)],
        child: MaterialApp(
          theme: AppTheme.dark,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: home,
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  group('parsing', () {
    test('spots read as words', () {
      expect(Spot.isVenue('venue'), isTrue);
      expect(Spot.category('asset:sound_system'), 'Sound system');
      expect(Spot.category('service:photography'), 'Photography');
    });

    test("choices say why one can't apply", () {
      expect(_detail.choices.first.block, ApplyBlock.spotTaken);
      expect(_detail.choices.last.canApply, isTrue);
      expect(_detail.choices.last.price, 18000);
      expect(_list.last.waiting?.id, 'app-9');
    });
  });

  testWidgets('lists open packages with their taken spots', (tester) async {
    await pump(tester, const OpenPackagesPage());

    expect(find.text('Garden Wedding Package'), findsOneWidget);
    expect(find.text('Venue · taken'), findsOneWidget);
    expect(find.text('Sound system · taken'), findsOneWidget);
    expect(
      find.text('You applied · waiting for the Event Foxer'),
      findsOneWidget,
    );
  });

  testWidgets('applies with an open listing; a taken spot says so', (
    tester,
  ) async {
    await pump(tester, const OpenPackagePage(id: 'tpl-1'));

    expect(find.text('Sky Hall'), findsOneWidget);
    await tester.tap(find.text('Apply'));
    await tester.pumpAndSettle();

    expect(find.text('Venue already taken'), findsOneWidget);
    await tester.enterText(
      find.byKey(const Key('open-apply-message')),
      'Two shooters',
    );
    await tester.tap(find.text('Send application'));
    await tester.pumpAndSettle();

    verify(
      () => repo.apply(
        'tpl-1',
        any(that: predicate<ApplyChoice>((c) => c.id == 's-1')),
        message: 'Two shooters',
      ),
    ).called(1);
    expect(find.text('Application sent.'), findsOneWidget);
  });

  testWidgets('the Event Foxer accepts an application', (tester) async {
    await pump(
      tester,
      const PackageApplicationsPage(
        templateId: 'tpl-1',
        packageName: 'Garden Wedding Package',
      ),
    );

    expect(find.text('Lens Studio'), findsOneWidget);
    expect(find.text('“Two shooters”'), findsOneWidget);
    await tester.tap(find.text('Accept'));
    await tester.pumpAndSettle();

    verify(() => repo.answer('tpl-1', 'app-1', accept: true)).called(1);
  });

  testWidgets('declining an application asks why', (tester) async {
    await pump(
      tester,
      const PackageApplicationsPage(
        templateId: 'tpl-1',
        packageName: 'Garden Wedding Package',
      ),
    );

    await tester.tap(find.text('Decline'));
    await tester.pumpAndSettle();
    expect(find.text('Why not this one?'), findsOneWidget);
    await tester.tap(find.text('Price too low'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Decline request'));
    await tester.pumpAndSettle();

    verify(
      () => repo.answer(
        'tpl-1',
        'app-1',
        accept: false,
        reason: InviteDeclineReason.priceTooLow,
        note: '',
      ),
    ).called(1);
  });
}
