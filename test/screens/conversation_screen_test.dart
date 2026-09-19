import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:english_kaliyona/core/services/app_services.dart';
import 'package:english_kaliyona/data/local/database/app_database.dart';
import 'package:english_kaliyona/screens/conversation/conversation_screen.dart';
import 'package:english_kaliyona/services/audio_service.dart';
import 'package:english_kaliyona/services/speech_recognition_service.dart';
import '../fakes/fake_audio_backend.dart';
import '../fakes/fake_speech_backend.dart';

/// Drives the real CONV001 (bundled content, real controllers, in-memory
/// database, fake audio/speech engines) through the screen: intro, a wrong
/// then right reply, a spoken reply, and on to the next line.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('a conversation plays through with retry, speaking and progress recorded', (tester) async {
    tester.view.physicalSize = const Size(800, 1600); // room for every answer option, as on a real phone
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    final speechBackend = FakeSpeechBackend();
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    appServices = AppServices(
      database: db,
      audio: AudioService(FakeAudioBackend()),
      speech: SpeechRecognitionService(speechBackend),
    );

    // Real IO (assets, sqlite) completes on the real event loop, not FakeAsync.
    Future<void> settle() async {
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 100)));
      await tester.pump();
    }

    final conversation = (await tester.runAsync(() => appServices.conversations.loadAll()))!.first;
    await tester.pumpWidget(MaterialApp(home: ConversationScreen(conversation: conversation)));
    await settle();

    // Intro shows the Kannada situation; one obvious action.
    expect(find.text('At Home'), findsOneWidget);
    expect(find.textContaining('ನೀವು ಮನೆಯಲ್ಲಿ'), findsOneWidget);
    await tester.tap(find.text('Start'));
    await settle();

    // Turn 1: a line from family — listen, then continue.
    expect(find.text('Are you hungry?'), findsOneWidget);
    await tester.tap(find.text('Continue'));
    await settle();

    // Turn 2, choose a reply: wrong first -> correction + retry, stays on the turn.
    expect(find.text('What do you say?'), findsOneWidget);
    await tester.tap(find.text('No, I am going home.'));
    await tester.pump();
    await tester.tap(find.text('CHECK'));
    await settle();
    expect(find.text('Not quite.'), findsOneWidget);
    expect(find.text('Try Again'), findsOneWidget);
    expect(find.text('2 / 6'), findsOneWidget);

    await tester.tap(find.text('Try Again'));
    await settle();
    await tester.tap(find.text('Yes, I want food.').first);
    await tester.pump();
    await tester.tap(find.text('CHECK'));
    await settle();
    expect(find.text('Correct!'), findsOneWidget);

    // Correct -> speak step.
    await tester.tap(find.text('Continue'));
    await settle();
    expect(find.text('Say this:'), findsOneWidget);
    await tester.tap(find.byIcon(Icons.mic_rounded));
    await settle();
    speechBackend.emitResult('Yes, I want food', isFinal: true, confidence: 0.9);
    await settle();
    expect(find.text('Correct!'), findsOneWidget);

    await tester.tap(find.text('Continue'));
    await settle();
    expect(find.text('Do you want water?'), findsOneWidget);
    expect(find.text('3 / 6'), findsOneWidget);

    // Progress went through the one shared system: 2 choice attempts, 1 spoken.
    final choice = await tester.runAsync(() => appServices.exerciseProgress.getByExerciseId('ECV0102C'));
    expect((choice!.attemptCount, choice.correctCount, choice.incorrectCount), (2, 1, 1));
    final spoken = await tester.runAsync(() => appServices.exerciseProgress.getByExerciseId('ECV0102S'));
    expect((spoken!.attemptCount, spoken.correctCount), (1, 1));

    await tester.pumpWidget(const SizedBox());
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 50)));
    await tester.runAsync(db.close);
  });
}
