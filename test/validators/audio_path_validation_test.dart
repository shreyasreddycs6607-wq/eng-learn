import 'package:flutter_test/flutter_test.dart';
import 'package:english_kaliyona/data/local/content/curriculum_validator.dart';
import 'package:english_kaliyona/models/exercise.dart';
import 'package:english_kaliyona/models/exercise_answer.dart';
import 'package:english_kaliyona/models/exercise_option.dart';
import 'package:english_kaliyona/models/lesson.dart';
import 'package:english_kaliyona/models/lesson_content.dart';
import 'package:english_kaliyona/models/sentence_pattern.dart';
import 'package:english_kaliyona/models/vocabulary.dart';

Lesson _lesson({String id = 'L001'}) => Lesson(
      id: id,
      level: 1,
      order: 1,
      topic: 'greetings',
      title: 'Hello',
      kannadaTitle: 'ನಮಸ್ಕಾರ',
      description: 'd',
      estimatedMinutes: 5,
    );

Vocabulary _vocab({String? englishAudio}) => Vocabulary(
      id: 'V001',
      english: 'Water',
      kannada: 'ನೀರು',
      category: 'food_drink',
      difficulty: 1,
      englishAudio: englishAudio,
    );

List<String> _validateVocab(String? path) => CurriculumValidator.validate(
      lessons: [_lesson()],
      vocabulary: [_vocab(englishAudio: path)],
      patterns: const [],
      exercises: const [],
      contents: const [],
    );

void main() {
  group('audio path validation', () {
    test('null is valid — no audio configured', () {
      expect(_validateVocab(null), isEmpty);
    });

    test('a well-formed local path is valid', () {
      expect(_validateVocab('audio/english/water.mp3'), isEmpty);
    });

    test('empty string is rejected, never treated as null', () {
      expect(_validateVocab(''), isNotEmpty);
    });

    test('http URL is rejected', () {
      expect(_validateVocab('http://example.com/water.mp3'), isNotEmpty);
    });

    test('https URL is rejected', () {
      expect(_validateVocab('https://example.com/water.mp3'), isNotEmpty);
    });

    test('path traversal is rejected', () {
      expect(_validateVocab('audio/english/../../etc/passwd.mp3'), isNotEmpty);
    });

    test('unix absolute path is rejected', () {
      expect(_validateVocab('/etc/audio/water.mp3'), isNotEmpty);
    });

    test('windows absolute path is rejected', () {
      expect(_validateVocab(r'C:\audio\water.mp3'), isNotEmpty);
    });

    test('path missing the audio/ prefix is rejected', () {
      expect(_validateVocab('water.mp3'), isNotEmpty);
    });

    test('unsupported extension is rejected', () {
      expect(_validateVocab('audio/english/water.txt'), isNotEmpty);
    });

    test('wav, m4a, aac and ogg are all accepted', () {
      for (final ext in ['wav', 'm4a', 'aac', 'ogg']) {
        expect(_validateVocab('audio/english/water.$ext'), isEmpty, reason: ext);
      }
    });
  });

  group('listening/speaking require audio', () {
    Exercise exercise(ExerciseType type, {String? audioPath}) => Exercise(
          id: 'E001',
          lessonId: 'L001',
          type: type,
          order: 1,
          question: 'q',
          audioPath: audioPath,
          options: type == ExerciseType.speaking
              ? const []
              : const [ExerciseOption(id: 'o1', text: 'Water')],
          answer: type == ExerciseType.speaking
              ? const TextAnswer(value: 'Water')
              : const OptionIdAnswer(value: 'o1'),
        );

    List<String> validateExercise(Exercise e) => CurriculumValidator.validate(
          lessons: [_lesson()],
          vocabulary: const [],
          patterns: const [],
          exercises: [e],
          contents: const [],
        );

    test('listening without audioPath is rejected', () {
      expect(validateExercise(exercise(ExerciseType.listening)), isNotEmpty);
    });

    test('listening with audioPath is valid', () {
      expect(validateExercise(exercise(ExerciseType.listening, audioPath: 'audio/english/water.mp3')), isEmpty);
    });

    test('speaking without audioPath is rejected', () {
      expect(validateExercise(exercise(ExerciseType.speaking)), isNotEmpty);
    });

    test('multipleChoice without audioPath is valid (audio is optional there)', () {
      expect(validateExercise(exercise(ExerciseType.multipleChoice)), isEmpty);
    });
  });

  test('sentence pattern example audio is validated the same way', () {
    const pattern = SentencePattern(
      id: 'SP001',
      pattern: 'p',
      kannadaPattern: 'kp',
      englishTemplate: 'e',
      difficulty: 1,
      examples: [
        SentenceExample(id: 'SE1', kannada: 'k1', english: 'e1', englishAudio: 'audio/english/a.mp3'),
        SentenceExample(id: 'SE2', kannada: 'k2', english: 'e2', englishAudio: 'https://bad.example/a.mp3'),
      ],
    );

    final errors = CurriculumValidator.validate(
      lessons: [_lesson()],
      vocabulary: const [],
      patterns: [pattern],
      exercises: const [],
      contents: const [],
    );

    expect(errors, isNotEmpty);
  });

  test('content record audio (english + telugu) is validated the same way', () {
    const content = LessonContent(
      id: 'C001',
      lessonId: 'L001',
      type: ContentType.word,
      kannadaText: 'ನೀರು',
      englishText: 'Water',
      englishAudio: 'audio/english/water.mp3',
      teluguAudio: 'not/a/valid/path.mp3',
      order: 1,
    );

    final errors = CurriculumValidator.validate(
      lessons: [_lesson()],
      vocabulary: const [],
      patterns: const [],
      exercises: const [],
      contents: [content],
    );

    expect(errors, isNotEmpty);
  });
}
