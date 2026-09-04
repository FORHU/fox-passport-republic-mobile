import 'package:flutter/material.dart';
import 'package:flutter_template/features/quiz/domain/entities/quiz_progress.dart';
import 'package:flutter_template/theme/tokens/colors.dart';
import 'package:flutter_template/theme/tokens/spacing.dart';

class QuizScoreSummaryDialog extends StatelessWidget {
  const QuizScoreSummaryDialog({
    required this.progress,
    required this.totalQuestions,
    required this.onReset,
    super.key,
  });

  final QuizProgress progress;
  final int totalQuestions;
  final VoidCallback onReset;

  @override
  Widget build(BuildContext context) {
    final maxScore = totalQuestions * 10;
    final percentage = maxScore > 0
        ? ((progress.score / maxScore) * 100).clamp(0, 100).round()
        : 0;

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      backgroundColor: AppColors.ui.surface,
      title: Row(
        children: [
          Icon(Icons.emoji_events_rounded,
              color: AppColors.status.warning, size: 28),
          SizedBox(width: AppSpacing.sm),
          Text(
            'Quiz Performance',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.text.primary,
            ),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(vertical: 16),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.ui.surfaceMuted,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                Text(
                  '$percentage%',
                  style: TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.w800,
                    color: percentage >= 70
                        ? AppColors.status.success
                        : (percentage >= 40
                            ? AppColors.status.warning
                            : AppColors.status.error),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${progress.score} points out of $maxScore',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.text.secondary,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: AppSpacing.md),
          _buildMetricRow(
            label: 'Questions Answered',
            value: '${progress.answeredCount} / $totalQuestions',
          ),
          const Divider(height: 16),
          _buildMetricRow(
            label: 'Accuracy',
            value: '$percentage%',
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(
            'Close',
            style: TextStyle(color: AppColors.text.secondary),
          ),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.ink.primary,
            foregroundColor: Colors.white,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
          onPressed: () {
            Navigator.of(context).pop();
            onReset();
          },
          child: const Text('Reset Quiz'),
        ),
      ],
    );
  }

  Widget _buildMetricRow({required String label, required String value}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            color: AppColors.text.secondary,
            fontWeight: FontWeight.w500,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            color: AppColors.text.primary,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}
