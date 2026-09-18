/// Three learner-facing states — product states, not a scientific
/// measurement. Always derived from [reviewLevel]/[attemptCount], never
/// stored redundantly, so it can never drift out of sync with the data it
/// describes (see Phase 8 §68/§83).
enum MasteryLevel { learning, practicing, comfortable }

/// Deterministic rule (Phase 8 §19-20):
/// - Learning: no attempts yet.
/// - Comfortable: at least 3 consecutive successful reviews *and* the most
///   recent review was successful (reviewLevel >= 3 already encodes both,
///   since any failure resets reviewLevel to 0 — see RevisionScheduler).
/// - Practicing: everything in between.
MasteryLevel masteryFor({required int attemptCount, required int reviewLevel}) {
  if (attemptCount == 0) return MasteryLevel.learning;
  if (reviewLevel >= 3) return MasteryLevel.comfortable;
  return MasteryLevel.practicing;
}
