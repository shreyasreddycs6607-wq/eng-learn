import 'exercise_answer.dart';
import 'feedback_type.dart';

/// What happened when the learner submitted one exercise — enough for the
/// feedback UI and (later) a spaced-repetition system, without ever storing
/// an arbitrary map.
class ExerciseResult {
  final String exerciseId;
  final bool isCorrect;
  final FeedbackType feedbackType;
  final ExerciseAnswer submittedAnswer;
  final String correctAnswerText;
  final String? explanation;

  const ExerciseResult({
    required this.exerciseId,
    required this.isCorrect,
    required this.feedbackType,
    required this.submittedAnswer,
    required this.correctAnswerText,
    this.explanation,
  });
}
