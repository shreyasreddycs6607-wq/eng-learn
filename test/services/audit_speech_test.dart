import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:english_kaliyona/data/local/database/app_database.dart';
import 'package:english_kaliyona/data/repositories/exercise_progress_repository.dart';
import 'package:english_kaliyona/models/speaking_outcome.dart';
import 'package:english_kaliyona/models/speech_recognition_state.dart';
import 'package:english_kaliyona/services/speaking_controller.dart';
import 'package:english_kaliyona/services/speaking_evaluator.dart';
import 'package:english_kaliyona/services/speech_recognition_service.dart';
import '../fakes/fake_speech_backend.dart';

/// Regression tests from the production audit: a speech session must always
/// resolve (never wait forever), and leaving a screen must release the mic.
void main() {
  late FakeSpeechBackend backend;
  late SpeechRecognitionService service;

  setUp(() {
    backend = FakeSpeechBackend();
    service = SpeechRecognitionService(backend)
      ..listenTimeout = const Duration(milliseconds: 40)
      ..stopTimeout = const Duration(milliseconds: 40);
  });

  tearDown(() => service.dispose());

  Future<void> wait([int ms = 90]) => Future<void>.delayed(Duration(milliseconds: ms));

  group('watchdog', () {
    test('a session that never produces a result ends in an error, not "Listening..." forever', () async {
      await service.startListening();
      expect(service.state, SpeechRecognitionState.listening);

      await wait();

      expect(service.state, SpeechRecognitionState.error);
      expect(backend.cancelCallCount, 1);
    });

    test('tapping stop with no result coming back also resolves', () async {
      await service.startListening();
      await service.stopListening();
      expect(service.state, SpeechRecognitionState.processing);

      await wait();

      expect(service.state, SpeechRecognitionState.error);
    });

    test('a real result disarms the watchdog', () async {
      await service.startListening();
      backend.emitResult('I want water', isFinal: true, confidence: 0.9);
      expect(service.state, SpeechRecognitionState.recognized);

      await wait();

      expect(service.state, SpeechRecognitionState.recognized);
      expect(backend.cancelCallCount, 0);
    });

    test('a timed-out attempt can be retried', () async {
      await service.startListening();
      await wait();
      expect(service.state, SpeechRecognitionState.error);

      await service.startListening();
      expect(service.state, SpeechRecognitionState.listening);
    });
  });

  group('leaving the screen', () {
    late AppDatabase db;
    late SpeakingController controller;

    setUp(() {
      db = AppDatabase.forTesting(NativeDatabase.memory());
      controller = SpeakingController(
        speech: service,
        exerciseId: 'E1',
        lessonId: 'L1',
        expectedText: 'I want water.',
        progressRepository: ExerciseProgressRepository(db),
      );
    });

    tearDown(() => db.close());

    test('disposing mid-listen cancels the microphone and frees the shared recognizer', () async {
      await controller.startSpeaking();
      expect(service.state, SpeechRecognitionState.listening);

      controller.dispose();
      await wait(10);

      expect(backend.cancelCallCount, 1);
      expect(service.state, SpeechRecognitionState.idle);
      // The next screen's mic tap works instead of being ignored as "already listening".
      await service.startListening();
      expect(backend.listenCallCount, 2);
    });

    test('disposing when nothing is listening does not touch the recognizer', () async {
      controller.dispose();
      await wait(10);
      expect(backend.cancelCallCount, 0);
    });
  });

  group('speaking matching contract (spec examples)', () {
    final evaluator = SpeakingEvaluator();
    SpeakingOutcome outcome(String said) => evaluator.evaluate(expectedText: 'I want water.', recognizedText: said).outcome;

    test('exact, case and punctuation differences are Good', () {
      expect(outcome('I want water.'), SpeakingOutcome.good);
      expect(outcome('I WANT WATER'), SpeakingOutcome.good);
      expect(outcome('  i want   water  '), SpeakingOutcome.good);
    });

    test('an extra or missing word is never Good', () {
      expect(outcome('I want some water.'), isNot(SpeakingOutcome.good));
      expect(outcome('I want'), isNot(SpeakingOutcome.good));
    });

    test('a different sentence is Try Again', () {
      expect(outcome('Where is the bus?'), SpeakingOutcome.tryAgain);
    });

    test('an empty transcript is Listen Again', () {
      expect(outcome(''), SpeakingOutcome.listenAgain);
    });
  });
}
