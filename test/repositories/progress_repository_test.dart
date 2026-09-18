import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:english_kaliyona/data/local/database/app_database.dart';
import 'package:english_kaliyona/data/repositories/progress_repository.dart';
import 'package:english_kaliyona/models/progress.dart';

void main() {
  late AppDatabase db;
  late ProgressRepository repo;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    repo = ProgressRepository(db);
  });

  tearDown(() => db.close());

  test('unstarted lesson has no progress row', () async {
    expect(await repo.loadLessonProgress('l1'), isNull);
  });

  test('saving progress round-trips and persists completion/attempts', () async {
    await repo.saveLessonProgress(const LessonProgress(
      lessonId: 'l1',
      completed: true,
      attempts: 1,
      correctAnswers: 3,
      incorrectAnswers: 1,
    ));

    final loaded = await repo.loadLessonProgress('l1');
    expect(loaded!.completed, isTrue);
    expect(loaded.attempts, 1);
    expect(loaded.correctAnswers, 3);
  });

  test('re-saving the same lesson updates rather than duplicates', () async {
    await repo.saveLessonProgress(const LessonProgress(lessonId: 'l1', attempts: 1));
    await repo.saveLessonProgress(const LessonProgress(lessonId: 'l1', completed: true, attempts: 2));

    final all = await repo.loadAllLessonProgress();
    expect(all.length, 1);
    expect(all['l1']!.attempts, 2);
  });

  test('user profile (streak/current lesson) persists', () async {
    await repo.saveProfile(UserProfile(currentLessonId: 'l2', streak: 4, lastLearningDate: DateTime(2026, 9, 17)));
    final profile = await repo.loadProfile();
    expect(profile.currentLessonId, 'l2');
    expect(profile.streak, 4);
  });

  test('resetAll clears both tables', () async {
    await repo.saveLessonProgress(const LessonProgress(lessonId: 'l1', completed: true));
    await repo.saveProfile(const UserProfile(streak: 5));

    await repo.resetAll();

    expect(await repo.loadAllLessonProgress(), isEmpty);
    expect((await repo.loadProfile()).streak, 0);
  });
}
