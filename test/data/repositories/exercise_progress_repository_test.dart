import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:english_kaliyona/data/local/database/app_database.dart';
import 'package:english_kaliyona/data/repositories/exercise_progress_repository.dart';
import 'package:english_kaliyona/models/mastery_level.dart';
import 'package:english_kaliyona/models/practice_attempt.dart';

void main() {
  late AppDatabase db;
  late ExerciseProgressRepository repo;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    repo = ExerciseProgressRepository(db);
  });

  tearDown(() => db.close());

  PracticeAttempt attempt(String id, {bool isCorrect = true, DateTime? at}) => PracticeAttempt(
        exerciseId: id,
        lessonId: 'L001',
        isCorrect: isCorrect,
        attemptedAt: at ?? DateTime(2026, 9, 18, 10),
      );

  test('a fresh exercise has no progress row', () async {
    expect(await repo.getByExerciseId('E1'), isNull);
  });

  test('one attempt creates a row with attemptCount 1', () async {
    await repo.recordAttempt(attempt('E1'));

    final progress = await repo.getByExerciseId('E1');
    expect(progress!.attemptCount, 1);
    expect(progress.correctCount, 1);
    expect(progress.incorrectCount, 0);
  });

  test('recording the same exercise twice updates one row, never duplicates it (§11/§110)', () async {
    await repo.recordAttempt(attempt('E1', isCorrect: true));
    await repo.recordAttempt(attempt('E1', isCorrect: false));

    final all = await repo.getAll();
    expect(all, hasLength(1));
    expect(all.first.attemptCount, 2);
    expect(all.first.correctCount, 1);
    expect(all.first.incorrectCount, 1);
  });

  test('lifetime history is never reset by a later failure (§82)', () async {
    await repo.recordAttempt(attempt('E1', isCorrect: true));
    await repo.recordAttempt(attempt('E1', isCorrect: true));
    await repo.recordAttempt(attempt('E1', isCorrect: true));
    await repo.recordAttempt(attempt('E1', isCorrect: false));

    final progress = (await repo.getByExerciseId('E1'))!;
    expect(progress.attemptCount, 4);
    expect(progress.correctCount, 3, reason: 'a failure must not erase prior correct history');
    expect(progress.incorrectCount, 1);
  });

  group('due items (§108)', () {
    test('an item with nextReviewAt in the past is due', () async {
      final now = DateTime(2026, 9, 18);
      await repo.recordAttempt(attempt('E1', isCorrect: false, at: now.subtract(const Duration(days: 5))));

      final due = await repo.getDueItems(now);
      expect(due.map((e) => e.exerciseId), contains('E1'));
    });

    test('an item scheduled in the future is not due', () async {
      final now = DateTime(2026, 9, 18);
      // A success schedules 1 day out from "now", i.e. in the future relative to "now" itself.
      await repo.recordAttempt(attempt('E1', isCorrect: true, at: now));

      final due = await repo.getDueItems(now);
      expect(due.map((e) => e.exerciseId), isNot(contains('E1')));
    });

    test('overdue items remain available, never discarded (§32)', () async {
      final longAgo = DateTime(2020, 1, 1);
      await repo.recordAttempt(attempt('E1', isCorrect: false, at: longAgo));

      final due = await repo.getDueItems(DateTime(2026, 9, 18));
      expect(due.map((e) => e.exerciseId), contains('E1'));
    });
  });

  group('mastery summary', () {
    test('a brand-new exercise (no attempts) is not counted at all — it has no row', () async {
      final summary = await repo.masterySummary();
      expect(summary[MasteryLevel.learning], 0);
    });

    test('a single attempt is Practicing, not yet Comfortable', () async {
      await repo.recordAttempt(attempt('E1', isCorrect: true));
      final summary = await repo.masterySummary();
      expect(summary[MasteryLevel.practicing], 1);
      expect(summary[MasteryLevel.comfortable], 0);
    });

    test('3 consecutive successes reach Comfortable', () async {
      var now = DateTime(2026, 9, 18);
      for (var i = 0; i < 3; i++) {
        await repo.recordAttempt(attempt('E1', isCorrect: true, at: now));
        now = now.add(const Duration(days: 10)); // always past the scheduled review
      }
      final summary = await repo.masterySummary();
      expect(summary[MasteryLevel.comfortable], 1);
    });

    test('a recent failure moves a Comfortable item back to Practicing (§20/§37)', () async {
      var now = DateTime(2026, 9, 18);
      for (var i = 0; i < 3; i++) {
        await repo.recordAttempt(attempt('E1', isCorrect: true, at: now));
        now = now.add(const Duration(days: 10));
      }
      expect((await repo.masterySummary())[MasteryLevel.comfortable], 1);

      await repo.recordAttempt(attempt('E1', isCorrect: false, at: now));

      final summary = await repo.masterySummary();
      expect(summary[MasteryLevel.comfortable], 0);
      expect(summary[MasteryLevel.practicing], 1);
    });
  });

  test('pruneDangling removes rows for exercises no longer in the curriculum', () async {
    await repo.recordAttempt(attempt('E_STILL_EXISTS'));
    await repo.recordAttempt(attempt('E_REMOVED'));

    await repo.pruneDangling({'E_STILL_EXISTS'});

    final all = await repo.getAll();
    expect(all.map((e) => e.exerciseId), ['E_STILL_EXISTS']);
  });

  test('two attempts recorded without awaiting are both kept (no lost update)', () async {
    await Future.wait([
      repo.recordAttempt(attempt('E1', isCorrect: false)),
      repo.recordAttempt(attempt('E1', isCorrect: true)),
    ]);

    final p = (await repo.getByExerciseId('E1'))!;
    expect((p.attemptCount, p.correctCount, p.incorrectCount), (2, 1, 1));
  });
}
