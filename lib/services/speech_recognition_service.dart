import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/recognized_speech.dart';
import '../models/speech_recognition_state.dart';
import 'speech_backend.dart';

/// The single place the app talks to the speech engine. Mirrors
/// AudioService's shape (Phase 5): one shared instance, a typed state
/// stream, and an injectable backend so tests never touch the real plugin.
/// The UI only ever calls startListening/stopListening/cancel/requestPermission
/// and reacts to [stateStream]/[results] — it never sees speech_to_text types.
class SpeechRecognitionService {
  final SpeechBackend _backend;
  final _stateController = StreamController<SpeechRecognitionState>.broadcast();
  final _resultsController = StreamController<RecognizedSpeech>.broadcast();
  SpeechRecognitionState _state = SpeechRecognitionState.idle;
  bool? _availableCache;

  SpeechRecognitionService([SpeechBackend? backend]) : _backend = backend ?? SpeechToTextBackend();

  Stream<SpeechRecognitionState> get stateStream => _stateController.stream;
  Stream<RecognizedSpeech> get results => _resultsController.stream;
  SpeechRecognitionState get state => _state;

  /// Engine availability on this device, independent of permission. Cached
  /// after the first check — callers ask this once per speaking screen, not
  /// on every rebuild.
  Future<bool> isAvailable() async {
    final cached = _availableCache;
    if (cached != null) return cached;
    final available = await _backend.initialize();
    _availableCache = available;
    if (!available) _emit(SpeechRecognitionState.unavailable);
    return available;
  }

  Future<bool> requestPermission() async {
    _emit(SpeechRecognitionState.requestingPermission);
    final granted = await _backend.requestPermission();
    _emit(granted ? SpeechRecognitionState.idle : SpeechRecognitionState.permissionDenied);
    return granted;
  }

  /// Starts one listening session. A second call while already
  /// listening/processing is ignored — there is only ever one active
  /// recognition session.
  Future<void> startListening() async {
    if (_state == SpeechRecognitionState.listening || _state == SpeechRecognitionState.processing) {
      return;
    }

    if (!await isAvailable()) {
      _emit(SpeechRecognitionState.unavailable);
      return;
    }

    if (!await _backend.hasPermission()) {
      if (!await requestPermission()) return;
    }

    _emit(SpeechRecognitionState.listening);
    if (kDebugMode) debugPrint('[SPEECH] Listening started');

    final started = await _backend.listen(
      onResult: (transcript, isFinal, confidence) {
        // State changes go out before the result itself, so a listener
        // reacting to the result (e.g. running evaluation) never has its
        // resulting state clobbered by a state-stream event queued earlier
        // in the same callback.
        if (isFinal) {
          _emit(SpeechRecognitionState.processing);
          _emit(SpeechRecognitionState.recognized);
        }
        if (kDebugMode && isFinal) debugPrint('[SPEECH] Transcript: $transcript');
        _resultsController.add(RecognizedSpeech(transcript: transcript, isFinal: isFinal, confidence: confidence));
      },
      onError: (message) {
        if (kDebugMode) debugPrint('[SPEECH] Error: $message');
        _emit(SpeechRecognitionState.error);
      },
    );

    if (!started) _emit(SpeechRecognitionState.error);
  }

  /// Learner tapped the mic again (or a UI timeout fired) to end capture
  /// early. The final transcript still arrives via the results stream.
  Future<void> stopListening() async {
    if (_state != SpeechRecognitionState.listening) return;
    _emit(SpeechRecognitionState.processing);
    await _backend.stop();
  }

  /// Discards the current attempt without producing a result.
  Future<void> cancel() async {
    await _backend.cancel();
    _emit(SpeechRecognitionState.idle);
  }

  void resetToIdle() {
    if (_state == SpeechRecognitionState.unavailable) return;
    _emit(SpeechRecognitionState.idle);
  }

  void _emit(SpeechRecognitionState next) {
    _state = next;
    _stateController.add(next);
  }

  Future<void> dispose() async {
    await _backend.dispose();
    await _stateController.close();
    await _resultsController.close();
  }
}
