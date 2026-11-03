import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_template/features/auth/domain/entities/user_entity.dart';
import 'package:flutter_template/features/auth/presentation/controllers/auth_controller.dart';
import 'package:flutter_template/features/spaces/presentation/widgets/first_steps_card.dart';
import 'package:flutter_template/features/spaces/presentation/widgets/overview_header.dart';
import 'package:flutter_template/l10n/generated/app_localizations.dart';
import 'package:flutter_template/theme/app_theme.dart';
import 'package:flutter_template/theme/tokens/colors.dart';
import 'package:flutter_test/flutter_test.dart';

class _Session extends AuthController {
  _Session(this.roles, this.name);

  final List<String> roles;
  final String name;

  @override
  AuthState build() => AuthState(
        user: UserEntity(
          id: 'u1',
          email: 'u1@example.com',
          name: name,
          roleType: roles,
        ),
      );
}

Widget _app(
  Widget child, {
  List<String> roles = const ['venueFoxer'],
  String name = '',
}) {
  return ProviderScope(
    overrides: [
      authControllerProvider.overrideWith(() => _Session(roles, name)),
    ],
    child: MaterialApp(
      theme: AppTheme.dark,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(body: SingleChildScrollView(child: child)),
    ),
  );
}

void main() {
  group('FirstStepsCard', () {
    testWidgets('counts the steps done and opens the next one', (
      tester,
    ) async {
      var opened = '';
      await tester.pumpWidget(
        _app(
          FirstStepsCard(
            steps: [
              const FirstStep(label: 'List a venue', done: true),
              FirstStep(
                label: 'Connect payouts',
                done: false,
                onTap: () => opened = 'payouts',
              ),
              FirstStep(
                label: 'Approve a partner',
                done: false,
                onTap: () => opened = 'partner',
              ),
            ],
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Getting started'), findsOneWidget);
      expect(find.text('1 of 3 steps done'), findsOneWidget);
      // One third, shown in the ring once it has settled.
      expect(find.text('33%'), findsOneWidget);

      await tester.tap(find.text('Connect payouts'));
      expect(opened, 'payouts');
    });

    testWidgets('does not show once every step is done', (tester) async {
      await tester.pumpWidget(
        _app(
          const FirstStepsCard(
            steps: [FirstStep(label: 'List a venue', done: true)],
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Getting started'), findsNothing);
    });

    testWidgets('a step already done is not tappable', (tester) async {
      var taps = 0;
      await tester.pumpWidget(
        _app(
          FirstStepsCard(
            steps: [
              FirstStep(label: 'Done step', done: true, onTap: () => taps++),
              const FirstStep(label: 'Next step', done: false),
            ],
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Done step'));
      expect(taps, 0);
    });
  });

  group('ProgressRing', () {
    testWidgets('counts up from zero while it fills', (tester) async {
      await tester.pumpWidget(_app(const ProgressRing(value: 0.5)));
      expect(find.text('0%'), findsOneWidget);

      await tester.pump(const Duration(milliseconds: 600));
      final midway = find.text('0%');
      expect(midway, findsNothing);

      await tester.pumpAndSettle();
      expect(find.text('50%'), findsOneWidget);
    });

    testWidgets('shows the final value at once with reduced motion', (
      tester,
    ) async {
      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(disableAnimations: true),
          child: _app(const ProgressRing(value: 0.5)),
        ),
      );

      expect(find.text('50%'), findsOneWidget);
    });
  });

  group('OverviewGreeting', () {
    testWidgets('names the role, and counts the others held', (tester) async {
      await tester.pumpWidget(
        _app(
          const OverviewGreeting(
            roleLabel: 'Venue Foxer',
            roleColor: AppColors.roleVenue,
          ),
          roles: const ['venueFoxer', 'eventFoxer'],
          name: 'Ada Lovelace',
        ),
      );
      await tester.pump();

      expect(find.text('Venue Foxer'), findsOneWidget);
      expect(find.text('+1'), findsOneWidget);
      // The greeting uses the first name only (morning, afternoon or evening).
      expect(find.textContaining(', Ada'), findsOneWidget);
      expect(find.textContaining('Lovelace'), findsNothing);
    });

    testWidgets('has nothing to name when there is no name', (tester) async {
      await tester.pumpWidget(
        _app(
          const OverviewGreeting(
            roleLabel: 'Venue Foxer',
            roleColor: AppColors.roleVenue,
          ),
        ),
      );
      await tester.pump();

      expect(find.text('Welcome back'), findsOneWidget);
    });

    testWidgets('shows no count for a single role', (tester) async {
      await tester.pumpWidget(
        _app(
          const OverviewGreeting(
            roleLabel: 'Venue Foxer',
            roleColor: AppColors.roleVenue,
          ),
        ),
      );
      await tester.pump();

      expect(find.textContaining('+'), findsNothing);
    });
  });
}
