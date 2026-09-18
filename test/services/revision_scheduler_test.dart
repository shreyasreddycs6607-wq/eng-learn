import 'package:flutter_test/flutter_test.dart';
import 'package:english_kaliyona/services/revision_scheduler.dart';

void main() {
  final scheduler = RevisionScheduler();

  test('new item, first successful review -> 1 day', () {
    final now = DateTime(2026, 9, 18, 10, 0);
    final result = scheduler.calculateNext(currentReviewLevel: 0, successful: true, now: now);

    expect(result.reviewLevel, 1);
    expect(result.nextReviewAt, DateTime(2026, 9, 19, 10, 0));
  });

  test('exact schedule progression matches the documented example (§106)', () {
    var now = DateTime(2026, 9, 18, 10, 0);
    var level = 0;

    var r = scheduler.calculateNext(currentReviewLevel: level, successful: true, now: now);
    expect(r.nextReviewAt, DateTime(2026, 9, 19, 10, 0));
    level = r.reviewLevel;
    now = r.nextReviewAt;

    r = scheduler.calculateNext(currentReviewLevel: level, successful: true, now: now);
    expect(r.nextReviewAt, DateTime(2026, 9, 21, 10, 0));
    level = r.reviewLevel;
    now = r.nextReviewAt;

    r = scheduler.calculateNext(currentReviewLevel: level, successful: true, now: now);
    expect(r.nextReviewAt, DateTime(2026, 9, 25, 10, 0));
    level = r.reviewLevel;
    now = r.nextReviewAt;

    r = scheduler.calculateNext(currentReviewLevel: level, successful: true, now: now);
    expect(r.nextReviewAt, DateTime(2026, 10, 2, 10, 0));
  });

  test('a 4th+ successful review stays at the longest interval (does not grow unbounded)', () {
    final now = DateTime(2026, 9, 18);
    final r = scheduler.calculateNext(currentReviewLevel: 4, successful: true, now: now);

    expect(r.reviewLevel, 4);
    expect(r.nextReviewAt, now.add(const Duration(days: 7)));
  });

  test('failure at a high review level resets to the shortest interval (§107)', () {
    final now = DateTime(2026, 9, 18);
    final r = scheduler.calculateNext(currentReviewLevel: 3, successful: false, now: now);

    expect(r.reviewLevel, 0);
    expect(r.nextReviewAt, now.add(const Duration(days: 1)));
  });

  test('first failure on a brand-new item also schedules a 1-day review', () {
    final now = DateTime(2026, 9, 18);
    final r = scheduler.calculateNext(currentReviewLevel: 0, successful: false, now: now);

    expect(r.reviewLevel, 0);
    expect(r.nextReviewAt, now.add(const Duration(days: 1)));
  });

  test('is deterministic: identical input always produces identical output', () {
    final now = DateTime(2026, 9, 18, 10, 0);
    final a = scheduler.calculateNext(currentReviewLevel: 2, successful: true, now: now);
    final b = scheduler.calculateNext(currentReviewLevel: 2, successful: true, now: now);

    expect(a.reviewLevel, b.reviewLevel);
    expect(a.nextReviewAt, b.nextReviewAt);
  });
}
