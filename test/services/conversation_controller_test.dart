import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:english_kaliyona/data/local/database/app_database.dart';
import 'package:english_kaliyona/data/repositories/exercise_progress_repository.dart';
import 'package:english_kaliyona/models/conversation.dart';
import 'package:english_kaliyona/models/exercise.dart';
import 'package:english_kaliyona/models/exercise_answer.dart';
import 'package:english_kaliyona/models/exercise_option.dart';
import 'package:english_kaliyona/models/mastery_level.dart';
import 'package:english_kaliyona/services/conversation_controller.dart';
import 'package:english_kaliyona/services/speaking_controller.dart';
import 'package:english_kaliyona/services/speech_recognition_service.dart';
import '../fakes/fake_speech_backend.dart';

const _choice = Exercise(
  id: 'C1',
  lessonId: 'L026',
  conversationId: 'CONV',
  type: ExerciseType.multipleChoice,
  order: 102,
  question: 'q',
  options: [ExerciseOption(id: 'o1', text: 'Yes, I want food.'), ExerciseOption(id: 'o2', text: 'Bye.'), ExerciseOption(id: 'o3', text: 'Tea.')],
  answer: OptionIdAnswer(value: 'o1'),
);
const _speak = Exercise(
  id: 'S1',
  lessonId: 'L026',
  conversationId: 'CONV',
  type: ExerciseType.speaking,
  order: 202,
  question: 'Say it',
  options: [],
  answer: TextAnswer(value: 'Yes, I want food.'),
);

const _conversation = Conversation(
  id: 'CONV',
  category: ConversationCategory.home,
  title: 't',
  kannadaTitle: 'k',
  kannadaSituation: 'k',
  situation: 's',
  turns: [
    ConversationTurn(order: 1, speaker: 'family', kannadaText: 'k', englishText: 'Are you hungry?'),
    ConversationTurn(order: 2, speaker: 'learner', kannadaText: 'k', englishText: 'Yes, I want food.', responseExerciseIds: ['C1', 'S1']),
    ConversationTurn(order: 3, speaker: 'family', kannadaText: 'k', englishText: 'Okay.'),
    ConversationTurn(order: 4, speaker: 'family', kannadaText: 'k', englishText: 'Here you are.'),
  ],
);

const _right = OptionIdAnswer(value: 'o1');
const _wrong = OptionIdAnswer(value: 'o2');

void main() {
  late FakeSpeechBackend backend;
  late AppDatabase db;
  late ExerciseProgressRepository progress;
  late ConversationController c;

  setUp(() {
    backend = FakeSpeechBackend();
    db = AppDatabase.forTesting(NativeDatabase.memory());
    progress = ExerciseProgressRepository(db);
    c = ConversationController(
      conversation: _conversation,
      exercises: {'C1': _choice, 'S1': _speak},
      progressRepository: progress,
      speakingFactory: (e) => SpeakingController(
        speech: SpeechRecognitionService(backend),
        exerciseId: e.id,
        lessonId: e.lessonId,
        expectedText: 'Yes, I want food.',
        progressRepository: progress,
      ),
    );
  });

  tearDown(() async {
    await Future<void>.delayed(const Duration(milliseconds: 50)); // let fire-and-forget writes land
    c.dispose();
    await db.close();
  });

  Future<void> settle() => Future<void>.delayed(const Duration(milliseconds: 20));

  /// Line turn -> learner turn's choose step.
  void toChoose() {
    c.continueTurn();
    expect(c.state.step, TurnStep.choose);
  }

  /// Correct choice -> speak step, mic started.
  Future<void> toSpeak() async {
    toChoose();
    c.submitChoice(_right);
    c.continueTurn();
    expect(c.state.step, TurnStep.speak);
    await c.speaking!.startSpeaking();
  }

  Future<void> say(String text) async {
    backend.emitResult(text, isFinal: true, confidence: 0.9);
    await settle();
  }

  group('choose a reply', () {
    test('A: correct first attempt records one success and moves to the speak step', () async {
      toChoose();
      c.submitChoice(_right);
      await settle();

      expect(c.state.outcome, StepOutcome.correct);
      expect(c.state.evaluatedAttempts, 1);
      final p = (await progress.getByExerciseId('C1'))!;
      expect((p.attemptCount, p.correctCount), (1, 1));

      c.continueTurn();
      expect(c.state.step, TurnStep.speak);
      expect(c.turnIndex, 1);
    });

    test('B: incorrect then correct stays on the turn, records both attempts, then advances', () async {
      toChoose();
      c.submitChoice(_wrong);
      expect(c.state.awaitingRetry, isTrue);
      expect(c.turnIndex, 1);
      expect(c.choiceResult!.correctAnswerText, 'Yes, I want food.'); // correction is shown

      await c.retry();
      expect(c.state.outcome, StepOutcome.pending);
      expect(c.state.evaluatedAttempts, 1);
      c.submitChoice(_right);
      await settle();

      expect(c.state.outcome, StepOutcome.correct);
      final p = (await progress.getByExerciseId('C1'))!;
      expect((p.attemptCount, p.correctCount, p.incorrectCount), (2, 1, 1)); // first miss is not erased
    });

    test('C: incorrect twice reveals the answer, records two failures and skips the speak step', () async {
      toChoose();
      c.submitChoice(_wrong);
      await c.retry();
      c.submitChoice(_wrong);
      await settle();

      expect(c.state.outcome, StepOutcome.revealed);
      expect(c.state.evaluatedAttempts, ConversationController.maxAttempts);
      expect(c.reinforcementCount, 1);
      final p = (await progress.getByExerciseId('C1'))!;
      expect((p.attemptCount, p.incorrectCount), (2, 2));

      c.continueTurn(); // not trapped — moves on to the next turn
      expect(c.turnIndex, 2);
      expect(c.state.step, TurnStep.line);
    });

    test('a double tap is one submission and one database write', () async {
      toChoose();
      c.submitChoice(_wrong);
      c.submitChoice(_wrong);
      c.submitChoice(_right);
      await settle();

      expect(c.state.evaluatedAttempts, 1);
      expect((await progress.getByExerciseId('C1'))!.attemptCount, 1);
    });

    test('an unsubmitted reply records nothing', () async {
      toChoose();
      await settle();
      expect(await progress.getByExerciseId('C1'), isNull);
    });

    test('the retry counter resets for the next turn', () async {
      toChoose();
      c.submitChoice(_wrong);
      await c.retry();
      c.submitChoice(_wrong);
      c.continueTurn();
      expect(c.state.evaluatedAttempts, 0);
      expect(c.state.outcome, StepOutcome.pending);
    });

    test('failures follow the existing mastery/revision rules', () async {
      toChoose();
      c.submitChoice(_wrong);
      await settle();
      final p = (await progress.getByExerciseId('C1'))!;
      expect(p.reviewLevel, 0);
      expect(p.mastery, MasteryLevel.practicing);
      expect(p.nextReviewAt!.difference(p.lastAttemptedAt!), const Duration(days: 1));
    });
  });

  group('speaking', () {
    test('D: Good immediately is one success and the turn completes', () async {
      await toSpeak();
      await say('Yes, I want food');

      expect(c.state.outcome, StepOutcome.correct);
      final p = (await progress.getByExerciseId('S1'))!;
      expect((p.attemptCount, p.correctCount), (1, 1));
      c.continueTurn();
      expect(c.turnIndex, 2);
    });

    test('E: Try Again then Good — first failure, then success, no third attempt', () async {
      await toSpeak();
      await say('I want tea');
      expect(c.state.awaitingRetry, isTrue);

      await c.retry();
      await say('Yes, I want food');

      expect(c.state.outcome, StepOutcome.correct);
      final p = (await progress.getByExerciseId('S1'))!;
      expect((p.attemptCount, p.correctCount, p.incorrectCount), (2, 1, 1));
    });

    test('F: Try Again twice reveals the target and lets the learner continue', () async {
      await toSpeak();
      await say('I want tea');
      await c.retry();
      await say('I am going home');

      expect(c.state.outcome, StepOutcome.revealed);
      expect(c.state.evaluatedAttempts, 2);
      expect(c.reinforcementCount, 1);
      expect((await progress.getByExerciseId('S1'))!.incorrectCount, 2);
      c.continueTurn();
      expect(c.turnIndex, 2);
    });

    test('G: Listen Again is not a failure and does not consume an attempt', () async {
      await toSpeak();
      await say('');

      expect(c.state.outcome, StepOutcome.pending);
      expect(c.state.evaluatedAttempts, 0);
      expect(c.state.recognitionFailures, 1);
      expect(await progress.getByExerciseId('S1'), isNull);

      await c.retry();
      await say('Yes, I want food');
      expect(c.state.outcome, StepOutcome.correct);
      final p = (await progress.getByExerciseId('S1'))!;
      expect((p.attemptCount, p.incorrectCount), (1, 0));
    });

    test('repeated Listen Agains never trap the learner', () async {
      await toSpeak();
      for (var i = 0; i < ConversationController.maxRecognitionFailures; i++) {
        await say('');
        await c.retry();
      }
      c.continueWithoutRecognition();

      expect(c.state.outcome, StepOutcome.revealed);
      expect(await progress.getByExerciseId('S1'), isNull); // nothing recorded, nothing penalised
      c.continueTurn();
      expect(c.turnIndex, 2);
    });

    test('continueWithoutRecognition is refused before enough failures', () async {
      await toSpeak();
      await say('');
      c.continueWithoutRecognition();
      expect(c.state.outcome, StepOutcome.pending);
    });

    test('a non-exact fuzzy match is never Good', () async {
      await toSpeak();
      await say('Yes I want foods'); // close, but not exact
      expect(c.state.outcome, isNot(StepOutcome.correct));
      expect((await progress.getByExerciseId('S1'))!.correctCount, 0);
    });

    test('the honest "I repeated it" fallback finishes the step without recording an attempt', () async {
      await toSpeak();
      c.speaking!.confirmWithoutRecognition();
      await settle();

      expect(c.state.outcome, StepOutcome.correct);
      expect(await progress.getByExerciseId('S1'), isNull);
    });
  });

  group('turn order', () {
    test('turns run in order and the conversation finishes after the last one', () {
      expect(c.turn.order, 1);
      c.continueTurn();
      expect(c.turn.order, 2);
    });

    test('a line turn cannot be skipped past the end and finishing is explicit', () {
      c.continueTurn(); // -> learner turn 2
      c.submitChoice(_wrong);
      c.retry();
      c.submitChoice(_wrong);
      c.continueTurn(); // -> turn 3
      c.continueTurn(); // -> turn 4
      expect(c.finished, isFalse);
      c.continueTurn();
      expect(c.finished, isTrue);
    });

    test('continue is ignored while the learner still owes an answer', () {
      toChoose();
      c.continueTurn();
      expect(c.state.step, TurnStep.choose);
      expect(c.turnIndex, 1);
    });
  });
}

