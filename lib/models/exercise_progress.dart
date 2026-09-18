import 'mastery_level.dart';

/// Domain-level per-exercise progress — kept separate from the Drift-
/// generated row type so the rest of the app never depends on generated
/// database code. Lifetime history (`attemptCount`/`correctCount`/
/// `incorrectCount`) is distinct from current revision state
/// (`reviewLevel`/`nextReviewAt`) — a failure never resets history.
class ExerciseProgress {
  final String exerciseId;
  final String lessonId;
  final int attemptCount;
  final int correctCount;
  final int incorrectCount;
  final int reviewLevel;
  final DateTime? lastAttemptedAt;
  final DateTime? lastCorrectAt;
  final DateTime? nextReviewAt;
  final DateTime createdAt;

  const ExerciseProgress({
    required this.exerciseId,
    required this.lessonId,
    this.attemptCount = 0,
    this.correctCount = 0,
    this.incorrectCount = 0,
    this.reviewLevel = 0,
    this.lastAttemptedAt,
    this.lastCorrectAt,
    this.nextReviewAt,
    required this.createdAt,
  });

  MasteryLevel get mastery => masteryFor(attemptCount: attemptCount, reviewLevel: reviewLevel);

  bool isDueBy(DateTime now) => nextReviewAt != null && !nextReviewAt!.isAfter(now);
}
