import 'package:flutter_template/core/errors/failure.dart';
import 'package:flutter_template/features/quiz/data/repositories/quiz_repository.dart';
import 'package:flutter_template/features/quiz/domain/entities/quiz_progress.dart';
import 'package:fpdart/fpdart.dart';

class ResetQuizProgressUseCase {
  ResetQuizProgressUseCase(this._repository);

  final QuizRepository _repository;

  Future<Either<Failure, QuizProgress>> call() => _repository.resetProgress();
}
