import 'package:flutter_test/flutter_test.dart';
import 'package:english_kaliyona/data/local/content/content_service.dart';
import 'package:english_kaliyona/data/repositories/exercise_repository.dart';
import 'package:english_kaliyona/data/repositories/lesson_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('bundled lesson JSON loads and is ordered', () async {
    final repo = LessonRepository(ContentService());
    final lessons = await repo.loadAll();

    expect(lessons, isNotEmpty);
    expect(lessons.length, greaterThanOrEqualTo(3));
    for (var i = 1; i < lessons.length; i++) {
      expect(lessons[i].order, greaterThan(lessons[i - 1].order));
    }
  });

  test('lesson content is attached and ordered per lesson', () async {
    final repo = LessonRepository(ContentService());
    final lesson = (await repo.byId('L001'))!;

    expect(lesson.contents, isNotEmpty);
    for (var i = 1; i < lesson.contents.length; i++) {
      expect(lesson.contents[i].order, greaterThan(lesson.contents[i - 1].order));
    }
  });

  test('bundled exercises reference real lessons and answers are among options', () async {
    final lessonRepo = LessonRepository(ContentService());
    final exerciseRepo = ExerciseRepository(ContentService());
    final lessonIds = (await lessonRepo.loadAll()).map((l) => l.id).toSet();
    final exercises = await exerciseRepo.loadAll();

    expect(exercises, isNotEmpty);
    for (final e in exercises) {
      expect(lessonIds.contains(e.lessonId), isTrue, reason: '${e.id} references unknown lesson ${e.lessonId}');
    }
  });
}
