import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_template/features/auth/presentation/controllers/auth_controller.dart';
import 'package:flutter_template/features/rewards/data/rewards_repository.dart';
import 'package:flutter_template/features/rewards/domain/daily_login.dart';
import 'package:flutter_template/l10n/generated/app_localizations.dart';
import 'package:flutter_template/shared/widgets/daily_login_card.dart';
import 'package:flutter_template/theme/app_theme.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockRepo extends Mock implements RewardsRepository {}

const _open = DailyLoginStatus(
  claimedToday: false,
  canClaim: true,
  amount: 15,
  streak: 0,
);

const _claimedToday = DailyLoginStatus(
  claimedToday: true,
  canClaim: false,
  amount: 15,
  streak: 3,
);

void main() {
  late _MockRepo repo;

  setUp(() => repo = _MockRepo());

  Future<void> show(WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          rewardsRepositoryProvider.overrideWithValue(repo),
          currentUserIdProvider.overrideWithValue('me'),
          // No network: the Tokens chip reads the wallet.
          walletProvider.overrideWith((ref) async => throw Exception('no')),
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

    test('knows each reason and ignores one it does not know', () {
      expect(
        DailyLoginBlock.tryParse('cap_reached'),
        DailyLoginBlock.capReached,
      );
      expect(DailyLoginBlock.tryParse('inactive'), DailyLoginBlock.inactive);
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

    testWidgets('is one slim row with a small button', (
      tester,
    ) async {
      tester.view
        ..physicalSize = const Size(360, 640)
        ..devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      when(() => repo.dailyLogin()).thenAnswer(
        (_) async => const DailyLoginStatus(
          claimedToday: false,
          canClaim: true,
          amount: 15,
          streak: 0,
        ),
      );
      await show(tester);

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
        ),
      );
      await show(tester);
      expect(find.text('+15 Tokens · 4-day streak'), findsOneWidget);
      expect(find.text('+15 Tokens'), findsNothing);
    });

    testWidgets('a claim pays once and the card says claimed', (tester) async {
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
      await show(tester);

      await tester.tap(find.text('Claim'));
      await tester.pumpAndSettle();

      verify(() => repo.claimDailyLogin()).called(1);
      expect(find.text('Claimed today'), findsOneWidget);
      expect(find.text('Come back tomorrow for +15 Tokens.'), findsOneWidget);
      expect(find.text('3-day streak'), findsOneWidget);
      expect(find.text('Claim'), findsNothing);
      expect(find.text('+15 Tokens added'), findsOneWidget);
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
      expect(find.text('Claim'), findsOneWidget);
    });
  });
}
