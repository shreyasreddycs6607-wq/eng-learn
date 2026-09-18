import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:english_kaliyona/data/local/database/app_database.dart';
import 'package:english_kaliyona/data/repositories/exercise_progress_repository.dart';
import 'package:english_kaliyona/models/speaking_outcome.dart';
import 'package:english_kaliyona/services/speaking_controller.dart';
import 'package:english_kaliyona/services/speech_recognition_service.dart';
import '../fakes/fake_speech_backend.dart';

void main() {
  late FakeSpeechBackend backend;
  late SpeechRecognitionService speech;
  late AppDatabase db;
  late ExerciseProgressRepository revision;
  late SpeakingController controller;

  setUp(() {
    backend = FakeSpeechBackend();
    speech = SpeechRecognitionService(backend);
    db = AppDatabase.forTesting(NativeDatabase.memory());
    revision = ExerciseProgressRepository(db);
    controller = SpeakingController(
      speech: speech,
      exerciseId: 'E01707',
      expectedText: 'I want water.',
      lessonId: 'L001',
      progressRepository: revision,
    );
  });

  tearDown(() => db.close());

  test('starts idle', () {
    expect(controller.state, SpeakingUiState.idle);
    expect(controller.lastResult, isNull);
  });

  test('unavailable engine surfaces the unavailable state', () async {
    backend.availableResult = false;
    await controller.checkAvailability();
    expect(controller.state, SpeakingUiState.unavailable);
  });

  test('a correct attempt produces Good and records exactly one success', () async {
    await controller.startSpeaking();
    backend.emitResult('I want water', isFinal: true, confidence: 0.9);
    await Future<void>.delayed(Duration.zero);

    expect(controller.state, SpeakingUiState.showingResult);
    expect(controller.lastResult!.outcome, SpeakingOutcome.good);
    final items = await revision.getAll();
    expect(items, hasLength(1));
    expect(items.first.correctCount, 1);
    expect(items.first.incorrectCount, 0);
  });

  test('an incorrect attempt produces Try Again and records one failed attempt', () async {
    await controller.startSpeaking();
    backend.emitResult('I want food', isFinal: true, confidence: 0.9);
    await Future<void>.delayed(Duration.zero);

    expect(controller.lastResult!.outcome, SpeakingOutcome.tryAgain);
    final items = await revision.getAll();
    expect(items, hasLength(1));
    expect(items.first.exerciseId, 'E01707');
    expect(items.first.incorrectCount, 1);
    expect(items.first.reviewLevel, 0);
  });

  test('an empty/unusable transcript produces Listen Again, not a revision failure', () async {
    await controller.startSpeaking();
    backend.emitResult('', isFinal: true, confidence: null);
    await Future<void>.delayed(Duration.zero);

    expect(controller.lastResult!.outcome, SpeakingOutcome.listenAgain);
    expect(await revision.getAll(), isEmpty);
  });

  test('a platform error is surfaced as a result, not a crash', () async {
    await controller.startSpeaking();
    backend.emitError('error_no_match');
    await Future<void>.delayed(Duration.zero);

    expect(controller.state, SpeakingUiState.showingResult);
    expect(controller.lastResult!.outcome, SpeakingOutcome.error);
  });

  test('permission denial is surfaced without crashing and blocks listening', () async {
    backend.permissionGranted = false;
    await controller.startSpeaking();

    expect(controller.state, SpeakingUiState.permissionDenied);
    expect(backend.listenCallCount, 0);
  });

  test('retry clears the previous result and starts a fresh session', () async {
    await controller.startSpeaking();
    backend.emitResult('I want food', isFinal: true, confidence: 0.9);
    await Future<void>.delayed(Duration.zero);
    expect(controller.lastResult, isNotNull);

    await controller.retry();

    expect(controller.state, SpeakingUiState.listening);
    expect(backend.listenCallCount, 2);
  });

  test('confirmWithoutRecognition produces an honest Good result without recording an attempt', () async {
    await controller.startSpeaking();
    backend.emitResult('I want food', isFinal: true, confidence: 0.9); // create a revision item first
    await Future<void>.delayed(Duration.zero);
    expect(await revision.getAll(), hasLength(1));

    controller.confirmWithoutRecognition();

    expect(controller.state, SpeakingUiState.showingResult);
    expect(controller.lastResult!.outcome, SpeakingOutcome.good);
    // The fallback confirmation must not silently resolve the revision item —
    // no automated evaluation actually happened.
    expect(await revision.getAll(), hasLength(1));
  });

  test('does not start a second listening session while already listening', () async {
    await controller.startSpeaking();
    await controller.startSpeaking();

    expect(backend.listenCallCount, 1);
  });
}
