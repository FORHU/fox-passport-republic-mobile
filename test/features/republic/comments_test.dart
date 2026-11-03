import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_template/core/constants/api_endpoints.dart';
import 'package:flutter_template/core/services/api_service.dart';
import 'package:flutter_template/features/auth/domain/entities/user_entity.dart';
import 'package:flutter_template/features/auth/presentation/controllers/auth_controller.dart';
import 'package:flutter_template/features/republic/data/republic_repository.dart';
import 'package:flutter_template/features/republic/domain/post.dart';
import 'package:flutter_template/features/republic/presentation/widgets/comments_sheet.dart';
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

Map<String, dynamic> _comment(
  String id, {
  String by = 'someone',
  String name = 'Maria',
  int likes = 0,
  bool liked = false,
  String? updatedAt,
  List<Map<String, dynamic>> replies = const [],
}) =>
    {
      'id': id,
      'content': 'Comment $id',
      'createdAt': '2026-01-01T00:00:00.000Z',
      'updatedAt': updatedAt ?? '2026-01-01T00:00:00.000Z',
      'likesCount': likes,
      'isLikedByMe': liked,
      'author': {'id': by, 'name': name},
      'replies': replies,
    };

void main() {
  late _MockApi api;

  setUp(() {
    api = _MockApi();
  });

  group('PostComment', () {
    test('reads likes, whether it was edited, and its replies', () {
      final c = PostComment.fromJson(
        _comment(
          'a',
          likes: 3,
          liked: true,
          updatedAt: '2026-01-02T00:00:00.000Z',
          replies: [_comment('b')],
        ),
      );

      expect(c.likesCount, 3);
      expect(c.isLikedByMe, isTrue);
      expect(c.edited, isTrue);
      expect(c.replies.single.edited, isFalse);
    });
  });

  group('requests', () {
    test('like, edit and delete go where the web sends them', () async {
      when(() => api.post(any(), any())).thenAnswer(
        (_) async => {
          'data': {'liked': true, 'likesCount': 4},
        },
      );
      when(() => api.patch(any(), any())).thenAnswer((_) async => {});
      when(() => api.delete(any(), any())).thenAnswer((_) async => {});
      final repo = RepublicRepository(api);

      final like = await repo.toggleCommentLike('p', 'c');
      await repo.editComment('p', 'c', ' new ');
      await repo.deleteComment('p', 'c');

      expect(like.liked, isTrue);
      expect(like.count, 4);
      verify(() => api.post(ApiEndpoints.feedCommentLike('p', 'c'))).called(1);
      verify(
        () => api.patch(ApiEndpoints.feedComment('p', 'c'), {'content': 'new'}),
      ).called(1);
      verify(() => api.delete(ApiEndpoints.feedComment('p', 'c'))).called(1);
    });
  });

  group('the sheet', () {
    late List<Map<String, dynamic>> comments;

    Future<void> open(WidgetTester tester) async {
      when(() => api.get(ApiEndpoints.feedComments('p'))).thenAnswer(
        (_) async => {'data': comments},
      );
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
            home: Builder(
              builder: (context) => Scaffold(
                body: TextButton(
                  onPressed: () =>
                      showCommentsSheet(context, postId: 'p', signedIn: true),
                  child: const Text('open'),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
    }

    setUp(() {
      comments = [
        _comment('1', replies: [_comment('2', by: 'me', name: 'Ada')]),
        _comment('3', by: 'me', name: 'Ada'),
      ];
    });

    testWidgets(
        'only your own comments have a menu; only top ones take a '
        'reply', (tester) async {
      await open(tester);

      // Two of the three are Ada's (the reply and comment 3).
      expect(find.byIcon(Icons.more_horiz_rounded), findsNWidgets(2));
      expect(find.text('Reply'), findsNWidgets(2));
      expect(find.text('Like'), findsNWidgets(3));
    });

    testWidgets('liking shows at once and uses the count the server gives', (
      tester,
    ) async {
      when(() => api.post(any(), any())).thenAnswer(
        (_) async => {
          'data': {'liked': true, 'likesCount': 7},
        },
      );
      await open(tester);

      await tester.tap(find.text('Like').first);
      await tester.pumpAndSettle();

      expect(find.text('7'), findsOneWidget);
      verify(
        () => api.post(ApiEndpoints.feedCommentLike('p', '1')),
      ).called(1);
    });

    testWidgets('a refused like is taken back', (tester) async {
      when(() => api.post(any(), any())).thenThrow(Exception('no'));
      await open(tester);

      await tester.tap(find.text('Like').first);
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.favorite_rounded), findsNothing);
    });

    testWidgets('Reply says who, and sends the comment as the parent', (
      tester,
    ) async {
      when(() => api.post(any(), any())).thenAnswer((_) async => {});
      await open(tester);

      await tester.tap(find.text('Reply').first);
      await tester.pumpAndSettle();
      expect(find.text('Replying to Maria'), findsOneWidget);

      await tester.enterText(find.byType(TextField), 'Thanks!');
      await tester.tap(find.byIcon(Icons.send_rounded));
      await tester.pumpAndSettle();

      verify(
        () => api.post(
          ApiEndpoints.feedComments('p'),
          {'content': 'Thanks!', 'parentId': '1'},
        ),
      ).called(1);
      expect(find.text('Replying to Maria'), findsNothing);
    });

    testWidgets('Edit fills the field and saves over the comment', (
      tester,
    ) async {
      when(() => api.patch(any(), any())).thenAnswer((_) async => {});
      await open(tester);

      await tester.tap(find.byIcon(Icons.more_horiz_rounded).last);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Edit'));
      await tester.pumpAndSettle();

      expect(find.text('Editing your comment'), findsOneWidget);
      expect(
        tester.widget<TextField>(find.byType(TextField)).controller!.text,
        'Comment 3',
      );

      await tester.enterText(find.byType(TextField), 'Changed');
      await tester.tap(find.byIcon(Icons.send_rounded));
      await tester.pumpAndSettle();

      verify(
        () => api.patch(
          ApiEndpoints.feedComment('p', '3'),
          {'content': 'Changed'},
        ),
      ).called(1);
    });

    testWidgets('Delete asks first, then removes it', (tester) async {
      when(() => api.delete(any(), any())).thenAnswer((_) async => {});
      await open(tester);

      await tester.tap(find.byIcon(Icons.more_horiz_rounded).last);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Delete comment'));
      await tester.pumpAndSettle();
      verifyNever(() => api.delete(any(), any()));

      await tester.tap(find.text('Delete'));
      await tester.pumpAndSettle();

      verify(() => api.delete(ApiEndpoints.feedComment('p', '3'))).called(1);
    });
  });
}
