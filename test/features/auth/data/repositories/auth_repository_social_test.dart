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
    when(() => storage.saveToken(any())).thenAnswer((_) async {});
    when(() => storage.saveUserModel(any())).thenAnswer((_) async {});
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
  });
}
