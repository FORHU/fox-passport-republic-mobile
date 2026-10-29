import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_template/core/constants/api_endpoints.dart';
import 'package:flutter_template/core/services/api_service.dart';
import 'package:flutter_template/features/auth/domain/entities/user_entity.dart';
import 'package:flutter_template/features/auth/presentation/controllers/auth_controller.dart';
import 'package:flutter_template/features/notifications/domain/notification_route.dart';
import 'package:flutter_template/features/republic/data/republic_repository.dart';
import 'package:flutter_template/features/republic/presentation/pages/post_page.dart';
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

Future<void> _pump(
  WidgetTester tester,
  _MockApi api, {
  bool openComments = false,
}) async {
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
        home: PostPage(postId: 'p1', openComments: openComments),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  late _MockApi api;

  setUp(() {
    api = _MockApi();
    when(() => api.get(ApiEndpoints.feedComments('p1')))
        .thenAnswer((_) async => {'data': <Object>[]});
  });

  test('a post link or notification opens that post', () {
    expect(notificationRoute('/republic?postId=p1'), '/republic/post/p1');
    expect(
      notificationRoute('/republic?postId=p1&comments=1'),
      '/republic/post/p1?comments=1',
    );
    expect(notificationRoute('/republic'), '/republic');
  });

  testWidgets('shows the post with its actions', (tester) async {
    when(() => api.get(ApiEndpoints.feedPost('p1'))).thenAnswer(
      (_) async => {
        'data': {
          'id': 'p1',
          'content': 'Open mic on Friday',
          'createdAt': DateTime.now().toUtc().toIso8601String(),
          'author': {'id': 'u1', 'name': 'Maria'},
        },
      },
    );
    await _pump(tester, api);

    expect(find.text('Open mic on Friday'), findsOneWidget);
    expect(find.text('Maria'), findsOneWidget);
  });

  testWidgets('opens the comments when asked to', (tester) async {
    when(() => api.get(ApiEndpoints.feedPost('p1'))).thenAnswer(
      (_) async => {
        'data': {
          'id': 'p1',
          'content': 'Open mic on Friday',
          'createdAt': DateTime.now().toUtc().toIso8601String(),
          'author': {'id': 'u1', 'name': 'Maria'},
        },
      },
    );
    await _pump(tester, api, openComments: true);

    verify(() => api.get(ApiEndpoints.feedComments('p1'))).called(1);
  });

  testWidgets('says so when the post is gone', (tester) async {
    when(() => api.get(ApiEndpoints.feedPost('p1')))
        .thenAnswer((_) async => {'data': null});
    await _pump(tester, api);

    expect(find.text('This post is not available'), findsOneWidget);
  });
}
