import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_template/features/auth/presentation/controllers/auth_controller.dart';
import 'package:flutter_template/features/quiz/data/datasources/quiz_remote_datasource.dart';
import 'package:flutter_template/features/quiz/data/repositories/quiz_repository.dart';
import 'package:flutter_template/features/quiz/domain/entities/quiz_progress.dart';
import 'package:flutter_template/features/quiz/domain/entities/quiz_question.dart';
import 'package:flutter_template/features/quiz/domain/usecases/get_quiz_progress_usecase.dart';
import 'package:flutter_template/features/quiz/domain/usecases/get_quiz_questions_usecase.dart';
import 'package:flutter_template/features/quiz/domain/usecases/reset_quiz_progress_usecase.dart';
import 'package:flutter_template/features/quiz/domain/usecases/save_quiz_progress_usecase.dart';

// --- Providers ---

final quizRemoteDataSourceProvider = Provider<QuizRemoteDataSource>((ref) {
  return QuizRemoteDataSourceImpl(ref.watch(apiServiceProvider));
});

final quizRepositoryProvider = Provider<QuizRepository>((ref) {
  return QuizRepositoryImpl(ref.watch(quizRemoteDataSourceProvider));
});

final getQuizQuestionsUseCaseProvider = Provider<GetQuizQuestionsUseCase>(
  (ref) => GetQuizQuestionsUseCase(ref.watch(quizRepositoryProvider)),
);

final getQuizProgressUseCaseProvider = Provider<GetQuizProgressUseCase>(
  (ref) => GetQuizProgressUseCase(ref.watch(quizRepositoryProvider)),
);

final saveQuizProgressUseCaseProvider = Provider<SaveQuizProgressUseCase>(
  (ref) => SaveQuizProgressUseCase(ref.watch(quizRepositoryProvider)),
);

final resetQuizProgressUseCaseProvider = Provider<ResetQuizProgressUseCase>(
  (ref) => ResetQuizProgressUseCase(ref.watch(quizRepositoryProvider)),
);

final quizControllerProvider =
    NotifierProvider<QuizController, QuizState>(QuizController.new);

// --- State ---

class QuizState extends Equatable {
  const QuizState({
    this.isLoading = false,
    this.isSubmitting = false,
    this.questions = const [],
    this.currentIndex = 0,
    this.progress = const QuizProgress(
      answers: {},
      score: 0,
      answeredCount: 0,
    ),
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
    bool clearError = false,
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
      error: clearError ? null : (error ?? this.error),
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
    unawaited(
      Future.microtask(() async {
        await loadProgress();
        await loadQuestions();
      }),
    );
    return const QuizState(isLoading: true);
  }

  Future<void> loadQuestions() async {
    state = state.copyWith(isLoading: true, clearError: true);

    final useCase = ref.read(getQuizQuestionsUseCaseProvider);
    final result = await useCase(
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
        currentIndex: 0,
        clearError: true,
      ),
    );
  }

  Future<void> loadProgress() async {
    final useCase = ref.read(getQuizProgressUseCaseProvider);
    final result = await useCase();
    result.fold(
      (_) => null,
      (prog) => state = state.copyWith(progress: prog),
    );
  }

  Future<void> selectOption(int optionIndex) async {
    final question = state.currentQuestion;
    if (question == null || state.hasAnsweredCurrent) return;

    final isCorrect = optionIndex == question.correctIndex;
    final updatedAnswers = Map<int, int>.from(state.progress.answers);
    updatedAnswers[question.id] = optionIndex;

    final newScore = state.progress.score + (isCorrect ? 10 : 0);
    final newAnsweredCount = state.progress.answeredCount + 1;

    final newProgress = state.progress.copyWith(
      answers: updatedAnswers,
      score: newScore,
      answeredCount: newAnsweredCount,
    );

    state = state.copyWith(progress: newProgress);

    // Save to PostgreSQL via UseCase
    final saveUseCase = ref.read(saveQuizProgressUseCaseProvider);
    await saveUseCase(
      answers: updatedAnswers,
      score: newScore,
      answeredCount: newAnsweredCount,
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

  void setCategory(String category) {
    if (state.selectedCategory == category) return;
    state = state.copyWith(selectedCategory: category);
    unawaited(loadQuestions());
  }

  void setDifficulty(String difficulty) {
    if (state.selectedDifficulty == difficulty) return;
    state = state.copyWith(selectedDifficulty: difficulty);
    unawaited(loadQuestions());
  }

  void setSearchQuery(String query) {
    state = state.copyWith(searchQuery: query);
    unawaited(loadQuestions());
  }

  Future<void> resetProgress() async {
    state = state.copyWith(isLoading: true);
    final resetUseCase = ref.read(resetQuizProgressUseCaseProvider);
    final result = await resetUseCase();
    result.fold(
      (failure) => state = state.copyWith(
        isLoading: false,
        error: failure.message,
      ),
      (resetProg) => state = state.copyWith(
        isLoading: false,
        progress: resetProg,
        clearError: true,
      ),
    );
  }
}
