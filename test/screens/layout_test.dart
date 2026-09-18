import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:english_kaliyona/core/services/app_services.dart';
import 'package:english_kaliyona/core/theme/app_theme.dart';
import 'package:english_kaliyona/data/local/database/app_database.dart';
import 'package:english_kaliyona/models/exercise.dart';
import 'package:english_kaliyona/models/lesson.dart';
import 'package:english_kaliyona/models/practice_attempt.dart';
import 'package:english_kaliyona/screens/conversation/conversation_list_screen.dart';
import 'package:english_kaliyona/screens/conversation/conversation_screen.dart';
import 'package:english_kaliyona/screens/home/home_screen.dart';
import 'package:english_kaliyona/screens/lesson/lesson_screen.dart';
import 'package:english_kaliyona/screens/progress/progress_screen.dart';
import 'package:english_kaliyona/screens/revision/daily_revision_screen.dart';
import 'package:english_kaliyona/screens/speaking/speaking_screen.dart';
import 'package:english_kaliyona/services/audio_service.dart';
import 'package:english_kaliyona/services/practice_controller.dart';
import 'package:english_kaliyona/services/speech_recognition_service.dart';
import 'package:english_kaliyona/widgets/practice_body.dart';
import '../fakes/fake_audio_backend.dart';
import '../fakes/fake_speech_backend.dart';

/// Responsive audit: every key screen on a small phone and with the phone's
/// "large text" setting. A RenderFlex overflow is reported as a test failure,
/// so simply pumping the screens is the assertion. (This checks layout only —
/// real Kannada glyph rendering can only be judged on a device.)
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase db;

  setUpAll(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    appServices = AppServices(
      database: db,
      audio: AudioService(FakeAudioBackend()),
      speech: SpeechRecognitionService(FakeSpeechBackend()),
    );
    // Some history, so Home shows its revision/mastery rows.
    await appServices.exerciseProgress.recordAttempt(PracticeAttempt(
      exerciseId: 'E00101',
      lessonId: 'L001',
      isCorrect: false,
      attemptedAt: DateTime.now().subtract(const Duration(days: 3)),
    ));
  });

  tearDownAll(() => db.close());

  const sizes = [Size(320, 568), Size(360, 740)];
  const textScales = [1.0, 1.3, 1.5];

  for (final size in sizes) {
    for (final scale in textScales) {
      testWidgets('no overflow at ${size.width.toInt()}x${size.height.toInt()}, text x$scale', (tester) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);

        Future<void> show(Widget screen) async {
          await tester.pumpWidget(MaterialApp(
            theme: AppTheme.light,
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(scale)),
              child: child!,
            ),
            home: screen,
          ));
          await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 120)));
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 400));
        }

        final lessons = (await tester.runAsync(() => appServices.lessons.loadAll()))!;
        final exercises = (await tester.runAsync(() => appServices.exercises.loadAll()))!;
        final conversations = (await tester.runAsync(() => appServices.conversations.loadAll()))!;

        // The lesson with the longest Kannada card is the worst case for LessonScreen.
        Lesson longest = lessons.first;
        var longestLen = 0;
        for (final l in lessons) {
          for (final c in l.contents) {
            if (c.kannadaText.length + c.englishText.length > longestLen) {
              longestLen = c.kannadaText.length + c.englishText.length;
              longest = l;
            }
          }
        }
        final longestCard = longest.contents.reduce(
            (a, b) => (a.kannadaText.length + a.englishText.length) >= (b.kannadaText.length + b.englishText.length) ? a : b);

        await show(const HomeScreen());
        await show(const ProgressScreen());
        await show(const ConversationListScreen());
        await show(const DailyRevisionScreen());
        await show(LessonScreen(lesson: Lesson(
          id: longest.id,
          level: longest.level,
          order: longest.order,
          topic: longest.topic,
          title: longest.title,
          kannadaTitle: longest.kannadaTitle,
          description: longest.description,
          estimatedMinutes: longest.estimatedMinutes,
          contents: [longestCard],
        )));
        await show(SpeakingScreen(lesson: longest, correct: 3, incorrect: 1, total: 4));

        // Every exercise type through the shared practice UI (longest question/option text is covered by the real data).
        for (final type in ExerciseType.values) {
          final sample = exercises.where((e) => e.type == type && e.conversationId == null).toList()
            ..sort((a, b) => (b.question.length + b.options.fold<int>(0, (n, o) => n + o.text.length))
                .compareTo(a.question.length + a.options.fold<int>(0, (n, o) => n + o.text.length)));
          final controller = PracticeController(exercises: [sample.first])..startSession();
          await show(PracticeBody(controller: controller, onContinue: () {}));
        }

        // Longest conversation lines: intro, then each kind of turn.
        final wordiest = conversations.reduce((a, b) =>
            a.turns.fold<int>(0, (n, t) => n + t.englishText.length) >= b.turns.fold<int>(0, (n, t) => n + t.englishText.length) ? a : b);
        await show(ConversationScreen(conversation: wordiest));
        await tester.tap(find.text('Start'));
        await tester.pump(const Duration(milliseconds: 400));
        await tester.tap(find.text('Continue')); // -> first learner turn (choose a reply)
        await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 120)));
        await tester.pump(const Duration(milliseconds: 400));
        expect(find.text('What do you say?'), findsOneWidget);

        await tester.pumpWidget(const SizedBox()); // dispose before the database closes
        await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 60)));
      });
    }
  }
}
