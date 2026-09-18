import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:english_kaliyona/data/local/database/app_database.dart';
import 'package:english_kaliyona/data/repositories/exercise_progress_repository.dart';
import 'package:english_kaliyona/models/exercise.dart';
import 'package:english_kaliyona/models/exercise_answer.dart';
import 'package:english_kaliyona/models/exercise_option.dart';
import 'package:english_kaliyona/models/feedback_type.dart';
import 'package:english_kaliyona/models/lesson.dart';
import 'package:english_kaliyona/models/practice_state.dart';
import 'package:english_kaliyona/services/practice_controller.dart';

Lesson _lesson() => const Lesson(
      id: 'L001',
      level: 1,
      order: 1,
      topic: 'greetings',
      title: 'Hello',
      kannadaTitle: 'ನಮಸ್ಕಾರ',
      description: 'd',
      estimatedMinutes: 5,
    );

Exercise _choiceExercise(String id, {String correctOptionId = 'o1'}) => Exercise(
      id: id,
      lessonId: 'L001',
      type: ExerciseType.multipleChoice,
      order: 1,
      question: 'q',
      options: const [
        ExerciseOption(id: 'o1', text: 'Water'),
        ExerciseOption(id: 'o2', text: 'Food'),
        ExerciseOption(id: 'o3', text: 'Tea'),
      ],
      answer: OptionIdAnswer(value: correctOptionId),
    );

Exercise _wordOrderingExercise(String id) => Exercise(
      id: id,
      lessonId: 'L001',
      type: ExerciseType.wordOrdering,
      order: 1,
      question: 'Arrange the words.',
      options: const [
        ExerciseOption(id: 'w1', text: 'I'),
        ExerciseOption(id: 'w2', text: 'want'),
        ExerciseOption(id: 'w3', text: 'water'),
      ],
      answer: const OrderedOptionIdsAnswer(value: ['w1', 'w2', 'w3']),
    );

void main() {
  group('session lifecycle', () {
    test('starts with the first exercise awaiting an answer', () {
      final controller = PracticeController(lesson: _lesson(), exercises: [_choiceExercise('E1')]);
      controller.startSession();

      expect(controller.session.status, PracticeStatus.awaitingAnswer);
      expect(controller.session.currentIndex, 0);
      expect(controller.session.currentExercise.id, 'E1');
    });

    test('a lesson with no exercises completes immediately', () {
      final controller = PracticeController(lesson: _lesson(), exercises: []);
      controller.startSession();

      expect(controller.session.status, PracticeStatus.completed);
    });

    test('exercises are presented in the order given (curriculum order, not reordered)', () {
      final exercises = [_choiceExercise('E1'), _choiceExercise('E2'), _choiceExercise('E3')];
      final controller = PracticeController(lesson: _lesson(), exercises: exercises);
      controller.startSession();

      expect(controller.session.currentExercise.id, 'E1');
      controller.submitAnswer(const OptionIdAnswer(value: 'o1'));
      controller.continueToNext();
      expect(controller.session.currentExercise.id, 'E2');
      controller.submitAnswer(const OptionIdAnswer(value: 'o1'));
      controller.continueToNext();
      expect(controller.session.currentExercise.id, 'E3');
    });
  });

  group('answer submission and feedback', () {
    test('a correct answer is marked correct and feedback is Correct', () {
      final controller = PracticeController(lesson: _lesson(), exercises: [_choiceExercise('E1')]);
      controller.startSession();

      final result = controller.submitAnswer(const OptionIdAnswer(value: 'o1'))!;

      expect(result.isCorrect, isTrue);
      expect(result.feedbackType, FeedbackType.correct);
      expect(controller.session.status, PracticeStatus.showingFeedback);
      expect(controller.session.correctCount, 1);
      expect(controller.session.incorrectCount, 0);
    });

    test('a wrong option-based answer is Wrong, never Almost', () {
      final controller = PracticeController(lesson: _lesson(), exercises: [_choiceExercise('E1')]);
      controller.startSession();

      final result = controller.submitAnswer(const OptionIdAnswer(value: 'o2'))!;

      expect(result.isCorrect, isFalse);
      expect(result.feedbackType, FeedbackType.wrong);
      expect(result.correctAnswerText, 'Water');
      expect(controller.session.incorrectCount, 1);
    });

    test('word ordering: exact match is correct', () {
      final controller = PracticeController(lesson: _lesson(), exercises: [_wordOrderingExercise('E1')]);
      controller.startSession();

      final result = controller.submitAnswer(const OrderedOptionIdsAnswer(value: ['w1', 'w2', 'w3']))!;

      expect(result.isCorrect, isTrue);
      expect(result.feedbackType, FeedbackType.correct);
    });

    test('word ordering: same words, wrong order, is deterministically Almost', () {
      final controller = PracticeController(lesson: _lesson(), exercises: [_wordOrderingExercise('E1')]);
      controller.startSession();

      final result = controller.submitAnswer(const OrderedOptionIdsAnswer(value: ['w1', 'w3', 'w2']))!;

      expect(result.isCorrect, isFalse);
      expect(result.feedbackType, FeedbackType.almost);
    });

    test('word ordering: substituting a distractor word is Wrong, not Almost', () {
      // A 4th distractor option (w4) exists but isn't part of the correct
      // sentence — using it instead of the right word is a genuinely
      // different set of words, not just a reordering.
      const exercise = Exercise(
        id: 'E1',
        lessonId: 'L001',
        type: ExerciseType.wordOrdering,
        order: 1,
        question: 'q',
        options: [
          ExerciseOption(id: 'w1', text: 'I'),
          ExerciseOption(id: 'w2', text: 'like'),
          ExerciseOption(id: 'w3', text: 'milk'),
          ExerciseOption(id: 'w4', text: 'water'),
        ],
        answer: OrderedOptionIdsAnswer(value: ['w1', 'w2', 'w3']),
      );
      final controller = PracticeController(lesson: _lesson(), exercises: [exercise]);
      controller.startSession();

      final result = controller.submitAnswer(const OrderedOptionIdsAnswer(value: ['w1', 'w2', 'w4']))!;

      expect(result.isCorrect, isFalse);
      expect(result.feedbackType, FeedbackType.wrong);
    });

    test('correctness is never altered by which feedback type is shown', () {
      final controller = PracticeController(lesson: _lesson(), exercises: [_wordOrderingExercise('E1')]);
      controller.startSession();
      final result = controller.submitAnswer(const OrderedOptionIdsAnswer(value: ['w3', 'w2', 'w1']))!;

      expect(result.feedbackType, FeedbackType.almost);
      expect(result.isCorrect, isFalse, reason: 'Almost must still count as incorrect for scoring');
    });
  });

  group('double submission prevention', () {
    test('submitting twice only records one attempt', () {
      final controller = PracticeController(lesson: _lesson(), exercises: [_choiceExercise('E1')]);
      controller.startSession();

      controller.submitAnswer(const OptionIdAnswer(value: 'o1'));
      controller.submitAnswer(const OptionIdAnswer(value: 'o2')); // second tap, different answer

      expect(controller.session.correctCount, 1);
      expect(controller.session.incorrectCount, 0);
      expect(controller.session.status, PracticeStatus.showingFeedback);
    });

    test('continuing twice does not advance twice', () {
      final exercises = [_choiceExercise('E1'), _choiceExercise('E2'), _choiceExercise('E3')];
      final controller = PracticeController(lesson: _lesson(), exercises: exercises);
      controller.startSession();
      controller.submitAnswer(const OptionIdAnswer(value: 'o1'));

      controller.continueToNext();
      controller.continueToNext(); // second tap before answering E2

      expect(controller.session.currentIndex, 1);
      expect(controller.session.currentExercise.id, 'E2');
    });

    test('cannot submit an answer while showing feedback', () {
      final controller = PracticeController(lesson: _lesson(), exercises: [_choiceExercise('E1')]);
      controller.startSession();
      controller.submitAnswer(const OptionIdAnswer(value: 'o1'));

      // Attempting to submit again while feedback is showing must not
      // silently overwrite the recorded result or double the score.
      controller.submitAnswer(const OptionIdAnswer(value: 'o3'));

      expect(controller.session.correctCount, 1);
      expect(controller.session.currentResult!.isCorrect, isTrue);
    });

    test('cannot submit after the session is completed', () {
      final controller = PracticeController(lesson: _lesson(), exercises: [_choiceExercise('E1')]);
      controller.startSession();
      controller.submitAnswer(const OptionIdAnswer(value: 'o1'));
      controller.continueToNext();

      expect(controller.session.status, PracticeStatus.completed);

      controller.submitAnswer(const OptionIdAnswer(value: 'o1'));
      expect(controller.session.status, PracticeStatus.completed);
      expect(controller.session.correctCount, 1, reason: 'must not double count after completion');
    });
  });

  group('session completion', () {
    test('finishing the last exercise completes the session, never a phantom next one', () {
      final exercises = [_choiceExercise('E1'), _choiceExercise('E2'), _choiceExercise('E3')];
      final controller = PracticeController(lesson: _lesson(), exercises: exercises);
      controller.startSession();

      for (var i = 0; i < 3; i++) {
        expect(controller.session.status, PracticeStatus.awaitingAnswer);
        controller.submitAnswer(const OptionIdAnswer(value: 'o1'));
        controller.continueToNext();
      }

      expect(controller.session.status, PracticeStatus.completed);
      expect(controller.session.correctCount, 3);
      // The index is deliberately clamped at the last valid exercise rather
      // than incremented past the end — completion never leaves the session
      // pointing at a nonexistent fourth exercise.
      expect(controller.session.currentIndex, 2);
    });
  });

  group('restart', () {
    test('restarting clears score, feedback, and returns to the first exercise', () {
      final exercises = [_choiceExercise('E1'), _choiceExercise('E2')];
      final controller = PracticeController(lesson: _lesson(), exercises: exercises);
      controller.startSession();
      controller.submitAnswer(const OptionIdAnswer(value: 'o2')); // wrong
      controller.continueToNext();

      controller.restartSession();

      expect(controller.session.status, PracticeStatus.awaitingAnswer);
      expect(controller.session.currentIndex, 0);
      expect(controller.session.correctCount, 0);
      expect(controller.session.incorrectCount, 0);
      expect(controller.session.currentResult, isNull);
    });
  });

  test('notifies listeners on every state transition', () {
    final controller = PracticeController(lesson: _lesson(), exercises: [_choiceExercise('E1')]);
    var notifications = 0;
    controller.addListener(() => notifications++);

    controller.startSession();
    controller.submitAnswer(const OptionIdAnswer(value: 'o1'));
    controller.continueToNext();

    expect(notifications, 3);
  });

  group('progress recording', () {
    late AppDatabase db;
    late ExerciseProgressRepository repo;

    setUp(() {
      db = AppDatabase.forTesting(NativeDatabase.memory());
      repo = ExerciseProgressRepository(db);
    });
    tearDown(() => db.close());

    test('one submission records exactly one attempt, even on a double tap', () async {
      final c = PracticeController(lesson: _lesson(), exercises: [_choiceExercise('E1')], progressRepository: repo)..startSession();
      c.submitAnswer(const OptionIdAnswer(value: 'o2'));
      c.submitAnswer(const OptionIdAnswer(value: 'o1'));
      await Future<void>.delayed(const Duration(milliseconds: 50));

      final p = (await repo.getByExerciseId('E1'))!;
      expect(p.attemptCount, 1);
      expect(p.incorrectCount, 1);
    });

    test('a revision session (no lesson) records attempts too', () async {
      final c = PracticeController(exercises: [_choiceExercise('E1')], progressRepository: repo)..startSession();
      c.submitAnswer(const OptionIdAnswer(value: 'o1'));
      await Future<void>.delayed(const Duration(milliseconds: 50));

      expect((await repo.getByExerciseId('E1'))!.correctCount, 1);
    });

    test('speaking exercises are recorded by SpeakingController, not double-counted here', () async {
      const speaking = Exercise(
        id: 'S1',
        lessonId: 'L001',
        type: ExerciseType.speaking,
        order: 1,
        question: 'Say it',
        options: [],
        answer: TextAnswer(value: 'I want water.'),
      );
      final c = PracticeController(exercises: [speaking], progressRepository: repo)..startSession();
      c.submitAnswer(const TextAnswer(value: 'I want water.'));
      await Future<void>.delayed(const Duration(milliseconds: 50));

      expect(await repo.getByExerciseId('S1'), isNull);
    });
  });
}
