import 'package:flutter_test/flutter_test.dart';
import 'package:english_kaliyona/data/local/content/content_service.dart';
import 'package:english_kaliyona/data/local/content/curriculum_validator.dart';
import 'package:english_kaliyona/data/repositories/exercise_repository.dart';
import 'package:english_kaliyona/data/repositories/lesson_repository.dart';
import 'package:english_kaliyona/data/repositories/sentence_pattern_repository.dart';
import 'package:english_kaliyona/data/repositories/vocabulary_repository.dart';

/// The Phase 4 schema-contract gate: loads the real bundled curriculum and
/// runs the full cross-reference / content-quality validation pass. A
/// failure here means the content contract was broken, not just a typo.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('bundled curriculum passes full validation with zero issues', () async {
    final content = ContentService();
    final lessons = LessonRepository(content);

    final errors = CurriculumValidator.validate(
      lessons: await lessons.loadAll(),
      vocabulary: await VocabularyRepository(content).loadAll(),
      patterns: await SentencePatternRepository(content).loadAll(),
      exercises: await ExerciseRepository(content).loadAll(),
      contents: await lessons.loadAllContent(),
    );

    expect(errors, isEmpty, reason: errors.join('\n'));
  });

  test('content manifest declares the expected schema/languages', () async {
    final manifest = await ContentService().manifest();
    expect(manifest.schemaVersion, 1);
    expect(manifest.language, 'kn');
    expect(manifest.secondaryAudioLanguage, 'te');
    expect(manifest.learningLanguage, 'en');
  });

  test('at least 10 lessons are fully playable (have content and exercises)', () async {
    final content = ContentService();
    final lessons = await LessonRepository(content).loadAll();
    final exercises = await ExerciseRepository(content).loadAll();
    final exerciseLessonIds = exercises.map((e) => e.lessonId).toSet();

    final playable = lessons.where((l) => l.contents.isNotEmpty && exerciseLessonIds.contains(l.id));
    expect(playable.length, greaterThanOrEqualTo(10));
  });

  test('all three curriculum levels are represented', () async {
    final lessons = await LessonRepository(ContentService()).loadAll();
    final levels = lessons.map((l) => l.level).toSet();
    expect(levels, {1, 2, 3});
  });
}
