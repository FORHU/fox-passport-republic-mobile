import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_template/core/services/api_service.dart';
import 'package:flutter_template/features/auth/domain/entities/user_entity.dart';
import 'package:flutter_template/features/auth/presentation/controllers/auth_controller.dart';
import 'package:flutter_template/features/republic/data/republic_repository.dart';
import 'package:flutter_template/features/republic/domain/post.dart';
import 'package:flutter_template/features/republic/presentation/pages/compose_post_page.dart';
import 'package:flutter_template/features/republic/presentation/pages/saved_posts_page.dart';
import 'package:flutter_template/features/republic/presentation/widgets/post_card.dart';
import 'package:flutter_template/l10n/generated/app_localizations.dart';
import 'package:flutter_template/routes/route_names.dart';
import 'package:flutter_template/theme/app_theme.dart';
import 'package:flutter_template/theme/tokens/colors.dart';
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

// Found on the phone: these are small things only a real screen shows.
void main() {
  testWidgets(
    'an avatar circle is not the colour of the sheets it sits on',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.dark,
          home: const Scaffold(
            body: AuthorAvatar(author: PostAuthor(id: 'u', name: 'Jasmine')),
          ),
        ),
      );

      final fill = tester
          .widgetList<ColoredBox>(
            find.descendant(
              of: find.byType(AuthorAvatar),
              matching: find.byType(ColoredBox),
            ),
          )
          .first
          .color;

      // The comments, share and menu sheets are all AppColors.surface; a
      // circle in the same colour is just a letter floating on the sheet.
      expect(fill, isNot(AppColors.surface));
      expect(fill, isNot(AppColors.canvas));
    },
  );

  testWidgets('the composer words field has rounded corners', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [authControllerProvider.overrideWith(_Session.new)],
        child: MaterialApp(
          theme: AppTheme.dark,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const ComposePostPage(),
        ),
      ),
    );
    await tester.pump();

    final border = tester
        .widget<TextField>(find.byType(TextField).first)
        .decoration!
        .border! as OutlineInputBorder;

    expect(border.borderRadius.topLeft.x, greaterThan(0));
    expect(border.borderSide, BorderSide.none);
  });

  group('an empty Saved list', () {
    late _MockApi api;

    setUp(() {
      api = _MockApi();
      when(() => api.get(any(), query: any(named: 'query'))).thenAnswer(
        (_) async => {'data': <Object>[], 'nextCursor': null},
      );
    });

    Future<void> open(WidgetTester tester) async {
      final router = GoRouter(
        routes: [
          GoRoute(path: '/', builder: (_, __) => const SavedPostsPage()),
          GoRoute(
            path: RouteNames.republic,
            builder: (_, __) => const Scaffold(body: Text('REPUBLIC')),
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
    }

    testWidgets('has a picture, the words, and a way to go and save one', (
      tester,
    ) async {
      await open(tester);

      expect(find.byIcon(Icons.bookmark_border_rounded), findsOneWidget);
      expect(
        find.text('Nothing saved yet. Save a post from its menu.'),
        findsOneWidget,
      );
      expect(find.text('Browse Republic'), findsOneWidget);
    });

    testWidgets('the button goes to the Republic', (tester) async {
      await open(tester);

      await tester.tap(find.text('Browse Republic'));
      await tester.pumpAndSettle();

      expect(find.text('REPUBLIC'), findsOneWidget);
    });
  });
}
