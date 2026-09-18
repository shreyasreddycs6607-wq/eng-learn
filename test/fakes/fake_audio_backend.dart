import 'dart:async';
import 'package:english_kaliyona/services/audio_backend.dart';

/// A controllable stand-in for the real audioplayers-backed AudioBackend,
/// so AudioService and the audio widgets can be unit/widget-tested without
/// a platform channel.
class FakeAudioBackend implements AudioBackend {
  final _completeController = StreamController<void>.broadcast();
  final List<String> playedAssets = [];
  final List<double> speeds = [];
  bool paused = false;
  bool stopped = true;

  /// When set, [play] throws for this asset path instead of succeeding —
  /// simulates a missing/corrupt audio file.
  String? failOnAsset;

  @override
  Stream<void> get onComplete => _completeController.stream;

  @override
  Future<void> play(String assetPath) async {
    if (assetPath == failOnAsset) {
      throw Exception('Simulated failure for $assetPath');
    }
    playedAssets.add(assetPath);
    paused = false;
    stopped = false;
  }

  @override
  Future<void> pause() async => paused = true;

  @override
  Future<void> resume() async => paused = false;

  @override
  Future<void> stop() async {
    stopped = true;
    paused = false;
  }

  @override
  Future<void> seek(Duration position) async {}

  @override
  Future<void> setSpeed(double speed) async => speeds.add(speed);

  @override
  Future<void> dispose() async => _completeController.close();

  void emitComplete() => _completeController.add(null);
}
