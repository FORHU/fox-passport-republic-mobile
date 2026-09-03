import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_template/core/errors/failure.dart';
import 'package:flutter_template/features/home/data/repositories/home_repository.dart';
import 'package:flutter_template/features/home/domain/entities/home_item.dart';
import 'package:flutter_template/features/home/presentation/controllers/home_controller.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

class MockHomeRepository extends Mock implements HomeRepository {}

void main() {
  late ProviderContainer container;
  late MockHomeRepository mockRepository;

  setUp(() {
    mockRepository = MockHomeRepository();
  });

  tearDown(() {
    container.dispose();
  });

  group('HomeController', () {
    const tItems = [HomeItem(id: '1', name: 'Ada Lovelace')];

    test(
      'build() fetches items in the background and populates state',
      () async {
        // Arrange
        when(
          () => mockRepository.getItems(),
        ).thenAnswer((_) async => const Right(tItems));
        container =
            ProviderContainer(
                overrides: [
                  homeRepositoryProvider.overrideWithValue(mockRepository),
                ],
              )
              // Reading the provider triggers `build()`, which schedules the
              // fetch as a microtask.
              ..read(homeControllerProvider);

        // Act — allow the scheduled microtask fetch to complete.
        await Future<void>.delayed(Duration.zero);

        // Assert
        final state = container.read(homeControllerProvider);
        expect(state.isLoading, false);
        expect(state.items, tItems);
        expect(state.error, isNull);
      },
    );

    test('a failed fetch surfaces the error and keeps items empty', () async {
      // Arrange
      const tFailure = ServerFailure('Boom');
      when(
        () => mockRepository.getItems(),
      ).thenAnswer((_) async => const Left(tFailure));
      container = ProviderContainer(
        overrides: [
          homeRepositoryProvider.overrideWithValue(mockRepository),
        ],
      )..read(homeControllerProvider);

      // Act — allow the scheduled microtask fetch to complete.
      await Future<void>.delayed(Duration.zero);

      // Assert
      final state = container.read(homeControllerProvider);
      expect(state.isLoading, false);
      expect(state.items, isEmpty);
      expect(state.error, tFailure.message);
    });

    test(
      'fetchItems() can be re-invoked explicitly (e.g. pull-to-refresh)',
      () async {
        // Arrange
        when(
          () => mockRepository.getItems(),
        ).thenAnswer((_) async => const Right(tItems));
        container = ProviderContainer(
          overrides: [
            homeRepositoryProvider.overrideWithValue(mockRepository),
          ],
        )..read(homeControllerProvider);
        await Future<void>.delayed(Duration.zero);

        // Act
        await container.read(homeControllerProvider.notifier).fetchItems();

        // Assert
        verify(() => mockRepository.getItems()).called(2);
      },
    );
  });
}
