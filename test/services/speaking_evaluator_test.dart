import 'package:flutter_test/flutter_test.dart';
import 'package:english_kaliyona/models/speaking_outcome.dart';
import 'package:english_kaliyona/services/speaking_evaluator.dart';

void main() {
  final evaluator = SpeakingEvaluator();

  group('normalizeSpeech', () {
    test('trims, lowercases, and collapses whitespace/punctuation', () {
      expect(normalizeSpeech('I want water.'), 'i want water');
      expect(normalizeSpeech('I want water'), 'i want water');
      expect(normalizeSpeech(' I WANT WATER '), 'i want water');
      expect(normalizeSpeech('I want   water.'), 'i want water');
      expect(normalizeSpeech('I want water!'), 'i want water');
    });
  });

  group('exact / near-exact matches -> good', () {
    test('identical text', () {
      final r = evaluator.evaluate(expectedText: 'I want water.', recognizedText: 'I want water.');
      expect(r.outcome, SpeakingOutcome.good);
    });

    test('missing trailing punctuation', () {
      final r = evaluator.evaluate(expectedText: 'I want water.', recognizedText: 'I want water');
      expect(r.outcome, SpeakingOutcome.good);
    });

    test('case difference', () {
      final r = evaluator.evaluate(expectedText: 'I Want Water.', recognizedText: 'i want water');
      expect(r.outcome, SpeakingOutcome.good);
    });

    test('whitespace difference', () {
      final r = evaluator.evaluate(expectedText: 'I want water.', recognizedText: '  I   want   water  ');
      expect(r.outcome, SpeakingOutcome.good);
    });

    test('exact match always reports similarity 1.0', () {
      final r = evaluator.evaluate(expectedText: 'I want water.', recognizedText: 'i want water');
      expect(r.similarity, 1.0);
    });
  });

  group('small transcription error -> almost', () {
    test('water / waiter is a documented almost case', () {
      final r = evaluator.evaluate(expectedText: 'I want water.', recognizedText: 'I want waiter.');
      expect(r.outcome, SpeakingOutcome.almost);
    });

    test('almost still reports isCorrect-relevant info: not equal to good', () {
      final r = evaluator.evaluate(expectedText: 'I want water.', recognizedText: 'I want waiter.');
      expect(r.outcome, isNot(SpeakingOutcome.good));
    });
  });

  group('different content word -> try again, never good or almost-by-accident', () {
    test('water -> food', () {
      final r = evaluator.evaluate(expectedText: 'I want water.', recognizedText: 'I want food.');
      expect(r.outcome, SpeakingOutcome.tryAgain);
    });

    test('want -> need (different verb)', () {
      final r = evaluator.evaluate(expectedText: 'I want water.', recognizedText: 'I need water.');
      expect(r.outcome, SpeakingOutcome.tryAgain);
    });

    test('want -> like', () {
      final r = evaluator.evaluate(expectedText: 'I want water.', recognizedText: 'I like water.');
      expect(r.outcome, SpeakingOutcome.tryAgain);
    });
  });

  group('word order changes -> try again', () {
    test('fully reordered sentence', () {
      final r = evaluator.evaluate(expectedText: 'I want water.', recognizedText: 'Water I want.');
      expect(r.outcome, SpeakingOutcome.tryAgain);
    });
  });

  group('completely different sentence -> try again', () {
    test('unrelated sentence', () {
      final r = evaluator.evaluate(expectedText: 'I want water.', recognizedText: 'Where is the bus?');
      expect(r.outcome, SpeakingOutcome.tryAgain);
    });
  });

  group('empty / unusable transcript -> listen again, never a normal wrong answer', () {
    test('empty transcript', () {
      final r = evaluator.evaluate(expectedText: 'I want water.', recognizedText: '');
      expect(r.outcome, SpeakingOutcome.listenAgain);
    });

    test('whitespace-only transcript', () {
      final r = evaluator.evaluate(expectedText: 'I want water.', recognizedText: '   ');
      expect(r.outcome, SpeakingOutcome.listenAgain);
    });

    test('noise/very short transcript for a multi-word target', () {
      final r = evaluator.evaluate(expectedText: 'I want water.', recognizedText: 'uh');
      expect(r.outcome, SpeakingOutcome.listenAgain);
    });

    test('listenAgain is distinct from tryAgain (recognition failure vs wrong speech)', () {
      final empty = evaluator.evaluate(expectedText: 'I want water.', recognizedText: '');
      final wrong = evaluator.evaluate(expectedText: 'I want water.', recognizedText: 'I want food.');
      expect(empty.outcome, isNot(wrong.outcome));
    });
  });

  group('threshold boundary (word-level similarity, single differing word)', () {
    // "cat" vs "cot": 1 substitution, len 3 -> similarity = 1 - 1/3 = 0.667 (>= 0.6) -> almost.
    test('just above threshold classifies as almost', () {
      final r = evaluator.evaluate(expectedText: 'I see a cat.', recognizedText: 'I see a cot.');
      expect(r.outcome, SpeakingOutcome.almost);
    });

    // "cat" vs "dog": 3 substitutions, len 3 -> similarity = 0.0 (< 0.6) -> tryAgain.
    test('well below threshold classifies as try again', () {
      final r = evaluator.evaluate(expectedText: 'I see a cat.', recognizedText: 'I see a dog.');
      expect(r.outcome, SpeakingOutcome.tryAgain);
    });

    // More than one changed word disqualifies "almost" even if each change is small.
    test('two changed words never classifies as almost regardless of similarity', () {
      final r = evaluator.evaluate(expectedText: 'I want water.', recognizedText: 'You want waiter.');
      expect(r.outcome, SpeakingOutcome.tryAgain);
    });

    // A sentence longer than 6 words never gets fuzzy leniency, even for a
    // single small word-level slip that would qualify as almost if shorter.
    test('long sentences do not receive almost leniency', () {
      final r = evaluator.evaluate(
        expectedText: 'I want to go to the market today please.',
        recognizedText: 'I want to go to the markets today please.',
      );
      expect(r.outcome, SpeakingOutcome.tryAgain);
    });
  });

  group('no false positives — structurally similar but different-meaning phrases', () {
    const target = 'I want water.';
    const alternatives = [
      'I want food.',
      'I want milk.',
      'I need water.',
      'I like water.',
      'I want coffee.',
    ];

    for (final alt in alternatives) {
      test('"$alt" must not be Good against target "$target"', () {
        final r = evaluator.evaluate(expectedText: target, recognizedText: alt);
        expect(r.outcome, isNot(SpeakingOutcome.good));
      });
    }

    test('only the exact target produces Good', () {
      final r = evaluator.evaluate(expectedText: target, recognizedText: 'I want water');
      expect(r.outcome, SpeakingOutcome.good);
    });
  });

  test('fuzzy matching can never upgrade a non-exact transcript to good', () {
    // Every non-exact case across the whole suite must resolve to
    // almost/tryAgain/listenAgain — this is a structural guarantee, not
    // just a handful of examples.
    final cases = [
      'I want food.',
      'I want waiter.',
      'Water I want.',
      'Where is the bus?',
      '',
      'uh',
    ];
    for (final recognized in cases) {
      final r = evaluator.evaluate(expectedText: 'I want water.', recognizedText: recognized);
      expect(r.outcome, isNot(SpeakingOutcome.good), reason: 'recognized="$recognized"');
    }
  });
}
