import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_template/core/services/api_service.dart';
import 'package:flutter_template/features/auth/domain/entities/user_entity.dart';
import 'package:flutter_template/features/auth/presentation/controllers/auth_controller.dart';
import 'package:flutter_template/features/profile/presentation/pages/citizen_profile_page.dart';
import 'package:flutter_template/features/spaces/data/bids_repository.dart';
import 'package:flutter_template/features/spaces/data/spaces_repository.dart';
import 'package:flutter_template/features/spaces/domain/open_slot.dart';
import 'package:flutter_template/features/spaces/presentation/pages/open_slots_page.dart';
import 'package:flutter_template/l10n/generated/app_localizations.dart';
import 'package:flutter_template/shared/citizens/citizen_profile.dart';
import 'package:flutter_template/shared/citizens/citizen_repository.dart';
import 'package:flutter_template/shared/currency/currency.dart';
import 'package:flutter_template/shared/currency/currency_providers.dart';
import 'package:flutter_template/shared/follow/follow_button.dart';
import 'package:flutter_template/shared/follow/follow_repository.dart';
import 'package:flutter_template/shared/follow/follow_status.dart';
import 'package:flutter_template/theme/app_theme.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

// The app theme makes every ElevatedButton and OutlinedButton as wide as its
// parent allows (`Size.fromHeight`). A button in a Row with no width limit then
// asks for infinite width and the layout throws, so these run under the real
// theme, which the default test theme would hide.

class _MockApi extends Mock implements ApiService {}

class _Session extends AuthController {
  @override
  AuthState build() => const AuthState(
        user: UserEntity(id: 'me', email: 'a@b.co', name: 'Ada'),
      );
}

class _Follows extends FollowRepository {
  _Follows(this.current) : super(_MockApi());

  final FollowStatus current;

  @override
  Future<FollowStatus> status(String userId) async => current;
}

class _Bids extends BidsRepository {
  _Bids() : super(_MockApi());

  @override
  Future<List<OpenSlotEvent>> openSlots() async => const [
        OpenSlotEvent(
          id: 'e1',
          name: 'Launch party',
          slots: [
            OpenSlot(id: 's1', price: 3000, currency: 'PHP', description: 'DJ'),
          ],
        ),
      ];
}

Future<void> _pump(
  WidgetTester tester,
  Widget home, {
  List<Override> overrides = const [],
}) async {
  tester.view
    ..physicalSize = const Size(360, 800)
    ..devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        authControllerProvider.overrideWith(_Session.new),
        moneyFormatterProvider
            .overrideWithValue(const MoneyFormatter(currency: 'PHP')),
        ...overrides,
      ],
      child: MaterialApp(
        theme: AppTheme.dark,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: home,
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  for (final state in FollowState.values) {
    testWidgets('the Follow button lays out when it is ${state.name}', (
      tester,
    ) async {
      await _pump(
        tester,
        const Scaffold(body: Center(child: FollowButton(userId: 'u1'))),
        overrides: [
          followRepositoryProvider.overrideWithValue(
            _Follows(FollowStatus(state: state, followers: 3)),
          ),
        ],
      );

      expect(tester.takeException(), isNull);
      expect(find.byType(FollowButton), findsOneWidget);
    });
  }

  testWidgets('Open event slots lays out its Apply buttons', (tester) async {
    await _pump(
      tester,
      const OpenSlotsPage(),
      overrides: [
        bidsRepositoryProvider.overrideWithValue(_Bids()),
        myServicesProvider.overrideWith((ref) async => const []),
      ],
    );

    expect(tester.takeException(), isNull);
    expect(find.text('Apply'), findsOneWidget);
  });

  testWidgets('a profile lays out Follow and Message side by side', (
    tester,
  ) async {
    await _pump(
      tester,
      CitizenProfilePage(userId: 'u1', onMessage: (_, __) async {}),
      overrides: [
        followRepositoryProvider
            .overrideWithValue(_Follows(const FollowStatus(followers: 9))),
        citizenProfileProvider.overrideWith(
          (ref, id) async => CitizenProfile.tryParse({
            'id': 'u1',
            'name': 'Rex Santos',
            'roleType': ['eventFoxer'],
          })!,
        ),
        citizenCountsProvider.overrideWith(
          (ref, id) async =>
              const CitizenFollowCounts(followers: 9, following: 4),
        ),
      ],
    );

    expect(tester.takeException(), isNull);
    expect(find.text('Follow'), findsOneWidget);
    expect(find.text('Message'), findsOneWidget);
  });
}
