import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_template/features/auth/presentation/controllers/auth_controller.dart';
import 'package:flutter_template/features/rewards/data/rewards_repository.dart';
import 'package:flutter_template/features/rewards/domain/daily_login.dart';
import 'package:flutter_template/features/rewards/domain/wallet.dart';
import 'package:flutter_template/l10n/generated/app_localizations.dart';
import 'package:flutter_template/shared/widgets/daily_login_card.dart';
import 'package:flutter_template/shared/widgets/daily_login_dialog.dart';
import 'package:flutter_template/theme/app_theme.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockRepo extends Mock implements RewardsRepository {}

const _flat = [15, 15, 15, 15, 15, 15, 15];

const _open = DailyLoginStatus(
  claimedToday: false,
  canClaim: true,
  amount: 15,
  nextAmount: 15,
  streak: 0,
  cycle: _flat,
);

const _claimedToday = DailyLoginStatus(
  claimedToday: true,
  canClaim: false,
  amount: 15,
  nextAmount: 15,
  streak: 3,
  cycleDay: 3,
  cycle: _flat,
);

WalletSummary _wallet(int coins) => WalletSummary(
      coins: coins,
      pendingCoins: 0,
      totalEarnedCoins: coins,
      history: const [],
    );

void main() {
  late _MockRepo repo;

  setUp(() => repo = _MockRepo());

  Future<void> show(
    WidgetTester tester, {
    int? balance,
    Size size = const Size(900, 2000),
  }) async {
    tester.view
      ..physicalSize = size
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          rewardsRepositoryProvider.overrideWithValue(repo),
          currentUserIdProvider.overrideWithValue('me'),
          // No network: the Tokens chip and the modal read the wallet.
          walletProvider.overrideWith((ref) async {
            if (balance == null) throw Exception('no');
            return _wallet(balance);
          }),
        ],
        child: MaterialApp(
          theme: AppTheme.dark,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const Scaffold(body: Column(children: [DailyLoginCard()])),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  group('the daily login model', () {
    test('reads the status', () {
      final s = DailyLoginStatus.fromJson(const {
        'claimedToday': false,
        'canClaim': false,
        'reason': 'email_not_verified',
        'amount': 15,
        'streak': 2,
      });
      expect(s.block, DailyLoginBlock.emailNotVerified);
      expect(s.amount, 15);
      expect(s.streak, 2);
    });

    test('reads the 7-day cycle', () {
      final s = DailyLoginStatus.fromJson(const {
        'claimedToday': true,
        'canClaim': false,
        'amount': 5,
        'nextAmount': 5,
        'streak': 3,
        'cycleDay': 3,
        'cycle': [5, 5, 5, 5, 5, 5, 20],
      });
      expect(s.cycleDay, 3);
      expect(s.cycle, [5, 5, 5, 5, 5, 5, 20]);
      expect(s.day7Amount, 20);
      expect(s.tomorrow, 5);
    });

    test('has no week to draw when the server sends no cycle', () {
      final s = DailyLoginStatus.fromJson(const {'amount': 15});
      expect(s.cycle, isEmpty);
      expect(s.day7Amount, 0);
      expect(s.cycleDay, 1);
      // Tomorrow falls back to today's amount.
      expect(s.tomorrow, 15);
    });

    test('holds the cycle day to 1 to 7', () {
      expect(DailyLoginStatus.fromJson(const {'cycleDay': 99}).cycleDay, 7);
      expect(DailyLoginStatus.fromJson(const {'cycleDay': 0}).cycleDay, 1);
    });

    test('knows each reason and ignores one it does not know', () {
      expect(
        DailyLoginBlock.tryParse('cap_reached'),
        DailyLoginBlock.capReached,
      );
      expect(DailyLoginBlock.tryParse('inactive'), DailyLoginBlock.inactive);
      expect(
        DailyLoginBlock.tryParse('no_attended_booking'),
        DailyLoginBlock.noAttendedBooking,
      );
      expect(DailyLoginBlock.tryParse('something_new'), isNull);
      expect(DailyLoginBlock.tryParse(null), isNull);
    });

    test('survives a reply with nothing in it', () {
      final c = DailyLoginClaim.fromJson(const {});
      expect(c.claimed, isFalse);
      expect(c.coinsAwarded, 0);
      expect(c.status.canClaim, isFalse);
    });
  });

  group('the daily login card', () {
    testWidgets('offers the claim while today is unclaimed', (tester) async {
      when(() => repo.dailyLogin()).thenAnswer((_) async => _open);
      await show(tester);

      expect(find.text('Daily login'), findsOneWidget);
      expect(find.text('+15 Tokens'), findsOneWidget);
      expect(find.text('Claim'), findsOneWidget);
    });

    testWidgets('is one slim row with a small button', (tester) async {
      when(() => repo.dailyLogin()).thenAnswer((_) async => _open);
      await show(tester, size: const Size(360, 640));

      expect(tester.takeException(), isNull);
      // The card and the button are small: not a tall block with a button
      // across the whole width.
      expect(
        tester.getSize(find.byType(DailyLoginCard)).height,
        lessThan(110),
      );
      expect(tester.getSize(find.byType(ElevatedButton)).width, lessThan(140));
      expect(find.text('+15 Tokens'), findsOneWidget);
    });

    testWidgets('shows the streak when there is one', (tester) async {
      when(() => repo.dailyLogin()).thenAnswer(
        (_) async => const DailyLoginStatus(
          claimedToday: false,
          canClaim: true,
          amount: 15,
          streak: 4,
          cycleDay: 5,
          cycle: _flat,
        ),
      );
      await show(tester);
      expect(find.text('+15 Tokens · 4-day streak'), findsOneWidget);
    });

    testWidgets('a claim pays once and opens the Day done modal', (
      tester,
    ) async {
      var claimed = false;
      when(() => repo.dailyLogin()).thenAnswer(
        (_) async => claimed ? _claimedToday : _open,
      );
      when(() => repo.claimDailyLogin()).thenAnswer((_) async {
        claimed = true;
        return const DailyLoginClaim(
          claimed: true,
          coinsAwarded: 15,
          status: _claimedToday,
        );
      });
      await show(tester, balance: 1255);

      await tester.tap(find.text('Claim'));
      await tester.pumpAndSettle();

      verify(() => repo.claimDailyLogin()).called(1);
      // The modal: what was paid, and the new balance.
      expect(find.byType(DailyLoginDialog), findsOneWidget);
      expect(find.text('CLAIMED'), findsOneWidget);
      expect(find.text('Day 3 done'), findsOneWidget);
      expect(find.text('New balance'), findsOneWidget);
      expect(find.text('1,255 Tokens'), findsOneWidget);
      // On the dialog's chip.
      expect(find.text('+15 Tokens'), findsOneWidget);

      await tester.tap(find.text('Done'));
      await tester.pumpAndSettle();
      expect(find.byType(DailyLoginDialog), findsNothing);
      // Behind it the card now says claimed.
      expect(find.text('Claimed today'), findsOneWidget);
      expect(find.text('3-day streak'), findsOneWidget);
      expect(find.text('Claim'), findsNothing);
    });

    testWidgets('a second tap while claiming does not claim twice', (
      tester,
    ) async {
      when(() => repo.dailyLogin()).thenAnswer((_) async => _open);
      when(() => repo.claimDailyLogin()).thenAnswer((_) async {
        await Future<void>.delayed(const Duration(milliseconds: 200));
        return const DailyLoginClaim(
          claimed: true,
          coinsAwarded: 15,
          status: _claimedToday,
        );
      });
      await show(tester);

      await tester.tap(find.text('Claim'));
      await tester.pump();
      // The button is busy: a tap now is ignored.
      await tester.tap(find.byType(ElevatedButton), warnIfMissed: false);
      await tester.pumpAndSettle();

      verify(() => repo.claimDailyLogin()).called(1);
    });

    testWidgets('shows claimed when today was already claimed', (tester) async {
      when(() => repo.dailyLogin()).thenAnswer((_) async => _claimedToday);
      await show(tester);

      expect(find.text('Claimed today'), findsOneWidget);
      expect(find.text('Come back tomorrow for +15 Tokens.'), findsOneWidget);
      expect(find.byType(ElevatedButton), findsNothing);
    });

    testWidgets('says to verify the email instead of offering a claim', (
      tester,
    ) async {
      when(() => repo.dailyLogin()).thenAnswer(
        (_) async => const DailyLoginStatus(
          claimedToday: false,
          canClaim: false,
          block: DailyLoginBlock.emailNotVerified,
          amount: 15,
          streak: 0,
        ),
      );
      await show(tester);

      expect(
        find.text('Verify your email to claim your daily Tokens.'),
        findsOneWidget,
      );
      expect(find.byType(ElevatedButton), findsNothing);
    });

    testWidgets('says a paid booking is needed this month', (tester) async {
      when(() => repo.dailyLogin()).thenAnswer(
        (_) async => const DailyLoginStatus(
          claimedToday: false,
          canClaim: false,
          block: DailyLoginBlock.noAttendedBooking,
          amount: 15,
          streak: 0,
        ),
      );
      await show(tester);

      expect(find.textContaining('attended a paid booking'), findsOneWidget);
      expect(
        find.text('Verify your email to claim your daily Tokens.'),
        findsNothing,
      );
      expect(find.byType(ElevatedButton), findsNothing);
    });

    testWidgets('says the monthly limit is reached', (tester) async {
      when(() => repo.dailyLogin()).thenAnswer(
        (_) async => const DailyLoginStatus(
          claimedToday: false,
          canClaim: false,
          block: DailyLoginBlock.capReached,
          amount: 15,
          streak: 5,
        ),
      );
      await show(tester);

      expect(find.textContaining("this month's limit"), findsOneWidget);
      expect(find.byType(ElevatedButton), findsNothing);
    });

    testWidgets('takes no room when the rule is off', (tester) async {
      when(() => repo.dailyLogin()).thenAnswer(
        (_) async => const DailyLoginStatus(
          claimedToday: false,
          canClaim: false,
          block: DailyLoginBlock.inactive,
          amount: 0,
          streak: 0,
        ),
      );
      await show(tester);
      expect(find.text('Daily login'), findsNothing);
    });

    testWidgets('takes no room when it cannot be reached', (tester) async {
      when(() => repo.dailyLogin()).thenAnswer((_) async => throw Exception());
      await show(tester);
      expect(find.text('Daily login'), findsNothing);
    });

    testWidgets('a failed claim says so and stays claimable', (tester) async {
      when(() => repo.dailyLogin()).thenAnswer((_) async => _open);
      when(() => repo.claimDailyLogin()).thenAnswer(
        (_) async => throw Exception('offline'),
      );
      await show(tester);

      await tester.tap(find.text('Claim'));
      await tester.pumpAndSettle();

      expect(
        find.text("We couldn't claim that right now. Try again."),
        findsOneWidget,
      );
      expect(find.byType(DailyLoginDialog), findsNothing);
      expect(find.text('Claim'), findsOneWidget);
    });
  });

  group('the daily login modal', () {
    testWidgets('tapping the card opens the week, with today to claim', (
      tester,
    ) async {
      when(() => repo.dailyLogin()).thenAnswer((_) async => _open);
      await show(tester);

      await tester.tap(find.text('Daily login'));
      await tester.pumpAndSettle();

      expect(find.byType(DailyLoginDialog), findsOneWidget);
      expect(find.text('Day 1 of 7'), findsOneWidget);
      expect(
        find.text('Log in every day to build your streak.'),
        findsOneWidget,
      );
      // Seven days, each with what it pays.
      expect(find.text('+15'), findsNWidgets(7));
      expect(find.text('Claim +15 Tokens'), findsOneWidget);
      expect(find.text('Not now'), findsNothing);
    });

    testWidgets('the close button closes it without claiming', (tester) async {
      when(() => repo.dailyLogin()).thenAnswer((_) async => _open);
      await show(tester);
      await tester.tap(find.text('Daily login'));
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.close_rounded));
      await tester.pumpAndSettle();

      expect(find.byType(DailyLoginDialog), findsNothing);
      verifyNever(() => repo.claimDailyLogin());
      expect(find.text('Claim'), findsOneWidget);
    });

    testWidgets('claiming inside it turns it into the Day done view', (
      tester,
    ) async {
      var claimed = false;
      when(() => repo.dailyLogin()).thenAnswer(
        (_) async => claimed ? _claimedToday : _open,
      );
      when(() => repo.claimDailyLogin()).thenAnswer((_) async {
        claimed = true;
        return const DailyLoginClaim(
          claimed: true,
          coinsAwarded: 15,
          status: _claimedToday,
        );
      });
      await show(tester, balance: 1255);
      await tester.tap(find.text('Daily login'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Claim +15 Tokens'));
      await tester.pumpAndSettle();

      verify(() => repo.claimDailyLogin()).called(1);
      expect(find.text('Day 3 done'), findsOneWidget);
      expect(find.text('New balance'), findsOneWidget);
      expect(find.text('Done'), findsOneWidget);
      expect(find.text('Not now'), findsNothing);
    });

    testWidgets('opened on a claimed day it shows the balance, not a payment', (
      tester,
    ) async {
      when(() => repo.dailyLogin()).thenAnswer((_) async => _claimedToday);
      await show(tester, balance: 425);
      await tester.tap(find.text('Claimed today'));
      await tester.pumpAndSettle();

      expect(find.text('Day 3 done'), findsOneWidget);
      expect(find.text('Come back tomorrow for +15 Tokens.'), findsWidgets);
      expect(find.text('Balance'), findsOneWidget);
      expect(find.text('425 Tokens'), findsOneWidget);
      expect(find.text('New balance'), findsNothing);
      // Nothing was paid just now, so there is no payment chip.
      expect(find.text('+15 Tokens'), findsNothing);
    });

    testWidgets('says what day 7 pays when it pays more', (tester) async {
      when(() => repo.dailyLogin()).thenAnswer(
        (_) async => const DailyLoginStatus(
          claimedToday: false,
          canClaim: true,
          amount: 5,
          nextAmount: 5,
          streak: 2,
          cycleDay: 3,
          cycle: [5, 5, 5, 5, 5, 5, 20],
        ),
      );
      await show(tester);
      await tester.tap(find.text('Daily login'));
      await tester.pumpAndSettle();

      expect(find.text('Day 3 of 7'), findsOneWidget);
      expect(find.textContaining('Day 7 pays +20.'), findsOneWidget);
      expect(find.text('+20'), findsOneWidget);
      expect(find.text('+5'), findsNWidgets(6));
    });

    testWidgets('says nothing about day 7 when every day pays the same', (
      tester,
    ) async {
      when(() => repo.dailyLogin()).thenAnswer((_) async => _open);
      await show(tester);
      await tester.tap(find.text('Daily login'));
      await tester.pumpAndSettle();

      expect(find.textContaining('Day 7 pays'), findsNothing);
    });

    testWidgets('draws no week when the server sent no cycle', (tester) async {
      when(() => repo.dailyLogin()).thenAnswer(
        (_) async => const DailyLoginStatus(
          claimedToday: false,
          canClaim: true,
          amount: 15,
          streak: 0,
        ),
      );
      await show(tester);
      await tester.tap(find.text('Daily login'));
      await tester.pumpAndSettle();

      expect(find.byType(DailyLoginDialog), findsOneWidget);
      expect(find.text('Claim +15 Tokens'), findsOneWidget);
      expect(find.text('+15'), findsNothing);
    });

    testWidgets('gives the reason and a Done button when it cannot be claimed',
        (
      tester,
    ) async {
      when(() => repo.dailyLogin()).thenAnswer(
        (_) async => const DailyLoginStatus(
          claimedToday: false,
          canClaim: false,
          block: DailyLoginBlock.emailNotVerified,
          amount: 15,
          streak: 0,
          cycle: _flat,
        ),
      );
      await show(tester);
      await tester.tap(find.text('Daily login'));
      await tester.pumpAndSettle();

      expect(
        find.text('Verify your email to claim your daily Tokens.'),
        findsWidgets,
      );
      expect(find.text('Done'), findsOneWidget);
      expect(find.textContaining('Claim +'), findsNothing);
    });

    testWidgets('the close button closes it', (tester) async {
      when(() => repo.dailyLogin()).thenAnswer((_) async => _open);
      await show(tester);
      await tester.tap(find.text('Daily login'));
      await tester.pumpAndSettle();

      await tester.tap(find.byTooltip('Close'));
      await tester.pumpAndSettle();
      expect(find.byType(DailyLoginDialog), findsNothing);
    });
  });
}
