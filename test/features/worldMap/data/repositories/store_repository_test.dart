import 'package:flutter_template/core/errors/exceptions.dart';
import 'package:flutter_template/core/errors/failure.dart';
import 'package:flutter_template/features/worldMap/data/datasources/store_remote_datasource.dart';
import 'package:flutter_template/features/worldMap/data/models/store_model.dart';
import 'package:flutter_template/features/worldMap/data/repositories/store_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockStoreRemoteDataSource extends Mock implements StoreRemoteDataSource {}

void main() {
  late MockStoreRemoteDataSource mockRemote;
  late StoreRepositoryImpl repository;

  setUp(() {
    mockRemote = MockStoreRemoteDataSource();
    repository = StoreRepositoryImpl(mockRemote);
  });

  group('StoreRepositoryImpl.getNearbyStores', () {
    const tStores = [
      StoreModel(
        id: '1',
        name: 'Downtown Market',
        address: '123 Main St',
        distanceKm: 0.8,
        rating: 4.5,
      ),
    ];

    test('returns Right(stores) on success', () async {
      // Arrange
      when(
        () => mockRemote.getNearbyStores(),
      ).thenAnswer((_) async => tStores);

      // Act
      final result = await repository.getNearbyStores();

      // Assert
      expect(result.isRight(), isTrue);
      expect(result.getRight().toNullable(), tStores);
    });

    test('maps UnauthorizedException to UnauthorizedFailure', () async {
      // Arrange
      when(
        () => mockRemote.getNearbyStores(),
      ).thenThrow(const UnauthorizedException('Session expired'));

      // Act
      final result = await repository.getNearbyStores();

      // Assert
      expect(result.isLeft(), isTrue);
      final failure = result.getLeft().toNullable();
      expect(failure, isA<UnauthorizedFailure>());
      expect(failure!.message, 'Session expired');
    });

    test('maps NetworkException to NetworkFailure', () async {
      // Arrange
      when(
        () => mockRemote.getNearbyStores(),
      ).thenThrow(const NetworkException());

      // Act
      final result = await repository.getNearbyStores();

      // Assert
      expect(result.isLeft(), isTrue);
      expect(result.getLeft().toNullable(), isA<NetworkFailure>());
    });

    test('maps ServerException to ServerFailure', () async {
      // Arrange
      when(
        () => mockRemote.getNearbyStores(),
      ).thenThrow(const ServerException('Boom', statusCode: 500));

      // Act
      final result = await repository.getNearbyStores();

      // Assert
      expect(result.isLeft(), isTrue);
      expect(result.getLeft().toNullable(), isA<ServerFailure>());
    });

    test('maps an unexpected error to ServerFailure', () async {
      // Arrange
      when(() => mockRemote.getNearbyStores()).thenThrow(Exception('boom'));

      // Act
      final result = await repository.getNearbyStores();

      // Assert
      expect(result.isLeft(), isTrue);
      expect(result.getLeft().toNullable(), isA<ServerFailure>());
    });
  });
}
