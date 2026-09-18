import 'package:flutter/material.dart';
import '../../models/exercise.dart';
import '../../models/exercise_answer.dart';
import 'choice_exercise.dart';
import 'speaking_exercise.dart';
import 'word_ordering_exercise.dart';

/// The only place that maps ExerciseType to a widget. Adding a new exercise
/// to the curriculum JSON never requires touching this — it only changes
/// when a genuinely new *type* is introduced (see the schema-boundary note
/// in the Phase 6 report for "match pairs").
Widget buildExerciseView({
  required Exercise exercise,
  required ExerciseAnswer? submittedAnswer,
  required ValueChanged<ExerciseAnswer> onSubmit,
}) {
  return switch (exercise.type) {
    ExerciseType.multipleChoice =>
      MultipleChoiceExercise(exercise: exercise, submittedAnswer: submittedAnswer, onSubmit: onSubmit),
    ExerciseType.kannadaToEnglish =>
      KannadaToEnglishExercise(exercise: exercise, submittedAnswer: submittedAnswer, onSubmit: onSubmit),
    ExerciseType.englishToKannada =>
      EnglishToKannadaExercise(exercise: exercise, submittedAnswer: submittedAnswer, onSubmit: onSubmit),
    ExerciseType.fillBlank =>
      FillBlankExercise(exercise: exercise, submittedAnswer: submittedAnswer, onSubmit: onSubmit),
    ExerciseType.listening =>
      ListeningExercise(exercise: exercise, submittedAnswer: submittedAnswer, onSubmit: onSubmit),
    ExerciseType.wordOrdering =>
      WordOrderingExercise(exercise: exercise, submittedAnswer: submittedAnswer, onSubmit: onSubmit),
    ExerciseType.speaking =>
      SpeakingExercise(exercise: exercise, submittedAnswer: submittedAnswer, onSubmit: onSubmit),
  };
}
