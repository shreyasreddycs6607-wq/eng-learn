import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:english_kaliyona/data/local/database/app_database.dart';
import 'package:english_kaliyona/data/repositories/exercise_progress_repository.dart';
import 'package:english_kaliyona/data/repositories/progress_repository.dart';
import 'package:english_kaliyona/models/progress.dart';

/// Opens a database that is really at schema v3 (lesson rows still carry the
/// old `mastery` column) and lets AppDatabase migrate it, so the v3 -> v4
/// step is exercised rather than assumed.
void main() {
  test('v3 -> v4 keeps lesson and exercise progress and drops the old mastery column', () async {
    final db = AppDatabase.forTesting(NativeDatabase.memory(setup: (raw) {
      raw.execute('''
        CREATE TABLE lesson_progress_entries (
          lesson_id TEXT NOT NULL, completed INTEGER NOT NULL DEFAULT 0, attempts INTEGER NOT NULL DEFAULT 0,
          correct_answers INTEGER NOT NULL DEFAULT 0, incorrect_answers INTEGER NOT NULL DEFAULT 0,
          mastery INTEGER NOT NULL DEFAULT 0, last_practiced INTEGER, PRIMARY KEY (lesson_id));''');
      raw.execute('''
        CREATE TABLE user_profile_entries (
          id INTEGER NOT NULL DEFAULT 0, current_lesson_id TEXT, streak INTEGER NOT NULL DEFAULT 0,
          last_learning_date INTEGER, PRIMARY KEY (id));''');
      raw.execute('''
        CREATE TABLE exercise_progress_entries (
          exercise_id TEXT NOT NULL, lesson_id TEXT NOT NULL, attempt_count INTEGER NOT NULL DEFAULT 0,
          correct_count INTEGER NOT NULL DEFAULT 0, incorrect_count INTEGER NOT NULL DEFAULT 0,
          review_level INTEGER NOT NULL DEFAULT 0, last_attempted_at INTEGER, last_correct_at INTEGER,
          next_review_at INTEGER, created_at INTEGER NOT NULL, PRIMARY KEY (exercise_id));''');
      raw.execute("INSERT INTO lesson_progress_entries (lesson_id, completed, attempts, correct_answers, mastery) VALUES ('L001', 1, 2, 5, 3);");
      raw.execute("INSERT INTO exercise_progress_entries (exercise_id, lesson_id, attempt_count, correct_count, review_level, created_at) VALUES ('E1', 'L001', 3, 3, 3, 1758000000);");
      raw.execute('PRAGMA user_version = 3;');
    }));

    final lesson = await ProgressRepository(db).loadLessonProgress('L001');
    expect(lesson!.completed, isTrue);
    expect(lesson.attempts, 2);
    expect(lesson.correctAnswers, 5);

    final exercise = await ExerciseProgressRepository(db).getByExerciseId('E1');
    expect((exercise!.attemptCount, exercise.reviewLevel), (3, 3));

    final columns = await db.customSelect("SELECT name FROM pragma_table_info('lesson_progress_entries')").get();
    expect(columns.map((r) => r.read<String>('name')), isNot(contains('mastery')));

    await db.close();
  });

  test('a fresh install creates every table at the current schema version', () async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    await ProgressRepository(db).saveProfile(const UserProfile(streak: 2));
    expect((await ProgressRepository(db).loadProfile()).streak, 2);
    expect(await ExerciseProgressRepository(db).getAll(), isEmpty);
    await db.close();
  });
}
