/// A practice session's lifecycle. PracticeController is the only thing
/// that moves a session between these — no screen sets this directly.
///
/// notStarted -> active -> awaitingAnswer -> showingFeedback -> active -> ... -> completed
///
/// `submitAnswer` only acts from [awaitingAnswer]; `continueToNext` only
/// acts from [showingFeedback]. Any other call is a no-op, which is what
/// makes double-submission and "answer after completion" impossible.
enum PracticeStatus { notStarted, active, awaitingAnswer, showingFeedback, completed }
