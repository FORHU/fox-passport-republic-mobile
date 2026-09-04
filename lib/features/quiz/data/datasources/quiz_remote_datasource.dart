import 'package:dio/dio.dart';
import 'package:flutter_template/core/constants/api_endpoints.dart';
import 'package:flutter_template/core/errors/exceptions.dart';
import 'package:flutter_template/core/services/api_service.dart';
import 'package:flutter_template/core/utils/logger.dart';
import 'package:flutter_template/features/quiz/data/models/quiz_progress_model.dart';
import 'package:flutter_template/features/quiz/data/models/quiz_question_model.dart';

abstract class QuizRemoteDataSource {
  Future<List<QuizQuestionModel>> getQuestions({
    String? category,
    String? difficulty,
    String? search,
  });

  Future<QuizProgressModel> getProgress();

  Future<QuizProgressModel> saveProgress({
    required Map<int, int> answers,
    required int score,
    required int answeredCount,
  });

  Future<QuizProgressModel> resetProgress();
}

class QuizRemoteDataSourceImpl implements QuizRemoteDataSource {
  QuizRemoteDataSourceImpl(this._api);

  final ApiService _api;

  Options _tenantOptions() {
    return Options(
      headers: {
        'x-tenant-slug': 'flutter-v1',
        'x-tenant-id': 'flutter-v1',
      },
    );
  }

  @override
  Future<List<QuizQuestionModel>> getQuestions({
    String? category,
    String? difficulty,
    String? search,
  }) async {
    try {
      final queryParameters = <String, dynamic>{
        'tenant': 'flutter-v1',
      };
      if (category != null && category != 'ALL') {
        queryParameters['category'] = category;
      }
      if (difficulty != null && difficulty != 'ALL') {
        queryParameters['difficulty'] = difficulty;
      }
      if (search != null && search.isNotEmpty) {
        queryParameters['search'] = search;
      }

      final response = await _api.client.get<dynamic>(
        ApiEndpoints.quiz,
        queryParameters: queryParameters,
        options: _tenantOptions(),
      );

      final data = response.data;
      if (data is Map && data['data'] != null) {
        final payload = data['data'];
        final rawList = (payload is Map && payload['items'] is List)
            ? payload['items'] as List<dynamic>
            : (payload is List ? payload : <dynamic>[]);

        return rawList
            .map(
              (e) => QuizQuestionModel.fromJson(
                (e as Map).cast<String, dynamic>(),
              ),
            )
            .toList();
      }

      throw const ServerException(
        'Invalid response format received from Quiz API.',
      );
    } on DioException catch (e) {
      appLogger.e('Failed to fetch quiz questions from PostgreSQL: $e');
      final resData = e.response?.data;
      final serverMsg = resData is Map ? resData['message']?.toString() : null;
      throw ServerException(
        serverMsg ?? 'Failed to load quiz questions from server.',
        statusCode: e.response?.statusCode,
      );
    } on AppException {
      rethrow;
    } catch (e) {
      appLogger.e('Unexpected error fetching quiz questions: $e');
      throw ServerException(e.toString());
    }
  }

  @override
  Future<QuizProgressModel> getProgress() async {
    try {
      final response = await _api.client.get<dynamic>(
        ApiEndpoints.quizProgress,
        queryParameters: {'tenant': 'flutter-v1'},
        options: _tenantOptions(),
      );
      final data = response.data;
      if (data is Map && data['data'] != null) {
        return QuizProgressModel.fromJson(
          (data['data'] as Map).cast<String, dynamic>(),
        );
      }
      return const QuizProgressModel(answers: {}, score: 0, answeredCount: 0);
    } on DioException catch (e) {
      appLogger.w('Failed to fetch remote quiz progress: $e');
      final resData = e.response?.data;
      final serverMsg = resData is Map ? resData['message']?.toString() : null;
      throw ServerException(
        serverMsg ?? 'Failed to load quiz progress.',
        statusCode: e.response?.statusCode,
      );
    } catch (e) {
      appLogger.w('Unexpected error getting quiz progress: $e');
      throw ServerException(e.toString());
    }
  }

  @override
  Future<QuizProgressModel> saveProgress({
    required Map<int, int> answers,
    required int score,
    required int answeredCount,
  }) async {
    final payload = {
      'answers': answers.map((k, v) => MapEntry(k.toString(), v)),
      'score': score,
      'answeredCount': answeredCount,
      'sessionId': 'flutter-device-session',
      'tenant': 'flutter-v1',
    };

    try {
      final response = await _api.client.post<dynamic>(
        ApiEndpoints.quizProgress,
        data: payload,
        options: _tenantOptions(),
      );
      final data = response.data;
      if (data is Map && data['data'] != null) {
        return QuizProgressModel.fromJson(
          (data['data'] as Map).cast<String, dynamic>(),
        );
      }
      return QuizProgressModel(
        answers: answers,
        score: score,
        answeredCount: answeredCount,
      );
    } on DioException catch (e) {
      appLogger.w('Failed to save quiz progress to PostgreSQL: $e');
      final resData = e.response?.data;
      final serverMsg = resData is Map ? resData['message']?.toString() : null;
      throw ServerException(
        serverMsg ?? 'Failed to save quiz progress.',
        statusCode: e.response?.statusCode,
      );
    } catch (e) {
      appLogger.w('Unexpected error saving quiz progress: $e');
      throw ServerException(e.toString());
    }
  }

  @override
  Future<QuizProgressModel> resetProgress() async {
    try {
      final response = await _api.client.post<dynamic>(
        ApiEndpoints.quizReset,
        data: {
          'sessionId': 'flutter-device-session',
          'tenant': 'flutter-v1',
        },
        options: _tenantOptions(),
      );
      final data = response.data;
      if (data is Map && data['data'] != null) {
        return QuizProgressModel.fromJson(
          (data['data'] as Map).cast<String, dynamic>(),
        );
      }
      return const QuizProgressModel(answers: {}, score: 0, answeredCount: 0);
    } on DioException catch (e) {
      appLogger.w('Failed to reset remote quiz progress: $e');
      final resData = e.response?.data;
      final serverMsg = resData is Map ? resData['message']?.toString() : null;
      throw ServerException(
        serverMsg ?? 'Failed to reset quiz progress.',
        statusCode: e.response?.statusCode,
      );
    } catch (e) {
      appLogger.w('Unexpected error resetting quiz progress: $e');
      throw ServerException(e.toString());
    }
  }
}
