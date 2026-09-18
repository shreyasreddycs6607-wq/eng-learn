import 'package:flutter/material.dart';
import '../core/theme/app_theme.dart';

/// One tappable answer card. Shown in its resting state until [answered],
/// then highlights green/red so correctness is never conveyed by color alone
/// (the feedback text in FeedbackCard carries the same message).
class AnswerOption extends StatelessWidget {
  final String label;
  final bool isSelected;
  final bool isCorrectAnswer;
  final bool answered;
  final VoidCallback onTap;

  const AnswerOption({
    super.key,
    required this.label,
    required this.isSelected,
    required this.isCorrectAnswer,
    required this.answered,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    Color borderColor = AppColors.primary;
    if (answered && isSelected) {
      borderColor = isCorrectAnswer ? AppColors.correct : AppColors.incorrect;
    } else if (answered && isCorrectAnswer) {
      borderColor = AppColors.correct;
    }
    // Picked but not yet checked — a filled tint, distinct from the
    // post-check colors above so "selected" is never confused with "correct".
    final fill = !answered && isSelected ? AppColors.primary.withValues(alpha: 0.1) : null;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: OutlinedButton(
        onPressed: answered ? null : onTap,
        style: OutlinedButton.styleFrom(
          backgroundColor: fill,
          side: BorderSide(color: borderColor, width: 2),
        ),
        child: Text(label, style: TextStyle(color: answered ? borderColor : AppColors.textPrimary)),
      ),
    );
  }
}
