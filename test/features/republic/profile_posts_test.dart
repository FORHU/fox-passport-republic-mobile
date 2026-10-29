import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_template/core/services/api_service.dart';
import 'package:flutter_template/features/auth/domain/entities/user_entity.dart';
import 'package:flutter_template/features/auth/presentation/controllers/auth_controller.dart';
import 'package:flutter_template/features/republic/data/republic_repository.dart';
import 'package:flutter_template/features/republic/presentation/widgets/post_card.dart';
import 'package:flutter_template/features/republic/presentation/widgets/profile_posts.dart';
import 'package:flutter_template/l10n/generated/app_localizations.dart';
import 'package:flutter_template/shared/widgets/post_media.dart';
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

Map<String, dynamic> _post(String id, {List<String> media = const []}) => {
      'id': id,
      'content': 'Post $id',
      'createdAt': DateTime.now().toUtc().toIso8601String(),
      'author': {'id': 'u1', 'name': 'Rex Santos'},
      'mediaUrls': media,
      'likesCount': 2,
      'commentsCount': 1,
    };

void main() {
  late _MockApi api;

  Future<void> pump(WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authControllerProvider.overrideWith(_Session.new),
          republicRepositoryProvider.overrideWithValue(RepublicRepository(api)),
        ],
        child: MaterialApp(
          theme: AppTheme.dark,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const Scaffold(
            body: SingleChildScrollView(child: ProfilePosts(authorId: 'u1')),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
  }

  setUp(() {
    api = _MockApi();
    when(() => api.get(any(), query: any(named: 'query'))).thenAnswer(
      (_) async => {
        'data': [
          _post('1', media: ['https://img.test/a.jpg']),
          _post('2'),
        ],
        'nextCursor': null,
      },
    );
  });

  test('asks the feed for that person by author, not by tab', () async {
    await RepublicRepository(api).feed(tab: RepublicRepository.authorTab('u1'));

    final q = (verify(
      () => api.get(any(), query: captureAny(named: 'query')),
    ).captured.last as Map)
        .cast<String, dynamic>();
    expect(q['authorId'], 'u1');
    expect(q.containsKey('tab'), isFalse);
  });

  testWidgets('shows their posts as feed cards, with photos', (tester) async {
    await pump(tester);

    expect(find.byType(PostCard), findsNWidgets(2));
    expect(find.text('Post 1'), findsOneWidget);
    expect(find.byType(PostMedia), findsOneWidget);
    // The same actions as the Republic.
    expect(find.text('Like'), findsNWidgets(2));
    expect(find.text('Comments'), findsNWidgets(2));
    expect(find.text('Share'), findsNWidgets(2));
  });

  testWidgets('Like is sent for the post that was tapped', (tester) async {
    when(() => api.post(any(), any()))
        .thenAnswer((_) async => {'data': <String, dynamic>{}});
    await pump(tester);

    await tester.tap(find.text('Like').first);
    await tester.pump(const Duration(milliseconds: 100));

    verify(() => api.post(any(that: contains('1')), any())).called(1);
  });

  testWidgets('says so when they have no posts', (tester) async {
    when(() => api.get(any(), query: any(named: 'query')))
        .thenAnswer((_) async => {'data': <Object>[], 'nextCursor': null});
    await pump(tester);

    expect(find.text('No Republic posts yet'), findsOneWidget);
  });
}
