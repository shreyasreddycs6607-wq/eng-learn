import '../models/speaking_outcome.dart';
import '../models/speaking_result.dart';

/// Compares recognized speech against the curriculum's target phrase.
/// Completely local and deterministic — no AI, no semantic matching, no
/// network call. Fuzzy matching exists only to tolerate small speech-
/// recognition transcription errors; it can soften a result to
/// [SpeakingOutcome.almost] but can never turn a non-exact transcript into
/// [SpeakingOutcome.good]. See normalizeSpeech for the only normalization
/// this evaluator performs.
class SpeakingEvaluator {
  /// The only per-word threshold in the evaluator, and it only ever
  /// narrows a single already-matched-in-position word — see
  /// [_isAlmostMatch]. It never gates the sentence as a whole.
  static const double _almostWordSimilarityThreshold = 0.6;

  SpeakingResult evaluate({required String expectedText, required String recognizedText}) {
    final expected = normalizeSpeech(expectedText);
    final recognized = normalizeSpeech(recognizedText);

    if (expected.isEmpty || recognized.isEmpty) {
      return SpeakingResult(
        outcome: SpeakingOutcome.listenAgain,
        expectedText: expectedText,
        recognizedText: recognizedText,
      );
    }

    if (expected == recognized) {
      return SpeakingResult(
        outcome: SpeakingOutcome.good,
        expectedText: expectedText,
        recognizedText: recognizedText,
        similarity: 1.0,
      );
    }

    final expectedWords = expected.split(' ');
    final recognizedWords = recognized.split(' ');

    // A transcript far too short to plausibly represent the target sentence
    // (e.g. "uh") is a recognition problem, not a wrong answer.
    if (recognizedWords.length == 1 && expectedWords.length > 1 && recognized.length <= 3) {
      return SpeakingResult(
        outcome: SpeakingOutcome.listenAgain,
        expectedText: expectedText,
        recognizedText: recognizedText,
        similarity: _charSimilarity(expected, recognized),
      );
    }

    final similarity = _charSimilarity(expected, recognized);
    final outcome = _isAlmostMatch(expectedWords, recognizedWords)
        ? SpeakingOutcome.almost
        : SpeakingOutcome.tryAgain;

    return SpeakingResult(
      outcome: outcome,
      expectedText: expectedText,
      recognizedText: recognizedText,
      similarity: similarity,
    );
  }

  /// Deterministic and narrow: same word count, same word order, and
  /// exactly one word differs — and that one word must itself be
  /// character-similar (catches an ASR slip like "water" -> "waiter").
  /// A changed *content* word ("water" -> "food"), a reordered sentence,
  /// or more than one changed word is always Try Again, never Almost.
  bool _isAlmostMatch(List<String> expectedWords, List<String> recognizedWords) {
    if (expectedWords.length != recognizedWords.length) return false;
    if (expectedWords.length > 6) return false; // keep fuzzy matching to short beginner sentences

    var changedIndex = -1;
    var changedCount = 0;
    for (var i = 0; i < expectedWords.length; i++) {
      if (expectedWords[i] != recognizedWords[i]) {
        changedCount++;
        changedIndex = i;
      }
    }
    if (changedCount != 1) return false;

    final wordSimilarity = _charSimilarity(expectedWords[changedIndex], recognizedWords[changedIndex]);
    return wordSimilarity >= _almostWordSimilarityThreshold;
  }

  double _charSimilarity(String a, String b) {
    if (a == b) return 1.0;
    final maxLen = a.length > b.length ? a.length : b.length;
    if (maxLen == 0) return 1.0;
    final distance = _levenshtein(a, b);
    return (1 - distance / maxLen).clamp(0.0, 1.0);
  }

  int _levenshtein(String a, String b) {
    final la = a.length, lb = b.length;
    if (la == 0) return lb;
    if (lb == 0) return la;
    var previous = List<int>.generate(lb + 1, (j) => j);
    var current = List<int>.filled(lb + 1, 0);
    for (var i = 1; i <= la; i++) {
      current[0] = i;
      for (var j = 1; j <= lb; j++) {
        final cost = a[i - 1] == b[j - 1] ? 0 : 1;
        current[j] = [
          current[j - 1] + 1,
          previous[j] + 1,
          previous[j - 1] + cost,
        ].reduce((x, y) => x < y ? x : y);
      }
      final swap = previous;
      previous = current;
      current = swap;
    }
    return previous[lb];
  }
}

/// The one centralized normalization for speaking evaluation. Deliberately
/// conservative: no synonyms, no translation, no reordering, no AI.
String normalizeSpeech(String input) {
  var value = input.trim().toLowerCase();
  value = value.replaceAll(RegExp(r'[.!?,;:]+'), ' ');
  value = value.replaceAll(RegExp(r'\s+'), ' ');
  return value.trim();
}
