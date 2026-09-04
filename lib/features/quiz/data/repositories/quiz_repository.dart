import 'package:flutter_template/core/errors/exceptions.dart';
import 'package:flutter_template/core/errors/failure.dart';
import 'package:flutter_template/features/quiz/data/datasources/quiz_remote_datasource.dart';
import 'package:flutter_template/features/quiz/domain/entities/quiz_progress.dart';
import 'package:flutter_template/features/quiz/domain/entities/quiz_question.dart';
import 'package:fpdart/fpdart.dart';

abstract class QuizRepository {
  Future<Either<Failure, List<QuizQuestion>>> getQuestions({
    String? category,
    String? difficulty,
    String? search,
  });

  Future<Either<Failure, QuizProgress>> getProgress();

  Future<Either<Failure, QuizProgress>> saveProgress({
    required Map<int, int> answers,
    required int score,
    required int answeredCount,
  });

  Future<Either<Failure, QuizProgress>> resetProgress();
}

class QuizRepositoryImpl implements QuizRepository {
  QuizRepositoryImpl(this._remote);

  final QuizRemoteDataSource _remote;

  @override
  Future<Either<Failure, List<QuizQuestion>>> getQuestions({
    String? category,
    String? difficulty,
    String? search,
  }) async {
    try {
      final items = await _remote.getQuestions(
        category: category,
        difficulty: difficulty,
        search: search,
      );
      return Right(items);
    } on AppException catch (e) {
      return Left(ServerFailure(e.message));
    } on Object catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, QuizProgress>> getProgress() async {
    try {
      final progress = await _remote.getProgress();
      return Right(progress);
    } on AppException catch (e) {
      return Left(ServerFailure(e.message));
    } on Object catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, QuizProgress>> saveProgress({
    required Map<int, int> answers,
    required int score,
    required int answeredCount,
  }) async {
    try {
      final progress = await _remote.saveProgress(
        answers: answers,
        score: score,
        answeredCount: answeredCount,
      );
      return Right(progress);
    } on AppException catch (e) {
      return Left(ServerFailure(e.message));
    } on Object catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, QuizProgress>> resetProgress() async {
    try {
      final progress = await _remote.resetProgress();
      return Right(progress);
    } on AppException catch (e) {
      return Left(ServerFailure(e.message));
    } on Object catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}
