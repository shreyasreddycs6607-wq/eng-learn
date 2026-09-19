import 'package:drift/drift.dart';
import '../../models/progress.dart';
import '../../models/reminder_setting.dart';
import '../local/database/app_database.dart';

/// The only place in the app that talks to the progress database. Screens
/// and services work with plain [LessonProgress]/[UserProfile] objects.
class ProgressRepository {
  final AppDatabase _db;

  ProgressRepository(this._db);

  Future<Map<String, LessonProgress>> loadAllLessonProgress() async {
    final rows = await _db.select(_db.lessonProgressEntries).get();
    return {for (final row in rows) row.lessonId: _toDomain(row)};
  }

  Future<LessonProgress?> loadLessonProgress(String lessonId) async {
    final row = await (_db.select(_db.lessonProgressEntries)..where((t) => t.lessonId.equals(lessonId)))
        .getSingleOrNull();
    return row == null ? null : _toDomain(row);
  }

  Future<void> saveLessonProgress(LessonProgress progress) async {
    await _db.into(_db.lessonProgressEntries).insertOnConflictUpdate(
          LessonProgressEntriesCompanion(
            lessonId: Value(progress.lessonId),
            completed: Value(progress.completed),
            attempts: Value(progress.attempts),
            correctAnswers: Value(progress.correctAnswers),
            incorrectAnswers: Value(progress.incorrectAnswers),
            lastPracticed: Value(progress.lastPracticed),
          ),
        );
  }

  Future<UserProfile> loadProfile() async {
    final row =
        await (_db.select(_db.userProfileEntries)..where((t) => t.id.equals(0))).getSingleOrNull();
    if (row == null) return const UserProfile();
    return UserProfile(
      currentLessonId: row.currentLessonId,
      streak: row.streak,
      lastLearningDate: row.lastLearningDate,
    );
  }

  Future<void> saveProfile(UserProfile profile) async {
    await _db.into(_db.userProfileEntries).insertOnConflictUpdate(
          UserProfileEntriesCompanion(
            id: const Value(0),
            currentLessonId: Value(profile.currentLessonId),
            streak: Value(profile.streak),
            lastLearningDate: Value(profile.lastLearningDate),
          ),
        );
  }

  Future<ReminderSetting> loadReminder() async {
    final row = await (_db.select(_db.reminderSettingEntries)..where((t) => t.id.equals(0))).getSingleOrNull();
    return row == null ? const ReminderSetting() : ReminderSetting(enabled: row.enabled, minutesOfDay: row.minutesOfDay);
  }

  Future<void> saveReminder(ReminderSetting setting) async {
    await _db.into(_db.reminderSettingEntries).insertOnConflictUpdate(
          ReminderSettingEntriesCompanion(
            id: const Value(0),
            enabled: Value(setting.enabled),
            minutesOfDay: Value(setting.minutesOfDay),
          ),
        );
  }

  /// Developer-only: wipes all progress. Never exposed in the normal learner UI.
  Future<void> resetAll() async {
    await _db.delete(_db.lessonProgressEntries).go();
    await _db.delete(_db.userProfileEntries).go();
    await _db.delete(_db.exerciseProgressEntries).go();
  }

  LessonProgress _toDomain(LessonProgressEntry row) => LessonProgress(
        lessonId: row.lessonId,
        completed: row.completed,
        attempts: row.attempts,
        correctAnswers: row.correctAnswers,
        incorrectAnswers: row.incorrectAnswers,
        lastPracticed: row.lastPracticed,
      );
}
