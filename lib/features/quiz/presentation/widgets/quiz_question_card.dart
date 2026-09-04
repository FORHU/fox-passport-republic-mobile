import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_template/features/quiz/domain/entities/quiz_question.dart';
import 'package:flutter_template/theme/tokens/colors.dart';
import 'package:flutter_template/theme/tokens/spacing.dart';

class QuizQuestionCard extends StatelessWidget {
  const QuizQuestionCard({
    required this.question,
    required this.selectedOption,
    required this.onOptionSelected,
    super.key,
  });

  final QuizQuestion question;
  final int? selectedOption;
  final ValueChanged<int> onOptionSelected;

  bool get hasAnswered => selectedOption != null;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildHeaderBadges(),
          SizedBox(height: AppSpacing.md),
          Text(
            question.question,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.text.primary,
              height: 1.35,
            ),
          ),
          if (question.codeSnippet != null &&
              question.codeSnippet!.trim().isNotEmpty) ...[
            SizedBox(height: AppSpacing.md),
            _buildCodeSnippet(question.codeSnippet!),
          ],
          SizedBox(height: AppSpacing.lg),
          ...List.generate(question.options.length, (index) {
            return Padding(
              padding: EdgeInsets.only(bottom: AppSpacing.sm),
              child: _buildOptionTile(index),
            );
          }),
          if (hasAnswered) ...[
            SizedBox(height: AppSpacing.md),
            _buildExplanation(),
            SizedBox(height: AppSpacing.xl),
          ],
        ],
      ),
    );
  }

  Widget _buildHeaderBadges() {
    final difficultyColor = switch (question.difficulty.toUpperCase()) {
      'BEGINNER' => const Color(0xFF10B981),
      'INTERMEDIATE' => const Color(0xFF3B82F6),
      'ADVANCED' => const Color(0xFFF59E0B),
      'EXPERT' => const Color(0xFFEF4444),
      _ => AppColors.text.secondary,
    };

    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.ink.primary.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            question.category.replaceAll('_', ' '),
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
              color: AppColors.ink.primary,
            ),
          ),
        ),
        SizedBox(width: AppSpacing.xs),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: difficultyColor.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            question.difficulty.toUpperCase(),
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
              color: difficultyColor,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCodeSnippet(String snippet) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF18181B),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFF27272A)),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Text(
          snippet,
          style: const TextStyle(
            fontFamily: 'monospace',
            fontSize: 13,
            color: Color(0xFFE4E4E7),
            height: 1.45,
          ),
        ),
      ),
    );
  }

  Widget _buildOptionTile(int index) {
    final isSelected = selectedOption == index;
    final isCorrectOption = index == question.correctIndex;

    var bgColor = AppColors.ui.surface;
    var borderColor = AppColors.ui.borderHairline;
    var textColor = AppColors.text.primary;
    Widget? trailingIcon;

    if (hasAnswered) {
      if (isCorrectOption) {
        bgColor = AppColors.status.success.withValues(alpha: 0.12);
        borderColor = AppColors.status.success;
        textColor = const Color(0xFF065F46);
        trailingIcon = Icon(
          Icons.check_circle_rounded,
          color: AppColors.status.success,
          size: 20,
        );
      } else if (isSelected) {
        bgColor = AppColors.status.error.withValues(alpha: 0.1);
        borderColor = AppColors.status.error;
        textColor = const Color(0xFF991B1B);
        trailingIcon = Icon(
          Icons.cancel_rounded,
          color: AppColors.status.error,
          size: 20,
        );
      } else {
        textColor = AppColors.text.tertiary;
      }
    }

    final optionLabels = ['A', 'B', 'C', 'D', 'E', 'F'];
    final label = index < optionLabels.length ? optionLabels[index] : '$index';

    return InkWell(
      onTap: hasAnswered ? null : () => onOptionSelected(index),
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
              color: borderColor,
              width: isSelected || isCorrectOption && hasAnswered ? 1.5 : 1),
          boxShadow: [
            if (!hasAnswered)
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.02),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 26,
              height: 26,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: hasAnswered && isCorrectOption
                    ? AppColors.status.success
                    : (hasAnswered && isSelected
                        ? AppColors.status.error
                        : AppColors.ui.surfaceMuted),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: hasAnswered && (isCorrectOption || isSelected)
                      ? Colors.white
                      : AppColors.text.secondary,
                ),
              ),
            ),
            SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                question.options[index],
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  color: textColor,
                  height: 1.35,
                ),
              ),
            ),
            if (trailingIcon != null) trailingIcon,
          ],
        ),
      ),
    );
  }

  Widget _buildExplanation() {
    final isCorrect = selectedOption == question.correctIndex;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isCorrect ? const Color(0xFFF0FDF4) : const Color(0xFFFEF2F2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isCorrect ? const Color(0xFFBBF7D0) : const Color(0xFFFECACA),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isCorrect ? Icons.verified_rounded : Icons.info_outline_rounded,
                size: 18,
                color: isCorrect
                    ? const Color(0xFF15803D)
                    : const Color(0xFFB91C1C),
              ),
              const SizedBox(width: 8),
              Text(
                isCorrect ? 'Correct Answer!' : 'Explanation',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: isCorrect
                      ? const Color(0xFF15803D)
                      : const Color(0xFFB91C1C),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            question.explanation,
            style: TextStyle(
              fontSize: 13,
              height: 1.45,
              color:
                  isCorrect ? const Color(0xFF166534) : const Color(0xFF991B1B),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 250.ms).slideY(begin: 0.1, end: 0);
  }
}
