import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:english_kaliyona/models/exercise.dart';
import 'package:english_kaliyona/models/exercise_answer.dart';
import 'package:english_kaliyona/models/exercise_option.dart';
import 'package:english_kaliyona/widgets/exercise/choice_exercise.dart';

Exercise _exercise() => const Exercise(
      id: 'E1',
      lessonId: 'L001',
      type: ExerciseType.multipleChoice,
      order: 1,
      question: 'What does this mean?',
      options: [
        ExerciseOption(id: 'o1', text: 'Water'),
        ExerciseOption(id: 'o2', text: 'Food'),
        ExerciseOption(id: 'o3', text: 'Tea'),
      ],
      answer: OptionIdAnswer(value: 'o1'),
    );

void main() {
  testWidgets('renders every option and starts with Check disabled', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: MultipleChoiceExercise(exercise: _exercise(), submittedAnswer: null, onSubmit: (_) {}),
      ),
    ));

    expect(find.text('Water'), findsOneWidget);
    expect(find.text('Food'), findsOneWidget);
    expect(find.text('Tea'), findsOneWidget);

    final button = tester.widget<ElevatedButton>(find.widgetWithText(ElevatedButton, 'CHECK'));
    expect(button.onPressed, isNull);
  });

  testWidgets('selecting an option enables Check; tapping it submits that option', (tester) async {
    ExerciseAnswer? submitted;
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: MultipleChoiceExercise(
          exercise: _exercise(),
          submittedAnswer: null,
          onSubmit: (a) => submitted = a,
        ),
      ),
    ));

    await tester.tap(find.text('Water'));
    await tester.pump();

    final button = tester.widget<ElevatedButton>(find.widgetWithText(ElevatedButton, 'CHECK'));
    expect(button.onPressed, isNotNull);

    await tester.tap(find.widgetWithText(ElevatedButton, 'CHECK'));
    await tester.pump();

    expect(submitted, isA<OptionIdAnswer>());
    expect((submitted as OptionIdAnswer).value, 'o1');
  });

  testWidgets('once submitted, options lock and Check disappears', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: MultipleChoiceExercise(
          exercise: _exercise(),
          submittedAnswer: const OptionIdAnswer(value: 'o2'),
          onSubmit: (_) {},
        ),
      ),
    ));

    expect(find.widgetWithText(ElevatedButton, 'CHECK'), findsNothing);

    // Tapping an option after submission must not change anything.
    await tester.tap(find.text('Water'));
    await tester.pump();
    expect(find.widgetWithText(ElevatedButton, 'CHECK'), findsNothing);
  });
}
