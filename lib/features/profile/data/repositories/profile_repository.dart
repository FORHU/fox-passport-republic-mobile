import 'package:flutter_template/core/errors/exceptions.dart';
import 'package:flutter_template/core/errors/failure.dart';
import 'package:flutter_template/features/messages/data/photo_picker.dart';
import 'package:flutter_template/features/profile/data/datasources/profile_remote_datasource.dart';
import 'package:flutter_template/features/profile/domain/entities/profile_entity.dart';
import 'package:flutter_template/features/profile/domain/entities/profile_update.dart';
import 'package:fpdart/fpdart.dart';

/// Repository contract (the abstraction the domain layer depends on).
abstract class ProfileRepository {
  Future<Either<Failure, ProfileEntity>> getProfile();

  Future<Either<Failure, Unit>> updateProfile(ProfileUpdate update);

  /// Uploads a photo and returns its URL.
  Future<Either<Failure, String>> uploadPhoto(PickedPhoto photo);

  Future<Either<Failure, Unit>> changePassword({
    required String currentPassword,
    required String newPassword,
  });

  Future<Either<Failure, Unit>> deleteAccount(String password);
}

/// Coordinates the remote data source. Catches the data layer's typed
/// exceptions and maps them to typed [Failure] values.
class ProfileRepositoryImpl implements ProfileRepository {
  ProfileRepositoryImpl(this._remote);

  final ProfileRemoteDataSource _remote;

  @override
  Future<Either<Failure, ProfileEntity>> getProfile() =>
      _guard(_remote.getProfile);

  @override
  Future<Either<Failure, Unit>> updateProfile(ProfileUpdate update) =>
      _guard(() async {
        await _remote.updateProfile(update);
        return unit;
      });

  @override
  Future<Either<Failure, String>> uploadPhoto(PickedPhoto photo) =>
      _guard(() => _remote.uploadPhoto(photo));

  @override
  Future<Either<Failure, Unit>> changePassword({
    required String currentPassword,
    required String newPassword,
  }) =>
      _guard(() async {
        await _remote.changePassword(
          currentPassword: currentPassword,
          newPassword: newPassword,
        );
        return unit;
      });

  @override
  Future<Either<Failure, Unit>> deleteAccount(String password) =>
      _guard(() async {
        await _remote.deleteAccount(password);
        return unit;
      });

  Future<Either<Failure, T>> _guard<T>(Future<T> Function() call) async {
    try {
      return Right(await call());
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
