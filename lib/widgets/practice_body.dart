import 'package:flutter/material.dart';
import '../models/exercise.dart';
import '../models/practice_state.dart';
import '../services/practice_controller.dart';
import 'audio_player_button.dart';
import 'exercise/exercise_view.dart';
import 'feedback_card.dart';
import 'lesson_header.dart';

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
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              LessonHeader(current: session.currentIndex + 1, total: session.total),
              const SizedBox(height: 16),
              Expanded(
                child: LayoutBuilder(
                  builder: (context, box) => Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Smaller share while feedback is showing, so the feedback card always fits.
                      ConstrainedBox(
                        constraints: BoxConstraints(maxHeight: box.maxHeight * (result == null ? 0.4 : 0.25)),
                        child: SingleChildScrollView(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (revealText && exercise.kannadaText != null)
                                Text(exercise.kannadaText!, style: Theme.of(context).textTheme.displayMedium),
                              if (revealText && exercise.englishText != null)
                                Text(exercise.englishText!, style: Theme.of(context).textTheme.displayMedium),
                              const SizedBox(height: 12),
                              Text(exercise.question, style: Theme.of(context).textTheme.headlineMedium),
                              if (exercise.audioPath != null) ...[
                                const SizedBox(height: 16),
                                AudioPlayerButton(audioPath: exercise.audioPath, label: 'audio', size: 56),
                              ],
                            ],
                          ),
                        ),
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
}
