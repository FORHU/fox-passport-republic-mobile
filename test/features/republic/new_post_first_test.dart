import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_template/core/constants/api_endpoints.dart';
import 'package:flutter_template/core/services/api_service.dart';
import 'package:flutter_template/features/auth/domain/entities/user_entity.dart';
import 'package:flutter_template/features/auth/presentation/controllers/auth_controller.dart';
import 'package:flutter_template/features/republic/data/feed_controller.dart';
import 'package:flutter_template/features/republic/data/republic_repository.dart';
import 'package:flutter_template/features/republic/domain/new_post.dart';
import 'package:flutter_template/features/republic/domain/post.dart';
import 'package:flutter_template/features/republic/presentation/pages/republic_page.dart';
import 'package:flutter_template/l10n/generated/app_localizations.dart';
import 'package:flutter_template/routes/route_names.dart';
import 'package:flutter_template/theme/app_theme.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';

class _MockApi extends Mock implements ApiService {}

class _Session extends AuthController {
  @override
  AuthState build() => const AuthState(
        user: UserEntity(id: 'me', email: 'a@b.co', name: 'Ada'),
      );
}

Map<String, dynamic> _post(
  String id,
  String content, {
  bool pinned = false,
  String tab = 'community',
}) =>
    {
      'id': id,
      'content': content,
      'tab': tab,
      'isPinned': pinned,
      'createdAt': DateTime.now().toUtc().toIso8601String(),
      'author': {'id': 'u', 'name': 'Maria'},
    };

void main() {
  late _MockApi api;

  setUp(() {
    api = _MockApi();
  });

  group('the data', () {
    test('creating a post hands back its id', () async {
      when(() => api.post(any(), any())).thenAnswer(
        (_) async => {
          'success': true,
          'data': {'id': 'p9'},
        },
      );

      final id = await RepublicRepository(api).createPost(
        const NewPost(type: ComposeType.story, content: 'Hi'),
      );

      expect(id, 'p9');
    });

    test('an answer with no id is null, not a crash', () async {
      when(() => api.post(any(), any())).thenAnswer((_) async => {});

      final id = await RepublicRepository(api).createPost(
        const NewPost(type: ComposeType.story, content: 'Hi'),
      );

      expect(id, isNull);
    });

    test('a new post goes first, once, even if it is already in the list',
        () async {
      when(() => api.get(any(), query: any(named: 'query'))).thenAnswer(
        (_) async => {
          'data': [
            _post('a', 'pinned', pinned: true),
            _post('b', 'second'),
          ],
          'nextCursor': null,
        },
      );
      final container = ProviderContainer(
        overrides: [
          republicRepositoryProvider.overrideWithValue(RepublicRepository(api)),
        ],
      );
      addTearDown(container.dispose);
      final sub = container.listen(feedControllerProvider(null), (_, __) {});
      addTearDown(sub.close);
      await container.read(feedControllerProvider(null).future);

      container.read(feedControllerProvider(null).notifier)
        ..addFirst(Post.fromJson(_post('n', 'mine')))
        ..addFirst(Post.fromJson(_post('n', 'mine')));

      final ids = [
        for (final p
            in container.read(feedControllerProvider(null)).requireValue.posts)
          p.id,
      ];
      expect(ids, ['n', 'a', 'b']);
    });
  });

  group('after writing a post', () {
    Future<void> open(
      WidgetTester tester, {
      required String composeReturns,
      String? startTab,
    }) async {
      when(() => api.get(ApiEndpoints.feed, query: any(named: 'query')))
          .thenAnswer(
        (_) async => {
          'data': [
            _post('a', 'PINNED ONE', pinned: true),
            _post('b', 'An older post'),
          ],
          'nextCursor': null,
        },
      );
      when(() => api.get(ApiEndpoints.feedPost('n1'))).thenAnswer(
        (_) async => {'data': _post('n1', 'MY NEW POST')},
      );

      final router = GoRouter(
        routes: [
          GoRoute(path: '/', builder: (_, __) => const RepublicPage()),
          GoRoute(
            path: RouteNames.republicCompose,
            builder: (context, _) => Scaffold(
              body: TextButton(
                onPressed: () => context.pop(composeReturns),
                child: const Text('SEND'),
              ),
            ),
          ),
        ],
      );
      addTearDown(router.dispose);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            republicRepositoryProvider
                .overrideWithValue(RepublicRepository(api)),
            authControllerProvider.overrideWith(_Session.new),
          ],
          child: MaterialApp.router(
            routerConfig: router,
            theme: AppTheme.dark,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
          ),
        ),
      );
      await tester.pumpAndSettle();

      if (startTab != null) {
        await tester.tap(find.text(startTab));
        await tester.pumpAndSettle();
      }
      await tester.tap(find.text("What's on your mind?"));
      await tester.pumpAndSettle();
      await tester.tap(find.text('SEND'));
      await tester.pumpAndSettle();
    }

    testWidgets('it shows first, above the featured posts', (tester) async {
      await open(tester, composeReturns: 'n1');

      final mine = tester.getTopLeft(find.text('MY NEW POST'));
      final pinned = tester.getTopLeft(find.text('PINNED ONE'));
      expect(mine.dy, lessThan(pinned.dy));
      expect(find.text('Posted.'), findsOneWidget);
    });

    testWidgets('with no id to read it back, the list is simply reloaded', (
      tester,
    ) async {
      await open(tester, composeReturns: '');

      // Initial load plus the reload.
      verify(() => api.get(ApiEndpoints.feed, query: any(named: 'query')))
          .called(2);
      verifyNever(() => api.get(ApiEndpoints.feedPost('n1')));
    });

    testWidgets('a post from a tab that is not open opens its own tab', (
      tester,
    ) async {
      // The new post is a community story; the Partners tab is open.
      await open(tester, composeReturns: 'n1', startTab: 'Partners');

      verify(
        () => api.get(
          ApiEndpoints.feed,
          query: {'limit': 10, 'tab': 'community'},
        ),
      ).called(1);
      expect(find.text('MY NEW POST'), findsOneWidget);
    });
  });
}
