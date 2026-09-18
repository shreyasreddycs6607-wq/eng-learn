import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:english_kaliyona/core/services/app_services.dart';
import 'package:english_kaliyona/data/local/database/app_database.dart';
import 'package:english_kaliyona/models/exercise_answer.dart';
import 'package:english_kaliyona/models/lesson.dart';
import 'package:english_kaliyona/screens/lesson/lesson_screen.dart';
import 'package:english_kaliyona/screens/practice/practice_screen.dart';
import 'package:english_kaliyona/screens/speaking/speaking_screen.dart';
import 'package:english_kaliyona/services/audio_service.dart';
import 'package:english_kaliyona/services/speech_recognition_service.dart';
import '../fakes/fake_audio_backend.dart';
import '../fakes/fake_speech_backend.dart';

/// Navigation audit: Lesson -> Practice -> Speaking and back, including the
/// fast double taps that used to skip a lesson card, push Speaking twice, and
/// leave a dead, unanswerable practice screen behind when going Back.
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

  tearDownAll(() => db.close());

  /// Real time must pass for the button's double-tap window (it uses the wall clock).
  Future<void> pause(WidgetTester tester, [int ms = 700]) async {
    await tester.runAsync(() => Future<void>.delayed(Duration(milliseconds: ms)));
    await tester.pump();
  }

  /// Lets a route transition finish without waiting on loading spinners
  /// (pumpAndSettle would wait for the practice screen's asset load forever).
  Future<void> route(WidgetTester tester) async {
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
  }

  Future<Lesson> openLesson(WidgetTester tester) async {
    final lesson = (await tester.runAsync(() => appServices.lessons.byId('L001')))!;
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: Builder(
          builder: (context) => ElevatedButton(
            onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => LessonScreen(lesson: lesson))),
            child: const Text('Open'),
          ),
        ),
      ),
    ));
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    return lesson;
  }

  testWidgets('a fast double tap on Continue moves exactly one lesson card', (tester) async {
    final lesson = await openLesson(tester);
    final total = lesson.contents.length;
    expect(find.text('1 / $total'), findsOneWidget);

    await tester.tap(find.text('Continue'));
    await tester.tap(find.text('Continue'), warnIfMissed: false); // same instant
    await tester.pump();

    expect(find.text('2 / $total'), findsOneWidget);
    expect(find.text('3 / $total'), findsNothing);
  });

  testWidgets('lesson -> practice -> speaking opens each once, and Back returns to the lesson', (tester) async {
    final lesson = await openLesson(tester);

    // Through every content card; the last Continue is double-tapped.
    for (var i = 0; i < lesson.contents.length; i++) {
      await pause(tester);
      await tester.tap(find.text('Continue'));
      if (i == lesson.contents.length - 1) await tester.tap(find.text('Continue'), warnIfMissed: false);
      await route(tester);
    }
    await pause(tester); // the practice screen loads its exercises
    expect(find.byType(PracticeScreen), findsOneWidget);

    // Answer every practice exercise correctly.
    final exercises = (await tester.runAsync(() => appServices.exercises.forLesson(lesson.id)))!;
    for (var i = 0; i < exercises.length; i++) {
      final e = exercises[i];
      final correct = e.options.firstWhere((o) => o.id == (e.answer as OptionIdAnswer).value).text;
      await tester.tap(find.widgetWithText(OutlinedButton, correct).first);
      await tester.pump();
      await tester.tap(find.text('CHECK'));
      await pause(tester); // the answer is recorded in the background
      expect(find.text('✓ Correct!'), findsOneWidget, reason: e.id);

      await tester.tap(find.text('Continue'));
      if (i == exercises.length - 1) await tester.tap(find.text('Continue'), warnIfMissed: false); // double tap on the last one
      await route(tester);
    }

    // Speaking opened exactly once, replacing the finished practice screen.
    expect(find.text('Say:'), findsOneWidget);
    expect(find.byType(SpeakingScreen), findsOneWidget);
    expect(find.byType(PracticeScreen), findsNothing);

    await tester.tap(find.byIcon(Icons.arrow_back_rounded));
    await route(tester);

    // Back lands on the lesson — not on a second Speaking screen or a dead practice screen.
    expect(find.byType(SpeakingScreen), findsNothing);
    expect(find.byType(PracticeScreen), findsNothing);
    expect(find.byType(LessonScreen), findsOneWidget);
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 100)));
  });
}
