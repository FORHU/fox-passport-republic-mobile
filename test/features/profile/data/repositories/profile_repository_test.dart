import 'package:flutter_template/core/errors/exceptions.dart';
import 'package:flutter_template/core/errors/failure.dart';
import 'package:flutter_template/features/profile/data/datasources/profile_remote_datasource.dart';
import 'package:flutter_template/features/profile/data/models/profile_model.dart';
import 'package:flutter_template/features/profile/data/repositories/profile_repository.dart';
import 'package:flutter_template/features/profile/domain/entities/profile_update.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockProfileRemoteDataSource extends Mock
    implements ProfileRemoteDataSource {}

void main() {
  late MockProfileRemoteDataSource mockRemote;
  late ProfileRepositoryImpl repository;

  setUpAll(() => registerFallbackValue(const ProfileUpdate()));

  setUp(() {
    mockRemote = MockProfileRemoteDataSource();
    repository = ProfileRepositoryImpl(mockRemote);
  });

  group('ProfileRepositoryImpl.getProfile', () {
    const tProfile = ProfileModel(
      id: '1',
      name: 'Ada Lovelace',
      email: 'ada@example.com',
      bio: 'Building great things with Flutter.',
    );

    test('returns Right(profile) on success', () async {
      // Arrange
      when(() => mockRemote.getProfile()).thenAnswer((_) async => tProfile);

      // Act
      final result = await repository.getProfile();

      // Assert
      expect(result.isRight(), isTrue);
      expect(result.getRight().toNullable(), tProfile);
    });

    test('maps UnauthorizedException to UnauthorizedFailure', () async {
      // Arrange
      when(
        () => mockRemote.getProfile(),
      ).thenThrow(const UnauthorizedException('Session expired'));

      // Act
      final result = await repository.getProfile();

      // Assert
      expect(result.isLeft(), isTrue);
      final failure = result.getLeft().toNullable();
      expect(failure, isA<UnauthorizedFailure>());
      expect(failure!.message, 'Session expired');
    });

    test('maps NetworkException to NetworkFailure', () async {
      // Arrange
      when(() => mockRemote.getProfile()).thenThrow(const NetworkException());

      // Act
      final result = await repository.getProfile();

      // Assert
      expect(result.isLeft(), isTrue);
      expect(result.getLeft().toNullable(), isA<NetworkFailure>());
    });

    test('maps ServerException to ServerFailure', () async {
      // Arrange
      when(
        () => mockRemote.getProfile(),
      ).thenThrow(const ServerException('Boom', statusCode: 500));

      // Act
      final result = await repository.getProfile();

      // Assert
      expect(result.isLeft(), isTrue);
      expect(result.getLeft().toNullable(), isA<ServerFailure>());
    });

    test('maps an unexpected error to ServerFailure', () async {
      // Arrange
      when(() => mockRemote.getProfile()).thenThrow(Exception('boom'));

      // Act
      final result = await repository.getProfile();

      // Assert
      expect(result.isLeft(), isTrue);
      expect(result.getLeft().toNullable(), isA<ServerFailure>());
    });
  });

  group('ProfileRepositoryImpl.updateProfile', () {
    const update = ProfileUpdate(name: 'Ada');

    test('sends the change and returns Right on success', () async {
      when(() => mockRemote.updateProfile(update)).thenAnswer((_) async {});

      final result = await repository.updateProfile(update);

      expect(result.isRight(), isTrue);
      verify(() => mockRemote.updateProfile(update)).called(1);
    });

    test('maps a refusal from the API to ServerFailure with its message',
        () async {
      when(
        () => mockRemote.updateProfile(any()),
      ).thenThrow(const ServerException('Name is taken'));

      final result = await repository.updateProfile(update);

      final failure = result.getLeft().toNullable();
      expect(failure, isA<ServerFailure>());
      expect(failure?.message, 'Name is taken');
    });

    test('maps a lost connection to NetworkFailure', () async {
      when(
        () => mockRemote.updateProfile(any()),
      ).thenThrow(const NetworkException('offline'));

      final result = await repository.updateProfile(update);

      expect(result.getLeft().toNullable(), isA<NetworkFailure>());
    });
  });

  group('ProfileRepositoryImpl.changePassword', () {
    test('sends both passwords and returns Right on success', () async {
      when(
        () => mockRemote.changePassword(
          currentPassword: 'old',
          newPassword: 'new',
        ),
      ).thenAnswer((_) async {});

      final result = await repository.changePassword(
        currentPassword: 'old',
        newPassword: 'new',
      );

      expect(result.isRight(), isTrue);
    });

    test('says why the API refused, such as a wrong current password',
        () async {
      when(
        () => mockRemote.changePassword(
          currentPassword: any(named: 'currentPassword'),
          newPassword: any(named: 'newPassword'),
        ),
      ).thenThrow(const ServerException('Current password is incorrect'));

      final result = await repository.changePassword(
        currentPassword: 'wrong',
        newPassword: 'new',
      );

      expect(
        result.getLeft().toNullable()?.message,
        'Current password is incorrect',
      );
    });
  });

  group('ProfileRepositoryImpl.deleteAccount', () {
    test('returns Right once the account is deleted', () async {
      when(() => mockRemote.deleteAccount('pw')).thenAnswer((_) async {});

      final result = await repository.deleteAccount('pw');

      expect(result.isRight(), isTrue);
      verify(() => mockRemote.deleteAccount('pw')).called(1);
    });

    test('keeps the failure when the password is wrong', () async {
      when(
        () => mockRemote.deleteAccount(any()),
      ).thenThrow(const ServerException('Invalid password'));

      final result = await repository.deleteAccount('nope');

      expect(result.getLeft().toNullable()?.message, 'Invalid password');
    });
  });

  group('ProfileUpdate', () {
    test('sends only the fields that are set, under the API names', () {
      const update = ProfileUpdate(
        name: 'Ada',
        imageUrl: 'https://x.test/a.png',
        isPrivate: true,
      );

      expect(update.toJson(), {
        'name': 'Ada',
        'profileImage': 'https://x.test/a.png',
        'isPrivate': true,
      });
      expect(const ProfileUpdate().toJson(), isEmpty);
    });
  });

  group('ProfileModel', () {
    test('reads the username, phone, photo and privacy', () {
      final p = ProfileModel.fromJson(const {
        'data': {
          'id': 'u1',
          'name': 'Ada',
          'email': 'ada@example.com',
          'username': 'ada_l',
          'phone': '+639171234567',
          'imgId': 'https://x.test/a.png',
          'isPrivate': true,
        },
      });

      expect(p.username, 'ada_l');
      expect(p.phone, '+639171234567');
      expect(p.imageUrl, 'https://x.test/a.png');
      expect(p.isPrivate, isTrue);
    });

    test('leaves out what the API did not send', () {
      final p = ProfileModel.fromJson(const {'id': 'u1', 'email': 'a@b.co'});

      expect(p.phone, isNull);
      expect(p.imageUrl, isNull);
      expect(p.isPrivate, isFalse);
    });
  });
}
