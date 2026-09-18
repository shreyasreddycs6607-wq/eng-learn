import 'package:flutter_test/flutter_test.dart';
import 'package:english_kaliyona/models/exercise.dart';
import 'package:english_kaliyona/models/exercise_answer.dart';
import 'package:english_kaliyona/models/exercise_option.dart';
import 'package:english_kaliyona/services/exercise_answer_formatter.dart';

void main() {
  const exercise = Exercise(
    id: 'E1',
    lessonId: 'L001',
    type: ExerciseType.wordOrdering,
    order: 1,
    question: 'q',
    options: [
      ExerciseOption(id: 'w1', text: 'I'),
      ExerciseOption(id: 'w2', text: 'want'),
      ExerciseOption(id: 'w3', text: 'water'),
    ],
    answer: OrderedOptionIdsAnswer(value: ['w1', 'w2', 'w3']),
  );

  test('formats an OptionIdAnswer as its option text', () {
    const choiceExercise = Exercise(
      id: 'E2',
      lessonId: 'L001',
      type: ExerciseType.multipleChoice,
      order: 1,
      question: 'q',
      options: [ExerciseOption(id: 'o1', text: 'Water'), ExerciseOption(id: 'o2', text: 'Food')],
      answer: OptionIdAnswer(value: 'o1'),
    );

    expect(ExerciseAnswerFormatter.formatExpectedAnswer(choiceExercise), 'Water');
  });

  test('formats an OrderedOptionIdsAnswer as space-joined option text, in order', () {
    expect(ExerciseAnswerFormatter.formatExpectedAnswer(exercise), 'I want water');
  });

  test('formats a submitted (possibly wrong) OrderedOptionIdsAnswer the same way', () {
    const submitted = OrderedOptionIdsAnswer(value: ['w1', 'w3', 'w2']);
    expect(ExerciseAnswerFormatter.formatSubmittedAnswer(exercise, submitted), 'I water want');
  });

  test('formats a TextAnswer as its literal value', () {
    const speaking = Exercise(
      id: 'E3',
      lessonId: 'L001',
      type: ExerciseType.speaking,
      order: 1,
      question: 'q',
      options: [],
      answer: TextAnswer(value: 'I want water.'),
    );

    expect(ExerciseAnswerFormatter.formatExpectedAnswer(speaking), 'I want water.');
  });
}
