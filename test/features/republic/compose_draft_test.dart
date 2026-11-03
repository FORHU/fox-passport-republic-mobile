import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_template/core/constants/api_endpoints.dart';
import 'package:flutter_template/core/services/api_service.dart';
import 'package:flutter_template/core/services/storage_service.dart';
import 'package:flutter_template/features/auth/domain/entities/user_entity.dart';
import 'package:flutter_template/features/auth/presentation/controllers/auth_controller.dart';
import 'package:flutter_template/features/republic/data/compose_draft.dart';
import 'package:flutter_template/features/republic/data/republic_repository.dart';
import 'package:flutter_template/features/republic/presentation/pages/compose_post_page.dart';
import 'package:flutter_template/l10n/generated/app_localizations.dart';
import 'package:flutter_template/theme/app_theme.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _MockApi extends Mock implements ApiService {}

class _Session extends AuthController {
  @override
  AuthState build() => const AuthState(
        user: UserEntity(id: 'me', email: 'a@b.co', name: 'Ada'),
      );
}

const _key = 'republic.compose_draft.me';

void main() {
  late _MockApi api;

  setUp(() {
    api = _MockApi();
    registerFallbackValue(<String, Object?>{});
  });

  group('ComposeDraftStore', () {
    test('keeps a draft, and forgets it when it is emptied', () async {
      SharedPreferences.setMockInitialValues({});
      final store = ComposeDraftStore(
        await SharedPreferences.getInstance(),
        'me',
      );

      expect(store.read(), isNull);
      await store.write(const ComposeDraft(text: 'Friday night'));
      expect(store.read()?.text, 'Friday night');

      await store.write(const ComposeDraft(text: '  '));
      expect(store.read(), isNull);
    });

    test('a damaged draft reads as none', () async {
      SharedPreferences.setMockInitialValues({_key: '{not json'});
      final store = ComposeDraftStore(
        await SharedPreferences.getInstance(),
        'me',
      );

      expect(store.read(), isNull);
    });

    test('each person has their own draft', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      await ComposeDraftStore(prefs, 'a')
          .write(const ComposeDraft(text: 'mine'));

      expect(ComposeDraftStore(prefs, 'b').read(), isNull);
    });
  });

  group('the composer', () {
    Future<SharedPreferences> open(
      WidgetTester tester,
      Map<String, Object> stored,
    ) async {
      SharedPreferences.setMockInitialValues(stored);
      final prefs = await SharedPreferences.getInstance();
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(prefs),
            republicRepositoryProvider
                .overrideWithValue(RepublicRepository(api)),
            authControllerProvider.overrideWith(_Session.new),
          ],
          child: MaterialApp(
            theme: AppTheme.dark,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: const ComposePostPage(),
          ),
        ),
      );
      await tester.pump();
      return prefs;
    }

    testWidgets('brings back what was typed and not posted', (tester) async {
      await open(tester, {
        _key: '{"text":"Open mic on Friday","options":[],"poll":false}',
      });
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Open mic on Friday'), findsOneWidget);
      expect(find.text('Draft restored'), findsOneWidget);
      await tester.pumpAndSettle(const Duration(seconds: 5));
    });

    testWidgets('keeps the words after typing stops', (tester) async {
      final prefs = await open(tester, {});

      await tester.enterText(find.byType(TextField).first, 'Hello Republic');
      await tester.pump(const Duration(seconds: 1));

      expect(prefs.getString(_key), contains('Hello Republic'));
    });

    testWidgets('keeps the words when you leave before the pause ends', (
      tester,
    ) async {
      final prefs = await open(tester, {});

      await tester.enterText(find.byType(TextField).first, 'Gone in a flash');
      await tester.pumpWidget(const SizedBox());
      await tester.pump();

      expect(prefs.getString(_key), contains('Gone in a flash'));
    });

    testWidgets('posting clears the draft', (tester) async {
      final prefs = await open(tester, {});
      when(() => api.post(ApiEndpoints.feed, any())).thenAnswer(
        (_) async => {
          'data': {'id': 'p1'},
        },
      );

      await tester.enterText(find.byType(TextField).first, 'Hello Republic');
      await tester.pump(const Duration(seconds: 1));
      expect(prefs.getString(_key), isNotNull);

      await tester.tap(find.byType(ElevatedButton));
      await tester.pumpAndSettle(const Duration(seconds: 5));

      expect(prefs.getString(_key), isNull);
    });
  });
}
