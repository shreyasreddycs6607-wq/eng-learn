import 'package:flutter_test/flutter_test.dart';
import 'package:english_kaliyona/models/exercise_progress.dart';
import 'package:english_kaliyona/services/revision_selector.dart';

final _now = DateTime(2026, 9, 20, 10);

ExerciseProgress _p(String id, {required DateTime due, int incorrect = 0}) => ExerciseProgress(
      exerciseId: id,
      lessonId: 'L001',
      attemptCount: 1,
      incorrectCount: incorrect,
      nextReviewAt: due,
      createdAt: DateTime(2026, 9, 1),
    );

void main() {
  test('only due items are selected; future items are excluded', () {
    final result = RevisionSelector.select([
      _p('A', due: DateTime(2026, 9, 20, 9)),
      _p('B', due: DateTime(2026, 9, 21)),
    ], _now);
    expect(result.map((e) => e.exerciseId), ['A']);
  });

  test('overdue beats due-today, then more failures, then earlier due date, then id', () {
    final result = RevisionSelector.select([
      _p('today', due: DateTime(2026, 9, 20, 8), incorrect: 5),
      _p('overdueFew', due: DateTime(2026, 9, 18), incorrect: 1),
      _p('overdueMany', due: DateTime(2026, 9, 19), incorrect: 3),
      _p('overdueManyEarlier', due: DateTime(2026, 9, 17), incorrect: 3),
      _p('tieB', due: DateTime(2026, 9, 10), incorrect: 0),
      _p('tieA', due: DateTime(2026, 9, 10), incorrect: 0),
    ], _now);
    expect(result.map((e) => e.exerciseId),
        ['overdueManyEarlier', 'overdueMany', 'overdueFew', 'tieA', 'tieB', 'today']);
  });

  test('the session is capped and each exercise appears once', () {
    final many = [for (var i = 0; i < 20; i++) _p('E${i.toString().padLeft(2, '0')}', due: DateTime(2026, 9, 1))];
    final result = RevisionSelector.select(many, _now);
    expect(result, hasLength(RevisionSelector.sessionSize));
    expect(result.map((e) => e.exerciseId).toSet(), hasLength(RevisionSelector.sessionSize));
  });

  test('selection is deterministic regardless of input order', () {
    final items = [_p('B', due: DateTime(2026, 9, 1)), _p('A', due: DateTime(2026, 9, 1))];
    expect(RevisionSelector.select(items, _now).map((e) => e.exerciseId),
        RevisionSelector.select(items.reversed.toList(), _now).map((e) => e.exerciseId));
  });
}
