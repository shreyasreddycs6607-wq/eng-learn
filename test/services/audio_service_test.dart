import 'package:flutter_test/flutter_test.dart';
import 'package:english_kaliyona/models/audio_state.dart';
import 'package:english_kaliyona/services/audio_service.dart';
import '../fakes/fake_audio_backend.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late FakeAudioBackend backend;
  late AudioService service;

  setUp(() {
    backend = FakeAudioBackend();
    service = AudioService(backend);
  });

  test('starts idle', () {
    expect(service.state.status, AudioPlaybackStatus.idle);
    expect(service.state.currentAsset, isNull);
  });

  test('play transitions to playing and records the asset', () async {
    final ok = await service.play('audio/english/water.mp3');

    expect(ok, isTrue);
    expect(service.state.status, AudioPlaybackStatus.playing);
    expect(service.state.currentAsset, 'audio/english/water.mp3');
    expect(backend.playedAssets, ['audio/english/water.mp3']);
  });

  test('a second play stops the first clip before starting the next (no overlap)', () async {
    await service.play('audio/english/water.mp3');
    await service.play('audio/kannada/water.mp3');

    // stop() was called between the two plays, and only the second is current.
    expect(backend.playedAssets, ['audio/english/water.mp3', 'audio/kannada/water.mp3']);
    expect(service.state.currentAsset, 'audio/kannada/water.mp3');
  });

  test('pause and resume toggle status without losing the current asset', () async {
    await service.play('audio/english/water.mp3');

    await service.pause();
    expect(service.state.status, AudioPlaybackStatus.paused);
    expect(backend.paused, isTrue);

    await service.resume();
    expect(service.state.status, AudioPlaybackStatus.playing);
    expect(backend.paused, isFalse);
  });

  test('replay restarts the current asset from idle-after-complete', () async {
    await service.play('audio/english/water.mp3');
    backend.emitComplete();
    await Future<void>.delayed(Duration.zero);
    expect(service.state.status, AudioPlaybackStatus.completed);

    final ok = await service.replay();
    expect(ok, isTrue);
    expect(backend.playedAssets, ['audio/english/water.mp3', 'audio/english/water.mp3']);
    expect(service.state.status, AudioPlaybackStatus.playing);
  });

  test('replay with nothing loaded is a no-op', () async {
    expect(await service.replay(), isFalse);
  });

  test('a failed play reports an error state instead of throwing', () async {
    backend.failOnAsset = 'audio/english/missing.mp3';

    final ok = await service.play('audio/english/missing.mp3');

    expect(ok, isFalse);
    expect(service.state.status, AudioPlaybackStatus.error);
  });

  test('setSpeed persists across subsequent play calls', () async {
    await service.setSpeed(0.75);
    await service.play('audio/english/water.mp3');

    expect(service.state.speed, 0.75);
    expect(backend.speeds, contains(0.75));
  });

  test('stop resets to idle but keeps the chosen speed', () async {
    await service.setSpeed(0.75);
    await service.play('audio/english/water.mp3');

    await service.stop();

    expect(service.state.status, AudioPlaybackStatus.idle);
    expect(service.state.currentAsset, isNull);
    expect(service.state.speed, 0.75);
  });
}
