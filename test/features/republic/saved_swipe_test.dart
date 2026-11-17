import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_template/core/constants/api_endpoints.dart';
import 'package:flutter_template/core/services/api_service.dart';
import 'package:flutter_template/features/auth/domain/entities/user_entity.dart';
import 'package:flutter_template/features/auth/presentation/controllers/auth_controller.dart';
import 'package:flutter_template/features/republic/data/republic_repository.dart';
import 'package:flutter_template/features/republic/presentation/pages/saved_posts_page.dart';
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

Map<String, dynamic> _post(String id, String text) => {
      'id': id,
      'content': text,
      'createdAt': '2026-01-01T00:00:00.000Z',
      'author': {'id': 'u', 'name': 'Maria'},
      'isSavedByMe': true,
    };

void main() {
  const failedText = "That didn't work. Try again.";
  late _MockApi api;
  var saved = <Map<String, dynamic>>[];

  setUp(() {
    api = _MockApi();
    saved = [_post('p1', 'First saved post'), _post('p2', 'Second saved post')];
    when(() => api.get(any(), query: any(named: 'query'))).thenAnswer(
      (_) async => {'data': List<Map<String, dynamic>>.of(saved)},
    );
    when(() => api.post(ApiEndpoints.feedSave('p1'))).thenAnswer((_) async {
      // First call unsaves (p1 leaves), the second saves it again.
      final has = saved.any((p) => p['id'] == 'p1');
      if (has) {
        saved.removeWhere((p) => p['id'] == 'p1');
      } else {
        saved.insert(0, _post('p1', 'First saved post'));
      }
      return {
        'data': {'saved': !has},
      };
    });
  });

  Future<void> open(WidgetTester tester) async {
    tester.view
      ..physicalSize = const Size(800, 2000)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          republicRepositoryProvider.overrideWithValue(RepublicRepository(api)),
          authControllerProvider.overrideWith(_Session.new),
        ],
        child: MaterialApp(
          theme: AppTheme.dark,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const SavedPostsPage(),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('swiping a saved post away unsaves it, and Undo brings it back', (
    tester,
  ) async {
    await open(tester);
    expect(find.text('First saved post'), findsOneWidget);
    expect(find.text('Second saved post'), findsOneWidget);

    await tester.drag(find.text('First saved post'), const Offset(-800, 0));
    await tester.pumpAndSettle();

    expect(find.text('First saved post'), findsNothing);
    expect(find.text('Second saved post'), findsOneWidget);
    verify(() => api.post(ApiEndpoints.feedSave('p1'))).called(1);
    expect(find.text('Removed from saved'), findsOneWidget);

    await tester.tap(find.text('Undo'));
    await tester.pumpAndSettle();

    verify(() => api.post(ApiEndpoints.feedSave('p1'))).called(1);
    expect(find.text('First saved post'), findsOneWidget);
  });

  testWidgets('a refused unsave puts the post back and says so', (
    tester,
  ) async {
    await open(tester);
    when(() => api.post(ApiEndpoints.feedSave('p1'))).thenAnswer(
      (_) async => throw Exception('server said no'),
    );

    await tester.drag(find.text('First saved post'), const Offset(-800, 0));
    await tester.pumpAndSettle();

    expect(find.text('First saved post'), findsOneWidget);
    expect(find.text('Removed from saved'), findsNothing);
    expect(find.text(failedText), findsOneWidget);
  });
}
