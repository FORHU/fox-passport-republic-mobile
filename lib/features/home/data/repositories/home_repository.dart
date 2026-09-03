import 'package:flutter_template/core/errors/exceptions.dart';
import 'package:flutter_template/core/errors/failure.dart';
import 'package:flutter_template/features/home/data/datasources/home_remote_datasource.dart';
import 'package:flutter_template/features/home/domain/entities/home_item.dart';
import 'package:fpdart/fpdart.dart';

/// Repository contract (the abstraction the domain layer depends on).
abstract class HomeRepository {
  Future<Either<Failure, List<HomeItem>>> getItems();
}

/// Coordinates the remote data source. Catches the data layer's typed
/// exceptions and maps them to typed [Failure] values.
class HomeRepositoryImpl implements HomeRepository {
  HomeRepositoryImpl(this._remote);

  final HomeRemoteDataSource _remote;

  @override
  Future<Either<Failure, List<HomeItem>>> getItems() async {
    try {
      final items = await _remote.getItems();
      return Right(items);
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
