/// The result of one scheduling decision: the new review level and when
/// the item should next come due.
class ScheduleResult {
  final int reviewLevel;
  final DateTime nextReviewAt;
  const ScheduleResult({required this.reviewLevel, required this.nextReviewAt});
}

/// Centralized, deterministic spaced-repetition scheduling (Phase 8 §21-23).
/// Given identical input (same review level, same outcome, same `now`) this
/// always produces the same result — no randomness, no AI, no network.
class RevisionScheduler {
  /// Interval applied after the Nth consecutive successful review
  /// (1-indexed): 1st success -> 1 day, 2nd -> 2 days, 3rd -> 4 days,
  /// 4th -> 7 days (weekly), 5th -> 14 days, 6th+ -> 30 days (monthly).
  /// Centralized here so scheduling is never scattered across the app (§22).
  /// Mastery is unaffected by the longer steps: Comfortable starts at
  /// reviewLevel 3 (see masteryFor).
  static const List<Duration> intervals = [
    Duration(days: 1),
    Duration(days: 2),
    Duration(days: 4),
    Duration(days: 7),
    Duration(days: 14),
    Duration(days: 30),
  ];

  /// [currentReviewLevel] is the level *before* this review (0 for a new or
  /// previously-failed item). A successful review advances the level by one
  /// (capped at the longest interval); a failed review resets it to 0 and
  /// schedules the shortest interval — never punitive, just "review again
  /// soon" (§35).
  ScheduleResult calculateNext({
    required int currentReviewLevel,
    required bool successful,
    required DateTime now,
  }) {
    if (successful) {
      final newLevel = (currentReviewLevel + 1).clamp(1, intervals.length);
      return ScheduleResult(reviewLevel: newLevel, nextReviewAt: now.add(intervals[newLevel - 1]));
    }
    return ScheduleResult(reviewLevel: 0, nextReviewAt: now.add(intervals[0]));
  }
}
