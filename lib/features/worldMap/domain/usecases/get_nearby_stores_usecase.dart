import 'package:flutter_template/core/errors/failure.dart';
import 'package:flutter_template/features/worldMap/data/repositories/store_repository.dart';
import 'package:flutter_template/features/worldMap/domain/entities/store_entity.dart';
import 'package:fpdart/fpdart.dart';

/// A single business action.
/// Callable like a function: `getNearbyStoresUseCase()`.
class GetNearbyStoresUseCase {
  GetNearbyStoresUseCase(this._repository);

  final StoreRepository _repository;

  Future<Either<Failure, List<StoreEntity>>> call() =>
      _repository.getNearbyStores();
}
