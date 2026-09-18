/// Domain-level progress for one lesson. Kept separate from the Drift-generated
/// row type so the rest of the app never depends on generated database code.
class LessonProgress {
  final String lessonId;
  final bool completed;
  final int attempts;
  final int correctAnswers;
  final int incorrectAnswers;
  final DateTime? lastPracticed;

  const LessonProgress({
    required this.lessonId,
    this.completed = false,
    this.attempts = 0,
    this.correctAnswers = 0,
    this.incorrectAnswers = 0,
    this.lastPracticed,
  });

  LessonProgress copyWith({
    bool? completed,
    int? attempts,
    int? correctAnswers,
    int? incorrectAnswers,
    DateTime? lastPracticed,
  }) {
    return LessonProgress(
      lessonId: lessonId,
      completed: completed ?? this.completed,
      attempts: attempts ?? this.attempts,
      correctAnswers: correctAnswers ?? this.correctAnswers,
      incorrectAnswers: incorrectAnswers ?? this.incorrectAnswers,
      lastPracticed: lastPracticed ?? this.lastPracticed,
    );
  }
}

/// Local-only app state. Not a user account — no login, no email, nothing
/// leaves the device. `totalLessonsCompleted`/`totalWordsLearned` are derived
/// from [LessonProgress] rows rather than stored here, so they can never
/// drift out of sync with the per-lesson data.
class UserProfile {
  final String? currentLessonId;
  final int streak;
  final DateTime? lastLearningDate;

  const UserProfile({this.currentLessonId, this.streak = 0, this.lastLearningDate});
}
