import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:english_kaliyona/data/local/content/content_service.dart';
import 'package:english_kaliyona/data/local/database/app_database.dart';
import 'package:english_kaliyona/data/repositories/exercise_progress_repository.dart';
import 'package:english_kaliyona/data/repositories/lesson_repository.dart';
import 'package:english_kaliyona/data/repositories/progress_repository.dart';
import 'package:english_kaliyona/models/exercise_answer.dart';
import 'package:english_kaliyona/models/mastery_level.dart';
import 'package:english_kaliyona/models/practice_attempt.dart';
import 'package:english_kaliyona/models/progress.dart';
import 'package:english_kaliyona/services/answer_checker.dart';
import 'package:english_kaliyona/services/progress_service.dart';

/// Production-audit coverage for the things that could silently corrupt a
/// learner's progress: streak, mastery transitions, persistence across a real
/// close/reopen, and answer checking edge cases.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('streak', () {
    late AppDatabase db;
    late ProgressRepository repo;
    late ProgressService service;

    setUp(() {
      db = AppDatabase.forTesting(NativeDatabase.memory());
      repo = ProgressRepository(db);
      service = ProgressService(LessonRepository(ContentService()), repo);
    });
    tearDown(() => db.close());

    DateTime daysAgo(int n) {
      final now = DateTime.now();
      return DateTime(now.year, now.month, now.day - n); // calendar days, DST-proof
    }

    Future<void> lastLearned(int daysBack, {int streak = 3}) =>
        repo.saveProfile(UserProfile(streak: streak, lastLearningDate: daysAgo(daysBack)));

    test('the first meaningful activity starts the streak at 1', () async {
      expect(await service.recordActivityToday(), 1);
    });

    test('more activity on the same day never increments it again', () async {
      await lastLearned(0);
      expect(await service.recordActivityToday(), 3);
      expect(await service.recordActivityToday(), 3);
    });

    test('learning on the next calendar day increments it', () async {
      await lastLearned(1);
      expect(await service.recordActivityToday(), 4);
    });

    test('a missed day restarts it at 1 (the documented policy)', () async {
      await lastLearned(2);
      expect(await service.recordActivityToday(), 1);
    });

    test('a restart does not double-count: a fresh service on the same data agrees', () async {
      await lastLearned(1);
      await service.recordActivityToday();
      final restarted = ProgressService(LessonRepository(ContentService()), repo);
      expect(await restarted.recordActivityToday(), 4);
    });
  });

  group('mastery transitions (attempts -> Learning / Practicing / Comfortable)', () {
    late AppDatabase db;
    late ExerciseProgressRepository repo;

    setUp(() {
      db = AppDatabase.forTesting(NativeDatabase.memory());
      repo = ExerciseProgressRepository(db);
    });
    tearDown(() => db.close());

    Future<MasteryLevel> run(String pattern) async {
      var t = DateTime(2026, 9, 1, 10);
      for (final ch in pattern.split('')) {
        await repo.recordAttempt(PracticeAttempt(exerciseId: 'E1', lessonId: 'L1', isCorrect: ch == 'C', attemptedAt: t));
        t = t.add(const Duration(minutes: 1));
      }
      return (await repo.getByExerciseId('E1'))!.mastery;
    }

    test('no attempts is Learning', () async {
      expect(await repo.getByExerciseId('E1'), isNull);
    });

    const cases = {
      'C': MasteryLevel.practicing,
      'CC': MasteryLevel.practicing,
      'CCC': MasteryLevel.comfortable,
      'CCCC': MasteryLevel.comfortable,
      'CCCCCC': MasteryLevel.comfortable,
      'W': MasteryLevel.practicing,
      'WC': MasteryLevel.practicing,
      'CCW': MasteryLevel.practicing,
      'CCCW': MasteryLevel.practicing, // Comfortable -> incorrect
      'CCCWCC': MasteryLevel.practicing, // needs 3 in a row again
      'CCCWCCC': MasteryLevel.comfortable, // Practicing -> 3 correct
    };
    cases.forEach((pattern, expected) {
      test('$pattern -> ${expected.name}', () async => expect(await run(pattern), expected));
    });
  });

  group('persistence across a real close and reopen', () {
    test('attempts, revision schedule, lesson progress and streak survive', () async {
      final dir = await Directory.systemTemp.createTemp('kaliyona_db_');
      final file = File('${dir.path}/progress.sqlite');
      addTearDown(() => dir.delete(recursive: true));

      var db = AppDatabase.forTesting(NativeDatabase(file));
      final attempt = DateTime(2026, 9, 1, 10);
      final exercises = ExerciseProgressRepository(db);
      await exercises.recordAttempt(PracticeAttempt(exerciseId: 'E1', lessonId: 'L1', isCorrect: true, attemptedAt: attempt));
      await exercises.recordAttempt(PracticeAttempt(exerciseId: 'E1', lessonId: 'L1', isCorrect: true, attemptedAt: attempt));
      await exercises.recordAttempt(PracticeAttempt(exerciseId: 'E2', lessonId: 'L1', isCorrect: false, attemptedAt: attempt));
      final progress = ProgressRepository(db);
      await progress.saveLessonProgress(const LessonProgress(lessonId: 'L1', completed: true, attempts: 1, correctAnswers: 3));
      await progress.saveProfile(UserProfile(streak: 5, lastLearningDate: DateTime(2026, 9, 1)));
      await db.close(); // "force close"

      db = AppDatabase.forTesting(NativeDatabase(file)); // "reopen"
      addTearDown(db.close);
      final e1 = (await ExerciseProgressRepository(db).getByExerciseId('E1'))!;
      final e2 = (await ExerciseProgressRepository(db).getByExerciseId('E2'))!;
      expect((e1.attemptCount, e1.correctCount, e1.reviewLevel), (2, 2, 2));
      expect(e1.nextReviewAt, attempt.add(const Duration(days: 2)));
      expect((e2.incorrectCount, e2.reviewLevel), (1, 0));
      expect(await ExerciseProgressRepository(db).getAll(), hasLength(2)); // no duplicate rows

      final lesson = (await ProgressRepository(db).loadLessonProgress('L1'))!;
      expect((lesson.completed, lesson.correctAnswers), (true, 3));
      expect((await ProgressRepository(db).loadProfile()).streak, 5);
    });
  });

  group('answer checking edge cases', () {
    test('an empty spoken/typed answer is never accepted against a real target', () {
      expect(checkAnswer(expected: const TextAnswer(value: 'I want water.'), submitted: const TextAnswer(value: '')), isFalse);
      expect(checkAnswer(expected: const TextAnswer(value: 'I want water.'), submitted: const TextAnswer(value: '   ')), isFalse);
    });

    test('text ignores case, spacing and trailing punctuation only', () {
      expect(checkAnswer(expected: const TextAnswer(value: 'I want water.'), submitted: const TextAnswer(value: '  i  WANT water')), isTrue);
      expect(checkAnswer(expected: const TextAnswer(value: 'I want water.'), submitted: const TextAnswer(value: 'I want some water.')), isFalse);
    });

    test('kinds never match each other', () {
      expect(checkAnswer(expected: const OptionIdAnswer(value: 'o1'), submitted: const TextAnswer(value: 'o1')), isFalse);
      expect(checkAnswer(expected: const OrderedOptionIdsAnswer(value: ['o1']), submitted: const OptionIdAnswer(value: 'o1')), isFalse);
    });

    test('word order is significant, and a repeated or missing id fails', () {
      const expected = OrderedOptionIdsAnswer(value: ['w1', 'w2', 'w3']);
      expect(checkAnswer(expected: expected, submitted: const OrderedOptionIdsAnswer(value: ['w1', 'w2', 'w3'])), isTrue);
      expect(checkAnswer(expected: expected, submitted: const OrderedOptionIdsAnswer(value: ['w2', 'w1', 'w3'])), isFalse);
      expect(checkAnswer(expected: expected, submitted: const OrderedOptionIdsAnswer(value: ['w1', 'w1', 'w3'])), isFalse);
      expect(checkAnswer(expected: expected, submitted: const OrderedOptionIdsAnswer(value: ['w1', 'w2'])), isFalse);
    });

    test('an option answer must be exactly the expected id', () {
      expect(checkAnswer(expected: const OptionIdAnswer(value: 'o1'), submitted: const OptionIdAnswer(value: 'o2')), isFalse);
      expect(checkAnswer(expected: const OptionIdAnswer(value: 'o1'), submitted: const OptionIdAnswer(value: '')), isFalse);
    });
  });
}
