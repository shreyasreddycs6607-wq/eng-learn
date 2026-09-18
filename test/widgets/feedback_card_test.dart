import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:english_kaliyona/models/feedback_type.dart';
import 'package:english_kaliyona/widgets/feedback_card.dart';

Widget _wrap(Widget child) => MaterialApp(home: Scaffold(body: child));

void main() {
  testWidgets('correct feedback shows the friendly headline and hides the correct-answer line', (tester) async {
    await tester.pumpWidget(_wrap(FeedbackCard(
      feedbackType: FeedbackType.correct,
      correctAnswer: 'Water',
      onContinue: () {},
    )));

    expect(find.textContaining('Correct!'), findsOneWidget);
    expect(find.textContaining('Correct answer:'), findsNothing);
  });

  testWidgets('almost feedback is visually distinct from wrong and still reveals the answer', (tester) async {
    await tester.pumpWidget(_wrap(FeedbackCard(
      feedbackType: FeedbackType.almost,
      correctAnswer: 'I want water',
      onContinue: () {},
    )));

    expect(find.text('Almost!'), findsOneWidget);
    expect(find.textContaining('Correct answer: I want water'), findsOneWidget);
  });

  testWidgets('wrong feedback reveals the correct answer and explanation', (tester) async {
    await tester.pumpWidget(_wrap(FeedbackCard(
      feedbackType: FeedbackType.wrong,
      correctAnswer: 'Water',
      explanation: 'ನೀರು means water.',
      onContinue: () {},
    )));

    expect(find.text('Not quite.'), findsOneWidget);
    expect(find.textContaining('Correct answer: Water'), findsOneWidget);
    expect(find.text('ನೀರು means water.'), findsOneWidget);
  });

  testWidgets('Continue calls the callback exactly once per tap', (tester) async {
    var taps = 0;
    await tester.pumpWidget(_wrap(FeedbackCard(
      feedbackType: FeedbackType.correct,
      correctAnswer: 'Water',
      onContinue: () => taps++,
    )));

    await tester.tap(find.text('Continue'));
    await tester.pump();

    expect(taps, 1);
  });
}
