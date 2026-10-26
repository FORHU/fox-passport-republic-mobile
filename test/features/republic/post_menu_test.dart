import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_template/core/constants/api_endpoints.dart';
import 'package:flutter_template/core/services/api_service.dart';
import 'package:flutter_template/features/auth/domain/entities/user_entity.dart';
import 'package:flutter_template/features/auth/presentation/controllers/auth_controller.dart';
import 'package:flutter_template/features/republic/data/feed_controller.dart';
import 'package:flutter_template/features/republic/data/republic_repository.dart';
import 'package:flutter_template/features/republic/domain/post.dart';
import 'package:flutter_template/features/republic/presentation/widgets/post_card.dart';
import 'package:flutter_template/features/republic/presentation/widgets/post_menu_sheet.dart';
import 'package:flutter_template/l10n/generated/app_localizations.dart';
import 'package:flutter_template/theme/app_theme.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockApi extends Mock implements ApiService {}

class _Session extends AuthController {
  @override
  AuthState build() => const AuthState(
        user: UserEntity(id: 'me', email: 'a@b.co', name: 'Ada'),
      );
}

Map<String, dynamic> _post(String id, {bool saved = false}) => {
      'id': id,
      'content': 'Post $id',
      'createdAt': DateTime.now().toUtc().toIso8601String(),
      'isSavedByMe': saved,
      'author': {'id': 'someone', 'name': 'Maria'},
    };

void main() {
  late _MockApi api;
  late ProviderContainer container;

  setUp(() {
    api = _MockApi();
    container = ProviderContainer(
      overrides: [
        republicRepositoryProvider.overrideWithValue(RepublicRepository(api)),
      ],
    );
    addTearDown(container.dispose);
  });

  void feedOf(List<Map<String, dynamic>> posts, {String? endpoint}) {
    when(
      () => api.get(endpoint ?? ApiEndpoints.feed, query: any(named: 'query')),
    ).thenAnswer((_) async => {'data': posts, 'nextCursor': null});
  }

  List<Post> postsOf(String? tab) =>
      container.read(feedControllerProvider(tab)).requireValue.posts;

  group('requests', () {
    test('save, hide, delete, edit and report go where the web sends them',
        () async {
      when(() => api.post(any(), any())).thenAnswer(
        (_) async => {
          'data': {'saved': true},
        },
      );
      when(() => api.delete(any(), any())).thenAnswer((_) async => {});
      when(() => api.patch(any(), any())).thenAnswer((_) async => {});
      final repo = RepublicRepository(api);

      expect(await repo.toggleSave('p1'), isTrue);
      await repo.hide('p1');
      await repo.delete('p1');
      await repo.edit('p1', '  new words ');
      await repo.report('p1', 'Spam');

      verify(() => api.post(ApiEndpoints.feedSave('p1'))).called(1);
      verify(() => api.post(ApiEndpoints.feedHide('p1'))).called(1);
      verify(() => api.delete(ApiEndpoints.feedPost('p1'))).called(1);
      verify(
        () => api.patch(ApiEndpoints.feedPost('p1'), {'content': 'new words'}),
      ).called(1);
      verify(
        () => api.post(
          ApiEndpoints.reports,
          {'targetType': 'post', 'targetId': 'p1', 'reason': 'Spam'},
        ),
      ).called(1);
    });
  });

  group('the list', () {
    test('saving marks the post saved', () async {
      feedOf([_post('1')]);
      when(() => api.post(any(), any())).thenAnswer(
        (_) async => {
          'data': {'saved': true},
        },
      );
      await container.read(feedControllerProvider(null).future);

      final ok = await container
          .read(feedControllerProvider(null).notifier)
          .toggleSave('1');

      expect(ok, isTrue);
      expect(postsOf(null).single.isSavedByMe, isTrue);
    });

    test('Saved reads /feed/saved, and unsaving drops the post', () async {
      feedOf(
        [_post('1', saved: true), _post('2', saved: true)],
        endpoint: ApiEndpoints.feedSaved,
      );
      when(() => api.post(any(), any())).thenAnswer(
        (_) async => {
          'data': {'saved': false},
        },
      );
      const tab = RepublicRepository.savedTab;
      await container.read(feedControllerProvider(tab).future);

      await container
          .read(feedControllerProvider(tab).notifier)
          .toggleSave('1');

      expect([for (final p in postsOf(tab)) p.id], ['2']);
    });

    test('delete and hide take the post off, edit changes its words', () async {
      feedOf([_post('1'), _post('2'), _post('3')]);
      when(() => api.delete(any(), any())).thenAnswer((_) async => {});
      when(() => api.post(any(), any())).thenAnswer((_) async => {});
      when(() => api.patch(any(), any())).thenAnswer((_) async => {});
      await container.read(feedControllerProvider(null).future);
      final c = container.read(feedControllerProvider(null).notifier);

      await c.delete('1');
      await c.hide('2');
      await c.edit('3', ' Better ');

      expect(postsOf(null), hasLength(1));
      expect(postsOf(null).single.content, 'Better');
      expect(postsOf(null).single.edited, isTrue);
    });

    test('a refused delete leaves the post where it is', () async {
      feedOf([_post('1')]);
      when(() => api.delete(any(), any())).thenThrow(Exception('no'));
      await container.read(feedControllerProvider(null).future);

      await expectLater(
        container.read(feedControllerProvider(null).notifier).delete('1'),
        throwsException,
      );
      expect(postsOf(null), hasLength(1));
    });
  });

  group('screens', () {
    Future<void> pump(WidgetTester tester, Widget child) => tester.pumpWidget(
          ProviderScope(
            overrides: [authControllerProvider.overrideWith(_Session.new)],
            child: MaterialApp(
              theme: AppTheme.dark,
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              home: Scaffold(body: SingleChildScrollView(child: child)),
            ),
          ),
        );

    testWidgets('a long post folds behind See more', (tester) async {
      final long = Post.fromJson({
        ..._post('1'),
        'content': List.filled(60, 'word').join(' '),
      });
      await pump(
        tester,
        PostCard(post: long, onLike: () {}, onComments: () {}),
      );

      expect(
        find.textContaining('See more', findRichText: true),
        findsOneWidget,
      );
    });

    testWidgets('there is no menu button unless asked for', (tester) async {
      final post = Post.fromJson(_post('1'));
      await pump(
        tester,
        PostCard(post: post, onLike: () {}, onComments: () {}),
      );
      expect(find.byIcon(Icons.more_horiz_rounded), findsNothing);

      await pump(
        tester,
        PostCard(
          post: post,
          onLike: () {},
          onComments: () {},
          onMore: () {},
        ),
      );
      expect(find.byIcon(Icons.more_horiz_rounded), findsOneWidget);
    });

    Future<void> open(WidgetTester tester, {required bool owner}) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.dark,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Builder(
            builder: (context) => Scaffold(
              body: TextButton(
                onPressed: () => showPostMenu(
                  context,
                  isOwner: owner,
                  saved: false,
                  canCopyLink: false,
                ),
                child: const Text('open'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
    }

    testWidgets('your own post can be edited or deleted', (tester) async {
      await open(tester, owner: true);

      expect(find.text('Edit post'), findsOneWidget);
      expect(find.text('Delete post'), findsOneWidget);
      expect(find.text('Report post'), findsNothing);
      expect(find.text('Save post'), findsOneWidget);
      expect(find.text('Copy link'), findsNothing);
    });

    testWidgets('someone elses post can be hidden or reported', (tester) async {
      await open(tester, owner: false);

      expect(find.text('Hide post'), findsOneWidget);
      expect(find.text('Report post'), findsOneWidget);
      expect(find.text('Edit post'), findsNothing);
      expect(find.text('Delete post'), findsNothing);
    });
  });
}
