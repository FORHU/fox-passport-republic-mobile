import 'package:flutter_template/core/errors/failure.dart';
import 'package:flutter_template/features/profile/data/repositories/profile_repository.dart';
import 'package:fpdart/fpdart.dart';

/// Changes the display name on the account.
class UpdateProfileNameUseCase {
  UpdateProfileNameUseCase(this._repository);

  final ProfileRepository _repository;

  Future<Either<Failure, Unit>> call(String name) =>
      _repository.updateName(name.trim());
}
