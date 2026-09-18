import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:english_kaliyona/models/audio_state.dart';
import 'package:english_kaliyona/services/audio_service.dart';
import 'package:english_kaliyona/widgets/audio_player_button.dart';
import '../fakes/fake_audio_backend.dart';

/// Regression tests from the production audit: rapid taps never leave the
/// audio state wrong, and audio that isn't bundled is hidden, not broken.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late FakeAudioBackend backend;
  late AudioService service;

  setUp(() {
    backend = FakeAudioBackend();
    service = AudioService(backend);
  });

  tearDown(() => service.dispose());

  group('rapid taps', () {
    test('two quick plays: only the last one plays and the state describes it', () async {
      final first = service.play('audio/english/a.wav');
      final second = service.play('audio/english/b.wav');

      expect(await first, isFalse); // superseded
      expect(await second, isTrue);
      expect(backend.playedAssets, ['audio/english/b.wav']);
      expect(service.state.currentAsset, 'audio/english/b.wav');
      expect(service.state.status, AudioPlaybackStatus.playing);
    });

    test('stop() while a clip is still starting prevents it from starting at all', () async {
      final pending = service.play('audio/english/a.wav');
      await service.stop();

      expect(await pending, isFalse);
      expect(backend.playedAssets, isEmpty);
      expect(service.state.status, AudioPlaybackStatus.idle);
    });

    test('a failed older clip does not overwrite the newer clip\'s state', () async {
      backend.failOnAsset = 'audio/english/missing.wav';
      final older = service.play('audio/english/missing.wav');
      final newer = service.play('audio/english/b.wav');
      await older;
      await newer;

      expect(service.state.status, AudioPlaybackStatus.playing);
      expect(service.state.currentAsset, 'audio/english/b.wav');
    });
  });

  group('bundled audio', () {
    test('before the manifest is read, nothing is hidden by mistake', () {
      expect(service.isBundled('audio/english/anything.wav'), isTrue);
    });

    test('once read, only bundled clips count as present', () async {
      await service.loadBundledAssets(() async => ['assets/audio/english/hello.wav']);

      expect(service.hasAudio('audio/english/hello.wav'), isTrue);
      expect(service.hasAudio('audio/english/water_telugu.mp3'), isFalse);
      expect(service.hasAudio(null), isFalse);
    });

    test('a manifest failure keeps everything visible rather than hiding audio', () async {
      await service.loadBundledAssets(() async => throw Exception('no manifest'));
      expect(service.isBundled('audio/english/hello.wav'), isTrue);
    });

    testWidgets('the play button appears for a bundled clip and disappears for a missing one', (tester) async {
      await service.loadBundledAssets(() async => ['assets/audio/english/hello.wav']);

      Future<void> show(String path) => tester.pumpWidget(MaterialApp(
            home: Scaffold(body: AudioPlayerButton(audioPath: path, label: 'audio', audioService: service)),
          ));

      await show('audio/english/hello.wav');
      expect(find.byIcon(Icons.volume_up_rounded), findsOneWidget);

      await show('audio/telugu/water_telugu.mp3');
      expect(find.byIcon(Icons.volume_up_rounded), findsNothing);
      expect(find.byIcon(Icons.refresh_rounded), findsNothing); // no broken/error state either
    });
  });
}
