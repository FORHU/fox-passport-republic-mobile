import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_template/features/auth/domain/entities/user_entity.dart';
import 'package:flutter_template/features/auth/presentation/controllers/auth_controller.dart';
import 'package:flutter_template/features/onboarding/presentation/controllers/onboarding_controller.dart';
import 'package:flutter_template/features/onboarding/presentation/pages/onboarding_page.dart';
import 'package:flutter_template/features/onboarding/presentation/widgets/onboarding_chrome.dart';
import 'package:flutter_template/l10n/generated/app_localizations.dart';
import 'package:flutter_template/shared/roles/role_catalog.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

const _user = UserEntity(id: 'u1', email: 'ada@example.com', name: 'Ada');

class _Session extends AuthController {
  @override
  AuthState build() => const AuthState(user: _user);
}

/// Onboarding parked on one step, with nothing to load.
class _Onboarding extends OnboardingController {
  _Onboarding(this._state);

  final OnboardingState _state;

  @override
  OnboardingState build() => _state;
}

Future<void> _pump(
  WidgetTester tester,
  OnboardingStep step, {
  required double width,
}) async {
  tester.view
    ..physicalSize = Size(width, 2400)
    ..devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    ProviderScope(
      retry: (_, __) => null,
      overrides: [
        authControllerProvider.overrideWith(_Session.new),
        onboardingControllerProvider.overrideWith(
          () => _Onboarding(OnboardingState(isLoading: false, step: step)),
        ),
      ],
      child: const MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: OnboardingPage(),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

/// The left edge every block in the card lines up with: the footer's
/// stretched primary action.
double _contentLeft(WidgetTester tester) =>
    tester.getTopLeft(find.byType(OutlineActionButton)).dx;

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  group('roles step', () {
    testWidgets('two columns: cards in a row share one height', (tester) async {
      await _pump(tester, OnboardingStep.roles, width: 600);

      final cards = find.byType(RoleCard);
      expect(cards, findsNWidgets(roleCatalog.length));
      for (var i = 0; i + 1 < roleCatalog.length; i += 2) {
        final left = tester.getRect(cards.at(i));
        final right = tester.getRect(cards.at(i + 1));
        expect(right.top, left.top, reason: 'row ${i ~/ 2} top');
        expect(right.height, left.height, reason: 'row ${i ~/ 2} height');
        expect(right.left, greaterThan(left.right));
      }
    });

    testWidgets('two columns: an odd last card stays in the left column',
        (tester) async {
      await _pump(tester, OnboardingStep.roles, width: 600);

      final cards = find.byType(RoleCard);
      final first = tester.getRect(cards.first);
      final last = tester.getRect(cards.last);
      expect(last.left, first.left);
      if (roleCatalog.length.isOdd) expect(last.width, first.width);
    });

    testWidgets('one column: every card spans the content width',
        (tester) async {
      await _pump(tester, OnboardingStep.roles, width: 360);

      final contentLeft = _contentLeft(tester);
      final contentWidth =
          tester.getSize(find.byType(OutlineActionButton)).width;
      for (final card in find.byType(RoleCard).evaluate()) {
        final rect = tester.getRect(find.byWidget(card.widget));
        expect(rect.left, contentLeft);
        expect(rect.width, contentWidth);
      }
    });

    testWidgets('Back lines up with the content edge', (tester) async {
      await _pump(tester, OnboardingStep.roles, width: 360);

      final arrow = find.descendant(
        of: find.byType(BackAction),
        matching: find.byIcon(Icons.arrow_back_rounded),
      );
      expect(tester.getTopLeft(arrow).dx, _contentLeft(tester));
      // Still a full-size tap target.
      expect(
        tester.getSize(find.byType(BackAction)).height,
        greaterThanOrEqualTo(48),
      );
    });
  });

  testWidgets('intent options: icon and arrow share one top line',
      (tester) async {
    await _pump(tester, OnboardingStep.intent, width: 360);

    final icon = tester.getRect(find.byIcon(Icons.local_activity_rounded));
    final arrow =
        tester.getRect(find.byIcon(Icons.arrow_forward_rounded).first);
    expect(arrow.center.dy, closeTo(icon.center.dy, 0.5));
  });
}
