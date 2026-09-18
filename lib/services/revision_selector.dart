import '../models/exercise_progress.dart';

/// Deterministic Today's Revision selection (no shuffle, no randomness):
/// overdue (due before today) first, then more lifetime failures, then the
/// earlier nextReviewAt, then exerciseId as a stable final tie-break. Capped
/// so a session stays roughly 5–10 minutes.
class RevisionSelector {
  /// ~40s per exercise → 8 items ≈ 5 min, up to ~10 with feedback reading.
  static const sessionSize = 8;

  static List<ExerciseProgress> select(List<ExerciseProgress> items, DateTime now, {int limit = sessionSize}) {
    final today = DateTime(now.year, now.month, now.day);
    final due = items.where((i) => i.isDueBy(now)).toList()
      ..sort((a, b) {
        final aOver = a.nextReviewAt!.isBefore(today);
        final bOver = b.nextReviewAt!.isBefore(today);
        if (aOver != bOver) return aOver ? -1 : 1;
        final byFailures = b.incorrectCount.compareTo(a.incorrectCount);
        if (byFailures != 0) return byFailures;
        final byDue = a.nextReviewAt!.compareTo(b.nextReviewAt!);
        return byDue != 0 ? byDue : a.exerciseId.compareTo(b.exerciseId);
      });
    return due.take(limit).toList();
  }
}
