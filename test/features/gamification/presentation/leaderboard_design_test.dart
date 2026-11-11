import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_template/features/auth/presentation/controllers/auth_controller.dart';
import 'package:flutter_template/features/gamification/data/leaderboard_repository.dart';
import 'package:flutter_template/features/gamification/domain/foxer_board.dart';
import 'package:flutter_template/features/gamification/presentation/pages/leaderboard_page.dart';
import 'package:flutter_template/features/gamification/presentation/widgets/board_row.dart';
import 'package:flutter_template/l10n/generated/app_localizations.dart';
import 'package:flutter_template/shared/widgets/segmented_pills.dart';
import 'package:flutter_template/theme/tokens/colors.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _wrap(Widget child) => MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: child,
    );

Color? _fillOf(WidgetTester tester, String label) {
  final box = tester.widget<AnimatedContainer>(
    find
        .ancestor(
          of: find.text(label),
          matching: find.byType(AnimatedContainer),
        )
        .first,
  );
  return (box.decoration! as BoxDecoration).color;
}

/// Boards with nobody on them: these tests are about the page's chrome.
class _EmptyBoards implements LeaderboardRepository {
  @override
  Future<FoxerBoard> foxers(
    LeaderboardRole role, {
    FoxerTab tab = FoxerTab.topRated,
    String? city,
  }) async =>
      FoxerBoard(role: role, tab: tab, rows: const []);
}

void main() {
  group('SegmentedPills', () {
    Widget pills({required bool prominent}) => _wrap(
          Scaffold(
            body: SegmentedPills<int>(
              options: const [
                SegmentOption(1, 'Citizens'),
                SegmentOption(2, 'Foxers'),
              ],
              value: 1,
              prominent: prominent,
              onChanged: (_) {},
            ),
          ),
        );

    testWidgets('prominent: the chosen side is white, the other is clear',
        (tester) async {
      await tester.pumpWidget(pills(prominent: true));

      expect(_fillOf(tester, 'Citizens'), AppColors.textPrimary);
      expect(_fillOf(tester, 'Foxers'), Colors.transparent);
      expect(
        tester.widget<Text>(find.text('Citizens')).style?.color,
        AppColors.canvas,
      );
    });

    testWidgets('by default the chosen side is raised, as everywhere else',
        (tester) async {
      await tester.pumpWidget(pills(prominent: false));

      expect(_fillOf(tester, 'Citizens'), AppColors.surfaceRaised);
    });
  });

  group('BoardRow avatar', () {
    testWidgets('is round for a citizen and a rounded square for a Foxer',
        (tester) async {
      await tester.pumpWidget(
        _wrap(
          const Scaffold(
            body: Column(
              children: [
                BoardRow(
                  position: 1,
                  name: 'Ana',
                  isMe: false,
                ),
                BoardRow(
                  position: 2,
                  name: 'Glass Pavilion',
                  squareAvatar: true,
                  isMe: false,
                ),
              ],
            ),
          ),
        ),
      );

      expect(find.byType(CircleAvatar), findsOneWidget);
      expect(find.byType(ClipRRect), findsOneWidget);
      // The square one shows the initial when there is no picture.
      expect(find.text('G'), findsOneWidget);
      expect(find.text('A'), findsOneWidget);
    });
  });

  group('the page', () {
    testWidgets('has a round back button that goes back', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            leaderboardRepositoryProvider.overrideWithValue(_EmptyBoards()),
            currentUserIdProvider.overrideWithValue('u1'),
          ],
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Builder(
              builder: (context) => Scaffold(
                body: TextButton(
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const LeaderboardPage(
                        initialRole: LeaderboardRole.venue,
                      ),
                    ),
                  ),
                  child: const Text('open'),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      expect(find.text('Leaderboard'), findsOneWidget);
      final back = find.byIcon(Icons.chevron_left_rounded);
      expect(back, findsOneWidget);
      expect(
        tester.getSize(
          find.ancestor(of: back, matching: find.byType(Container)).first,
        ),
        const Size(44, 44),
      );

      await tester.tap(back);
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
      expect(find.text('Leaderboard'), findsNothing);
    });
  });
}
