import 'package:flutter/material.dart';
import '../core/theme/app_theme.dart';

/// One tappable answer tile. Resting until [answered], then it turns green/red so
/// correctness is never conveyed by colour alone: the round marker on the left
/// changes shape (tick / cross) and the feedback panel says it in words too.
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
    final showCorrect = answered && isCorrectAnswer;
    final showWrong = answered && isSelected && !isCorrectAnswer;
    final picked = !answered && isSelected;

    final Color border;
    final Color fill;
    final Color textColor;
    if (showCorrect) {
      border = AppColors.correct;
      fill = AppColors.correctSoft;
      textColor = AppColors.correct;
    } else if (showWrong) {
      border = AppColors.incorrect;
      fill = AppColors.incorrectSoft;
      textColor = AppColors.incorrect;
    } else if (picked) {
      border = AppColors.primary;
      fill = AppColors.primarySoft;
      textColor = AppColors.textPrimary;
    } else {
      border = AppColors.border;
      fill = AppColors.surface;
      textColor = answered ? AppColors.textSecondary : AppColors.textPrimary;
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: OutlinedButton(
        onPressed: answered ? null : onTap,
        style: OutlinedButton.styleFrom(
          minimumSize: const Size.fromHeight(68),
          alignment: Alignment.centerLeft,
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          backgroundColor: fill,
          disabledBackgroundColor: fill,
          foregroundColor: textColor,
          disabledForegroundColor: textColor,
          side: BorderSide(color: border, width: picked || showCorrect || showWrong ? 2.5 : 2),
        ),
        child: Row(
          children: [
            _marker(showCorrect: showCorrect, showWrong: showWrong, picked: picked, border: border),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                label,
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, height: 1.35, color: textColor),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _marker({required bool showCorrect, required bool showWrong, required bool picked, required Color border}) {
    final IconData? icon = showCorrect
        ? Icons.check_rounded
        : showWrong
            ? Icons.close_rounded
            : picked
                ? Icons.check_rounded
                : null;
    final filled = showCorrect || showWrong || picked;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      width: 30,
      height: 30,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: filled ? border : Colors.transparent,
        border: Border.all(color: border, width: 2),
      ),
      child: icon == null ? null : Icon(icon, size: 19, color: Colors.white),
    );
  }
}
