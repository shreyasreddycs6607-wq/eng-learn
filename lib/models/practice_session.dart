import '../models/exercise.dart';
import '../models/exercise_result.dart';
import '../models/lesson.dart';
import 'practice_state.dart';

/// An immutable snapshot of one practice run through a lesson's exercises.
/// PracticeController holds the current snapshot and replaces it wholesale
/// on every transition — never a `Map<String, dynamic>` bag of fields.
class PracticeSession {
  /// Null for a revision session, which can span exercises from many
  /// lessons — only the lesson-practice flow (LessonScreen -> PracticeScreen)
  /// sets this, and only to navigate to the end-of-lesson Speaking screen.
  final Lesson? lesson;
  final List<Exercise> exercises;
  final int currentIndex;
  final int correctCount;
  final int incorrectCount;
  final PracticeStatus status;
  final ExerciseResult? currentResult;

  const PracticeSession({
    this.lesson,
    required this.exercises,
    this.currentIndex = 0,
    this.correctCount = 0,
    this.incorrectCount = 0,
    this.status = PracticeStatus.notStarted,
    this.currentResult,
  });

  int get total => exercises.length;
  int get completedCount => correctCount + incorrectCount;
  bool get isLastExercise => currentIndex >= exercises.length - 1;
  Exercise get currentExercise => exercises[currentIndex];

  PracticeSession copyWith({
    int? currentIndex,
    int? correctCount,
    int? incorrectCount,
    PracticeStatus? status,
    ExerciseResult? currentResult,
    bool clearResult = false,
  }) {
    return PracticeSession(
      lesson: lesson,
      exercises: exercises,
      currentIndex: currentIndex ?? this.currentIndex,
      correctCount: correctCount ?? this.correctCount,
      incorrectCount: incorrectCount ?? this.incorrectCount,
      status: status ?? this.status,
      currentResult: clearResult ? null : (currentResult ?? this.currentResult),
    );
  }
}
