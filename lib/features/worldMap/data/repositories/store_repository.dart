import 'package:flutter_template/core/errors/exceptions.dart';
import 'package:flutter_template/core/errors/failure.dart';
import 'package:flutter_template/features/worldMap/data/datasources/store_remote_datasource.dart';
import 'package:flutter_template/features/worldMap/domain/entities/store_entity.dart';
import 'package:fpdart/fpdart.dart';

/// Repository contract (the abstraction the domain layer depends on).
abstract class StoreRepository {
  Future<Either<Failure, List<StoreEntity>>> getNearbyStores();
}

/// Coordinates the remote data source. Catches the data layer's typed
/// exceptions and maps them to typed [Failure] values.
class StoreRepositoryImpl implements StoreRepository {
  StoreRepositoryImpl(this._remote);

  final StoreRemoteDataSource _remote;

  @override
  Future<Either<Failure, List<StoreEntity>>> getNearbyStores() async {
    try {
      final stores = await _remote.getNearbyStores();
      return Right(stores);
    } on UnauthorizedException catch (e) {
      return Left(UnauthorizedFailure(e.message));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    } on AppException catch (e) {
      return Left(ServerFailure(e.message));
    } on Object catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}
