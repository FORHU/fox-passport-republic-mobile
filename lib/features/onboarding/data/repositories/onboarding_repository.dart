import 'package:flutter_template/core/errors/exceptions.dart';
import 'package:flutter_template/core/errors/failure.dart';
import 'package:flutter_template/features/onboarding/data/datasources/onboarding_remote_datasource.dart';
import 'package:flutter_template/features/onboarding/domain/entities/onboarding_models.dart';
import 'package:fpdart/fpdart.dart';

/// Contract the controller depends on.
abstract class OnboardingRepository {
  Future<Either<Failure, ProfileSeed>> fetchProfile();
  Future<Either<Failure, void>> saveProfile({
    required String name,
    required String country,
    required String state,
    required String city,
    required String district,
  });
  Future<Either<Failure, List<RoleRequestSummary>>> fetchMyRoleRequests();
  Future<Either<Failure, List<GeoCountry>>> fetchCountries();
  Future<Either<Failure, List<GeoState>>> fetchStates(String countryCode);
  Future<Either<Failure, List<String>>> fetchCities(
    String countryCode, {
    String? stateCode,
  });
}

class OnboardingRepositoryImpl implements OnboardingRepository {
  OnboardingRepositoryImpl(this._remote);

  final OnboardingRemoteDataSource _remote;

  /// Maps the data layer's exceptions to Failures, once, for every call.
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

  @override
  Future<Either<Failure, ProfileSeed>> fetchProfile() =>
      _guard(_remote.fetchProfile);

  @override
  Future<Either<Failure, void>> saveProfile({
    required String name,
    required String country,
    required String state,
    required String city,
    required String district,
  }) =>
      _guard(
        () => _remote.updateProfile(
          name: name,
          country: country,
          state: state,
          city: city,
          district: district,
        ),
      );

  @override
  Future<Either<Failure, List<RoleRequestSummary>>> fetchMyRoleRequests() =>
      _guard(_remote.fetchMyRoleRequests);

  @override
  Future<Either<Failure, List<GeoCountry>>> fetchCountries() =>
      _guard(_remote.fetchCountries);

  @override
  Future<Either<Failure, List<GeoState>>> fetchStates(String countryCode) =>
      _guard(() => _remote.fetchStates(countryCode));

  @override
  Future<Either<Failure, List<String>>> fetchCities(
    String countryCode, {
    String? stateCode,
  }) =>
      _guard(() => _remote.fetchCities(countryCode, stateCode: stateCode));
}
