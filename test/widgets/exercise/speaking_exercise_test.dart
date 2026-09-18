import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:english_kaliyona/models/exercise.dart';
import 'package:english_kaliyona/models/exercise_answer.dart';
import 'package:english_kaliyona/services/speaking_controller.dart';
import 'package:english_kaliyona/services/speech_recognition_service.dart';
import 'package:english_kaliyona/widgets/exercise/speaking_exercise.dart';
import '../../fakes/fake_speech_backend.dart';

const _exercise = Exercise(
  id: 'E01707',
  lessonId: 'L017',
  type: ExerciseType.speaking,
  order: 1,
  question: 'Say this sentence.',
  englishText: 'I want water.',
  audioPath: 'audio/english/i_want_water.mp3',
  options: [],
  answer: TextAnswer(value: 'I want water.'),
);

Widget _wrap(Widget child) => MaterialApp(home: Scaffold(body: SizedBox(height: 500, child: child)));

void main() {
  late FakeSpeechBackend backend;
  late SpeechRecognitionService speech;
  late SpeakingController controller;

  setUp(() {
    backend = FakeSpeechBackend();
    speech = SpeechRecognitionService(backend);
    controller = SpeakingController(speech: speech, exerciseId: _exercise.id, lessonId: _exercise.lessonId, expectedText: 'I want water.');
  });

  testWidgets('shows the microphone when the engine is available', (tester) async {
    await tester.pumpWidget(_wrap(SpeakingExercise(
      exercise: _exercise,
      submittedAnswer: null,
      onSubmit: (_) {},
      controller: controller,
    )));
    await tester.pump();

    expect(find.byIcon(Icons.mic_rounded), findsOneWidget);
  });

  testWidgets('a correct attempt shows Good and Continue submits the expected TextAnswer', (tester) async {
    ExerciseAnswer? submitted;
    await tester.pumpWidget(_wrap(SpeakingExercise(
      exercise: _exercise,
      submittedAnswer: null,
      onSubmit: (a) => submitted = a,
      controller: controller,
    )));
    await tester.pump();

    await controller.startSpeaking();
    backend.emitResult('I want water', isFinal: true, confidence: 0.9);
    await tester.pump();

    expect(find.textContaining('Good'), findsOneWidget);

    await tester.tap(find.text('Continue'));
    await tester.pump();

    expect(submitted, isA<TextAnswer>());
    expect((submitted as TextAnswer).value, 'I want water.');
  });

  testWidgets('a wrong attempt shows what was heard and the target, with a retry option', (tester) async {
    await tester.pumpWidget(_wrap(SpeakingExercise(
      exercise: _exercise,
      submittedAnswer: null,
      onSubmit: (_) {},
      controller: controller,
    )));
    await tester.pump();

    await controller.startSpeaking();
    backend.emitResult('I want food', isFinal: true, confidence: 0.9);
    await tester.pump();

    expect(find.textContaining('I want food'), findsOneWidget);
    expect(find.textContaining('I want water'), findsOneWidget);
    expect(find.textContaining('Try Again'), findsOneWidget);
  });

  testWidgets('unavailable engine shows the fallback and never blocks completion', (tester) async {
    backend.availableResult = false;
    ExerciseAnswer? submitted;
    await tester.pumpWidget(_wrap(SpeakingExercise(
      exercise: _exercise,
      submittedAnswer: null,
      onSubmit: (a) => submitted = a,
      controller: controller,
    )));
    await tester.pump();
    await tester.pump();

    expect(find.textContaining("isn't available"), findsOneWidget);
    expect(find.byIcon(Icons.mic_rounded), findsNothing);

    await tester.tap(find.text('I repeated it'));
    await tester.pump();

    expect(submitted, isA<TextAnswer>());
    expect((submitted as TextAnswer).value, 'I want water.');
  });

  testWidgets('once submitted, shows a locked confirmation and no controls', (tester) async {
    await tester.pumpWidget(_wrap(SpeakingExercise(
      exercise: _exercise,
      submittedAnswer: const TextAnswer(value: 'I want water.'),
      onSubmit: (_) {},
      controller: controller,
    )));
    await tester.pump();

    expect(find.byIcon(Icons.mic_rounded), findsNothing);
    expect(find.byIcon(Icons.check_circle_rounded), findsOneWidget);
  });
}
