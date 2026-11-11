import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_template/core/services/storage_service.dart';
import 'package:flutter_template/features/auth/presentation/controllers/auth_controller.dart';
import 'package:flutter_template/features/rewards/data/rewards_repository.dart';
import 'package:flutter_template/features/rewards/domain/wallet.dart';
import 'package:flutter_template/l10n/generated/app_localizations.dart';
import 'package:flutter_template/shared/reward_moment/reward_moment.dart';
import 'package:flutter_template/shared/reward_moment/reward_moments.dart';
import 'package:flutter_template/shared/reward_moment/reward_sheet.dart';
import 'package:flutter_template/shared/tickets/ticket.dart';
import 'package:flutter_template/shared/tickets/tickets_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

final _t0 = DateTime.utc(2026, 11, 9, 10);

WalletEntry _attend(String bookingId, {int minutes = 5}) => WalletEntry(
      id: 'g-$bookingId',
      isGrant: true,
      action: 'attend_event',
      coinsDelta: 40,
      refType: 'booking',
      refId: bookingId,
      createdAt: _t0.add(Duration(minutes: minutes)),
    );

Ticket _ticket(String id, String name) => Ticket(
      id: id,
      eventName: name,
      startAt: _t0,
      endAt: _t0.add(const Duration(hours: 4)),
      status: 'completed',
    );

void main() {
  group('the wallet entry', () {
    test('keeps what a grant was for', () {
      final e = WalletEntry.fromJson(const {
        'id': 'g1',
        'type': 'grant',
        'action': 'attend_event',
        'coinsDelta': 40,
        'refType': 'booking',
        'refId': 'b-77',
        'createdAt': '2026-11-09T10:05:00.000Z',
      });

      expect(e.refType, 'booking');
      expect(e.refId, 'b-77');
    });

    test('a change to earlier Coins has no reference', () {
      final e = WalletEntry.fromJson(const {
        'id': 'l1',
        'type': 'lifecycle',
        'lifecycleType': 'REDEMPTION',
        'coinsDelta': -100,
        'createdAt': '2026-11-09T10:05:00.000Z',
      });

      expect(e.refType, isNull);
      expect(e.refId, isNull);
    });
  });

  group('the moment', () {
    test('names the booking the biggest grant was for', () {
      final moments = detectRewardMoments(
        history: [
          _attend('b-77'),
          WalletEntry(
            id: 'x',
            isGrant: true,
            action: 'like_feed',
            coinsDelta: 0,
            refType: 'feed',
            refId: 'p1',
            createdAt: _t0.add(const Duration(minutes: 6)),
          ),
        ],
        seenAt: _t0,
      );

      expect(moments.reward!.bookingId, 'b-77');
    });

    test('a grant for something else names no booking', () {
      final moments = detectRewardMoments(
        history: [
          WalletEntry(
            id: 'x',
            isGrant: true,
            action: 'post_feed',
            coinsDelta: 3,
            refType: 'feed',
            refId: 'p1',
            createdAt: _t0.add(const Duration(minutes: 6)),
          ),
        ],
        seenAt: _t0,
      );

      expect(moments.reward!.bookingId, isNull);
    });
  });

  group('the sheet', () {
    Future<void> open(WidgetTester tester, {String? eventName}) async {
      tester.view
        ..physicalSize = const Size(800, 1800)
        ..devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: RewardSheet(
              reward: const RewardMoment(
                coins: 40,
                action: 'attend_event',
              ),
              eventName: eventName,
            ),
          ),
        ),
      );
    }

    testWidgets('names the event and the new stamp', (tester) async {
      await open(tester, eventName: 'Rooftop Sessions');

      expect(find.text('You attended Rooftop Sessions'), findsOneWidget);
      expect(find.text('New stamp added'), findsOneWidget);
      expect(find.text('Rooftop Sessions'), findsOneWidget); // the stamp row
    });

    testWidgets('without the event it says it generally, with no stamp row',
        (tester) async {
      await open(tester);

      expect(find.text('You attended an event'), findsOneWidget);
      expect(find.text('New stamp added'), findsNothing);
    });
  });

  group('the check', () {
    late SharedPreferences prefs;

    setUp(() async {
      resetRewardMomentGuard();
      SharedPreferences.setMockInitialValues({});
      prefs = await SharedPreferences.getInstance();
      await prefs.setString(rewardSeenAtKey('u1'), _t0.toIso8601String());
    });

    Future<void> run(
      WidgetTester tester, {
      required Future<List<Ticket>> Function() tickets,
    }) async {
      tester.view
        ..physicalSize = const Size(800, 1800)
        ..devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        ProviderScope(
          retry: (_, __) => null,
          overrides: [
            sharedPreferencesProvider.overrideWithValue(prefs),
            currentUserIdProvider.overrideWithValue('u1'),
            walletProvider.overrideWith(
              (ref) async => WalletSummary(
                coins: 100,
                pendingCoins: 0,
                totalEarnedCoins: 100,
                history: [_attend('b-77')],
              ),
            ),
            pastTicketsProvider.overrideWith((ref) => tickets()),
          ],
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Consumer(
              builder: (context, ref, _) => TextButton(
                onPressed: () => showPendingRewardMoments(context, ref),
                child: const Text('check'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('check'));
      await tester.pumpAndSettle();
    }

    testWidgets('finds the event among the tickets by booking', (tester) async {
      await run(
        tester,
        tickets: () async => [
          _ticket('b-1', 'Other Night'),
          _ticket('b-77', 'Rooftop Sessions'),
        ],
      );

      expect(find.text('You attended Rooftop Sessions'), findsOneWidget);
      expect(find.text('New stamp added'), findsOneWidget);
    });

    testWidgets('a booking it cannot find still shows the sheet',
        (tester) async {
      await run(
        tester,
        tickets: () async => [_ticket('b-1', 'Other Night')],
      );

      expect(find.text('You attended an event'), findsOneWidget);
      expect(find.text('New stamp added'), findsNothing);
    });

    testWidgets('tickets that cannot be loaded still show the sheet',
        (tester) async {
      await run(tester, tickets: () async => throw Exception('offline'));

      expect(find.text('You attended an event'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
