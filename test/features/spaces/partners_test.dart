import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_template/core/services/api_service.dart';
import 'package:flutter_template/core/services/storage_service.dart';
import 'package:flutter_template/features/auth/domain/entities/user_entity.dart';
import 'package:flutter_template/features/auth/presentation/controllers/auth_controller.dart';
import 'package:flutter_template/features/spaces/data/spaces_repository.dart';
import 'package:flutter_template/features/spaces/domain/partner_models.dart';
import 'package:flutter_template/features/spaces/domain/space_models.dart';
import 'package:flutter_template/features/spaces/presentation/pages/partners_page.dart';
import 'package:flutter_template/l10n/generated/app_localizations.dart';
import 'package:flutter_template/shared/catalog/catalog_item.dart';
import 'package:flutter_template/shared/catalog/catalog_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _MockApi extends Mock implements ApiService {}

class _MockRepo extends Mock implements SpacesRepository {}

class _MockCatalog extends Mock implements CatalogRepository {}

class _Session extends AuthController {
  @override
  AuthState build() => const AuthState(
        user: UserEntity(
          id: 'u1',
          email: 'a@b.co',
          name: 'Ada',
          roleType: ['venueFoxer', 'eventFoxer'],
        ),
      );
}

Map<String, dynamic> _row(
  String id, {
  String status = 'pending',
  String initiatedBy = 'eventFoxer',
  Object? price,
  String venue = 'Sky Hall',
  String foxer = 'Ada Events',
}) =>
    {
      'id': id,
      'status': status,
      'initiatedBy': initiatedBy,
      'agreedPrice': price,
      'venue': {'id': 'v1', 'name': venue},
      'eventFoxer': {'id': 'e1', 'name': foxer},
    };

Map<String, dynamic> _body({
  List<Map<String, dynamic>> mayor = const [],
  List<Map<String, dynamic>> foxer = const [],
}) =>
    {
      'success': true,
      'data': {'asVenueMayor': mayor, 'asEventFoxer': foxer},
    };

void main() {
  group('Partner', () {
    test('an application waits for the Mayor; an invitation for the Foxer', () {
      final application = Partner.tryParse(_row('a'), PartnerSide.mayor)!;
      final invite = Partner.tryParse(
        _row('b', initiatedBy: 'venueFoxer'),
        PartnerSide.mayor,
      )!;

      expect(application.awaitingMe, isTrue);
      expect(application.startedByMe, isFalse);
      expect(invite.awaitingMe, isFalse);
      expect(invite.startedByMe, isTrue);

      final asFoxer = Partner.tryParse(
        _row('b', initiatedBy: 'venueFoxer'),
        PartnerSide.eventFoxer,
      )!;
      expect(asFoxer.awaitingMe, isTrue);
    });

    test('only the Mayor can end an approved partnership', () {
      final approved = _row('a', status: 'approved');

      expect(
        Partner.tryParse(approved, PartnerSide.mayor)!.canRevoke,
        isTrue,
      );
      expect(
        Partner.tryParse(approved, PartnerSide.eventFoxer)!.canRevoke,
        isFalse,
      );
      expect(
        Partner.tryParse(_row('a'), PartnerSide.mayor)!.canRevoke,
        isFalse,
      );
    });

    test('reads the agreed price, and skips rows it cannot read', () {
      expect(
        Partner.tryParse(_row('a', price: '2500.00'), PartnerSide.mayor)!
            .agreedPrice,
        2500,
      );
      expect(
        Partner.tryParse(_row('a', status: 'odd'), PartnerSide.mayor),
        isNull,
      );
      expect(Partner.tryParse({'id': 'x'}, PartnerSide.mayor), isNull);
    });

    test('both lists come from one response', () {
      final lists = PartnerLists.fromJson(
        _body(mayor: [_row('a')], foxer: [_row('b'), _row('c')]),
      );

      expect(lists.asMayor, hasLength(1));
      expect(lists.asEventFoxer, hasLength(2));
      expect(
        () => PartnerLists.fromJson({'success': true}),
        throwsFormatException,
      );
    });
  });

  group('the waiting count', () {
    ProviderContainer containerWith(PartnerLists lists) {
      final c = ProviderContainer(
        overrides: [partnersProvider.overrideWith((ref) async => lists)],
      );
      addTearDown(c.dispose);
      return c;
    }

    test('counts only what waits for the person, per side', () async {
      final lists = PartnerLists(
        asMayor: [
          Partner.tryParse(_row('a'), PartnerSide.mayor)!,
          Partner.tryParse(_row('b'), PartnerSide.mayor)!,
          // The Mayor's own invitation waits for the Event Foxer.
          Partner.tryParse(
            _row('c', initiatedBy: 'venueFoxer'),
            PartnerSide.mayor,
          )!,
          Partner.tryParse(_row('d', status: 'approved'), PartnerSide.mayor)!,
        ],
        asEventFoxer: [
          Partner.tryParse(
            _row('e', initiatedBy: 'venueFoxer'),
            PartnerSide.eventFoxer,
          )!,
        ],
      );
      final c = containerWith(lists)..listen(partnersProvider, (_, __) {});
      await c.read(partnersProvider.future);

      expect(c.read(partnersWaitingProvider(PartnerSide.mayor)), 2);
      expect(c.read(partnersWaitingProvider(PartnerSide.eventFoxer)), 1);
    });

    test('is zero until the list has loaded', () {
      final c = containerWith(const PartnerLists());

      expect(c.read(partnersWaitingProvider(PartnerSide.mayor)), 0);
    });
  });

  group('the partner calls', () {
    late _MockApi api;
    late SpacesRepository repo;

    setUp(() {
      api = _MockApi();
      repo = SpacesRepository(api, 'u1');
      when(() => api.patch(any(), any())).thenAnswer((_) async => {});
      when(() => api.patch(any())).thenAnswer((_) async => {});
      when(() => api.delete(any())).thenAnswer((_) async => {});
    });

    test('approve, reject, withdraw and end go to the right routes', () async {
      await repo.approvePartner('a1');
      await repo.rejectPartner('a1', reason: ' not now ');
      await repo.rejectPartner('a1');
      await repo.cancelPartner('a1');
      await repo.revokePartner('a1');

      verify(() => api.patch('/venue-affiliations/a1/approve')).called(1);
      verify(
        () => api.patch(
          '/venue-affiliations/a1/reject',
          {'rejectionReason': 'not now'},
        ),
      ).called(1);
      verify(
        () => api.patch('/venue-affiliations/a1/reject', <String, dynamic>{}),
      ).called(1);
      verify(() => api.patch('/venue-affiliations/a1/cancel')).called(1);
      verify(() => api.delete('/venue-affiliations/a1')).called(1);
    });

    test('inviting names the venue and the Event Foxer', () async {
      when(() => api.post(any(), any())).thenAnswer((_) async => {});

      await repo.inviteEventFoxer('v9', 'e2');

      verify(
        () => api.post(
          '/venue-affiliations/invite',
          {'venueId': 'v9', 'eventFoxerId': 'e2'},
        ),
      ).called(1);
    });

    test('applying names the venue', () async {
      when(() => api.post(any(), any())).thenAnswer((_) async => {});

      await repo.applyToVenue('v9');

      verify(
        () => api.post('/venue-affiliations/apply', {'venueId': 'v9'}),
      ).called(1);
    });

    test('lists both directions from /mine', () async {
      when(() => api.get('/venue-affiliations/mine'))
          .thenAnswer((_) async => _body(mayor: [_row('a')]));

      final lists = await repo.partners();

      expect(lists.asMayor.single.id, 'a');
    });
  });

  group('the Partners screen', () {
    late _MockRepo repo;

    late _MockCatalog catalog;
    var venues = const <SpaceListing>[
      SpaceListing(id: 'v1', name: 'Sky Hall', status: 'available'),
    ];

    setUp(() {
      repo = _MockRepo();
      catalog = _MockCatalog();
      venues = const [
        SpaceListing(id: 'v1', name: 'Sky Hall', status: 'available'),
      ];
    });

    Future<void> pump(
      WidgetTester tester,
      PartnerSide side,
      PartnerLists lists,
    ) async {
      tester.view
        ..physicalSize = const Size(900, 2400)
        ..devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      when(() => repo.partners()).thenAnswer((_) async => lists);
      when(() => repo.approvePartner(any())).thenAnswer((_) async {});
      when(() => repo.rejectPartner(any())).thenAnswer((_) async {});
      when(() => repo.cancelPartner(any())).thenAnswer((_) async {});
      when(() => repo.revokePartner(any())).thenAnswer((_) async {});
      when(() => repo.applyToVenue(any())).thenAnswer((_) async {});
      when(() => repo.inviteEventFoxer(any(), any())).thenAnswer((_) async {});
      await tester.pumpWidget(
        ProviderScope(
          retry: (_, __) => null,
          overrides: [
            spacesRepositoryProvider.overrideWithValue(repo),
            catalogRepositoryProvider.overrideWithValue(catalog),
            myVenuesProvider.overrideWith((ref) async => venues),
            sharedPreferencesProvider.overrideWithValue(prefs),
            authControllerProvider.overrideWith(_Session.new),
          ],
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: PartnersPage(side: side),
          ),
        ),
      );
      await tester.pump();
      await tester.pump();
    }

    PartnerLists mayorLists(List<Map<String, dynamic>> rows) => PartnerLists(
          asMayor: [
            for (final r in rows) Partner.tryParse(r, PartnerSide.mayor)!,
          ],
        );

    testWidgets('a Mayor approves an application', (tester) async {
      await pump(tester, PartnerSide.mayor, mayorLists([_row('a')]));

      expect(find.text('Needs your answer'), findsOneWidget);
      expect(
        find.text('Ada Events applied to host at Sky Hall'),
        findsOneWidget,
      );

      await tester.tap(find.text('Approve'));
      await tester.pump();

      verify(() => repo.approvePartner('a')).called(1);
      expect(find.text("Done. They've been told."), findsOneWidget);
    });

    testWidgets('rejecting asks first, and backing out does nothing', (
      tester,
    ) async {
      await pump(tester, PartnerSide.mayor, mayorLists([_row('a')]));

      await tester.tap(find.text('Reject'));
      await tester.pumpAndSettle();
      expect(find.text('Say no to this?'), findsOneWidget);

      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      verifyNever(() => repo.rejectPartner(any()));

      await tester.tap(find.text('Reject'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(TextButton, 'Reject'));
      await tester.pumpAndSettle();
      verify(() => repo.rejectPartner('a')).called(1);
    });

    testWidgets('shows the price an application agreed to', (tester) async {
      await pump(
        tester,
        PartnerSide.mayor,
        mayorLists([_row('a', price: '2500')]),
      );

      expect(find.textContaining('Agreed price:'), findsOneWidget);
    });

    testWidgets('an invitation the Mayor sent can only be withdrawn', (
      tester,
    ) async {
      await pump(
        tester,
        PartnerSide.mayor,
        mayorLists([_row('a', initiatedBy: 'venueFoxer')]),
      );

      expect(find.text('Waiting for them'), findsOneWidget);
      expect(find.text('Approve'), findsNothing);

      await tester.tap(find.text('Withdraw'));
      await tester.pump();
      verify(() => repo.cancelPartner('a')).called(1);
    });

    testWidgets('a Mayor can end an active partnership, after asking', (
      tester,
    ) async {
      await pump(
        tester,
        PartnerSide.mayor,
        mayorLists([_row('a', status: 'approved')]),
      );

      expect(find.text('Active'), findsOneWidget);
      await tester.tap(find.text('End partnership'));
      await tester.pumpAndSettle();
      expect(find.text('End this partnership?'), findsOneWidget);

      await tester.tap(find.widgetWithText(TextButton, 'End partnership'));
      await tester.pumpAndSettle();
      verify(() => repo.revokePartner('a')).called(1);
    });

    testWidgets('an Event Foxer answers an invitation from a Mayor', (
      tester,
    ) async {
      await pump(
        tester,
        PartnerSide.eventFoxer,
        PartnerLists(
          asEventFoxer: [
            Partner.tryParse(
              _row('a', initiatedBy: 'venueFoxer'),
              PartnerSide.eventFoxer,
            )!,
          ],
        ),
      );

      expect(
        find.text('Sky Hall invited you to host events there'),
        findsOneWidget,
      );
      await tester.tap(find.text('Accept'));
      await tester.pump();
      verify(() => repo.approvePartner('a')).called(1);
      expect(find.text('Decline'), findsOneWidget);
    });

    testWidgets('an Event Foxer cannot end an active partnership', (
      tester,
    ) async {
      await pump(
        tester,
        PartnerSide.eventFoxer,
        PartnerLists(
          asEventFoxer: [
            Partner.tryParse(
              _row('a', status: 'approved'),
              PartnerSide.eventFoxer,
            )!,
          ],
        ),
      );

      expect(find.text('Active'), findsOneWidget);
      expect(find.text('End partnership'), findsNothing);
    });

    testWidgets('keeps past partnerships out of the way, and says when empty', (
      tester,
    ) async {
      await pump(
        tester,
        PartnerSide.mayor,
        mayorLists([_row('a', status: 'rejected')]),
      );
      expect(find.text('Past'), findsOneWidget);
      expect(find.text('Declined'), findsOneWidget);
      expect(find.text('Approve'), findsNothing);
    });

    testWidgets('says so when there are no partners yet', (tester) async {
      await pump(tester, PartnerSide.mayor, const PartnerLists());
      expect(find.text('No partners yet.'), findsOneWidget);
    });

    testWidgets('each side sees only its own button', (tester) async {
      await pump(tester, PartnerSide.mayor, const PartnerLists());
      expect(find.text('Invite an Event Foxer'), findsOneWidget);
      expect(find.text('Apply to a venue'), findsNothing);
    });

    testWidgets('an Event Foxer finds a venue and applies to it', (
      tester,
    ) async {
      registerFallbackValue(CatalogKind.venues);
      when(
        () => catalog.fetch(
          any(),
          query: any(named: 'query'),
          limit: any(named: 'limit'),
        ),
      ).thenAnswer(
        (_) async => const CatalogPage(
          items: [
            CatalogItem(id: 'v9', kind: CatalogKind.venues, title: 'Moon Hall'),
            CatalogItem(id: 'v1', kind: CatalogKind.venues, title: 'Sky Hall'),
          ],
          total: 2,
        ),
      );
      await pump(
        tester,
        PartnerSide.eventFoxer,
        PartnerLists(
          asEventFoxer: [
            Partner.tryParse(_row('a'), PartnerSide.eventFoxer)!,
          ],
        ),
      );

      await tester.tap(find.text('Apply to a venue'));
      await tester.pumpAndSettle();
      expect(find.text('Choose a venue'), findsOneWidget);
      // Sky Hall (v1) is already on the list, so it cannot be picked.
      expect(find.text('Already on your list'), findsOneWidget);
      await tester.tap(find.text('Sky Hall'));
      await tester.pumpAndSettle();
      verifyNever(() => repo.applyToVenue(any()));

      await tester.tap(find.text('Moon Hall'));
      await tester.pumpAndSettle();
      expect(find.text('Apply to Moon Hall?'), findsOneWidget);

      await tester.tap(find.widgetWithText(TextButton, 'Apply'));
      await tester.pumpAndSettle();
      verify(() => repo.applyToVenue('v9')).called(1);
      expect(find.text('Applied. The Mayor has been told.'), findsOneWidget);
    });

    testWidgets('backing out of the confirmation applies to nothing', (
      tester,
    ) async {
      registerFallbackValue(CatalogKind.venues);
      when(
        () => catalog.fetch(
          any(),
          query: any(named: 'query'),
          limit: any(named: 'limit'),
        ),
      ).thenAnswer(
        (_) async => const CatalogPage(
          items: [
            CatalogItem(id: 'v9', kind: CatalogKind.venues, title: 'Moon Hall'),
          ],
          total: 1,
        ),
      );
      await pump(tester, PartnerSide.eventFoxer, const PartnerLists());

      await tester.tap(find.text('Apply to a venue'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Moon Hall'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      verifyNever(() => repo.applyToVenue(any()));
    });

    void foxers(List<CatalogItem> items) {
      registerFallbackValue(CatalogKind.venues);
      when(
        () => catalog.fetch(
          any(),
          query: any(named: 'query'),
          limit: any(named: 'limit'),
        ),
      ).thenAnswer((_) async => CatalogPage(items: items, total: items.length));
    }

    const ada = CatalogItem(
      id: 'e1',
      kind: CatalogKind.foxers,
      title: 'Ada Events',
      roles: ['eventFoxer'],
    );
    const bo = CatalogItem(
      id: 'e2',
      kind: CatalogKind.foxers,
      title: 'Bo Events',
      roles: ['eventFoxer'],
    );
    const gus = CatalogItem(
      id: 'g1',
      kind: CatalogKind.foxers,
      title: 'Gus Gear',
      roles: ['gearFoxer'],
    );

    testWidgets('a Mayor invites an Event Foxer to their venue', (
      tester,
    ) async {
      foxers([bo, gus]);
      await pump(tester, PartnerSide.mayor, const PartnerLists());

      await tester.tap(find.text('Invite an Event Foxer'));
      await tester.pumpAndSettle();
      expect(find.text('Choose an Event Foxer'), findsOneWidget);
      // Only Event Foxers are offered.
      expect(find.text('Bo Events'), findsOneWidget);
      expect(find.text('Gus Gear'), findsNothing);

      await tester.tap(find.text('Bo Events'));
      await tester.pumpAndSettle();
      expect(find.text('Invite Bo Events?'), findsOneWidget);
      expect(
        find.text("They'll be asked to host events at Sky Hall."),
        findsOneWidget,
      );

      await tester.tap(find.widgetWithText(TextButton, 'Invite'));
      await tester.pumpAndSettle();
      verify(() => repo.inviteEventFoxer('v1', 'e2')).called(1);
      expect(find.text('Invitation sent.'), findsOneWidget);
    });

    testWidgets('someone already partnered at the venue cannot be asked again',
        (
      tester,
    ) async {
      foxers([ada, bo]);
      await pump(tester, PartnerSide.mayor, mayorLists([_row('a')]));

      await tester.tap(find.text('Invite an Event Foxer'));
      await tester.pumpAndSettle();
      expect(find.text('Already on your list'), findsOneWidget);

      await tester.tap(find.text('Ada Events').last);
      await tester.pumpAndSettle();
      verifyNever(() => repo.inviteEventFoxer(any(), any()));
    });

    testWidgets('with several live venues the Mayor chooses which', (
      tester,
    ) async {
      foxers([bo]);
      venues = const [
        SpaceListing(id: 'v1', name: 'Sky Hall', status: 'available'),
        SpaceListing(id: 'v2', name: 'Old Barn', status: 'available'),
        SpaceListing(id: 'v3', name: 'Draft Villa', status: 'draft'),
      ];
      await pump(tester, PartnerSide.mayor, const PartnerLists());

      await tester.tap(find.text('Invite an Event Foxer'));
      await tester.pumpAndSettle();
      expect(find.text('Which venue?'), findsOneWidget);
      // A venue that is not live yet is not offered.
      expect(find.text('Draft Villa'), findsNothing);

      await tester.tap(find.text('Old Barn'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Bo Events'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(TextButton, 'Invite'));
      await tester.pumpAndSettle();

      verify(() => repo.inviteEventFoxer('v2', 'e2')).called(1);
    });

    testWidgets('a Mayor with no live venue is told why', (tester) async {
      venues = const [
        SpaceListing(id: 'v3', name: 'Draft Villa', status: 'draft'),
      ];
      await pump(tester, PartnerSide.mayor, const PartnerLists());

      await tester.tap(find.text('Invite an Event Foxer'));
      await tester.pumpAndSettle();

      expect(
        find.text('You need a live venue to invite someone.'),
        findsOneWidget,
      );
      expect(find.text('Choose an Event Foxer'), findsNothing);
    });

    testWidgets('says so when an action fails', (tester) async {
      await pump(tester, PartnerSide.mayor, mayorLists([_row('a')]));
      when(() => repo.approvePartner(any())).thenThrow(Exception('no'));

      await tester.tap(find.text('Approve'));
      await tester.pump();

      expect(find.text("That didn't go through. Try again."), findsOneWidget);
    });
  });
}
