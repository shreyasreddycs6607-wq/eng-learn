import 'package:flutter/material.dart';
import '../core/theme/app_theme.dart';
import '../models/feedback_type.dart';
import 'primary_button.dart';

/// Bottom banner shown after an exercise is answered. Always encouraging —
/// a wrong (or almost) answer reveals the correct one rather than blocking
/// retries. Correct/Almost/Wrong is decided once by PracticeController and
/// only rendered here — never re-derived from a color or a string.
class FeedbackCard extends StatelessWidget {
  final FeedbackType feedbackType;
  final String correctAnswer;
  final String? explanation;
  final VoidCallback onContinue;

  /// "Continue" everywhere except Real-Life Practice's retry prompt.
  final String buttonLabel;

  const FeedbackCard({
    super.key,
    required this.feedbackType,
    required this.correctAnswer,
    this.explanation,
    required this.onContinue,
    this.buttonLabel = 'Continue',
  });

  Color get _color => switch (feedbackType) {
        FeedbackType.correct => AppColors.correct,
        FeedbackType.almost => AppColors.almost,
        FeedbackType.wrong => AppColors.incorrect,
      };

  String get _headline => switch (feedbackType) {
        FeedbackType.correct => '✓ Correct!',
        FeedbackType.almost => 'Almost!',
        FeedbackType.wrong => 'Not quite.',
      };

  @override
  Widget build(BuildContext context) {
    final color = _color;
    return Semantics(
      liveRegion: true,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(
                  feedbackType == FeedbackType.correct ? Icons.check_circle_rounded : Icons.error_rounded,
                  color: color,
                ),
                const SizedBox(width: 8),
                Text(_headline, style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: color)),
              ],
            ),
            if (feedbackType != FeedbackType.correct) ...[
              const SizedBox(height: 6),
              Text('Correct answer: $correctAnswer', style: const TextStyle(fontSize: 17, color: AppColors.textPrimary)),
            ],
            if (explanation != null) ...[
              const SizedBox(height: 6),
              Text(explanation!, style: const TextStyle(fontSize: 15, color: AppColors.textSecondary)),
            ],
            const SizedBox(height: 16),
            PrimaryButton(label: buttonLabel, onPressed: onContinue),
          ],
        ),
      ),
    );
  }
}
