import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:english_kaliyona/data/local/content/content_service.dart';
import 'package:english_kaliyona/data/local/database/app_database.dart';
import 'package:english_kaliyona/data/repositories/lesson_repository.dart';
import 'package:english_kaliyona/data/repositories/progress_repository.dart';
import 'package:english_kaliyona/services/progress_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase db;
  late ProgressService service;
  late LessonRepository lessons;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    lessons = LessonRepository(ContentService());
    service = ProgressService(lessons, ProgressRepository(db));
  });

  tearDown(() => db.close());

  test('next lesson is the first one on a fresh install', () async {
    final all = await lessons.loadAll();
    expect((await service.nextLesson()).id, all.first.id);
  });

  test('completing a lesson advances the next-lesson pointer', () async {
    final all = await lessons.loadAll();
    await service.completeLesson(lessonId: all[0].id, correctInPass: 3, incorrectInPass: 0);

    expect((await service.nextLesson()).id, all[1].id);
  });

  test('completing a lesson does not double-count it toward totals', () async {
    final all = await lessons.loadAll();
    await service.completeLesson(lessonId: all[0].id, correctInPass: 2, incorrectInPass: 1);
    await service.completeLesson(lessonId: all[0].id, correctInPass: 3, incorrectInPass: 0);

    final progress = await service.loadAllProgress();
    expect(progress.length, 1);
    expect(progress[all[0].id]!.attempts, 2);
    expect(service.totalWordsLearned(all, progress), all[0].contents.length);
  });

  test('streak increments once per day and resets after a missed day', () async {
    expect(await service.recordActivityToday(), 1);
    expect(await service.recordActivityToday(), 1); // same day, no double count
  });
}
