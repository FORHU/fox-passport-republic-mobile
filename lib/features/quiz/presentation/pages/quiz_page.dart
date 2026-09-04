import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_template/features/quiz/presentation/controllers/quiz_controller.dart';
import 'package:flutter_template/features/quiz/presentation/widgets/quiz_question_card.dart';
import 'package:flutter_template/features/quiz/presentation/widgets/quiz_score_summary.dart';
import 'package:flutter_template/shared/widgets/app_state_view.dart';
import 'package:flutter_template/theme/tokens/colors.dart';
import 'package:flutter_template/theme/tokens/spacing.dart';

class QuizPage extends ConsumerWidget {
  const QuizPage({super.key});

  static const List<String> categories = [
    'ALL',
    'RIVERPOD',
    'WIDGET_LIFECYCLE',
    'STATE_MANAGEMENT',
    'PERFORMANCE',
    'NAVIGATION',
    'DART_PATTERNS',
    'ASYNCHRONY',
    'NETWORKING',
    'ANIMATIONS',
    'ARCHITECTURE',
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(quizControllerProvider);
    final controller = ref.read(quizControllerProvider.notifier);

    return Scaffold(
      backgroundColor: AppColors.ui.background,
      appBar: AppBar(
        backgroundColor: AppColors.ui.surface,
        elevation: 0,
        title: Text(
          'Flutter Quiz',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: AppColors.text.primary,
          ),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.symmetric(vertical: 10),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.ink.primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.stars_rounded,
                    color: AppColors.status.warning, size: 16),
                const SizedBox(width: 4),
                Text(
                  '${state.progress.score} pts',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.ink.primary,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'View Performance',
            icon: Icon(Icons.emoji_events_outlined,
                color: AppColors.text.primary),
            onPressed: () {
              showDialog<void>(
                context: context,
                builder: (_) => QuizScoreSummaryDialog(
                  progress: state.progress,
                  totalQuestions: state.questions.length,
                  onReset: controller.resetProgress,
                ),
              );
            },
          ),
          SizedBox(width: AppSpacing.xs),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            _buildCategoryBar(ref, state),
            if (state.questions.isNotEmpty) _buildProgressBar(state),
            Expanded(
              child: _buildContent(context, ref, state),
            ),
            if (state.questions.isNotEmpty) _buildBottomControls(ref, state),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryBar(WidgetRef ref, QuizState state) {
    final controller = ref.read(quizControllerProvider.notifier);

    return Container(
      height: 48,
      margin: EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: ListView.separated(
        padding: EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        scrollDirection: Axis.horizontal,
        itemCount: categories.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final cat = categories[index];
          final isSelected = state.selectedCategory == cat;

          return ChoiceChip(
            label: Text(cat.replaceAll('_', ' ')),
            labelStyle: TextStyle(
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              color: isSelected ? Colors.white : AppColors.text.secondary,
            ),
            selected: isSelected,
            selectedColor: AppColors.ink.primary,
            backgroundColor: AppColors.ui.surface,
            side: BorderSide(
              color: isSelected
                  ? AppColors.ink.primary
                  : AppColors.ui.borderHairline,
            ),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            onSelected: (_) => controller.setCategory(cat),
          );
        },
      ),
    );
  }

  Widget _buildProgressBar(QuizState state) {
    final total = state.questions.length;
    final current = state.currentIndex + 1;
    final progressVal = total > 0 ? (current / total) : 0.0;

    return Column(
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Question $current of $total',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.text.secondary,
                ),
              ),
              Text(
                '${state.progress.answeredCount} answered',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: AppColors.text.tertiary,
                ),
              ),
            ],
          ),
        ),
        LinearProgressIndicator(
          value: progressVal,
          backgroundColor: AppColors.ui.borderHairline,
          valueColor: AlwaysStoppedAnimation<Color>(AppColors.ink.primary),
          minHeight: 3,
        ),
        SizedBox(height: AppSpacing.md),
      ],
    );
  }

  Widget _buildContent(BuildContext context, WidgetRef ref, QuizState state) {
    if (state.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.error != null && state.questions.isEmpty) {
      return AppStateView(
        type: AppStateType.error,
        title: 'Could not load quiz questions',
        message: state.error,
        actionLabel: 'Retry',
        onAction: () =>
            ref.read(quizControllerProvider.notifier).loadQuestions(),
      );
    }

    if (state.questions.isEmpty) {
      return AppStateView(
        type: AppStateType.empty,
        title: 'No questions found',
        message: 'Try selecting a different category filter.',
        actionLabel: 'Reset filter',
        onAction: () =>
            ref.read(quizControllerProvider.notifier).setCategory('ALL'),
      );
    }

    final question = state.currentQuestion;
    if (question == null) return const SizedBox.shrink();

    return QuizQuestionCard(
      key: ValueKey(question.id),
      question: question,
      selectedOption: state.currentAnswer,
      onOptionSelected: (optIndex) {
        ref.read(quizControllerProvider.notifier).selectOption(optIndex);
      },
    );
  }

  Widget _buildBottomControls(WidgetRef ref, QuizState state) {
    final controller = ref.read(quizControllerProvider.notifier);
    final isFirst = state.currentIndex == 0;
    final isLast = state.currentIndex == state.questions.length - 1;

    return Container(
      padding: EdgeInsets.symmetric(
          horizontal: AppSpacing.lg, vertical: AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.ui.surface,
        border: Border(top: BorderSide(color: AppColors.ui.borderHairline)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.text.primary,
              side: BorderSide(color: AppColors.ui.borderHairline),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
            onPressed: isFirst ? null : controller.previousQuestion,
            icon: const Icon(Icons.arrow_back_rounded, size: 16),
            label: const Text('Previous'),
          ),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.ink.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
            onPressed: isLast ? null : controller.nextQuestion,
            iconAlignment: IconAlignment.end,
            icon: const Icon(Icons.arrow_forward_rounded, size: 16),
            label: Text(isLast ? 'Completed' : 'Next'),
          ),
        ],
      ),
    );
  }
}
