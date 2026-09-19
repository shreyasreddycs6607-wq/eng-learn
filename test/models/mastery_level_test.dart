import 'package:flutter_test/flutter_test.dart';
import 'package:english_kaliyona/models/mastery_level.dart';

void main() {
  test('0 attempts is Learning', () {
    expect(masteryFor(attemptCount: 0, reviewLevel: 0), MasteryLevel.learning);
  });

  test('attempted with fewer than 3 consecutive correct is Practicing', () {
    expect(masteryFor(attemptCount: 1, reviewLevel: 0), MasteryLevel.practicing);
    expect(masteryFor(attemptCount: 2, reviewLevel: 2), MasteryLevel.practicing);
  });

  test('3 consecutive correct is Comfortable', () {
    expect(masteryFor(attemptCount: 3, reviewLevel: 3), MasteryLevel.comfortable);
    expect(masteryFor(attemptCount: 9, reviewLevel: 4), MasteryLevel.comfortable);
    expect(masteryFor(attemptCount: 12, reviewLevel: 6), MasteryLevel.comfortable); // monthly reviews
  });

  test('a failure (reviewLevel reset to 0) drops Comfortable back to Practicing', () {
    expect(masteryFor(attemptCount: 4, reviewLevel: 0), MasteryLevel.practicing);
  });
}
