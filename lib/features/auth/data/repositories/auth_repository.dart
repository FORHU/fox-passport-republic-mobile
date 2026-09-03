import 'package:flutter_template/core/errors/exceptions.dart';
import 'package:flutter_template/core/errors/failure.dart';
import 'package:flutter_template/core/services/storage_service.dart';
import 'package:flutter_template/features/auth/data/datasources/auth_remote_datasource.dart';
import 'package:flutter_template/features/auth/domain/entities/user_entity.dart';
import 'package:fpdart/fpdart.dart';

/// Repository contract (the abstraction the domain layer depends on).
abstract class AuthRepository {
  Future<Either<Failure, UserEntity>> login(String email, String password);
  Future<Either<Failure, void>> register(
    String email,
    String password, {
    String? name,
    String? countryCode,
    String roleName,
  });
  Future<Either<Failure, void>> logout();
  Future<Either<Failure, UserEntity>> refreshAuth();
}

/// Coordinates the remote data source and local token storage. Catches the
/// data layer's typed exceptions and maps them to typed [Failure] values.
class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl(this._remote, this._storage);

  final AuthRemoteDataSource _remote;
  final StorageService _storage;

  @override
  Future<Either<Failure, UserEntity>> login(
    String email,
    String password,
  ) async {
    try {
      final user = await _remote.login(email, password);
      await _storage.saveToken(user.token);
      final refreshToken = user.refreshToken;
      if (refreshToken != null && refreshToken.isNotEmpty) {
        await _storage.saveRefreshToken(refreshToken);
      }
      // Save full user model to local cache for instant offline startup.
      await _storage.saveUserModel(user);
      return Right(user);
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

  @override
  Future<Either<Failure, void>> register(
    String email,
    String password, {
    String? name,
    String? countryCode,
    String roleName = 'USER',
  }) async {
    try {
      await _remote.register(
        email,
        password,
        name: name,
        countryCode: countryCode,
        roleName: roleName,
      );
      return const Right(null);
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

  @override
  Future<Either<Failure, void>> logout() async {
    // Revoke the session server-side and only clear the local session once the
    // server confirms. A network/server failure is surfaced (session kept) so
    // we never sign the user out locally while their session lives on the
    // server. A 401 is the exception: the session is already invalid
    // server-side (interceptor cleared tokens), so we treat it as logged out.
    try {
      final refreshToken = await _storage.readRefreshToken();
      await _remote.logout(refreshToken);
    } on UnauthorizedException catch (_) {
      // Session already gone server-side — fall through and clear local state.
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    } on AppException catch (e) {
      return Left(ServerFailure(e.message));
    }

    try {
      await _storage.clearSession();
      return const Right(null);
    } on Object catch (e) {
      return Left(CacheFailure('Failed to clear local session: $e'));
    }
  }

  @override
  Future<Either<Failure, UserEntity>> refreshAuth() async {
    try {
      final token = await _storage.readToken();
      if (token == null || token.isEmpty) {
        return const Left(UnauthorizedFailure('No token found'));
      }
      final user = await _remote.checkAuth(token);
      // Update local cache with fresh background fetch.
      await _storage.saveUserModel(user);
      return Right(user);
    } on UnauthorizedException catch (e) {
      await _storage.clearSession(); // Clear stale tokens.
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
