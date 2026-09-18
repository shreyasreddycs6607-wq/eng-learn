import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:english_kaliyona/services/audio_service.dart';
import 'package:english_kaliyona/widgets/audio_player_button.dart';
import '../fakes/fake_audio_backend.dart';

Widget _wrap(Widget child) => MaterialApp(home: Scaffold(body: Center(child: child)));

void main() {
  testWidgets('renders nothing when audio is unavailable (null path)', (tester) async {
    final service = AudioService(FakeAudioBackend());
    await tester.pumpWidget(_wrap(AudioPlayerButton(
      audioPath: null,
      label: 'Telugu explanation',
      showLabel: true,
      audioService: service,
    )));

    expect(find.byType(AudioPlayerButton), findsOneWidget);
    expect(find.byIcon(Icons.volume_up_rounded), findsNothing);
    expect(find.text('Telugu explanation'), findsNothing);
  });

  testWidgets('shows a play button when audio is available, and playing state after tap', (tester) async {
    final backend = FakeAudioBackend();
    final service = AudioService(backend);
    await tester.pumpWidget(_wrap(AudioPlayerButton(
      audioPath: 'audio/english/water.mp3',
      label: 'English pronunciation',
      audioService: service,
    )));

    expect(find.byIcon(Icons.volume_up_rounded), findsOneWidget);

    await tester.tap(find.byType(AudioPlayerButton));
    await tester.pump();

    expect(backend.playedAssets, ['audio/english/water.mp3']);
    expect(find.byIcon(Icons.pause_rounded), findsOneWidget);
  });

  testWidgets('a playback error shows a retry affordance instead of crashing', (tester) async {
    final backend = FakeAudioBackend()..failOnAsset = 'audio/english/broken.mp3';
    final service = AudioService(backend);
    await tester.pumpWidget(_wrap(AudioPlayerButton(
      audioPath: 'audio/english/broken.mp3',
      label: 'audio',
      showLabel: true,
      audioService: service,
    )));

    await tester.tap(find.byType(AudioPlayerButton));
    await tester.pump();

    expect(tester.takeException(), isNull);
    expect(find.text('Couldn\'t play audio'), findsOneWidget);
  });

  testWidgets('tapping while playing pauses, tapping again resumes', (tester) async {
    final backend = FakeAudioBackend();
    final service = AudioService(backend);
    await tester.pumpWidget(_wrap(AudioPlayerButton(
      audioPath: 'audio/english/water.mp3',
      label: 'English pronunciation',
      audioService: service,
    )));

    await tester.tap(find.byType(AudioPlayerButton));
    await tester.pump();
    expect(find.byIcon(Icons.pause_rounded), findsOneWidget);

    await tester.tap(find.byType(AudioPlayerButton));
    await tester.pump();
    expect(backend.paused, isTrue);
    expect(find.byIcon(Icons.play_arrow_rounded), findsOneWidget);
  });
}
