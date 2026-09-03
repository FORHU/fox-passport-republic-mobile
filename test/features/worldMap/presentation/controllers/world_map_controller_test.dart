import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_template/core/errors/failure.dart';
import 'package:flutter_template/features/worldMap/data/repositories/store_repository.dart';
import 'package:flutter_template/features/worldMap/domain/entities/store_entity.dart';
import 'package:flutter_template/features/worldMap/presentation/controllers/world_map_controller.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

class MockStoreRepository extends Mock implements StoreRepository {}

void main() {
  late ProviderContainer container;
  late MockStoreRepository mockRepository;

  setUp(() {
    mockRepository = MockStoreRepository();
  });

  tearDown(() {
    container.dispose();
  });

  group('WorldMapController', () {
    const tStores = [
      StoreEntity(
        id: '1',
        name: 'Downtown Market',
        address: '123 Main St',
        distanceKm: 0.8,
        rating: 4.5,
      ),
    ];

    test('build() fetches nearby stores in the background', () async {
      // Arrange
      when(
        () => mockRepository.getNearbyStores(),
      ).thenAnswer((_) async => const Right(tStores));
      container = ProviderContainer(
        overrides: [
          storeRepositoryProvider.overrideWithValue(mockRepository),
        ],
      )..read(worldMapControllerProvider);

      // Act — allow the scheduled microtask fetch to complete.
      await Future<void>.delayed(Duration.zero);

      // Assert
      final state = container.read(worldMapControllerProvider);
      expect(state.isLoading, false);
      expect(state.stores, tStores);
      expect(state.error, isNull);
    });

    test('a failed fetch surfaces the error and keeps stores empty', () async {
      // Arrange
      const tFailure = ServerFailure('Boom');
      when(
        () => mockRepository.getNearbyStores(),
      ).thenAnswer((_) async => const Left(tFailure));
      container = ProviderContainer(
        overrides: [
          storeRepositoryProvider.overrideWithValue(mockRepository),
        ],
      )..read(worldMapControllerProvider);

      // Act — allow the scheduled microtask fetch to complete.
      await Future<void>.delayed(Duration.zero);

      // Assert
      final state = container.read(worldMapControllerProvider);
      expect(state.isLoading, false);
      expect(state.stores, isEmpty);
      expect(state.error, tFailure.message);
    });
  });
}
