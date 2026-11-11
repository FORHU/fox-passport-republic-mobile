import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_template/features/auth/domain/entities/user_entity.dart';
import 'package:flutter_template/features/auth/presentation/controllers/auth_controller.dart';
import 'package:flutter_template/features/profile/presentation/pages/citizen_profile_page.dart';
import 'package:flutter_template/l10n/generated/app_localizations.dart';
import 'package:flutter_template/shared/citizens/citizen_profile.dart';
import 'package:flutter_template/shared/citizens/citizen_repository.dart';
import 'package:flutter_test/flutter_test.dart';

class _Session extends AuthController {
  @override
  AuthState build() => const AuthState(
        user: UserEntity(id: 'me', email: 'a@b.co', name: 'Ada'),
      );
}

const _profile = CitizenProfile(
  id: 'me',
  name: 'Ada Lovelace',
  stamps: [CitizenStamp(id: 's1', eventName: 'Rooftop Sessions')],
  badges: [
    CitizenBadge(id: 'b1', name: 'First Night Out', rarity: 'Common'),
  ],
);

Widget _app(int initialTab) => ProviderScope(
      overrides: [
        authControllerProvider.overrideWith(_Session.new),
        citizenProfileProvider.overrideWith((ref, id) async => _profile),
        citizenCountsProvider.overrideWith((ref, id) async => null),
      ],
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: CitizenProfileView(userId: 'me', initialTab: initialTab),
        ),
      ),
    );

void main() {
  void tall(WidgetTester tester) {
    tester.view
      ..physicalSize = const Size(800, 2400)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);
  }

  testWidgets('opens on Stamps by default', (tester) async {
    tall(tester);
    await tester.pumpWidget(_app(0));
    await tester.pumpAndSettle();

    expect(find.text('Rooftop Sessions'), findsWidgets);
    expect(find.text('First Night Out'), findsNothing);
  });

  testWidgets('opens on Badges when asked', (tester) async {
    tall(tester);
    await tester.pumpWidget(_app(1));
    await tester.pumpAndSettle();

    expect(find.text('First Night Out'), findsOneWidget);
    expect(find.text('Rooftop Sessions'), findsNothing);
  });

  testWidgets('switches to Badges when asked again while it is showing',
      (tester) async {
    tall(tester);
    await tester.pumpWidget(_app(0));
    await tester.pumpAndSettle();
    expect(find.text('Rooftop Sessions'), findsWidgets);

    // The Passport is already on screen when the rank-up sheet sends the
    // person to their badges.
    await tester.pumpWidget(_app(1));
    await tester.pumpAndSettle();

    expect(find.text('First Night Out'), findsOneWidget);
  });
}
