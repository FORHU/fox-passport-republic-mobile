import 'package:flutter/material.dart';
import 'package:flutter_template/features/gamification/domain/foxer_board.dart';
import 'package:flutter_template/l10n/generated/app_localizations.dart';
import 'package:flutter_template/shared/widgets/paws.dart';
import 'package:flutter_template/theme/app_theme.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> _show(WidgetTester tester, Widget child, {double width = 320}) =>
    tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(body: SizedBox(width: width, child: child)),
      ),
    );

void main() {
  testWidgets('shows the Paws and the review count', (tester) async {
    await _show(tester, const PawsLabel(paws: 4.83, reviewCount: 32));

    expect(find.text('4.8 · 32'), findsOneWidget);
    expect(find.text('New'), findsNothing);
  });

  testWidgets('is New with no Paws or under 5 reviews', (tester) async {
    await _show(tester, const PawsLabel(paws: null, reviewCount: 3));
    expect(find.text('New'), findsOneWidget);

    await _show(tester, const PawsLabel(paws: 5, reviewCount: 4));
    expect(find.text('New'), findsOneWidget);
    expect(find.textContaining('5.0'), findsNothing);
  });

  testWidgets('five paws draw without overflow at any value', (tester) async {
    for (final v in [0.0, 0.4, 4.3, 5.0, 9.0]) {
      await _show(tester, PawsRow(paws: v), width: 120);
      expect(tester.takeException(), isNull);
      expect(find.byIcon(Icons.pets), findsNWidgets(10));
    }
  });

  test('a board row reads the Paws fields, and tolerates their absence', () {
    final full = FoxerBoardEntry.fromJson(
      const {
        'position': 1,
        'userId': 'u1',
        'name': 'A',
        'paws': 4.8,
        'reviewCount': 32,
        'completedBookings': 40,
        'foxerSince': '2026-01-05T00:00:00.000Z',
        'isVerified': true,
      },
      fallbackRole: LeaderboardRole.venue,
    );
    expect(full.paws, 4.8);
    expect(full.completedBookings, 40);
    expect(full.foxerSince, DateTime.utc(2026, 1, 5));
    expect(full.isVerified, isTrue);

    final old = FoxerBoardEntry.fromJson(
      const {
        'userId': 'u2',
        'starRating': 4.0,
        'reviewCount': 2,
      },
      fallbackRole: LeaderboardRole.venue,
    );
    expect(old.paws, isNull);
    expect(old.isVerified, isFalse);
    expect(old.foxerSince, isNull);
  });
}
