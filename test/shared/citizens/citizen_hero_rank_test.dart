import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_template/l10n/generated/app_localizations.dart';
import 'package:flutter_template/shared/citizens/citizen_hero.dart';
import 'package:flutter_template/shared/citizens/citizen_profile.dart';
import 'package:flutter_template/shared/citizens/citizen_repository.dart';
import 'package:flutter_template/shared/widgets/rank_badge.dart';
import 'package:flutter_test/flutter_test.dart';

Finder _badge(int rank) =>
    find.byWidgetPredicate((w) => w is RankBadge && w.rank == rank);

Future<void> _show(
  WidgetTester tester, {
  required int level,
  required bool isMe,
}) async {
  tester.view
    ..physicalSize = const Size(800, 2000)
    ..devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        citizenCountsProvider.overrideWith((ref, id) async => null),
      ],
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: SingleChildScrollView(
            child: CitizenHero(
              profile: CitizenProfile(
                id: 'u1',
                name: 'Ian Visperas',
                username: 'ian',
                level: level,
                xp: 4630,
              ),
              isMe: isMe,
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('shows the rank badge and the rank name with the level',
      (tester) async {
    await _show(tester, level: 5, isMe: true);

    expect(_badge(3), findsOneWidget); // level 5 is rank 3
    expect(find.text('Explorer · Level 5'), findsOneWidget);
  });

  testWidgets('moves up a rank at the thresholds', (tester) async {
    await _show(tester, level: 20, isMe: true);
    expect(_badge(6), findsOneWidget);
    expect(find.text('Adventurer · Level 20'), findsOneWidget);

    await _show(tester, level: 19, isMe: true);
    expect(_badge(5), findsOneWidget);
    expect(find.text('Voyager · Level 19'), findsOneWidget);
  });

  testWidgets('a new citizen is a Newcomer', (tester) async {
    await _show(tester, level: 1, isMe: true);

    expect(_badge(1), findsOneWidget);
    expect(find.text('Newcomer · Level 1'), findsOneWidget);
  });

  testWidgets('someone else sees the rank and level too, never the XP',
      (tester) async {
    await _show(tester, level: 12, isMe: false);

    expect(_badge(4), findsOneWidget);
    expect(find.text('Trailblazer · Level 12'), findsOneWidget);
    expect(find.textContaining('XP'), findsNothing);
  });
}
