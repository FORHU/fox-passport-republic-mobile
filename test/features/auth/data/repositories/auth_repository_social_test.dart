import 'package:flutter_template/core/errors/exceptions.dart';
import 'package:flutter_template/core/errors/failure.dart';
import 'package:flutter_template/core/services/storage_service.dart';
import 'package:flutter_template/features/auth/data/datasources/auth_remote_datasource.dart';
import 'package:flutter_template/features/auth/data/datasources/social_credential_source.dart';
import 'package:flutter_template/features/auth/data/models/user_model.dart';
import 'package:flutter_template/features/auth/data/repositories/auth_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockRemote extends Mock implements AuthRemoteDataSource {}

class MockStorage extends Mock implements StorageService {}

class MockSocial extends Mock implements SocialCredentialSource {}

class FakeUser extends Fake implements UserModel {}

void main() {
  const tUser = UserModel(
    id: 'u1',
    email: 'g@example.com',
    name: 'G',
    token: 'access',
  );

  late MockRemote remote;
  late MockStorage storage;
  late MockSocial social;
  late AuthRepositoryImpl repository;

  setUpAll(() {
    registerFallbackValue(FakeUser());
    registerFallbackValue(SocialProvider.google);
  });

  setUp(() {
    remote = MockRemote();
    storage = MockStorage();
    social = MockSocial();
    repository = AuthRepositoryImpl(remote, storage, social: social);

    when(() => social.isSupported).thenReturn(true);
    when(() => social.signOut()).thenAnswer((_) async {});
    when(() => storage.saveToken(any())).thenAnswer((_) async {});
    when(() => storage.saveUserModel(any())).thenAnswer((_) async {});
    // /profile has no token of its own; the repository keeps the session's.
    when(() => remote.checkAuth(any())).thenAnswer(
      (_) async => const UserModel(
        id: 'u1',
        email: 'g@example.com',
        name: 'G',
        token: '',
      ),
    );
  });

  group('AuthRepositoryImpl.loginWithSocial', () {
    test('posts a native token and persists the session', () async {
      when(() => social.obtain(SocialProvider.google))
          .thenAnswer((_) async => const SocialToken('google-id-token'));
      when(
        () => remote.loginWithSocialToken(
          SocialProvider.google,
          'google-id-token',
        ),
      ).thenAnswer((_) async => tUser);

      final result = await repository.loginWithSocial(SocialProvider.google);

      expect(result.getRight().toNullable(), tUser);
      verify(() => storage.saveToken('access')).called(1);
      verifyNever(() => social.signOut());
    });

    test('a dismissed provider UI is a quiet cancellation', () async {
      when(() => social.obtain(any())).thenThrow(const SocialSignInCancelled());

      final result = await repository.loginWithSocial(SocialProvider.google);

      expect(
        result.getLeft().toNullable(),
        isA<SocialSignInCancelledFailure>(),
      );
      verifyNever(() => storage.saveToken(any()));
    });

    test('maps a rejected token (401) to UnauthorizedFailure', () async {
      when(() => social.obtain(any()))
          .thenAnswer((_) async => const SocialToken('bad'));
      when(() => remote.loginWithSocialToken(any(), any()))
          .thenThrow(const UnauthorizedException('Google sign-in failed'));

      final result = await repository.loginWithSocial(SocialProvider.google);

      expect(result.getLeft().toNullable(), isA<UnauthorizedFailure>());
      verifyNever(() => storage.saveToken(any()));
      // Forgets the refused account, so the next tap shows the picker.
      verify(() => social.signOut()).called(1);
    });

    test('an unverified account with that email is SocialAccountNotLinked',
        () async {
      when(() => social.obtain(any()))
          .thenAnswer((_) async => const SocialToken('google-id-token'));
      when(() => remote.loginWithSocialToken(any(), any())).thenThrow(
        const UnauthorizedException('account not linked', statusCode: 401),
      );

      final result = await repository.loginWithSocial(SocialProvider.google);

      expect(
        result.getLeft().toNullable(),
        isA<SocialAccountNotLinkedFailure>(),
      );
      verifyNever(() => storage.saveToken(any()));
      verify(() => social.signOut()).called(1);
    });

    test('an unreachable API also forgets the account', () async {
      when(() => social.obtain(any()))
          .thenAnswer((_) async => const SocialToken('google-id-token'));
      when(() => remote.loginWithSocialToken(any(), any()))
          .thenThrow(const NetworkException());

      final result = await repository.loginWithSocial(SocialProvider.google);

      expect(result.getLeft().toNullable(), isA<NetworkFailure>());
      verify(() => social.signOut()).called(1);
    });

    test('maps provider-side failures to ServerFailure', () async {
      when(() => social.obtain(any()))
          .thenThrow(const ServerException('Google did not return a token'));

      final result = await repository.loginWithSocial(SocialProvider.google);

      expect(result.getLeft().toNullable(), isA<ServerFailure>());
    });

    test('fails cleanly where social sign-in is unsupported', () async {
      when(() => social.isSupported).thenReturn(false);

      final result = await repository.loginWithSocial(SocialProvider.google);

      expect(result.getLeft().toNullable(), isA<ServerFailure>());
      verifyNever(() => social.obtain(any()));
    });

    test('a cancelled provider sheet does not sign the provider out', () async {
      when(() => social.obtain(any())).thenThrow(const SocialSignInCancelled());

      await repository.loginWithSocial(SocialProvider.google);

      verifyNever(() => social.signOut());
    });

    // api#419: the sign-in payload can't say what the account still lacks.
    test('reads /profile, so a Google account without a password sets up',
        () async {
      when(() => social.obtain(any()))
          .thenAnswer((_) async => const SocialToken('google-id-token'));
      when(() => remote.loginWithSocialToken(any(), any()))
          .thenAnswer((_) async => tUser);
      when(() => remote.checkAuth('access')).thenAnswer(
        (_) async => const UserModel(
          id: 'u1',
          email: 'g@example.com',
          name: 'G',
          token: '',
          hasPassword: false,
          needsCredentialSetup: true,
        ),
      );

      final user = (await repository.loginWithSocial(SocialProvider.google))
          .getRight()
          .toNullable();

      expect(user?.needsCredentialSetup, isTrue);
      expect(user?.hasPassword, isFalse);
      expect((user as UserModel?)?.token, 'access');
      final saved = verify(() => storage.saveUserModel(captureAny()))
          .captured
          .last as UserModel;
      expect(saved.needsCredentialSetup, isTrue);
      expect(saved.token, 'access');
    });

    test('keeps the sign-in when the /profile read fails', () async {
      when(() => social.obtain(any()))
          .thenAnswer((_) async => const SocialToken('google-id-token'));
      when(() => remote.loginWithSocialToken(any(), any()))
          .thenAnswer((_) async => tUser);
      when(() => remote.checkAuth(any())).thenThrow(const NetworkException());

      final result = await repository.loginWithSocial(SocialProvider.google);

      expect(result.getRight().toNullable(), tUser);
      verifyNever(() => social.signOut());
    });
  });

  group('AuthRepositoryImpl account setup (api#419)', () {
    test('sets what is missing and keeps the fresh user with the session',
        () async {
      when(() => storage.readToken()).thenAnswer((_) async => 'access');
      when(
        () => remote.setUpCredentials(
          username: 'new.name',
          password: 'Str0ng!Passw0rd',
        ),
      ).thenAnswer(
        (_) async => const UserModel(
          id: 'u1',
          email: 'g@example.com',
          name: 'G',
          token: '',
          username: 'new.name',
        ),
      );

      final user = (await repository.setUpCredentials(
        username: 'new.name',
        password: 'Str0ng!Passw0rd',
      ))
          .getRight()
          .toNullable();

      expect(user?.username, 'new.name');
      expect(user?.needsCredentialSetup, isFalse);
      final saved = verify(() => storage.saveUserModel(captureAny()))
          .captured
          .single as UserModel;
      expect(saved.token, 'access');
    });

    test("passes on the API's refusal", () async {
      when(() => storage.readToken()).thenAnswer((_) async => 'access');
      when(
        () => remote.setUpCredentials(
          username: any(named: 'username'),
          password: any(named: 'password'),
        ),
      ).thenThrow(
        const ServerException('Username already taken', statusCode: 400),
      );

      final result = await repository.setUpCredentials(username: 'taken');

      expect(result.getLeft().toNullable()?.message, 'Username already taken');
      verifyNever(() => storage.saveUserModel(any()));
    });

    test('says whether a username is free', () async {
      when(() => remote.isUsernameAvailable('free.name'))
          .thenAnswer((_) async => true);
      when(() => remote.isUsernameAvailable('taken'))
          .thenAnswer((_) async => false);

      expect(
        (await repository.isUsernameAvailable('free.name'))
            .getRight()
            .toNullable(),
        isTrue,
      );
      expect(
        (await repository.isUsernameAvailable('taken')).getRight().toNullable(),
        isFalse,
      );
    });
  });

  group('AuthRepositoryImpl.logout', () {
    test('signs out of Google/Facebook after clearing the session', () async {
      when(() => remote.logout()).thenAnswer((_) async {});
      when(() => storage.clearSession()).thenAnswer((_) async {});

      final result = await repository.logout();

      expect(result.isRight(), isTrue);
      verifyInOrder([
        () => storage.clearSession(),
        () => social.signOut(),
      ]);
    });

    test('keeps the provider signed in when the server logout fails', () async {
      when(() => remote.logout()).thenThrow(const NetworkException());

      final result = await repository.logout();

      expect(result.getLeft().toNullable(), isA<NetworkFailure>());
      verifyNever(() => social.signOut());
    });
  });
}
