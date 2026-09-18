import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:english_kaliyona/models/exercise.dart';
import 'package:english_kaliyona/models/exercise_answer.dart';
import 'package:english_kaliyona/models/exercise_option.dart';
import 'package:english_kaliyona/widgets/exercise/word_ordering_exercise.dart';

Exercise _exercise() => const Exercise(
      id: 'E1',
      lessonId: 'L001',
      type: ExerciseType.wordOrdering,
      order: 1,
      question: 'Arrange the words.',
      options: [
        ExerciseOption(id: 'w1', text: 'I'),
        ExerciseOption(id: 'w2', text: 'want'),
        ExerciseOption(id: 'w3', text: 'water'),
      ],
      answer: OrderedOptionIdsAnswer(value: ['w1', 'w2', 'w3']),
    );

void main() {
  testWidgets('Check stays disabled until every word is placed', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(body: WordOrderingExercise(exercise: _exercise(), submittedAnswer: null, onSubmit: (_) {})),
    ));

    expect(tester.widget<ElevatedButton>(find.widgetWithText(ElevatedButton, 'CHECK')).onPressed, isNull);

    await tester.tap(find.text('I'));
    await tester.pump();
    expect(tester.widget<ElevatedButton>(find.widgetWithText(ElevatedButton, 'CHECK')).onPressed, isNull);
  });

  testWidgets('placing words in a chosen order and checking submits that exact order', (tester) async {
    ExerciseAnswer? submitted;
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: WordOrderingExercise(exercise: _exercise(), submittedAnswer: null, onSubmit: (a) => submitted = a),
      ),
    ));

    // Deliberately out of order: want, I, water.
    await tester.tap(find.text('want'));
    await tester.pump();
    await tester.tap(find.text('I'));
    await tester.pump();
    await tester.tap(find.text('water'));
    await tester.pump();

    await tester.tap(find.widgetWithText(ElevatedButton, 'CHECK'));
    await tester.pump();

    expect(submitted, isA<OrderedOptionIdsAnswer>());
    expect((submitted as OrderedOptionIdsAnswer).value, ['w2', 'w1', 'w3']);
  });

  testWidgets('tapping a placed word returns it to the bank', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(body: WordOrderingExercise(exercise: _exercise(), submittedAnswer: null, onSubmit: (_) {})),
    ));

    await tester.tap(find.text('I')); // I -> built
    await tester.pump();

    // Tapping "I" again (now in the built row) sends it back to the bank —
    // Check must still be disabled since the sentence is incomplete.
    await tester.tap(find.text('I'));
    await tester.pump();

    expect(tester.widget<ElevatedButton>(find.widgetWithText(ElevatedButton, 'CHECK')).onPressed, isNull);
  });

  testWidgets('once submitted, the built sentence is locked', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: WordOrderingExercise(
          exercise: _exercise(),
          submittedAnswer: const OrderedOptionIdsAnswer(value: ['w1', 'w2', 'w3']),
          onSubmit: (_) {},
        ),
      ),
    ));

    expect(find.widgetWithText(ElevatedButton, 'CHECK'), findsNothing);
    expect(find.text('I'), findsOneWidget);
    expect(find.text('want'), findsOneWidget);
    expect(find.text('water'), findsOneWidget);
  });
}
