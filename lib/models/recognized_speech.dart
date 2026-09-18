/// One transcript update from the speech engine. `confidence` is optional
/// and never load-bearing — some platform engines don't provide a reliable
/// value, so the evaluator never depends on it.
class RecognizedSpeech {
  final String transcript;
  final bool isFinal;
  final double? confidence;

  const RecognizedSpeech({required this.transcript, required this.isFinal, this.confidence});
}
