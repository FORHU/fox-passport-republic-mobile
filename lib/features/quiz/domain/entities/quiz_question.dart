import 'package:equatable/equatable.dart';

class QuizQuestion extends Equatable {
  const QuizQuestion({
    required this.id,
    required this.category,
    required this.difficulty,
    required this.question,
    required this.options,
    required this.correctIndex,
    required this.explanation,
    this.codeSnippet,
  });

  final int id;
  final String category;
  final String difficulty;
  final String question;
  final String? codeSnippet;
  final List<String> options;
  final int correctIndex;
  final String explanation;

  @override
  List<Object?> get props => [
        id,
        category,
        difficulty,
        question,
        codeSnippet,
        options,
        correctIndex,
        explanation,
      ];
}
