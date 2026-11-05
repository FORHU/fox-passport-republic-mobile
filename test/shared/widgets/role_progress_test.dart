import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_template/core/constants/api_endpoints.dart';
import 'package:flutter_template/core/errors/exceptions.dart';
import 'package:flutter_template/core/services/api_service.dart';
import 'package:flutter_template/features/rewards/data/rewards_repository.dart';
import 'package:flutter_template/l10n/generated/app_localizations.dart';
import 'package:flutter_template/shared/widgets/role_progress.dart';
import 'package:flutter_template/theme/app_theme.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockApi extends Mock implements ApiService {}

Map<String, dynamic> _wallet({String rank = 'Veteran', int level = 12}) => {
      'success': true,
      'data': {
        'coins': 1240,
        'pendingCoins': 0,
        'totalEarnedCoins': 1240,
        'level': level,
        'rank': rank,
        'history': <Object>[],
      },
    };

void main() {
  late _MockApi api;

  setUp(() => api = _MockApi());

  Future<void> show(WidgetTester tester, {String path = 'venueFoxer'}) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          rewardsRepositoryProvider.overrideWithValue(RewardsRepository(api)),
        ],
        child: MaterialApp(
          theme: AppTheme.dark,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(body: RoleProgress(path: path)),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('shows the role rank and level, and the Coins', (tester) async {
    when(() => api.get(ApiEndpoints.rewardsMe, query: {'path': 'venueFoxer'}))
        .thenAnswer((_) async => _wallet());

    await show(tester);

    expect(find.text('Veteran · Level 12'), findsOneWidget);
    expect(find.text('1,240'), findsOneWidget);
  });

  testWidgets('asks for the path of the space it is in', (tester) async {
    when(() => api.get(ApiEndpoints.rewardsMe, query: {'path': 'eventFoxer'}))
        .thenAnswer((_) async => _wallet(rank: 'Pro', level: 6));

    await show(tester, path: 'eventFoxer');

    expect(find.text('Pro · Level 6'), findsOneWidget);
    verify(
      () => api.get(ApiEndpoints.rewardsMe, query: {'path': 'eventFoxer'}),
    ).called(1);
  });

  testWidgets('still shows the Coins when the server names no rank', (
    tester,
  ) async {
    when(() => api.get(ApiEndpoints.rewardsMe, query: {'path': 'venueFoxer'}))
        .thenAnswer((_) async => _wallet(rank: ''));

    await show(tester);

    expect(find.textContaining('Level'), findsNothing);
    expect(find.text('1,240'), findsOneWidget);
  });

  testWidgets('takes no room when the wallet cannot be had', (tester) async {
    when(() => api.get(ApiEndpoints.rewardsMe, query: {'path': 'venueFoxer'}))
        .thenThrow(const NetworkException());

    await show(tester);

    expect(tester.getSize(find.byType(RoleProgress)), Size.zero);
  });
}
