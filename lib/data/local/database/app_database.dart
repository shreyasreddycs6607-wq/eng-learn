import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

part 'app_database.g.dart';

/// One row per lesson the learner has touched. Static curriculum content
/// (lessons/exercises/vocabulary) lives in bundled JSON, not here — this
/// table is only the dynamic, per-learner state that must survive restarts.
class LessonProgressEntries extends Table {
  TextColumn get lessonId => text()();
  BoolColumn get completed => boolean().withDefault(const Constant(false))();
  IntColumn get attempts => integer().withDefault(const Constant(0))();
  IntColumn get correctAnswers => integer().withDefault(const Constant(0))();
  IntColumn get incorrectAnswers => integer().withDefault(const Constant(0))();
  DateTimeColumn get lastPracticed => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {lessonId};
}

/// Single-row table (id is always 0) for local app state. Not a user
/// account — no login, no email, nothing leaves the device.
class UserProfileEntries extends Table {
  IntColumn get id => integer().withDefault(const Constant(0))();
  TextColumn get currentLessonId => text().nullable()();
  IntColumn get streak => integer().withDefault(const Constant(0))();
  DateTimeColumn get lastLearningDate => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

/// One row per exercise the learner has ever attempted — of any type
/// (multipleChoice, listening, speaking, ...). References the curriculum by
/// id only; the exercise's own question/answer/audio stay in the bundled
/// JSON, never duplicated here.
///
/// This generalizes Phase 7's speaking-only `SpeakingRevisionEntries` into
/// one coherent revision model per Phase 8 §9-11, rather than a second,
/// overlapping table — every exercise type feeds the same spaced-repetition
/// schedule (see RevisionScheduler), not just speaking.
///
/// `reviewLevel` (0-4) tracks consecutive successful reviews and drives
/// `nextReviewAt` via RevisionScheduler; a failure resets it. `attemptCount`/
/// `correctCount`/`incorrectCount` are lifetime history and are never reset
/// by a failure — see Phase 8 §82-83 (history vs. current revision state).
class ExerciseProgressEntries extends Table {
  TextColumn get exerciseId => text()();
  TextColumn get lessonId => text()();
  IntColumn get attemptCount => integer().withDefault(const Constant(0))();
  IntColumn get correctCount => integer().withDefault(const Constant(0))();
  IntColumn get incorrectCount => integer().withDefault(const Constant(0))();
  IntColumn get reviewLevel => integer().withDefault(const Constant(0))();
  DateTimeColumn get lastAttemptedAt => dateTime().nullable()();
  DateTimeColumn get lastCorrectAt => dateTime().nullable()();
  DateTimeColumn get nextReviewAt => dateTime().nullable()();
  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column> get primaryKey => {exerciseId};
}

@DriftDatabase(tables: [LessonProgressEntries, UserProfileEntries, ExerciseProgressEntries])
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? executor]) : super(executor ?? _openConnection());

  /// Tests pass an in-memory executor directly; the app uses the real file.
  AppDatabase.forTesting(super.executor);

  @override
  int get schemaVersion => 4;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) => m.createAll(),
        onUpgrade: (m, from, to) async {
          // v1 -> v2: added the (now superseded) speaking-only revision table.
          // v2 -> v3: consolidated it into the general ExerciseProgressEntries
          // above (Phase 8). The app has no real learner data pre-launch, so
          // this drops the old table rather than migrating rows between two
          // incompatible shapes — never do this once real progress exists.
          if (from < 2) {
            await m.createTable(exerciseProgressEntries);
          } else if (from < 3) {
            await m.database.customStatement('DROP TABLE IF EXISTS speaking_revision_entries');
            await m.createTable(exerciseProgressEntries);
          }
          // v3 -> v4: dropped LessonProgressEntries.mastery. Mastery now has
          // exactly one definition (masteryFor, per exercise); the old
          // per-lesson accuracy-based value was unused. alterTable rebuilds
          // the table from the current definition and copies matching columns.
          if (from < 4) {
            await m.alterTable(TableMigration(lessonProgressEntries));
          }
        },
      );

  static QueryExecutor _openConnection() {
    return LazyDatabase(() async {
      final dir = await getApplicationDocumentsDirectory();
      final file = File(p.join(dir.path, 'progress.sqlite'));
      return NativeDatabase.createInBackground(file);
    });
  }
}
