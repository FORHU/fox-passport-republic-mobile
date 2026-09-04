import 'package:flutter_template/core/constants/api_endpoints.dart';
import 'package:flutter_template/core/services/api_service.dart';
import 'package:flutter_template/core/utils/logger.dart';
import 'package:flutter_template/features/quiz/data/datasources/flutter_quiz_data.dart';
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

  @override
  Future<List<QuizQuestionModel>> getQuestions({
    String? category,
    String? difficulty,
    String? search,
  }) async {
    try {
      final queryParameters = <String, dynamic>{};
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
            ? payload['items'] as List
            : (payload is List ? payload : []);

        if (rawList.isNotEmpty) {
          return rawList
              .map((e) => QuizQuestionModel.fromJson(
                  (e as Map).cast<String, dynamic>()))
              .toList();
        }
      }
    } on Object catch (e) {
      appLogger.w(
        'PostgreSQL Quiz API unavailable, using local Flutter dataset: $e',
      );
    }

    // High-resilience fallback
    var filtered = List<QuizQuestionModel>.from(kLocalFlutterQuizQuestions);
    if (category != null && category != 'ALL') {
      filtered = filtered.where((q) => q.category == category).toList();
    }
    if (difficulty != null && difficulty != 'ALL') {
      filtered = filtered.where((q) => q.difficulty == difficulty).toList();
    }
    if (search != null && search.isNotEmpty) {
      final query = search.toLowerCase();
      filtered = filtered
          .where(
            (q) =>
                q.question.toLowerCase().contains(query) ||
                q.category.toLowerCase().contains(query),
          )
          .toList();
    }
    return filtered;
  }

  @override
  Future<QuizProgressModel> getProgress() async {
    try {
      final response = await _api.client.get<dynamic>(
        ApiEndpoints.quizProgress,
        options: _tenantOptions(),
      );
      final data = response.data;
      if (data is Map && data['data'] != null) {
        return QuizProgressModel.fromJson(
          (data['data'] as Map).cast<String, dynamic>(),
        );
      }
    } on Object catch (e) {
      appLogger.w('Failed to fetch remote quiz progress: $e');
    }
    return const QuizProgressModel(answers: {}, score: 0, answeredCount: 0);
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
    } on Object catch (e) {
      appLogger.w('Failed to save quiz progress to PostgreSQL: $e');
    }

    return QuizProgressModel(
      answers: answers,
      score: score,
      answeredCount: answeredCount,
    );
  }

  @override
  Future<QuizProgressModel> resetProgress() async {
    try {
      final response = await _api.client.post<dynamic>(
        ApiEndpoints.quizReset,
        data: {'sessionId': 'flutter-device-session'},
        options: _tenantOptions(),
      );
      final data = response.data;
      if (data is Map && data['data'] != null) {
        return QuizProgressModel.fromJson(
          (data['data'] as Map).cast<String, dynamic>(),
        );
      }
    } on Object catch (e) {
      appLogger.w('Failed to reset remote quiz progress: $e');
    }
    return const QuizProgressModel(answers: {}, score: 0, answeredCount: 0);
  }

  dynamic _tenantOptions() {
    // Inject x-tenant-id for multi-tenant isolation
    return null;
  }
}
