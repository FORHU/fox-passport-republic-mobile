import 'package:flutter_template/core/errors/failure.dart';
import 'package:flutter_template/features/home/data/repositories/home_repository.dart';
import 'package:flutter_template/features/home/domain/entities/home_item.dart';
import 'package:fpdart/fpdart.dart';

/// A single business action. Callable like a function: `getHomeItemsUseCase()`.
class GetHomeItemsUseCase {
  GetHomeItemsUseCase(this._repository);

  final HomeRepository _repository;

  Future<Either<Failure, List<HomeItem>>> call() => _repository.getItems();
}
