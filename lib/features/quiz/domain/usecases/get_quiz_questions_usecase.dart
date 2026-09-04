import 'package:flutter_template/core/errors/failure.dart';
import 'package:flutter_template/features/quiz/data/repositories/quiz_repository.dart';
import 'package:flutter_template/features/quiz/domain/entities/quiz_question.dart';
import 'package:fpdart/fpdart.dart';

class GetQuizQuestionsUseCase {
  GetQuizQuestionsUseCase(this._repository);

  final QuizRepository _repository;

  Future<Either<Failure, List<QuizQuestion>>> call({
    String? category,
    String? difficulty,
    String? search,
  }) =>
      _repository.getQuestions(
        category: category,
        difficulty: difficulty,
        search: search,
      );
}
