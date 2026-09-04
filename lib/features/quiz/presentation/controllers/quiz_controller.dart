import 'dart:async';
import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_template/features/auth/presentation/controllers/auth_controller.dart';
import 'package:flutter_template/features/quiz/data/datasources/quiz_remote_datasource.dart';
import 'package:flutter_template/features/quiz/data/repositories/quiz_repository.dart';
import 'package:flutter_template/features/quiz/domain/entities/quiz_progress.dart';
import 'package:flutter_template/features/quiz/domain/entities/quiz_question.dart';

// --- Dependency wiring ---

final quizRepositoryProvider = Provider<QuizRepository>((ref) {
  final remote = QuizRemoteDataSourceImpl(ref.watch(apiServiceProvider));
  return QuizRepositoryImpl(remote);
});

// --- State ---

class QuizState extends Equatable {
  const QuizState({
    this.isLoading = false,
    this.isSubmitting = false,
    this.questions = const [],
    this.currentIndex = 0,
    this.progress = const QuizProgress(answers: {}, score: 0, answeredCount: 0),
    this.selectedCategory = 'ALL',
    this.selectedDifficulty = 'ALL',
    this.searchQuery = '',
    this.error,
  });

  final bool isLoading;
  final bool isSubmitting;
  final List<QuizQuestion> questions;
  final int currentIndex;
  final QuizProgress progress;
  final String selectedCategory;
  final String selectedDifficulty;
  final String searchQuery;
  final String? error;

  QuizQuestion? get currentQuestion =>
      questions.isNotEmpty && currentIndex < questions.length
          ? questions[currentIndex]
          : null;

  int? get currentAnswer {
    final q = currentQuestion;
    if (q == null) return null;
    return progress.answers[q.id];
  }

  bool get hasAnsweredCurrent => currentAnswer != null;

  bool get isCurrentCorrect {
    final q = currentQuestion;
    final ans = currentAnswer;
    if (q == null || ans == null) return false;
    return ans == q.correctIndex;
  }

  QuizState copyWith({
    bool? isLoading,
    bool? isSubmitting,
    List<QuizQuestion>? questions,
    int? currentIndex,
    QuizProgress? progress,
    String? selectedCategory,
    String? selectedDifficulty,
    String? searchQuery,
    String? error,
  }) {
    return QuizState(
      isLoading: isLoading ?? this.isLoading,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      questions: questions ?? this.questions,
      currentIndex: currentIndex ?? this.currentIndex,
      progress: progress ?? this.progress,
      selectedCategory: selectedCategory ?? this.selectedCategory,
      selectedDifficulty: selectedDifficulty ?? this.selectedDifficulty,
      searchQuery: searchQuery ?? this.searchQuery,
      error: error,
    );
  }

  @override
  List<Object?> get props => [
        isLoading,
        isSubmitting,
        questions,
        currentIndex,
        progress,
        selectedCategory,
        selectedDifficulty,
        searchQuery,
        error,
      ];
}

// --- Controller ---

class QuizController extends Notifier<QuizState> {
  @override
  QuizState build() {
    unawaited(Future.microtask(() async {
      await loadProgress();
      await loadQuestions();
    }));
    return const QuizState(isLoading: true);
  }

  QuizRepository get _repo => ref.read(quizRepositoryProvider);

  Future<void> loadQuestions() async {
    state = state.copyWith(isLoading: true, error: null);

    final result = await _repo.getQuestions(
      category: state.selectedCategory,
      difficulty: state.selectedDifficulty,
      search: state.searchQuery,
    );

    result.fold(
      (failure) => state = state.copyWith(
        isLoading: false,
        error: failure.message,
      ),
      (items) => state = state.copyWith(
        isLoading: false,
        questions: items,
      ),
    );
  }

  Future<void> loadProgress() async {
    final result = await _repo.getProgress();
    result.fold(
      (_) => null,
      (prog) => state = state.copyWith(progress: prog),
    );
  }

  Future<void> selectOption(int optionIndex) async {
    final q = state.currentQuestion;
    if (q == null || state.hasAnsweredCurrent) return;

    final updatedAnswers = Map<int, int>.from(state.progress.answers)
      ..[q.id] = optionIndex;
    final isCorrect = optionIndex == q.correctIndex;
    final newScore = state.progress.score + (isCorrect ? 10 : 0);
    final newAnsweredCount = updatedAnswers.length;

    final updatedProgress = QuizProgress(
      answers: updatedAnswers,
      score: newScore,
      answeredCount: newAnsweredCount,
    );

    state = state.copyWith(progress: updatedProgress);

    // Persist to backend
    unawaited(
      _repo.saveProgress(
        answers: updatedAnswers,
        score: newScore,
        answeredCount: newAnsweredCount,
      ),
    );
  }

  void nextQuestion() {
    if (state.currentIndex < state.questions.length - 1) {
      state = state.copyWith(currentIndex: state.currentIndex + 1);
    }
  }

  void previousQuestion() {
    if (state.currentIndex > 0) {
      state = state.copyWith(currentIndex: state.currentIndex - 1);
    }
  }

  void jumpToQuestion(int index) {
    if (index >= 0 && index < state.questions.length) {
      state = state.copyWith(currentIndex: index);
    }
  }

  Future<void> setCategory(String category) async {
    if (state.selectedCategory == category) return;
    state = state.copyWith(selectedCategory: category);
    await loadQuestions();
  }

  Future<void> setDifficulty(String difficulty) async {
    if (state.selectedDifficulty == difficulty) return;
    state = state.copyWith(selectedDifficulty: difficulty);
    await loadQuestions();
  }

  Future<void> setSearch(String query) async {
    state = state.copyWith(searchQuery: query);
    await loadQuestions();
  }

  Future<void> resetProgress() async {
    state = state.copyWith(isSubmitting: true);
    final result = await _repo.resetProgress();
    result.fold(
      (failure) => state = state.copyWith(
        isSubmitting: false,
        error: failure.message,
      ),
      (freshProgress) => state = state.copyWith(
        isSubmitting: false,
        progress: freshProgress,
        currentIndex: 0,
      ),
    );
  }
}

final quizControllerProvider =
    NotifierProvider<QuizController, QuizState>(QuizController.new);
