import 'package:audioplayers/audioplayers.dart';

/// Thin seam over the real audio package so [AudioService] can be unit
/// tested without a platform channel — tests substitute a fake backend
/// instead of mocking `audioplayers` itself.
abstract interface class AudioBackend {
  Stream<void> get onComplete;

  Future<void> play(String assetPath);
  Future<void> pause();
  Future<void> resume();
  Future<void> stop();
  Future<void> seek(Duration position);
  Future<void> setSpeed(double speed);
  Future<void> dispose();
}

class AudioplayersBackend implements AudioBackend {
  final AudioPlayer _player = AudioPlayer();

  @override
  Stream<void> get onComplete => _player.onPlayerComplete;

  @override
  Future<void> play(String assetPath) => _player.play(AssetSource(assetPath));

  @override
  Future<void> pause() => _player.pause();

  @override
  Future<void> resume() => _player.resume();

  @override
  Future<void> stop() => _player.stop();

  @override
  Future<void> seek(Duration position) => _player.seek(position);

  @override
  Future<void> setSpeed(double speed) => _player.setPlaybackRate(speed);

  @override
  Future<void> dispose() => _player.dispose();
}
