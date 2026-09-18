import '../data/repositories/lesson_repository.dart';
import '../data/repositories/progress_repository.dart';
import '../models/lesson.dart';
import '../models/progress.dart';

/// Business logic on top of ProgressRepository/LessonRepository: which
/// lesson is next and streak bookkeeping. Screens call this
/// instead of touching the database or curriculum repositories directly.
class ProgressService {
  final LessonRepository _lessons;
  final ProgressRepository _progress;

  ProgressService(this._lessons, this._progress);

  Future<Map<String, LessonProgress>> loadAllProgress() => _progress.loadAllLessonProgress();

  Future<UserProfile> loadProfile() => _progress.loadProfile();

  Future<Lesson> nextLesson() async {
    final lessons = await _lessons.loadAll();
    final progress = await _progress.loadAllLessonProgress();
    for (final lesson in lessons) {
      if (progress[lesson.id]?.completed != true) return lesson;
    }
    return lessons.last;
  }

  int totalWordsLearned(List<Lesson> lessons, Map<String, LessonProgress> progress) {
    return lessons
        .where((l) => progress[l.id]?.completed == true)
        .fold<int>(0, (sum, l) => sum + l.contents.length);
  }

  /// Records the result of finishing a lesson's exercises and bumps the streak.
  Future<void> completeLesson({
    required String lessonId,
    required int correctInPass,
    required int incorrectInPass,
  }) async {
    final existing = await _progress.loadLessonProgress(lessonId) ?? LessonProgress(lessonId: lessonId);
    final attempts = existing.attempts + 1;
    final correctAnswers = existing.correctAnswers + correctInPass;
    final incorrectAnswers = existing.incorrectAnswers + incorrectInPass;
    await _progress.saveLessonProgress(existing.copyWith(
      completed: true,
      attempts: attempts,
      correctAnswers: correctAnswers,
      incorrectAnswers: incorrectAnswers,
      lastPracticed: DateTime.now(),
    ));
    await recordActivityToday();
  }

  /// Bumps the streak once per calendar day; resets it if a day was missed.
  Future<int> recordActivityToday() async {
    final profile = await _progress.loadProfile();
    final today = _dateOnly(DateTime.now());
    final last = profile.lastLearningDate == null ? null : _dateOnly(profile.lastLearningDate!);

    int streak;
    if (last == today) {
      streak = profile.streak;
    } else if (last != null && today == DateTime(last.year, last.month, last.day + 1)) {
      streak = profile.streak + 1;
    } else {
      streak = 1;
    }

    await _progress.saveProfile(UserProfile(
      currentLessonId: profile.currentLessonId,
      streak: streak,
      lastLearningDate: today,
    ));
    return streak;
  }

  DateTime _dateOnly(DateTime dt) => DateTime(dt.year, dt.month, dt.day);
}
