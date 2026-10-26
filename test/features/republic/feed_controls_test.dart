import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_template/core/services/api_service.dart';
import 'package:flutter_template/features/auth/domain/entities/user_entity.dart';
import 'package:flutter_template/features/auth/presentation/controllers/auth_controller.dart';
import 'package:flutter_template/features/republic/data/feed_controller.dart';
import 'package:flutter_template/features/republic/data/republic_repository.dart';
import 'package:flutter_template/features/republic/domain/post.dart';
import 'package:flutter_template/features/republic/presentation/pages/republic_page.dart';
import 'package:flutter_template/features/republic/presentation/widgets/post_card.dart';
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

Map<String, dynamic> _post(String id, [String content = 'Post']) => {
      'id': id,
      'content': '$content $id',
      'createdAt': DateTime.now().toUtc().toIso8601String(),
      'author': {'id': 'u', 'name': 'Maria'},
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
    when(() => api.get(any(), query: any(named: 'query'))).thenAnswer(
      (_) async => {
        'data': [_post('1')],
        'nextCursor': null,
      },
    );
  });

  Map<String, dynamic> lastQuery() {
    final calls = verify(
      () => api.get(any(), query: captureAny(named: 'query')),
    ).captured;
    return (calls.last as Map).cast<String, dynamic>();
  }

  group('the request', () {
    test('Partners asks for its tab; no mode or search by default', () async {
      await RepublicRepository(api).feed(tab: 'partners');

      final q = lastQuery();
      expect(q['tab'], 'partners');
      expect(q.containsKey('mode'), isFalse);
      expect(q.containsKey('search'), isFalse);
    });

    test('Top posts and a search are sent along', () async {
      await RepublicRepository(api).feed(top: true, search: '#bonfire');

      final q = lastQuery();
      expect(q['mode'], 'top');
      expect(q['search'], '#bonfire');
    });

    test('an empty search is not sent', () async {
      await RepublicRepository(api).feed(search: '');

      expect(lastQuery().containsKey('search'), isFalse);
    });
  });

  group('the list', () {
    test('choosing Top reloads the feed with the new order', () async {
      final sub = container.listen(feedControllerProvider(null), (_, __) {});
      addTearDown(sub.close);
      await container.read(feedControllerProvider(null).future);
      clearInteractions(api);

      container.read(feedSortProvider.notifier).choose(FeedSort.top);
      await container.read(feedControllerProvider(null).future);

      expect(lastQuery()['mode'], 'top');
    });

    test('a search reloads it, and the next page keeps the search', () async {
      when(() => api.get(any(), query: any(named: 'query'))).thenAnswer(
        (_) async => {
          'data': [_post('1')],
          'nextCursor': 'c2',
        },
      );
      final sub = container.listen(feedControllerProvider(null), (_, __) {});
      addTearDown(sub.close);
      await container.read(feedControllerProvider(null).future);

      container.read(feedSearchProvider.notifier).set('  bonfire ');
      await container.read(feedControllerProvider(null).future);
      clearInteractions(api);
      await container.read(feedControllerProvider(null).notifier).loadMore();

      final q = lastQuery();
      expect(q['search'], 'bonfire');
      expect(q['cursor'], 'c2');
    });

    test('Saved is neither sorted nor searched', () async {
      container.read(feedSortProvider.notifier).choose(FeedSort.top);
      container.read(feedSearchProvider.notifier).set('x');
      const tab = RepublicRepository.savedTab;
      final sub = container.listen(feedControllerProvider(tab), (_, __) {});
      addTearDown(sub.close);

      await container.read(feedControllerProvider(tab).future);

      final q = lastQuery();
      expect(q.containsKey('mode'), isFalse);
      expect(q.containsKey('search'), isFalse);
    });
  });

  group('screens', () {
    Future<void> pumpPage(WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            republicRepositoryProvider
                .overrideWithValue(RepublicRepository(api)),
            authControllerProvider.overrideWith(_Session.new),
          ],
          child: MaterialApp(
            theme: AppTheme.dark,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: const RepublicPage(),
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('there are four tabs and a sort', (tester) async {
      await pumpPage(tester);

      for (final label in ['All', 'Community', 'Marketplace', 'Partners']) {
        expect(find.text(label), findsOneWidget, reason: label);
      }
      expect(find.text('Recent'), findsOneWidget);
    });

    testWidgets('choosing Top posts reads the feed that way', (tester) async {
      await pumpPage(tester);
      clearInteractions(api);

      await tester.tap(find.text('Recent'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Top posts'));
      await tester.pumpAndSettle();

      expect(lastQuery()['mode'], 'top');
      expect(find.text('Top posts'), findsOneWidget);
    });

    testWidgets('searching asks for the words, and an empty answer says so', (
      tester,
    ) async {
      await pumpPage(tester);

      await tester.tap(find.byIcon(Icons.search_rounded));
      await tester.pumpAndSettle();
      when(() => api.get(any(), query: any(named: 'query'))).thenAnswer(
        (_) async => {'data': <Object>[], 'nextCursor': null},
      );
      await tester.enterText(find.byType(TextField), 'zzz');
      await tester.testTextInput.receiveAction(TextInputAction.search);
      await tester.pumpAndSettle();

      expect(lastQuery()['search'], 'zzz');
      expect(find.text('No posts match “zzz”.'), findsOneWidget);

      await tester.tap(find.text('Clear search'));
      await tester.pumpAndSettle();
      expect(find.text('No posts match “zzz”.'), findsNothing);
    });

    testWidgets('a tapped hashtag is handed back with its #', (tester) async {
      String? tapped;
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.dark,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: PostCard(
              post: Post.fromJson(_post('1', 'Join the #bonfire tonight')),
              onLike: () {},
              onComments: () {},
              onHashtag: (t) => tapped = t,
            ),
          ),
        ),
      );

      final text = tester.widget<RichText>(
        find.byWidgetPredicate(
          (w) => w is RichText && w.text.toPlainText().contains('#bonfire'),
        ),
      );
      TextSpan? tag;
      text.text.visitChildren((span) {
        if (span is TextSpan && span.text == '#bonfire') tag = span;
        return true;
      });
      (tag!.recognizer! as TapGestureRecognizer).onTap!();

      expect(tapped, '#bonfire');
    });
  });
}
