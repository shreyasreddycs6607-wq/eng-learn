import '../models/exercise_answer.dart';

/// The only place exercise answers are compared. Widgets never inspect
/// ExerciseAnswer's runtime type themselves.
bool checkAnswer({required ExerciseAnswer expected, required ExerciseAnswer submitted}) {
  if (expected is OptionIdAnswer && submitted is OptionIdAnswer) {
    return expected.value == submitted.value;
  }
  if (expected is OrderedOptionIdsAnswer && submitted is OrderedOptionIdsAnswer) {
    if (expected.value.length != submitted.value.length) return false;
    for (var i = 0; i < expected.value.length; i++) {
      if (expected.value[i] != submitted.value[i]) return false;
    }
    return true;
  }
  if (expected is TextAnswer && submitted is TextAnswer) {
    return _normalize(expected.value) == _normalize(submitted.value);
  }
  return false;
}

/// Trims, lowercases, and drops trailing punctuation so "I want water."
/// and "I want Water" aren't treated as different answers.
String _normalize(String text) {
  return text.trim().toLowerCase().replaceAll(RegExp(r'[.!?]+$'), '').replaceAll(RegExp(r'\s+'), ' ');
}
