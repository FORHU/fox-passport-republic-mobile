import 'package:equatable/equatable.dart';

class QuizProgress extends Equatable {
  const QuizProgress({
    required this.answers,
    required this.score,
    required this.answeredCount,
  });

  final Map<int, int> answers;
  final int score;
  final int answeredCount;

  @override
  List<Object?> get props => [answers, score, answeredCount];
}
