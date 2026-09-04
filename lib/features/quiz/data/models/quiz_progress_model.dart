import 'package:flutter_template/features/quiz/domain/entities/quiz_progress.dart';

class QuizProgressModel extends QuizProgress {
  const QuizProgressModel({
    required super.answers,
    required super.score,
    required super.answeredCount,
  });

  factory QuizProgressModel.fromJson(Map<String, dynamic> json) {
    final rawAnswers = json['answers'];
    final parsedAnswers = <int, int>{};

    if (rawAnswers is Map) {
      rawAnswers.forEach((key, value) {
        final parsedKey = int.tryParse(key.toString());
        final parsedValue = int.tryParse(value.toString());
        if (parsedKey != null && parsedValue != null) {
          parsedAnswers[parsedKey] = parsedValue;
        }
      });
    }

    return QuizProgressModel(
      answers: parsedAnswers,
      score: (json['score'] as num?)?.toInt() ?? 0,
      answeredCount: (json['answeredCount'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'answers': answers.map((k, v) => MapEntry(k.toString(), v)),
      'score': score,
      'answeredCount': answeredCount,
    };
  }
}
