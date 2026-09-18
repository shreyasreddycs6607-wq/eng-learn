import 'package:english_kaliyona/services/speech_backend.dart';

/// A controllable stand-in for the real speech_to_text/permission_handler
/// backend, so SpeechRecognitionService (and anything built on it) can be
/// tested without a device, microphone, or speech engine.
class FakeSpeechBackend implements SpeechBackend {
  bool availableResult = true;
  bool permissionGranted = true;
  bool listenStartsSuccessfully = true;

  void Function(String transcript, bool isFinal, double? confidence)? _onResult;
  void Function(String message)? _onError;
  bool listening = false;
  int listenCallCount = 0;
  int stopCallCount = 0;
  int cancelCallCount = 0;

  @override
  Future<bool> initialize() async => availableResult;

  @override
  Future<bool> hasPermission() async => permissionGranted;

  @override
  Future<bool> requestPermission() async => permissionGranted;

  @override
  Future<bool> listen({
    required void Function(String transcript, bool isFinal, double? confidence) onResult,
    required void Function(String message) onError,
  }) async {
    listenCallCount++;
    if (!listenStartsSuccessfully) {
      onError('simulated start failure');
      return false;
    }
    _onResult = onResult;
    _onError = onError;
    listening = true;
    return true;
  }

  @override
  Future<void> stop() async {
    stopCallCount++;
    listening = false;
  }

  @override
  Future<void> cancel() async {
    cancelCallCount++;
    listening = false;
  }

  @override
  Future<void> dispose() async {}

  /// Test helper: simulates the platform delivering a transcript update.
  void emitResult(String transcript, {required bool isFinal, double? confidence}) {
    _onResult?.call(transcript, isFinal, confidence);
  }

  /// Test helper: simulates a platform-reported recognition error.
  void emitError(String message) => _onError?.call(message);
}
