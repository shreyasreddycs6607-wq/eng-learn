import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:english_kaliyona/models/audio_state.dart';
import 'package:english_kaliyona/services/audio_service.dart';
import 'package:english_kaliyona/widgets/audio_player_button.dart';
import 'package:english_kaliyona/widgets/audio_speed_control.dart';
import '../fakes/fake_audio_backend.dart';

/// End-to-end-ish flow across the shared AudioService, standing in for the
/// "listen → pause → replay → slow → move to next exercise" path a learner
/// takes across Lesson/Practice/Speaking screens.
void main() {
  testWidgets('listen, pause, replay, slow, then a new screen stops the old audio', (tester) async {
    final backend = FakeAudioBackend();
    final service = AudioService(backend);
    const englishKey = Key('english-audio');
    const teluguKey = Key('telugu-audio');

    // Screen 1: a content card with two audio buttons (English + Telugu),
    // exactly like LessonScreen renders.
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: Column(
          children: [
            AudioPlayerButton(
              key: englishKey,
              audioPath: 'audio/english/water.mp3',
              label: 'English',
              audioService: service,
            ),
            AudioPlayerButton(
              key: teluguKey,
              audioPath: 'audio/telugu/water_explanation.mp3',
              label: 'Telugu explanation',
              showLabel: true,
              audioService: service,
            ),
            AudioSpeedControl(audioService: service),
          ],
        ),
      ),
    ));

    // Listen (tap the English button specifically).
    await tester.tap(find.byKey(englishKey));
    await tester.pump();
    expect(service.state.status, AudioPlaybackStatus.playing);
    expect(service.state.currentAsset, 'audio/english/water.mp3');

    // Pause — only the English button shows the pause icon now.
    expect(find.descendant(of: find.byKey(englishKey), matching: find.byIcon(Icons.pause_rounded)), findsOneWidget);
    await tester.tap(find.byKey(englishKey));
    await tester.pump();
    expect(service.state.status, AudioPlaybackStatus.paused);

    // Resume, then slow down — speed change takes effect immediately.
    await tester.tap(find.byKey(englishKey));
    await tester.pump();
    await tester.tap(find.text('Slow'));
    await tester.pump();
    expect(service.state.speed, 0.75);
    expect(backend.speeds, contains(0.75));

    // Tap the Telugu button while English is still playing — never two
    // clips active at once.
    await tester.tap(find.byKey(teluguKey));
    await tester.pump();
    expect(service.state.currentAsset, 'audio/telugu/water_explanation.mp3');
    expect(backend.playedAssets.last, 'audio/telugu/water_explanation.mp3');
    // The English button reverted to idle since it's no longer the active clip.
    expect(find.descendant(of: find.byKey(englishKey), matching: find.byIcon(Icons.volume_up_rounded)),
        findsOneWidget);

    // Screen 2 (e.g. moving to the next exercise) stops the lesson's audio.
    await service.stop();
    expect(service.state.status, AudioPlaybackStatus.idle);
    expect(service.state.currentAsset, isNull);
  });
}
