import 'package:permission_handler/permission_handler.dart';
import 'package:speech_to_text/speech_to_text.dart';

/// Thin seam over speech_to_text + permission_handler, mirroring
/// AudioBackend from Phase 5 — SpeechRecognitionService is unit-tested
/// against a fake here, never against the real platform plugin.
abstract interface class SpeechBackend {
  /// Engine availability on this device — independent of mic permission.
  Future<bool> initialize();

  Future<bool> hasPermission();

  /// Triggers the OS permission prompt. Only ever called from a user
  /// action (tapping the mic), never at app startup.
  Future<bool> requestPermission();

  /// Starts one listening session. [onResult] fires for partial and final
  /// transcripts; [onError] fires for any platform-reported failure.
  /// Returns false if the session could not be started at all.
  Future<bool> listen({
    required void Function(String transcript, bool isFinal, double? confidence) onResult,
    required void Function(String message) onError,
  });

  Future<void> stop();
  Future<void> cancel();
  Future<void> dispose();
}

class SpeechToTextBackend implements SpeechBackend {
  final SpeechToText _speech = SpeechToText();
  bool _initialized = false;

  @override
  Future<bool> initialize() async {
    if (_initialized) return true;
    _initialized = await _speech.initialize(debugLogging: false);
    return _initialized;
  }

  @override
  Future<bool> hasPermission() => _speech.hasPermission;

  @override
  Future<bool> requestPermission() async {
    final status = await Permission.microphone.request();
    return status.isGranted;
  }

  @override
  Future<bool> listen({
    required void Function(String transcript, bool isFinal, double? confidence) onResult,
    required void Function(String message) onError,
  }) async {
    if (!_initialized) return false;
    try {
      await _speech.listen(
        onResult: (result) => onResult(
          result.recognizedWords,
          result.finalResult,
          result.hasConfidenceRating ? result.confidence : null,
        ),
        listenOptions: SpeechListenOptions(
          // Request on-device recognition specifically — this is what makes
          // the attempt offline where the platform supports it. If the
          // device can't do on-device recognition, the listen call fails
          // and the caller falls back to Listen+repeat, per Phase 7's
          // "never a hard dependency" requirement.
          onDevice: true,
          partialResults: true,
          listenMode: ListenMode.confirmation,
          cancelOnError: true,
          // Short sessions for beginner words/sentences — never indefinite.
          listenFor: const Duration(seconds: 8),
          pauseFor: const Duration(seconds: 3),
        ),
      );
      return true;
    } catch (e) {
      onError(e.toString());
      return false;
    }
  }

  @override
  Future<void> stop() => _speech.stop();

  @override
  Future<void> cancel() => _speech.cancel();

  @override
  Future<void> dispose() async {
    await _speech.cancel();
  }
}
