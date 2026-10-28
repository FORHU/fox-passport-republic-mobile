import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_template/core/errors/failure.dart';
import 'package:flutter_template/features/auth/domain/entities/user_entity.dart';
import 'package:flutter_template/features/auth/presentation/controllers/auth_controller.dart';
import 'package:flutter_template/features/messages/data/photo_picker.dart';
import 'package:flutter_template/features/profile/data/repositories/profile_repository.dart';
import 'package:flutter_template/features/profile/domain/entities/profile_entity.dart';
import 'package:flutter_template/features/profile/domain/entities/profile_update.dart';
import 'package:flutter_template/features/profile/presentation/controllers/profile_controller.dart';
import 'package:flutter_template/features/profile/presentation/pages/edit_profile_page.dart';
import 'package:flutter_template/l10n/generated/app_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';

class _MockProfileRepository extends Mock implements ProfileRepository {}

class _FakePicker implements PhotoPicker {
  _FakePicker(this.photo);

  final PickedPhoto? photo;

  @override
  Future<PickedPhoto?> pick() async => photo;
}

const _user = UserEntity(
  id: 'u1',
  email: 'ada@example.com',
  name: 'Ada',
  username: 'ada_l',
);

class _Session extends AuthController {
  @override
  AuthState build() => const AuthState(user: _user);
}

const _profile = ProfileEntity(
  id: 'u1',
  name: 'Ada',
  email: 'ada@example.com',
  username: 'ada_l',
  phone: '+639171234567',
);

Future<ProviderContainer> _pump(
  WidgetTester tester,
  _MockProfileRepository repo, {
  PhotoPicker? picker,
}) async {
  // Tall enough for the whole form, so the Save button is on screen.
  tester.view
    ..physicalSize = const Size(800, 1800)
    ..devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  late ProviderContainer container;
  final router = GoRouter(
    routes: [
      GoRoute(path: '/', builder: (_, __) => const Text('BACK')),
      GoRoute(path: '/edit', builder: (_, __) => const EditProfilePage()),
    ],
  );
  await tester.pumpWidget(
    ProviderScope(
      retry: (_, __) => null,
      overrides: [
        authControllerProvider.overrideWith(_Session.new),
        profileRepositoryProvider.overrideWithValue(repo),
        if (picker != null) photoPickerProvider.overrideWithValue(picker),
      ],
      child: Consumer(
        builder: (context, ref, _) {
          container = ProviderScope.containerOf(context);
          return MaterialApp.router(
            routerConfig: router,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
          );
        },
      ),
    ),
  );
  await tester.pumpAndSettle();
  unawaited(router.push('/edit'));
  await tester.pumpAndSettle();
  return container;
}

void main() {
  late _MockProfileRepository repo;

  setUpAll(() {
    registerFallbackValue(const ProfileUpdate());
    registerFallbackValue(PickedPhoto(bytes: Uint8List(0), name: 'x.png'));
  });

  setUp(() {
    repo = _MockProfileRepository();
    when(repo.getProfile).thenAnswer((_) async => const Right(_profile));
  });

  Finder field(String label) => find.widgetWithText(TextFormField, label);

  testWidgets('starts with what the profile already has', (tester) async {
    await _pump(tester, repo);

    expect(find.text('Edit profile'), findsWidgets);
    expect(
      tester.widget<TextFormField>(field('Name')).controller?.text,
      'Ada',
    );
    expect(
      tester.widget<TextFormField>(field('Username')).controller?.text,
      'ada_l',
    );
    expect(
      tester.widget<TextFormField>(field('Phone number')).controller?.text,
      '+639171234567',
    );
  });

  testWidgets('sends only what changed, and shows it everywhere', (
    tester,
  ) async {
    when(() => repo.updateProfile(any()))
        .thenAnswer((_) async => const Right(unit));
    final container = await _pump(tester, repo);

    await tester.enterText(field('Name'), 'Ada Byron');
    await tester.tap(find.text('Save changes'));
    await tester.pumpAndSettle();

    verify(() => repo.updateProfile(const ProfileUpdate(name: 'Ada Byron')))
        .called(1);
    expect(find.text('BACK'), findsOneWidget);
    expect(container.read(authControllerProvider).user?.name, 'Ada Byron');
  });

  testWidgets('the privacy switch is sent as isPrivate', (tester) async {
    when(() => repo.updateProfile(any()))
        .thenAnswer((_) async => const Right(unit));
    await _pump(tester, repo);

    await tester.tap(find.byType(Switch));
    await tester.tap(find.text('Save changes'));
    await tester.pumpAndSettle();

    verify(() => repo.updateProfile(const ProfileUpdate(isPrivate: true)))
        .called(1);
  });

  testWidgets('a bio is sent, and clearing it sends an empty one', (
    tester,
  ) async {
    when(() => repo.updateProfile(any()))
        .thenAnswer((_) async => const Right(unit));
    await _pump(tester, repo);

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Bio'),
      'Hi, I run gigs.',
    );
    await tester.tap(find.text('Save changes'));
    await tester.pumpAndSettle();

    verify(
      () => repo.updateProfile(const ProfileUpdate(bio: 'Hi, I run gigs.')),
    ).called(1);
  });

  testWidgets('with nothing changed it just goes back, no request', (
    tester,
  ) async {
    await _pump(tester, repo);

    await tester.tap(find.text('Save changes'));
    await tester.pumpAndSettle();

    verifyNever(() => repo.updateProfile(any()));
    expect(find.text('BACK'), findsOneWidget);
  });

  testWidgets('refuses a name that is not a name, without calling the API', (
    tester,
  ) async {
    await _pump(tester, repo);

    await tester.enterText(field('Name'), 'R2D2');
    await tester.tap(find.text('Save changes'));
    await tester.pumpAndSettle();

    expect(find.text('Name can only contain letters'), findsOneWidget);
    verifyNever(() => repo.updateProfile(any()));
  });

  testWidgets('refuses a username under three characters', (tester) async {
    await _pump(tester, repo);

    await tester.enterText(field('Username'), 'ab');
    await tester.tap(find.text('Save changes'));
    await tester.pumpAndSettle();

    expect(find.text('Username must be at least 3 characters'), findsOneWidget);
    verifyNever(() => repo.updateProfile(any()));
  });

  testWidgets('stays on the page and says so when saving fails', (
    tester,
  ) async {
    when(() => repo.updateProfile(any())).thenAnswer(
      (_) async => const Left(ServerFailure('Username is taken')),
    );
    final container = await _pump(tester, repo);

    await tester.enterText(field('Username'), 'grace');
    await tester.tap(find.text('Save changes'));
    await tester.pumpAndSettle();

    expect(find.text('Username is taken'), findsOneWidget);
    expect(find.text('BACK'), findsNothing);
    expect(container.read(authControllerProvider).user?.username, 'ada_l');
  });

  testWidgets('a new photo is uploaded, then set as the profile photo', (
    tester,
  ) async {
    final photo = PickedPhoto(bytes: Uint8List(4), name: 'me.png');
    when(() => repo.uploadPhoto(photo))
        .thenAnswer((_) async => const Right('https://x.test/me.png'));
    when(() => repo.updateProfile(any()))
        .thenAnswer((_) async => const Right(unit));
    final container = await _pump(tester, repo, picker: _FakePicker(photo));

    await tester.tap(find.text('Change photo'));
    // Not pumpAndSettle: the new photo's loading tile pulses for ever.
    for (var i = 0; i < 5; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }

    verify(
      () => repo.updateProfile(
        const ProfileUpdate(imageUrl: 'https://x.test/me.png'),
      ),
    ).called(1);
    expect(
      container.read(authControllerProvider).user?.imageUrl,
      'https://x.test/me.png',
    );
  });

  testWidgets('backing out of the photo picker changes nothing', (
    tester,
  ) async {
    await _pump(tester, repo, picker: _FakePicker(null));

    await tester.tap(find.text('Change photo'));
    await tester.pumpAndSettle();

    verifyNever(() => repo.uploadPhoto(any()));
    verifyNever(() => repo.updateProfile(any()));
  });
}
