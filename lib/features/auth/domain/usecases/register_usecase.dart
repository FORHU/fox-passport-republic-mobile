import 'package:flutter_template/core/errors/failure.dart';
import 'package:flutter_template/features/auth/data/repositories/auth_repository.dart';
import 'package:fpdart/fpdart.dart';

/// Registers a new user account.
class RegisterUseCase {
  RegisterUseCase(this._repository);

  final AuthRepository _repository;

  Future<Either<Failure, void>> call(
    String email,
    String password, {
    String? name,
    String? username,
    String? countryCode,
    String roleName = 'USER',
  }) =>
      _repository.register(
        email.trim(),
        password,
        name: name,
        username: username,
        countryCode: countryCode,
        roleName: roleName,
      );
}
