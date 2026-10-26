import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_template/core/constants/api_endpoints.dart';
import 'package:flutter_template/core/errors/exceptions.dart';
import 'package:flutter_template/core/services/api_service.dart';
import 'package:flutter_template/features/auth/domain/entities/user_entity.dart';
import 'package:flutter_template/features/auth/presentation/controllers/auth_controller.dart';
import 'package:flutter_template/features/event/data/event_repository.dart';
import 'package:flutter_template/features/event/data/waitlist_repository.dart';
import 'package:flutter_template/features/event/domain/waitlist_status.dart';
import 'package:flutter_template/features/event/presentation/pages/event_detail_page.dart';
import 'package:flutter_template/l10n/generated/app_localizations.dart';
import 'package:flutter_template/shared/catalog/catalog_item.dart';
import 'package:flutter_template/shared/currency/currency_providers.dart';
import 'package:flutter_template/shared/events/event_package.dart';
import 'package:flutter_template/shared/location/area.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockApi extends Mock implements ApiService {}

class _Session extends AuthController {
  @override
  AuthState build() => const AuthState(
        user: UserEntity(id: 'me', email: 'a@b.co', name: 'Ada'),
      );
}

class _SignedOut extends AuthController {
  @override
  AuthState build() => const AuthState();
}

/// Answers the waitlist calls from a script and remembers what was asked.
class _FakeWaitlist extends WaitlistRepository {
  _FakeWaitlist({
    this.current = const WaitlistStatus(),
    this.joinFails = false,
  }) : super(_MockApi());

  WaitlistStatus current;
  final bool joinFails;
  final calls = <String>[];

  @override
  Future<WaitlistStatus> status(String templateId) async {
    calls.add('status $templateId');
    return current;
  }

  @override
  Future<WaitlistStatus> join(String templateId) async {
    calls.add('join $templateId');
    if (joinFails) throw const ServerException('Already on the waitlist');
    return current = const WaitlistStatus(
      isOnWaitlist: true,
      position: 3,
      entryId: 'w1',
      totalWaiting: 3,
    );
  }

  @override
  Future<void> leave(String entryId) async {
    calls.add('leave $entryId');
    current = const WaitlistStatus();
  }
}

const _item = CatalogItem(
  id: 'ev1',
  kind: CatalogKind.events,
  title: 'Garden Birthday',
);

Map<String, Object> _json({required int current}) => {
      'id': 'ev1',
      'name': 'Garden Birthday',
      'category': 'birthday',
      'maxAttendees': 10,
      'currentAttendees': current,
      'estimatedTotal': 21000,
      'platformFeeAmount': 1000,
      'images': <Object>[],
      'templateVenues': [
        {
          'id': 'tv1',
          'isOptional': false,
          'agreedPrice': '20000',
          'venue': {'name': 'Garden Hall'},
        },
      ],
    };

void main() {
  late _MockApi api;

  setUp(() {
    api = _MockApi();
  });

  group('WaitlistStatus', () {
    test('reads where you stand', () {
      final s = WaitlistStatus.fromJson(const {
        'isOnWaitlist': true,
        'position': 2,
        'entryId': 'w9',
        'totalWaiting': 5,
      });

      expect(s.isOnWaitlist, isTrue);
      expect(s.position, 2);
      expect(s.entryId, 'w9');
      expect(s.totalWaiting, 5);
    });

    test('joining answers with the row nested under entry', () {
      final s = WaitlistStatus.fromJson(const {
        'entry': {'id': 'w1'},
        'position': 4,
        'totalWaiting': 4,
      });

      expect(s.isOnWaitlist, isTrue);
      expect(s.entryId, 'w1');
      expect(s.position, 4);
    });

    test('not on it, or an empty answer, is not on the waitlist', () {
      final none = WaitlistStatus.fromJson(const {
        'isOnWaitlist': false,
        'position': -1,
        'entryId': null,
        'totalWaiting': 2,
      });

      expect(none.isOnWaitlist, isFalse);
      expect(none.position, isNull);
      expect(none.totalWaiting, 2);
      expect(WaitlistStatus.fromJson(null).isOnWaitlist, isFalse);
    });

    test('leaving takes you off and one off the count, never below zero', () {
      const on = WaitlistStatus(
        isOnWaitlist: true,
        position: 1,
        entryId: 'w',
        totalWaiting: 1,
      );

      expect(on.left.isOnWaitlist, isFalse);
      expect(on.left.totalWaiting, 0);
      expect(const WaitlistStatus().left.totalWaiting, 0);
    });
  });

  group('requests', () {
    test('status, join and leave use the routes the API has', () async {
      when(() => api.get(any(), query: any(named: 'query'))).thenAnswer(
        (_) async => {
          'data': {
            'isOnWaitlist': false,
            'position': null,
            'entryId': null,
            'totalWaiting': 7,
          },
        },
      );
      when(() => api.post(any(), any())).thenAnswer(
        (_) async => {
          'data': {
            'entry': {'id': 'w1'},
            'position': 8,
            'totalWaiting': 8,
          },
        },
      );
      when(() => api.delete(any(), any())).thenAnswer((_) async => {});
      final repo = WaitlistRepository(api);

      expect((await repo.status('t1')).totalWaiting, 7);
      expect((await repo.join('t1')).position, 8);
      await repo.leave('w1');

      verify(
        () => api.get(ApiEndpoints.waitlist, query: {'templateId': 't1'}),
      ).called(1);
      verify(
        () => api.post(ApiEndpoints.waitlist, {'templateId': 't1'}),
      ).called(1);
      verify(() => api.delete(ApiEndpoints.waitlistEntry('w1'))).called(1);
    });
  });

  group('the event page', () {
    Future<_FakeWaitlist> open(
      WidgetTester tester, {
      required int attendees,
      WaitlistStatus status = const WaitlistStatus(),
      bool signedIn = true,
      bool joinFails = false,
    }) async {
      tester.view
        ..physicalSize = const Size(800, 2000)
        ..devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final fake = _FakeWaitlist(current: status, joinFails: joinFails);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            eventPackageProvider.overrideWith(
              (ref, item) async =>
                  EventPackage.fromJson(_json(current: attendees)),
            ),
            waitlistRepositoryProvider.overrideWithValue(fake),
            authControllerProvider
                .overrideWith(signedIn ? _Session.new : _SignedOut.new),
            displayCurrencyProvider.overrideWithValue('PHP'),
            fxRatesProvider.overrideWith((ref) async => null),
            profileLocationProvider
                .overrideWith((ref) async => const ProfileLocation()),
          ],
          child: const MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: EventDetailPage(item: _item),
          ),
        ),
      );
      await tester.pumpAndSettle();
      return fake;
    }

    testWidgets('a full event offers to join the waitlist, not to book', (
      tester,
    ) async {
      await open(tester, attendees: 10);

      expect(find.textContaining('This event is full.'), findsOneWidget);
      expect(find.text('Join waitlist'), findsOneWidget);
      expect(find.text('Choose a date'), findsNothing);
    });

    testWidgets('joining puts you on it and says where you stand', (
      tester,
    ) async {
      final fake = await open(tester, attendees: 10);

      await tester.tap(find.text('Join waitlist'));
      await tester.pumpAndSettle();

      expect(fake.calls, contains('join ev1'));
      expect(find.text('Leave waitlist'), findsOneWidget);
      expect(find.textContaining("You're number 3 of 3"), findsOneWidget);
      expect(find.text("You're on the waitlist."), findsOneWidget);
    });

    testWidgets('someone already on it sees their place and can leave', (
      tester,
    ) async {
      final fake = await open(
        tester,
        attendees: 10,
        status: const WaitlistStatus(
          isOnWaitlist: true,
          position: 2,
          entryId: 'w9',
          totalWaiting: 5,
        ),
      );

      expect(find.textContaining("You're number 2 of 5"), findsOneWidget);

      await tester.tap(find.text('Leave waitlist'));
      await tester.pumpAndSettle();

      expect(fake.calls, contains('leave w9'));
      expect(find.text('Join waitlist'), findsOneWidget);
      expect(find.text('You left the waitlist.'), findsOneWidget);
    });

    testWidgets('a refusal is shown and nothing changes', (tester) async {
      await open(tester, attendees: 10, joinFails: true);

      await tester.tap(find.text('Join waitlist'));
      await tester.pumpAndSettle();

      expect(find.text('Already on the waitlist'), findsOneWidget);
      expect(find.text('Join waitlist'), findsOneWidget);
    });

    testWidgets('signed out, joining asks to sign in and sends nothing', (
      tester,
    ) async {
      final fake = await open(tester, attendees: 10, signedIn: false);

      await tester.tap(find.text('Join waitlist'));
      await tester.pumpAndSettle();

      expect(find.text('Sign in to continue'), findsOneWidget);
      expect(fake.calls.where((c) => c.startsWith('join')), isEmpty);
    });

    testWidgets('when a spot opens, booking is back, with a note', (
      tester,
    ) async {
      await open(
        tester,
        attendees: 9,
        status: const WaitlistStatus(
          isOnWaitlist: true,
          position: 1,
          entryId: 'w9',
          totalWaiting: 1,
        ),
      );

      expect(find.textContaining('A spot opened up'), findsOneWidget);
      expect(find.text('Choose a date'), findsOneWidget);
      expect(find.text('Join waitlist'), findsNothing);
    });

    testWidgets('an event with room has no waitlist at all', (tester) async {
      final fake = await open(tester, attendees: 4);

      expect(find.text('Choose a date'), findsOneWidget);
      expect(find.text('Join waitlist'), findsNothing);
      expect(find.textContaining('A spot opened up'), findsNothing);
      expect(fake.calls, isNotEmpty);
    });
  });
}
