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
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildHeaderBadges(),
          const SizedBox(height: AppSpacing.md),
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
            const SizedBox(height: AppSpacing.md),
            _buildCodeSnippet(question.codeSnippet!),
          ],
          const SizedBox(height: AppSpacing.lg),
          ...List.generate(question.options.length, (index) {
            return Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: _buildOptionTile(index),
            );
          }),
          if (hasAnswered) ...[
            const SizedBox(height: AppSpacing.md),
            _buildExplanation(),
            const SizedBox(height: AppSpacing.xl),
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
        const SizedBox(width: AppSpacing.xs),
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
            fontFamily: 'Courier',
            fontSize: 13,
            color: Color(0xFFF4F4F5),
            height: 1.45,
          ),
        ),
      ),
    );
  }

  Widget _buildOptionTile(int index) {
    final isSelected = selectedOption == index;
    final isCorrectOption = index == question.correctIndex;

    var borderColor = AppColors.ui.borderHairline;
    var bgColor = AppColors.ui.surface;
    var textColor = AppColors.text.primary;

    if (hasAnswered) {
      if (isCorrectOption) {
        borderColor = AppColors.status.success;
        bgColor = AppColors.status.success.withValues(alpha: 0.08);
        textColor = AppColors.status.success;
      } else if (isSelected) {
        borderColor = AppColors.status.error;
        bgColor = AppColors.status.error.withValues(alpha: 0.08);
        textColor = AppColors.status.error;
      }
    } else if (isSelected) {
      borderColor = AppColors.ink.primary;
      bgColor = AppColors.ink.primary.withValues(alpha: 0.04);
    }

    final label = String.fromCharCode(65 + index); // A, B, C, D

    return Material(
      color: Colors.transparent,
      child: InkWell(
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
              width: (isSelected || isCorrectOption) && hasAnswered ? 1.5 : 1,
            ),
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
              const SizedBox(width: AppSpacing.sm),
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
              if (hasAnswered && isCorrectOption)
                Icon(
                  Icons.check_circle_rounded,
                  color: AppColors.status.success,
                  size: 20,
                )
              else if (hasAnswered && isSelected)
                Icon(
                  Icons.cancel_rounded,
                  color: AppColors.status.error,
                  size: 20,
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildExplanation() {
    final isCorrect = selectedOption == question.correctIndex;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isCorrect
            ? AppColors.status.success.withValues(alpha: 0.08)
            : AppColors.status.warning.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isCorrect
              ? AppColors.status.success.withValues(alpha: 0.3)
              : AppColors.status.warning.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isCorrect
                    ? Icons.check_circle_rounded
                    : Icons.info_outline_rounded,
                color: isCorrect
                    ? AppColors.status.success
                    : AppColors.status.warning,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                isCorrect ? 'Correct!' : 'Explanation',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: isCorrect
                      ? AppColors.status.success
                      : AppColors.status.warning,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            question.explanation,
            style: TextStyle(
              fontSize: 13.5,
              height: 1.45,
              color: AppColors.text.primary,
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 250.ms).slideY(begin: 0.1, end: 0);
  }
}
