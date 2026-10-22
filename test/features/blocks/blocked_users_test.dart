import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_template/core/constants/api_endpoints.dart';
import 'package:flutter_template/core/services/api_service.dart';
import 'package:flutter_template/features/auth/domain/entities/user_entity.dart';
import 'package:flutter_template/features/auth/presentation/controllers/auth_controller.dart';
import 'package:flutter_template/features/blocks/data/blocks_repository.dart';
import 'package:flutter_template/features/blocks/presentation/pages/blocked_users_page.dart';
import 'package:flutter_template/l10n/generated/app_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockApi extends Mock implements ApiService {}

class _Session extends AuthController {
  @override
  AuthState build() => const AuthState(
        user: UserEntity(id: 'u1', email: 'a@b.co', name: 'Ada'),
      );
}

Map<String, Object> _row(String id, String name, {String? username}) => {
      'id': id,
      'name': name,
      if (username != null) 'username': username,
    };

void main() {
  late _MockApi api;

  setUp(() {
    api = _MockApi();
  });

  Future<void> pump(WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        retry: (_, __) => null,
        overrides: [
          authControllerProvider.overrideWith(_Session.new),
          blocksRepositoryProvider.overrideWithValue(BlocksRepository(api)),
        ],
        child: const MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: BlockedUsersPage(),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  void listReturns(List<Map<String, Object>> rows) {
    when(() => api.get(ApiEndpoints.blocks, query: any(named: 'query')))
        .thenAnswer(
      (_) async => {
        'success': true,
        'data': {'data': rows, 'total': rows.length, 'page': 1},
      },
    );
  }

  testWidgets('lists who you blocked, with their usernames', (tester) async {
    listReturns([
      _row('b1', 'Grace Hopper', username: 'grace'),
      _row('b2', 'Linus'),
    ]);

    await pump(tester);

    expect(find.text('Blocked users'), findsOneWidget);
    expect(find.text('Grace Hopper'), findsOneWidget);
    expect(find.text('@grace'), findsOneWidget);
    expect(find.text('Linus'), findsOneWidget);
    expect(find.text('Unblock'), findsNWidgets(2));
  });

  testWidgets('says so when you have not blocked anyone', (tester) async {
    listReturns([]);

    await pump(tester);

    expect(find.text("You haven't blocked anyone."), findsOneWidget);
    expect(find.text('Unblock'), findsNothing);
  });

  testWidgets('unblocking asks the API, then drops them from the list', (
    tester,
  ) async {
    listReturns([_row('b1', 'Grace Hopper')]);
    when(() => api.delete(ApiEndpoints.unblock('b1')))
        .thenAnswer((_) async => {'success': true});
    await pump(tester);
    listReturns([]);

    await tester.tap(find.text('Unblock'));
    await tester.pumpAndSettle();

    verify(() => api.delete(ApiEndpoints.unblock('b1'))).called(1);
    expect(find.text('Grace Hopper'), findsNothing);
    expect(find.text('Grace Hopper was unblocked.'), findsOneWidget);
  });

  testWidgets('keeps them listed and says so when unblocking fails', (
    tester,
  ) async {
    listReturns([_row('b1', 'Grace Hopper')]);
    when(() => api.delete(ApiEndpoints.unblock('b1')))
        .thenThrow(Exception('offline'));
    await pump(tester);

    await tester.tap(find.text('Unblock'));
    await tester.pumpAndSettle();

    expect(find.text('Grace Hopper'), findsOneWidget);
    expect(
      find.text("We couldn't unblock them. Try again."),
      findsOneWidget,
    );
  });

  testWidgets('offers a retry when the list will not load', (tester) async {
    when(() => api.get(ApiEndpoints.blocks, query: any(named: 'query')))
        .thenThrow(Exception('offline'));

    await pump(tester);

    expect(find.text("We couldn't load this right now."), findsOneWidget);
    expect(find.text('Try again'), findsOneWidget);
  });

  test('a row without an id is skipped', () {
    expect(BlockedUser.tryParse({'name': 'No id'}), isNull);
    expect(BlockedUser.tryParse('nope'), isNull);
  });
}
