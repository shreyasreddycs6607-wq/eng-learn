import 'speaking_outcome.dart';

/// The outcome of comparing one recognized transcript against the target
/// phrase. `similarity` is nullable — it isn't meaningful for outcomes like
/// [SpeakingOutcome.unavailable] where no comparison happened at all.
class SpeakingResult {
  final SpeakingOutcome outcome;
  final String expectedText;
  final String recognizedText;
  final double? similarity;

  const SpeakingResult({
    required this.outcome,
    required this.expectedText,
    required this.recognizedText,
    this.similarity,
  });
}
