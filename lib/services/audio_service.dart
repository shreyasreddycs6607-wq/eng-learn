import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import '../models/audio_state.dart';
import 'audio_backend.dart';

/// The single place the app plays audio. One shared instance (via
/// appServices.audio) backs every screen, so there is always exactly one
/// active playback session — starting a new clip always stops the last one.
/// Knows nothing about lessons/exercises/progress; it only plays local
/// assets and reports state.
class AudioService with WidgetsBindingObserver {
  final AudioBackend _backend;
  final _stateController = StreamController<AudioState>.broadcast();
  AudioState _state = const AudioState.idle();
  StreamSubscription<void>? _completeSub;

  AudioService([AudioBackend? backend]) : _backend = backend ?? AudioplayersBackend() {
    _completeSub = _backend.onComplete.listen((_) {
      _emit(_state.copyWith(status: AudioPlaybackStatus.completed));
    });
    WidgetsBinding.instance.addObserver(this);
  }

  Stream<AudioState> get stateStream => _stateController.stream;
  AudioState get state => _state;

  /// (Re)starts playback of [assetPath] — relative to assets/, e.g.
  /// "audio/english/water.mp3". Stops whatever was playing first, so two
  /// clips never overlap. Returns false (never throws) if the asset can't
  /// be played, so a missing/corrupt file never crashes the lesson.
  Future<bool> play(String assetPath) async {
    _emit(AudioState(status: AudioPlaybackStatus.loading, currentAsset: assetPath, speed: _state.speed));
    try {
      await _backend.stop();
      await _backend.play(assetPath);
      await _backend.setSpeed(_state.speed);
      _emit(_state.copyWith(status: AudioPlaybackStatus.playing));
      if (kDebugMode) debugPrint('[AUDIO] Playing $assetPath');
      return true;
    } catch (e) {
      _emit(AudioState(status: AudioPlaybackStatus.error, currentAsset: assetPath, speed: _state.speed));
      if (kDebugMode) debugPrint('[AUDIO] Error loading $assetPath: $e');
      return false;
    }
  }

  Future<void> pause() async {
    if (_state.status != AudioPlaybackStatus.playing) return;
    await _backend.pause();
    _emit(_state.copyWith(status: AudioPlaybackStatus.paused));
  }

  Future<void> resume() async {
    if (_state.status != AudioPlaybackStatus.paused) return;
    await _backend.resume();
    _emit(_state.copyWith(status: AudioPlaybackStatus.playing));
  }

  /// Seeks to the start and plays again — used by the replay control after
  /// a clip completes, or to restart a difficult word from the top.
  Future<bool> replay() async {
    final asset = _state.currentAsset;
    if (asset == null) return false;
    return play(asset);
  }

  Future<void> seek(Duration position) => _backend.seek(position);

  /// Applies immediately if something is playing, and stays in effect for
  /// every subsequent [play] until changed again (e.g. 1.0x / 0.75x).
  Future<void> setSpeed(double speed) async {
    _emit(_state.copyWith(speed: speed));
    if (_state.isActive) await _backend.setSpeed(speed);
  }

  Future<void> stop() async {
    await _backend.stop();
    _emit(AudioState.idle(speed: _state.speed));
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // A learning app, not a music player — don't keep playing in the background.
    if (state != AppLifecycleState.resumed) stop();
  }

  void _emit(AudioState next) {
    _state = next;
    _stateController.add(next);
  }

  Future<void> dispose() async {
    WidgetsBinding.instance.removeObserver(this);
    await _completeSub?.cancel();
    await _stateController.close();
    await _backend.dispose();
  }
}
