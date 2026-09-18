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

  // The plugin reports errors and end-of-session through callbacks given to
  // initialize(), not through listen(); route them to the current session.
  void Function(String transcript, bool isFinal, double? confidence)? _onResult;
  void Function(String message)? _onError;
  bool _sawListening = false;
  bool _sessionEnded = false;

  @override
  Future<bool> initialize() async {
    if (_initialized) return true;
    _initialized = await _speech.initialize(
      debugLogging: false,
      onError: (error) {
        _sessionEnded = true;
        _onError?.call(error.errorMsg);
      },
      onStatus: (status) {
        if (status == SpeechToText.listeningStatus) _sawListening = true;
        // The engine stopped without ever delivering a final transcript (nothing
        // heard / timed out): report an empty final result so the learner gets
        // "Listen Again" instead of a screen that waits forever. Only after this
        // session actually started listening, so a late status from the previous
        // session can't end a new one.
        final ended = status == SpeechToText.doneStatus || status == SpeechToText.notListeningStatus;
        if (ended && _sawListening && !_sessionEnded) {
          _sessionEnded = true;
          _onResult?.call('', true, null);
        }
      },
    );
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
    _onResult = onResult;
    _onError = onError;
    _sawListening = false;
    _sessionEnded = false;
    try {
      await _speech.listen(
        onResult: (result) {
          if (result.finalResult) _sessionEnded = true;
          onResult(
            result.recognizedWords,
            result.finalResult,
            result.hasConfidenceRating ? result.confidence : null,
          );
        },
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
  Future<void> cancel() {
    _onResult = null; // a cancelled attempt must not report a result
    _onError = null;
    return _speech.cancel();
  }

  @override
  Future<void> dispose() async {
    _onResult = null;
    _onError = null;
    await _speech.cancel();
  }
}
