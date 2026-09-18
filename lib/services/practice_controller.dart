import 'dart:async';
import 'package:flutter/foundation.dart';
import '../data/repositories/exercise_progress_repository.dart';
import '../models/exercise.dart';
import '../models/exercise_answer.dart';
import '../models/exercise_result.dart';
import '../models/feedback_type.dart';
import '../models/lesson.dart';
import '../models/practice_attempt.dart';
import '../models/practice_session.dart';
import '../models/practice_state.dart';
import 'answer_checker.dart';
import 'exercise_answer_formatter.dart';

/// The practice engine. Owns the session state machine; screens only ever
/// read [session] and call these four methods. Every invalid call
/// (double submit, continuing before feedback, answering after completion)
/// is a deliberate no-op rather than a thrown error — the UI can call
/// eagerly without guarding every tap itself.
class PracticeController extends ChangeNotifier {
  final ExerciseProgressRepository? _progressRepository;
  PracticeSession _session;

  /// [lesson] is only needed by the lesson-practice flow (to navigate to the
  /// end-of-lesson Speaking screen) — a revision session omits it.
  /// [progressRepository], when provided, records exactly one Phase 8
  /// attempt per submission (never on a double tap — see the awaitingAnswer
  /// guard in [submitAnswer]).
  PracticeController({
    Lesson? lesson,
    required List<Exercise> exercises,
    ExerciseProgressRepository? progressRepository,
  })  : _progressRepository = progressRepository,
        _session = PracticeSession(lesson: lesson, exercises: exercises);

  PracticeSession get session => _session;

  void startSession() {
    _session = _session.copyWith(
      status: _session.exercises.isEmpty ? PracticeStatus.completed : PracticeStatus.awaitingAnswer,
      currentIndex: 0,
      correctCount: 0,
      incorrectCount: 0,
      clearResult: true,
    );
    notifyListeners();
  }

  /// Checks [answer] against the current exercise and moves to
  /// showingFeedback. No-ops if a submission has already been made for
  /// this exercise — the caller does not need to track that itself.
  ExerciseResult? submitAnswer(ExerciseAnswer answer) {
    if (_session.status != PracticeStatus.awaitingAnswer) return _session.currentResult;

    final exercise = _session.currentExercise;
    final isCorrect = checkAnswer(expected: exercise.answer, submitted: answer);
    final result = ExerciseResult(
      exerciseId: exercise.id,
      isCorrect: isCorrect,
      feedbackType: isCorrect ? FeedbackType.correct : _classifyIncorrect(exercise, answer),
      submittedAnswer: answer,
      correctAnswerText: ExerciseAnswerFormatter.formatExpectedAnswer(exercise),
      explanation: exercise.explanation,
    );

    _session = _session.copyWith(
      status: PracticeStatus.showingFeedback,
      currentResult: result,
      correctCount: _session.correctCount + (isCorrect ? 1 : 0),
      incorrectCount: _session.incorrectCount + (isCorrect ? 0 : 1),
    );
    notifyListeners();

    // Speaking exercises are recorded per evaluated attempt by
    // SpeakingController (Good/Almost/Try Again each count once; Listen Again
    // and the "I repeated it" fallback never do) — recording the final
    // submission here too would double-count.
    if (exercise.type != ExerciseType.speaking) {
      unawaited(_recordAttempt(exercise, isCorrect));
    }

    return result;
  }

  /// Fire-and-forget (Phase 8 §79/§97): a database hiccup must never block
  /// or crash the exercise result the learner is already seeing.
  Future<void> _recordAttempt(Exercise exercise, bool isCorrect) async {
    try {
      await _progressRepository?.recordAttempt(PracticeAttempt(
        exerciseId: exercise.id,
        lessonId: exercise.lessonId,
        isCorrect: isCorrect,
        attemptedAt: DateTime.now(),
      ));
    } catch (e) {
      if (kDebugMode) debugPrint('[PRACTICE] Progress write failed (non-fatal): $e');
    }
  }

  /// Deterministic "almost": right words, wrong order. This is the only
  /// case with an objective rule — everything else is plainly wrong rather
  /// than a guessed "close enough". No semantic/AI comparison, ever.
  FeedbackType _classifyIncorrect(Exercise exercise, ExerciseAnswer submitted) {
    final expected = exercise.answer;
    if (expected is OrderedOptionIdsAnswer && submitted is OrderedOptionIdsAnswer) {
      if (_sameElementsDifferentOrder(expected.value, submitted.value)) return FeedbackType.almost;
    }
    return FeedbackType.wrong;
  }

  bool _sameElementsDifferentOrder(List<String> expected, List<String> submitted) {
    if (expected.length != submitted.length) return false;
    if (listEquals(expected, submitted)) return false; // that's correct, not almost
    final sortedExpected = [...expected]..sort();
    final sortedSubmitted = [...submitted]..sort();
    return listEquals(sortedExpected, sortedSubmitted);
  }

  void continueToNext() {
    if (_session.status != PracticeStatus.showingFeedback) return;
    _session = _session.isLastExercise
        ? _session.copyWith(status: PracticeStatus.completed, clearResult: true)
        : _session.copyWith(
            status: PracticeStatus.awaitingAnswer,
            currentIndex: _session.currentIndex + 1,
            clearResult: true,
          );
    notifyListeners();
  }

  void restartSession() => startSession();
}
