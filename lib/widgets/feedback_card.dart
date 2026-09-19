import 'package:flutter/material.dart';
import '../core/theme/app_theme.dart';
import '../models/feedback_type.dart';
import 'icon_badge.dart';
import 'primary_button.dart';

/// Panel shown after an exercise is answered. Always encouraging — a wrong (or
/// almost) answer reveals the correct one instead of blocking. Correct/Almost/
/// Wrong is decided once by the engine and only rendered here — never
/// re-derived from a colour or a string. Tone is carried by colour, icon AND words.
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

  Color get _soft => switch (feedbackType) {
        FeedbackType.correct => AppColors.correctSoft,
        FeedbackType.almost => AppColors.almostSoft,
        FeedbackType.wrong => AppColors.incorrectSoft,
      };

  IconData get _icon => switch (feedbackType) {
        FeedbackType.correct => Icons.check_rounded,
        FeedbackType.almost => Icons.priority_high_rounded,
        FeedbackType.wrong => Icons.close_rounded,
      };

  String get _headline => switch (feedbackType) {
        FeedbackType.correct => 'Correct!',
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
          color: _soft,
          borderRadius: BorderRadius.circular(AppSpacing.radiusCard),
          border: Border.all(color: color.withValues(alpha: 0.35), width: 2),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                IconBadge(icon: _icon, size: 44, background: color, foreground: Colors.white),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(_headline, style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, height: 1.3, color: color)),
                ),
              ],
            ),
            if (feedbackType != FeedbackType.correct) ...[
              const SizedBox(height: 12),
              Text.rich(
                TextSpan(
                  text: 'Correct answer: ',
                  style: const TextStyle(fontSize: 17, height: 1.4, color: AppColors.textSecondary),
                  children: [
                    TextSpan(
                      text: correctAnswer,
                      style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                    ),
                  ],
                ),
              ),
            ],
            if (explanation != null) ...[
              const SizedBox(height: 8),
              Text(explanation!, style: const TextStyle(fontSize: 16, height: 1.45, color: AppColors.textSecondary)),
            ],
            const SizedBox(height: 16),
            PrimaryButton(label: buttonLabel, onPressed: onContinue, color: color),
          ],
        ),
      ),
    );
  }
}
