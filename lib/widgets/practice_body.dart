import 'package:flutter/material.dart';
import '../core/theme/app_theme.dart';
import '../models/exercise.dart';
import '../models/practice_state.dart';
import '../services/practice_controller.dart';
import 'audio_player_button.dart';
import 'exercise/exercise_view.dart';
import 'feedback_card.dart';
import 'lesson_header.dart';
import 'soft_card.dart';

/// The practice-session UI shell: progress header, prompt, the current
/// exercise's input widget, and feedback once answered. Shared by the
/// lesson-practice flow (PracticeScreen) and Today's Revision
/// (DailyRevisionScreen) — there is only ever one exercise renderer.
class PracticeBody extends StatelessWidget {
  final PracticeController controller;
  final VoidCallback onContinue;

  const PracticeBody({super.key, required this.controller, required this.onContinue});

  @override
  Widget build(BuildContext context) {
    final session = controller.session;
    final exercise = session.currentExercise;
    final result = session.currentResult;
    final showingFeedback = session.status == PracticeStatus.showingFeedback;
    // Listening exercises hide the text answer key until the attempt is checked.
    final revealText = exercise.type != ExerciseType.listening || showingFeedback;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.screen),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              LessonHeader(current: session.currentIndex + 1, total: session.total),
              const SizedBox(height: 20),
              Expanded(
                child: LayoutBuilder(
                  builder: (context, box) => Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Smaller share while feedback is showing, so the feedback card always fits.
                      ConstrainedBox(
                        constraints: BoxConstraints(maxHeight: box.maxHeight * (result == null ? 0.4 : 0.25)),
                        child: SingleChildScrollView(child: _prompt(context, exercise, revealText)),
                      ),
                      const SizedBox(height: 16),
                      Expanded(
                        child: buildExerciseView(
                          exercise: exercise,
                          submittedAnswer: result?.submittedAnswer,
                          onSubmit: controller.submitAnswer,
                        ),
                      ),
                      if (result != null)
                        FeedbackCard(
                          feedbackType: result.feedbackType,
                          correctAnswer: result.correctAnswerText,
                          explanation: result.explanation,
                          onContinue: onContinue,
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// The instruction as a quiet label, then the word/sentence itself on a card
  /// (with its audio), so the eye lands on the thing being learned.
  Widget _prompt(BuildContext context, Exercise exercise, bool revealText) {
    final text = Theme.of(context).textTheme;
    final subject = <Widget>[
      if (revealText && exercise.kannadaText != null) Text(exercise.kannadaText!, style: text.displaySmall),
      if (revealText && exercise.englishText != null) Text(exercise.englishText!, style: text.headlineMedium),
    ];
    final hasAudio = exercise.audioPath != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(exercise.question, style: text.titleMedium?.copyWith(color: AppColors.textSecondary)),
        if (subject.isNotEmpty || hasAudio) ...[
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: SoftCard(
              child: subject.isEmpty
                  ? Center(child: AudioPlayerButton(audioPath: exercise.audioPath, label: 'audio', size: 84))
                  : Row(
                      children: [
                        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: subject)),
                        if (hasAudio) ...[
                          const SizedBox(width: 12),
                          AudioPlayerButton(audioPath: exercise.audioPath, label: 'audio', size: 60),
                        ],
                      ],
                    ),
            ),
          ),
        ],
      ],
    );
  }
}
