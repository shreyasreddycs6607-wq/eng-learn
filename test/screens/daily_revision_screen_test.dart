import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:english_kaliyona/core/services/app_services.dart';
import 'package:english_kaliyona/data/local/database/app_database.dart';
import 'package:english_kaliyona/models/practice_attempt.dart';
import 'package:english_kaliyona/screens/revision/daily_revision_screen.dart';
import 'package:english_kaliyona/services/audio_service.dart';
import 'package:english_kaliyona/services/speech_recognition_service.dart';
import '../fakes/fake_audio_backend.dart';
import '../fakes/fake_speech_backend.dart';

/// Today's Revision through the real screen, using the shared PracticeBody,
/// the real curriculum and an in-memory database.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase db;

  setUpAll(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    appServices = AppServices(
      database: db,
      audio: AudioService(FakeAudioBackend()),
      speech: SpeechRecognitionService(FakeSpeechBackend()),
    );
  });

  Future<void> settle(WidgetTester tester) async {
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 100)));
    await tester.pump();
  }

  testWidgets('with no practice history it says so and offers only a way back', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: DailyRevisionScreen()));
    await settle(tester);

    expect(find.text('No revision yet'), findsOneWidget);
    expect(find.text('Back'), findsOneWidget);
    expect(find.text('Start Revision'), findsNothing);
  });

  testWidgets('a due item runs as a normal practice session and reschedules on success', (tester) async {
    // A wrong answer three days ago: due 2 days ago, so overdue.
    await tester.runAsync(() => appServices.exerciseProgress.recordAttempt(PracticeAttempt(
          exerciseId: 'E00101',
          lessonId: 'L001',
          isCorrect: false,
          attemptedAt: DateTime.now().subtract(const Duration(days: 3)),
        )));

    await tester.pumpWidget(const MaterialApp(home: DailyRevisionScreen()));
    await settle(tester);

    expect(find.text("Today's Revision"), findsOneWidget);
    expect(find.textContaining('1 item'), findsOneWidget);
    await tester.tap(find.text('Start Revision'));
    await tester.pump();

    // The same exercise UI the lessons use.
    expect(find.text('What does this mean?'), findsOneWidget);
    await tester.tap(find.text('Hello'));
    await tester.pump();
    await tester.tap(find.text('CHECK'));
    await settle(tester);
    expect(find.text('✓ Correct!'), findsOneWidget);

    await tester.tap(find.text('Continue'));
    await tester.pump();
    expect(find.text('Revision Complete!'), findsOneWidget);
    expect(find.textContaining('all 1 right'), findsOneWidget);

    final p = await tester.runAsync(() => appServices.exerciseProgress.getByExerciseId('E00101'));
    expect((p!.attemptCount, p.correctCount, p.incorrectCount, p.reviewLevel), (2, 1, 1, 1));
    expect(p.nextReviewAt!.isAfter(DateTime.now()), isTrue); // no longer due

    // Practising counted as a learning day — through the one existing streak.
    final profile = await tester.runAsync(() => appServices.progress.loadProfile());
    expect(profile!.streak, 1);

    await tester.pumpWidget(const SizedBox());
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 50)));
  });

  testWidgets('once nothing is due it says the learner is all caught up', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: DailyRevisionScreen()));
    await settle(tester);

    expect(find.text("You're all caught up!"), findsOneWidget);
  });

  tearDownAll(() => db.close());
}
