import '../models/exercise.dart';
import '../models/exercise_answer.dart';

/// Turns a canonical ExerciseAnswer into learner-facing text — the one place
/// that knows "OptionIdAnswer means look up option.text", so feedback UIs
/// never re-derive it themselves.
class ExerciseAnswerFormatter {
  static String formatExpectedAnswer(Exercise exercise) => _format(exercise, exercise.answer);

  static String _format(Exercise exercise, ExerciseAnswer answer) {
    return switch (answer) {
      OptionIdAnswer(value: final id) => _optionText(exercise, id),
      OrderedOptionIdsAnswer(value: final ids) => ids.map((id) => _optionText(exercise, id)).join(' '),
      TextAnswer(value: final text) => text,
    };
  }

  static String _optionText(Exercise exercise, String optionId) {
    for (final option in exercise.options) {
      if (option.id == optionId) return option.text;
    }
    return optionId;
  }
}
