/// What the learner should see after one speaking attempt. Never exposes
/// scoring internals (confidence, similarity numbers) to the UI layer —
/// those stay in [SpeakingResult] for tests/telemetry only.
enum SpeakingOutcome { good, almost, tryAgain, listenAgain, unavailable, permissionDenied, error }
