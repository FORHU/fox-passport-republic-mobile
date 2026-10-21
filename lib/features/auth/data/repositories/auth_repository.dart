import 'package:flutter_template/core/errors/exceptions.dart';
import 'package:flutter_template/core/errors/failure.dart';
import 'package:flutter_template/core/services/cookie_service.dart';
import 'package:flutter_template/core/services/storage_service.dart';
import 'package:flutter_template/features/auth/data/datasources/auth_remote_datasource.dart';
import 'package:flutter_template/features/auth/data/datasources/social_credential_source.dart';
import 'package:flutter_template/features/auth/data/models/user_model.dart';
import 'package:flutter_template/features/auth/domain/entities/user_entity.dart';
import 'package:fpdart/fpdart.dart';

/// Repository contract (the abstraction the domain layer depends on).
abstract class AuthRepository {
  Future<Either<Failure, UserEntity>> login(String email, String password);
  Future<Either<Failure, void>> register(
    String email,
    String password, {
    String? name,
    String? username,
    String? countryCode,
    String roleName,
  });
  Future<Either<Failure, void>> logout();
  Future<Either<Failure, UserEntity>> refreshAuth();

  /// True where the platform can run Google/Facebook sign-in at all.
  bool get isSocialSignInSupported;
  Future<Either<Failure, UserEntity>> loginWithSocial(SocialProvider provider);
  Future<Either<Failure, void>> verifyEmail(String email, String otpCode);
  Future<Either<Failure, void>> resendVerificationOtp(String email);
  Future<Either<Failure, void>> forgotPassword(String email);
  Future<Either<Failure, void>> resetPassword(
    String email,
    String otpCode,
    String newPassword,
  );
}

/// Coordinates the remote data source and local token storage. Catches the
/// data layer's typed exceptions and maps them to typed [Failure] values.
class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl(
    this._remote,
    this._storage, {
    CookieService? cookieService,
    SocialCredentialSource? social,
  })  : _cookieService = cookieService,
        _social = social;

  final AuthRemoteDataSource _remote;
  final StorageService _storage;
  final CookieService? _cookieService;
  final SocialCredentialSource? _social;

  @override
  bool get isSocialSignInSupported => _social?.isSupported ?? false;

  /// Stores tokens and the cached user — shared by every sign-in path.
  Future<void> _persistSession(UserModel user) async {
    await _storage.saveToken(user.token);
    // Save full user model to local cache for instant offline startup.
    await _storage.saveUserModel(user);
  }

  @override
  Future<Either<Failure, UserEntity>> loginWithSocial(
    SocialProvider provider,
  ) async {
    final social = _social;
    if (social == null || !social.isSupported) {
      return const Left(
        ServerFailure('Social sign-in is not available on this platform.'),
      );
    }

    try {
      final credential = await social.obtain(provider);
      final user = switch (credential) {
        SocialToken(:final value) =>
          await _remote.loginWithSocialToken(provider, value),
      };
      await _persistSession(user);
      return Right(user);
    } on SocialSignInCancelled {
      return const Left(SocialSignInCancelledFailure());
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
  Future<Either<Failure, UserEntity>> login(
    String email,
    String password,
  ) async {
    try {
      final user = await _remote.login(email, password);
      await _persistSession(user);
      return Right(user);
    } on UnauthorizedException catch (e) {
      // The API answers 403 for correct credentials on an unverified account.
      if (e.statusCode == 403) return Left(EmailNotVerifiedFailure(e.message));
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
    String? username,
    String? countryCode,
    String roleName = 'USER',
  }) async {
    try {
      await _remote.register(
        email,
        password,
        name: name,
        username: username,
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
      await _remote.logout();
    } on UnauthorizedException catch (_) {
      // Session already gone server-side — fall through and clear local state.
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    } on AppException catch (e) {
      return Left(ServerFailure(e.message));
    }

    try {
      await _storage.clearSession();
      await _cookieService?.clearCookies();
      return const Right(null);
    } on Object catch (e) {
      return Left(CacheFailure('Failed to clear local session: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> verifyEmail(String email, String otpCode) =>
      _guard(() => _remote.verifyEmail(email, otpCode));

  @override
  Future<Either<Failure, void>> resendVerificationOtp(String email) =>
      _guard(() => _remote.resendVerificationOtp(email));

  @override
  Future<Either<Failure, void>> forgotPassword(String email) =>
      _guard(() => _remote.forgotPassword(email));

  @override
  Future<Either<Failure, void>> resetPassword(
    String email,
    String otpCode,
    String newPassword,
  ) =>
      _guard(() => _remote.resetPassword(email, otpCode, newPassword));

  /// Runs a void remote call and maps the data layer's exceptions to Failures.
  Future<Either<Failure, void>> _guard(Future<void> Function() call) async {
    try {
      await call();
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
      await _cookieService?.clearCookies();
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
