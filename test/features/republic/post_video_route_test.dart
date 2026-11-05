import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_template/core/services/api_service.dart';
import 'package:flutter_template/features/auth/domain/entities/user_entity.dart';
import 'package:flutter_template/features/auth/presentation/controllers/auth_controller.dart';
import 'package:flutter_template/features/republic/data/reel_player.dart';
import 'package:flutter_template/features/republic/data/republic_repository.dart';
import 'package:flutter_template/features/republic/presentation/pages/republic_page.dart';
import 'package:flutter_template/l10n/generated/app_localizations.dart';
import 'package:flutter_template/routes/route_names.dart';
import 'package:flutter_template/theme/app_theme.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:video_player/video_player.dart';

class _MockApi extends Mock implements ApiService {}

class _Session extends AuthController {
  @override
  AuthState build() => const AuthState(
        user: UserEntity(id: 'me', email: 'a@b.co', name: 'Ada'),
      );
}

class _FakePlayer extends VideoPlayerController {
  _FakePlayer(String url) : super.networkUrl(Uri.parse(url));

  @override
  Future<void> initialize() async {
    value = value.copyWith(
      isInitialized: true,
      size: const Size(720, 1280),
      duration: const Duration(seconds: 30),
    );
  }

  @override
  Future<void> play() async => value = value.copyWith(isPlaying: true);

  @override
  Future<void> pause() async => value = value.copyWith(isPlaying: false);

  @override
  Future<void> setLooping(bool looping) async {}

  @override
  Future<void> setVolume(double volume) async {}

  @override
  // The real one tells the platform to let go of a texture there is not.
  // ignore: must_call_super
  Future<void> dispose() async {}
}

void main() {
  testWidgets('"+" in the Videos view opens the composer on the video picker', (
    tester,
  ) async {
    final api = _MockApi();
    when(() => api.get(any(), query: any(named: 'query'))).thenAnswer(
      (_) async => {'data': <Object>[], 'nextCursor': null},
    );
    tester.view
      ..physicalSize = const Size(900, 2400)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    String? opened;
    final router = GoRouter(
      routes: [
        GoRoute(path: '/', builder: (_, __) => const RepublicPage()),
        GoRoute(
          path: RouteNames.republicCompose,
          builder: (_, state) {
            opened = state.uri.toString();
            return const Scaffold(body: Text('COMPOSER'));
          },
        ),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          republicRepositoryProvider.overrideWithValue(RepublicRepository(api)),
          authControllerProvider.overrideWith(_Session.new),
          reelPlayerFactoryProvider.overrideWithValue(_FakePlayer.new),
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

    await tester.tap(find.text('Reels').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Post a reel'));
    await tester.pumpAndSettle();

    expect(find.text('COMPOSER'), findsOneWidget);
    expect(opened, '/republic/compose?video=1');
  });
}
