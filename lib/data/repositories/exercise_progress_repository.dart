import 'package:drift/drift.dart';
import '../../models/exercise_progress.dart';
import '../../models/mastery_level.dart';
import '../../models/practice_attempt.dart';
import '../local/database/app_database.dart';
import '../../services/revision_scheduler.dart';

/// The only place that touches ExerciseProgressEntries. Every completed
/// exercise submission (standard or speaking) flows through
/// [recordAttempt] exactly once — see PracticeController/SpeakingController
/// for the single call site each. One row per exerciseId (PK), so recording
/// the same exercise twice updates the existing row rather than duplicating
/// it (§11).
class ExerciseProgressRepository {
  final AppDatabase _db;
  final RevisionScheduler _scheduler;

  /// Called after each recorded attempt so the daily streak counts any
  /// meaningful activity (exercise, revision, conversation) through the one
  /// existing ProgressService.recordActivityToday — never a second streak.
  final Future<void> Function()? _onAttempt;

  ExerciseProgressRepository(this._db, [RevisionScheduler? scheduler, this._onAttempt])
      : _scheduler = scheduler ?? RevisionScheduler();

  /// Read-modify-write inside a transaction, so two attempts on the same
  /// exercise in quick succession (a fast retry) queue up instead of both
  /// reading the old row and the second overwriting the first.
  Future<void> recordAttempt(PracticeAttempt attempt) async {
    await _db.transaction(() async {
      final existing = await _row(attempt.exerciseId);
      final schedule = _scheduler.calculateNext(
        currentReviewLevel: existing?.reviewLevel ?? 0,
        successful: attempt.isCorrect,
        now: attempt.attemptedAt,
      );

      await _db.into(_db.exerciseProgressEntries).insertOnConflictUpdate(
            ExerciseProgressEntriesCompanion(
              exerciseId: Value(attempt.exerciseId),
              lessonId: Value(attempt.lessonId),
              attemptCount: Value((existing?.attemptCount ?? 0) + 1),
              correctCount: Value((existing?.correctCount ?? 0) + (attempt.isCorrect ? 1 : 0)),
              incorrectCount: Value((existing?.incorrectCount ?? 0) + (attempt.isCorrect ? 0 : 1)),
              reviewLevel: Value(schedule.reviewLevel),
              lastAttemptedAt: Value(attempt.attemptedAt),
              lastCorrectAt: Value(attempt.isCorrect ? attempt.attemptedAt : existing?.lastCorrectAt),
              nextReviewAt: Value(schedule.nextReviewAt),
              createdAt: Value(existing?.createdAt ?? attempt.attemptedAt),
            ),
          );
    });
    await _onAttempt?.call();
  }

  Future<ExerciseProgress?> getByExerciseId(String exerciseId) async {
    final row = await _row(exerciseId);
    return row == null ? null : _toDomain(row);
  }

  Future<List<ExerciseProgress>> getAll() async {
    final rows = await _db.select(_db.exerciseProgressEntries).get();
    return rows.map(_toDomain).toList();
  }

  /// nextReviewAt <= now, using real DateTime comparison — never formatted
  /// strings (§31). Overdue items (nextReviewAt far in the past) are
  /// included, never discarded (§32).
  Future<List<ExerciseProgress>> getDueItems(DateTime now) async {
    final rows = await (_db.select(_db.exerciseProgressEntries)
          ..where((t) => t.nextReviewAt.isSmallerOrEqualValue(now)))
        .get();
    return rows.map(_toDomain).toList();
  }

  /// Items with at least one recorded failure — used for deterministic
  /// revision-queue prioritization, not a "most difficult" AI ranking (§24).
  Future<List<ExerciseProgress>> getDifficultItems() async {
    final rows = await (_db.select(_db.exerciseProgressEntries)..where((t) => t.incorrectCount.isBiggerThanValue(0)))
        .get();
    return rows.map(_toDomain).toList();
  }

  Future<Map<MasteryLevel, int>> masterySummary() async {
    final all = await getAll();
    final summary = {for (final level in MasteryLevel.values) level: 0};
    for (final item in all) {
      summary[item.mastery] = (summary[item.mastery] ?? 0) + 1;
    }
    return summary;
  }

  /// Safety net (§75/§78): if curriculum content is ever removed, drop
  /// progress rows that now point at nothing rather than leaving them
  /// dangling or crashing a lookup.
  Future<void> pruneDangling(Set<String> validExerciseIds) async {
    final rows = await getAll();
    for (final row in rows) {
      if (!validExerciseIds.contains(row.exerciseId)) {
        await (_db.delete(_db.exerciseProgressEntries)..where((t) => t.exerciseId.equals(row.exerciseId))).go();
      }
    }
  }

  Future<ExerciseProgressEntry?> _row(String exerciseId) =>
      (_db.select(_db.exerciseProgressEntries)..where((t) => t.exerciseId.equals(exerciseId))).getSingleOrNull();

  ExerciseProgress _toDomain(ExerciseProgressEntry row) => ExerciseProgress(
        exerciseId: row.exerciseId,
        lessonId: row.lessonId,
        attemptCount: row.attemptCount,
        correctCount: row.correctCount,
        incorrectCount: row.incorrectCount,
        reviewLevel: row.reviewLevel,
        lastAttemptedAt: row.lastAttemptedAt,
        lastCorrectAt: row.lastCorrectAt,
        nextReviewAt: row.nextReviewAt,
        createdAt: row.createdAt,
      );
}
