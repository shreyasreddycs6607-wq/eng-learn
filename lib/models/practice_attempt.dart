/// One completed exercise submission, from either the standard practice
/// engine (Phase 6, via AnswerChecker) or speaking practice (Phase 7, via
/// SpeakingEvaluator). The single input to ExerciseProgressRepository —
/// callers never write attempt counters directly.
class PracticeAttempt {
  final String exerciseId;
  final String lessonId;
  final bool isCorrect;
  final DateTime attemptedAt;

  const PracticeAttempt({
    required this.exerciseId,
    required this.lessonId,
    required this.isCorrect,
    required this.attemptedAt,
  });
}
