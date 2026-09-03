import 'package:flutter_template/core/errors/exceptions.dart';
import 'package:flutter_template/core/errors/failure.dart';
import 'package:flutter_template/features/home/data/datasources/home_remote_datasource.dart';
import 'package:flutter_template/features/home/data/models/home_item_model.dart';
import 'package:flutter_template/features/home/data/repositories/home_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockHomeRemoteDataSource extends Mock implements HomeRemoteDataSource {}

void main() {
  late MockHomeRemoteDataSource mockRemote;
  late HomeRepositoryImpl repository;

  setUp(() {
    mockRemote = MockHomeRemoteDataSource();
    repository = HomeRepositoryImpl(mockRemote);
  });

  group('HomeRepositoryImpl.getItems', () {
    const tItems = [
      HomeItemModel(id: '1', name: 'Ada Lovelace'),
      HomeItemModel(id: '2', name: 'Alan Turing'),
    ];

    test('returns Right(items) on success', () async {
      // Arrange
      when(() => mockRemote.getItems()).thenAnswer((_) async => tItems);

      // Act
      final result = await repository.getItems();

      // Assert
      expect(result.isRight(), isTrue);
      expect(result.getRight().toNullable(), tItems);
    });

    test('maps UnauthorizedException to UnauthorizedFailure', () async {
      // Arrange
      when(
        () => mockRemote.getItems(),
      ).thenThrow(const UnauthorizedException('Session expired'));

      // Act
      final result = await repository.getItems();

      // Assert
      expect(result.isLeft(), isTrue);
      final failure = result.getLeft().toNullable();
      expect(failure, isA<UnauthorizedFailure>());
      expect(failure!.message, 'Session expired');
    });

    test('maps NetworkException to NetworkFailure', () async {
      // Arrange
      when(() => mockRemote.getItems()).thenThrow(const NetworkException());

      // Act
      final result = await repository.getItems();

      // Assert
      expect(result.isLeft(), isTrue);
      expect(result.getLeft().toNullable(), isA<NetworkFailure>());
    });

    test('maps ServerException to ServerFailure', () async {
      // Arrange
      when(
        () => mockRemote.getItems(),
      ).thenThrow(const ServerException('Boom', statusCode: 500));

      // Act
      final result = await repository.getItems();

      // Assert
      expect(result.isLeft(), isTrue);
      expect(result.getLeft().toNullable(), isA<ServerFailure>());
    });

    test('maps an unexpected error to ServerFailure', () async {
      // Arrange
      when(() => mockRemote.getItems()).thenThrow(Exception('boom'));

      // Act
      final result = await repository.getItems();

      // Assert
      expect(result.isLeft(), isTrue);
      expect(result.getLeft().toNullable(), isA<ServerFailure>());
    });
  });
}
