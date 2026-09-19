import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:english_kaliyona/core/services/app_services.dart';
import 'package:english_kaliyona/data/local/database/app_database.dart';
import 'package:english_kaliyona/screens/lesson/lesson_screen.dart';
import 'package:english_kaliyona/screens/progress/progress_screen.dart';
import 'package:english_kaliyona/services/audio_service.dart';
import 'package:english_kaliyona/services/speech_recognition_service.dart';
import '../fakes/fake_audio_backend.dart';
import '../fakes/fake_reminder_backend.dart';
import '../fakes/fake_speech_backend.dart';

/// A finished lesson can be done again from the Progress screen.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase db;
  final reminder = FakeReminderBackend();

  setUpAll(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    appServices = AppServices(
      database: db,
      audio: AudioService(FakeAudioBackend()),
      speech: SpeechRecognitionService(FakeSpeechBackend()),
      reminderBackend: reminder,
    );
    await appServices.progress.completeLesson(lessonId: 'L001', correctInPass: 4, incorrectInPass: 0);
  });

  tearDownAll(() => db.close());

  Future<void> settle(WidgetTester tester) async {
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 120)));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
  }

  testWidgets('a finished lesson opens again, an unfinished one does not, and a double tap opens one', (tester) async {
    tester.view.physicalSize = const Size(800, 4000); // tall enough that the lazy list builds every row
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    final l1 = (await tester.runAsync(() => appServices.lessons.byId('L001')))!;
    final l2 = (await tester.runAsync(() => appServices.lessons.byId('L002')))!;

    await tester.pumpWidget(const MaterialApp(home: ProgressScreen()));
    await settle(tester);
    expect(find.text('Tap a finished lesson to do it again.'), findsOneWidget);

    // Not finished yet: nothing happens.
    await tester.tap(find.text(l2.title));
    await settle(tester);
    expect(find.byType(LessonScreen), findsNothing);

    // Finished: opens the lesson — a double tap still opens exactly one.
    await tester.tap(find.text(l1.title));
    await tester.tap(find.text(l1.title), warnIfMissed: false);
    await settle(tester);
    expect(find.byType(LessonScreen), findsOneWidget);
    expect(find.text('1 / ${l1.contents.length}'), findsOneWidget);

    // Back returns to the progress list (not to a second lesson screen).
    await tester.tap(find.byIcon(Icons.arrow_back_rounded));
    await settle(tester);
    expect(find.byType(LessonScreen), findsNothing);
    expect(find.byType(ProgressScreen), findsOneWidget);

    await tester.pumpWidget(const SizedBox());
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 60)));
  });

  group('daily reminder switch', () {
    Future<void> open(WidgetTester tester) async {
      tester.view.physicalSize = const Size(800, 4000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(const MaterialApp(home: ProgressScreen()));
      await settle(tester);
    }

    testWidgets('turning it on schedules 6:00 PM, and turning it off cancels it', (tester) async {
      await open(tester);
      expect(find.text('Daily reminder'), findsOneWidget);
      expect(find.textContaining('Off.'), findsOneWidget);

      await tester.tap(find.byType(Switch));
      await settle(tester);
      expect(reminder.scheduled, [18 * 60]);
      expect(find.text('Every day at 6:00 PM'), findsOneWidget);
      expect(find.text('Change time'), findsOneWidget);

      final cancelsBefore = reminder.cancelCalls;
      await tester.tap(find.byType(Switch));
      await settle(tester);
      expect(reminder.cancelCalls, cancelsBefore + 1);
      expect(find.textContaining('Off.'), findsOneWidget);
      expect(find.text('Change time'), findsNothing);

      await tester.pumpWidget(const SizedBox());
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 60)));
    });

    testWidgets('a refused permission keeps it off and explains why', (tester) async {
      reminder.permissionGranted = false;
      addTearDown(() => reminder.permissionGranted = true);
      final scheduledBefore = reminder.scheduled.length;
      await open(tester);

      await tester.tap(find.byType(Switch));
      await settle(tester);

      expect(reminder.scheduled.length, scheduledBefore);
      expect(find.textContaining('Off.'), findsOneWidget);
      expect(find.textContaining('turned off for this app'), findsOneWidget);

      await tester.pumpWidget(const SizedBox());
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 60)));
    });
  });
}
