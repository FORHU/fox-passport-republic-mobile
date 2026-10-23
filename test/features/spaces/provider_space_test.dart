import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_template/core/services/api_service.dart';
import 'package:flutter_template/core/services/storage_service.dart';
import 'package:flutter_template/features/auth/domain/entities/user_entity.dart';
import 'package:flutter_template/features/auth/presentation/controllers/auth_controller.dart';
import 'package:flutter_template/features/spaces/data/spaces_repository.dart';
import 'package:flutter_template/features/spaces/domain/app_space.dart';
import 'package:flutter_template/features/spaces/domain/provider_kind.dart';
import 'package:flutter_template/features/spaces/domain/space_models.dart';
import 'package:flutter_template/features/spaces/presentation/pages/provider_listings_page.dart';
import 'package:flutter_template/features/spaces/presentation/pages/provider_overview_page.dart';
import 'package:flutter_template/features/spaces/presentation/widgets/space_switcher.dart';
import 'package:flutter_template/l10n/generated/app_localizations.dart';
import 'package:flutter_template/theme/app_theme.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _MockApi extends Mock implements ApiService {}

class _MockRepo extends Mock implements SpacesRepository {}

class _Session extends AuthController {
  _Session(this.roles);

  final List<String> roles;

  @override
  AuthState build() => AuthState(
        user: UserEntity(
          id: 'u1',
          email: 'a@b.co',
          name: 'Ada',
          roleType: roles,
        ),
      );
}

Map<String, dynamic> _row(
  String id,
  String key, {
  String status = 'pending_provider_confirmation',
  String name = 'Sound system',
  String event = 'Launch Night',
  String? startAt,
}) =>
    {
      'id': id,
      'status': status,
      'agreedPrice': 3500,
      'event': {
        'name': event,
        'startAt': startAt,
        'client': {'name': 'Cy'},
      },
      key: {'name': name, 'images': <Object>[]},
    };

void main() {
  setUpAll(() {
    registerFallbackValue(RequestKind.asset);
  });

  group('requests for gear and services', () {
    test('a request reads the asset or service it is for', () {
      final gear = VenueRequest.tryParse(
        _row('a', 'asset', name: 'PA system'),
        kind: RequestKind.asset,
      )!;
      final service = VenueRequest.tryParse(
        _row('b', 'service', name: 'DJ set'),
        kind: RequestKind.service,
      )!;

      expect(gear.kind, RequestKind.asset);
      expect(gear.venueName, 'PA system');
      expect(service.kind, RequestKind.service);
      expect(service.venueName, 'DJ set');
      expect(gear.needsReply, isTrue);
    });

    test('listing status words cover gear and services too', () {
      SpaceListing at(String s) => SpaceListing(id: 'x', name: 'x', status: s);

      expect(at('reserved').group, 'live');
      expect(at('paused').group, 'archived');
      expect(at('available').group, 'live');
    });
  });

  group('the supply calls', () {
    late _MockApi api;
    late SpacesRepository repo;

    setUp(() {
      api = _MockApi();
      repo = SpacesRepository(api, 'u1');
    });

    test('lists the requests for one kind, replies first', () async {
      when(() => api.get('/event-transactions/provider')).thenAnswer(
        (_) async => {
          'venues': [
            {'id': 'v'},
          ],
          'assets': [
            _row('a1', 'asset', status: 'approved'),
            _row('a2', 'asset'),
          ],
          'services': [
            _row('s1', 'service'),
          ],
        },
      );

      final gear = await repo.supplyRequests(RequestKind.asset);
      final services = await repo.supplyRequests(RequestKind.service);

      // Gear is not mixed with services, and the one needing a reply is first.
      expect(gear.map((r) => r.id), ['a2', 'a1']);
      expect(services.map((r) => r.id), ['s1']);
      expect(services.single.kind, RequestKind.service);
    });

    test('says so when the response has no list for the kind', () async {
      when(() => api.get('/event-transactions/provider'))
          .thenAnswer((_) async => {'venues': <Object>[]});

      expect(
        repo.supplyRequests(RequestKind.asset),
        throwsFormatException,
      );
    });

    test('answers a request as the kind of thing it is', () async {
      when(() => api.patch(any(), any())).thenAnswer((_) async => {});

      await repo.reviewVenueRequest(
        'r1',
        accept: true,
        kind: RequestKind.asset,
      );
      await repo.reviewVenueRequest('r2', accept: false);

      verify(
        () => api.patch(
          '/event-transactions/r1/review',
          {'type': 'asset', 'action': 'confirm'},
        ),
      ).called(1);
      verify(
        () => api.patch(
          '/event-transactions/r2/review',
          {'type': 'venue', 'action': 'reject'},
        ),
      ).called(1);
    });

    test('lists the gear and services the person owns', () async {
      when(() => api.get(any(), query: any(named: 'query'))).thenAnswer(
        (_) async => {
          'assets': [
            {'id': 'g1', 'name': 'PA', 'status': 'available'},
          ],
          'services': [
            {'id': 's1', 'name': 'DJ', 'status': 'paused'},
          ],
          'total': 1,
        },
      );

      final gear = await repo.myAssets();
      final services = await repo.myServices();

      expect(gear.single.name, 'PA');
      expect(services.single.group, 'archived');
      verify(
        () => api.get(
          '/asset',
          query: {'ownerId': 'u1', 'limit': 50, 'page': 1},
        ),
      ).called(1);
      verify(
        () => api.get(
          '/service',
          query: {'ownerId': 'u1', 'limit': 50, 'page': 1},
        ),
      ).called(1);
    });
  });

  group('the Provider screens', () {
    late _MockRepo repo;
    var requests = <VenueRequest>[];
    var assets = <SpaceListing>[];
    var services = <SpaceListing>[];

    setUp(() {
      repo = _MockRepo();
      requests = [];
      assets = [];
      services = [];
      when(
        () => repo.reviewVenueRequest(
          any(),
          accept: any(named: 'accept'),
          kind: any(named: 'kind'),
        ),
      ).thenAnswer((_) async {});
    });

    Future<void> pump(
      WidgetTester tester,
      Widget home, {
      List<String> roles = const ['gearFoxer'],
    }) async {
      tester.view
        ..physicalSize = const Size(390, 1800)
        ..devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      await tester.pumpWidget(
        ProviderScope(
          retry: (_, __) => null,
          overrides: [
            spacesRepositoryProvider.overrideWithValue(repo),
            sharedPreferencesProvider.overrideWithValue(prefs),
            authControllerProvider.overrideWith(() => _Session(roles)),
            supplyRequestsProvider.overrideWith((ref, kind) async => requests),
            myAssetsProvider.overrideWith((ref) async => assets),
            myServicesProvider.overrideWith((ref) async => services),
            payoutsProvider.overrideWith((ref) async => const PayoutSummary()),
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

    testWidgets('the overview says all is clear when nothing waits', (
      tester,
    ) async {
      await pump(tester, const ProviderOverviewPage(kind: ProviderKind.gear));

      expect(find.text("You're all caught up."), findsOneWidget);
      expect(find.text('Nothing confirmed yet.'), findsOneWidget);
    });

    testWidgets('a request waiting can be accepted from the overview', (
      tester,
    ) async {
      requests = [
        VenueRequest.tryParse(
          _row('a1', 'asset', name: 'PA system'),
          kind: RequestKind.asset,
        )!,
      ];
      await pump(tester, const ProviderOverviewPage(kind: ProviderKind.gear));

      expect(find.text('PA system'), findsOneWidget);
      await tester.tap(find.text('Accept').first);
      await tester.pump();

      verify(
        () => repo.reviewVenueRequest(
          'a1',
          accept: true,
          kind: RequestKind.asset,
        ),
      ).called(1);
    });

    testWidgets('confirmed jobs ahead are listed with their day', (
      tester,
    ) async {
      final soon = DateTime.now().add(const Duration(days: 3));
      requests = [
        VenueRequest.tryParse(
          _row(
            's1',
            'service',
            status: 'approved',
            name: 'DJ set',
            event: 'Gala',
            startAt: soon.toUtc().toIso8601String(),
          ),
          kind: RequestKind.service,
        )!,
      ];
      await pump(
        tester,
        const ProviderOverviewPage(kind: ProviderKind.services),
        roles: ['serviceFoxer'],
      );

      expect(find.text('DJ set'), findsOneWidget);
      expect(find.text('Gala'), findsOneWidget);
    });

    testWidgets('the Gear space lists gear', (tester) async {
      assets = const [
        SpaceListing(id: 'g1', name: 'PA system', status: 'available'),
      ];
      services = const [
        SpaceListing(id: 's1', name: 'DJ set', status: 'available'),
      ];
      await pump(
        tester,
        const ProviderListingsPage(kind: ProviderKind.gear),
      );

      expect(find.text('PA system'), findsOneWidget);
      // Services belong to the Services space.
      expect(find.text('DJ set'), findsNothing);
    });

    testWidgets('the Services space lists services', (tester) async {
      assets = const [
        SpaceListing(id: 'g1', name: 'PA system', status: 'available'),
      ];
      services = const [
        SpaceListing(id: 's1', name: 'DJ set', status: 'available'),
      ];
      await pump(
        tester,
        const ProviderListingsPage(kind: ProviderKind.services),
        roles: ['serviceFoxer'],
      );

      expect(find.text('DJ set'), findsOneWidget);
      expect(find.text('PA system'), findsNothing);
    });

    testWidgets('the tab of a Performer Foxer is called Performances', (
      tester,
    ) async {
      await pump(
        tester,
        const ProviderListingsPage(kind: ProviderKind.services),
        roles: ['performerFoxer'],
      );

      expect(find.text('Performances'), findsWidgets);
      expect(find.text('You have no services listed yet.'), findsOneWidget);
      expect(find.text('Add on the web'), findsOneWidget);
    });

    testWidgets('tapping a listing offers to edit it on the web', (
      tester,
    ) async {
      assets = const [
        SpaceListing(id: 'g1', name: 'PA system', status: 'available'),
      ];
      await pump(
        tester,
        const ProviderListingsPage(kind: ProviderKind.gear),
      );

      await tester.tap(find.text('PA system'));
      await tester.pumpAndSettle();

      expect(find.text('Edit on the web'), findsOneWidget);
    });
  });

  group('space names follow the roles held', () {
    test('the Services space of a Performer Foxer is called Performer', () {
      final context = {
        'performer': ['performerFoxer'],
        'service': ['serviceFoxer'],
        'both': ['serviceFoxer', 'performerFoxer'],
      };
      // Names need the generated strings; the roles decide which one.
      final l10n = lookupAppLocalizations(const Locale('en'));

      expect(
        spaceLabel(l10n, AppSpace.services, roles: context['performer']!),
        'Performer',
      );
      expect(
        spaceLabel(l10n, AppSpace.services, roles: context['service']!),
        'Services',
      );
      expect(
        spaceLabel(l10n, AppSpace.services, roles: context['both']!),
        'Services',
      );
      expect(spaceLabel(l10n, AppSpace.gear), 'Gear');
    });
  });
}
