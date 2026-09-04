import 'package:flutter_template/features/quiz/domain/entities/quiz_question.dart';

class QuizQuestionModel extends QuizQuestion {
  const QuizQuestionModel({
    required super.id,
    required super.category,
    required super.difficulty,
    required super.question,
    required super.options,
    required super.correctIndex,
    required super.explanation,
    super.codeSnippet,
  });

  factory QuizQuestionModel.fromJson(Map<String, dynamic> json) {
    return QuizQuestionModel(
      id: json['id'] as int? ?? 0,
      category: json['category'] as String? ?? 'GENERAL',
      difficulty: json['difficulty'] as String? ?? 'INTERMEDIATE',
      question: json['question'] as String? ?? '',
      codeSnippet: json['codeSnippet'] as String?,
      options: (json['options'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      correctIndex: json['correctIndex'] as int? ?? 0,
      explanation: json['explanation'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'category': category,
      'difficulty': difficulty,
      'question': question,
      'codeSnippet': codeSnippet,
      'options': options,
      'correctIndex': correctIndex,
      'explanation': explanation,
    };
  }
}
