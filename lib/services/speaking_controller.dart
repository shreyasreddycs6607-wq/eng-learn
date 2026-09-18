import 'dart:async';
import 'package:flutter/foundation.dart';
import '../data/repositories/exercise_progress_repository.dart';
import '../models/practice_attempt.dart';
import '../models/speaking_outcome.dart';
import '../models/speaking_result.dart';
import '../models/speech_recognition_state.dart';
import 'speaking_evaluator.dart';
import 'speech_recognition_service.dart';

/// UI-facing states for one speaking attempt. Mostly mirrors
/// SpeechRecognitionState, plus [showingResult] once SpeakingEvaluator has
/// produced a result the learner needs to act on.
enum SpeakingUiState {
  idle,
  unavailable,
  requestingPermission,
  permissionDenied,
  listening,
  processing,
  showingResult,
}

/// Orchestrates one speaking exercise: mic -> recognition -> evaluation ->
/// result, plus (best-effort, never blocking) Phase 8 progress bookkeeping
/// via the same ExerciseProgressRepository every other exercise type uses —
/// not a separate speaking-only revision system. A new instance per
/// exercise; the underlying SpeechRecognitionService/AudioService are the
/// app-wide shared singletons (see AppServices).
class SpeakingController extends ChangeNotifier {
  final SpeechRecognitionService _speech;
  final SpeakingEvaluator _evaluator;
  final ExerciseProgressRepository? _progress;
  final String exerciseId;
  final String lessonId;
  final String expectedText;

  SpeakingUiState _state = SpeakingUiState.idle;
  SpeakingResult? _lastResult;
  StreamSubscription<SpeechRecognitionState>? _stateSub;
  StreamSubscription? _resultsSub;

  SpeakingController({
    required SpeechRecognitionService speech,
    required this.exerciseId,
    required this.lessonId,
    required this.expectedText,
    SpeakingEvaluator? evaluator,
    ExerciseProgressRepository? progressRepository,
  })  : _speech = speech,
        _evaluator = evaluator ?? SpeakingEvaluator(),
        _progress = progressRepository {
    _stateSub = _speech.stateStream.listen(_onSpeechState);
    _resultsSub = _speech.results.where((r) => r.isFinal).listen((r) => _evaluate(r.transcript));
  }

  SpeakingUiState get state => _state;
  SpeakingResult? get lastResult => _lastResult;

  Future<void> checkAvailability() async {
    final available = await _speech.isAvailable();
    if (!available) _setState(SpeakingUiState.unavailable);
  }

  Future<void> startSpeaking() async {
    if (_state == SpeakingUiState.listening || _state == SpeakingUiState.processing) return;
    _lastResult = null;
    await _speech.startListening();
    // Sync immediately from the service's authoritative state rather than
    // waiting for the stream round-trip — startListening's own awaited
    // chain (permission prompt, engine start) may already be fully
    // resolved by the time we get here, and a caller awaiting this method
    // should see the true resulting state right away.
    _applySpeechState(_speech.state);
  }

  Future<void> stopSpeaking() => _speech.stopListening();

  /// Try again after Almost/Try Again/a recognition error — pre-submission
  /// retry is allowed and expected; this does not touch the practice
  /// engine's own (post-submission) retry rules.
  Future<void> retry() async {
    _lastResult = null;
    _setState(SpeakingUiState.idle);
    await startSpeaking();
  }

  /// The honest Phase 5/6 fallback when recognition is unavailable, denied,
  /// or the learner just wants to move on: an explicit self-confirmation,
  /// never claimed as an evaluated result. Not recorded as a practice
  /// attempt at all — no automated evaluation actually happened.
  void confirmWithoutRecognition() {
    _lastResult = SpeakingResult(outcome: SpeakingOutcome.good, expectedText: expectedText, recognizedText: expectedText);
    _setState(SpeakingUiState.showingResult);
  }

  void _onSpeechState(SpeechRecognitionState speechState) => _applySpeechState(speechState);

  void _applySpeechState(SpeechRecognitionState speechState) {
    switch (speechState) {
      case SpeechRecognitionState.unavailable:
        _setState(SpeakingUiState.unavailable);
      case SpeechRecognitionState.requestingPermission:
        _setState(SpeakingUiState.requestingPermission);
      case SpeechRecognitionState.permissionDenied:
        _setState(SpeakingUiState.permissionDenied);
      case SpeechRecognitionState.listening:
        _setState(SpeakingUiState.listening);
      case SpeechRecognitionState.processing:
        _setState(SpeakingUiState.processing);
      case SpeechRecognitionState.error:
        _handleResult(SpeakingResult(outcome: SpeakingOutcome.error, expectedText: expectedText, recognizedText: ''));
      case SpeechRecognitionState.recognized:
        break; // the transcript arrives via the results stream, handled in _evaluate
      case SpeechRecognitionState.idle:
        _setState(SpeakingUiState.idle);
    }
  }

  void _evaluate(String transcript) {
    _handleResult(_evaluator.evaluate(expectedText: expectedText, recognizedText: transcript));
  }

  void _handleResult(SpeakingResult result) {
    _lastResult = result;
    _setState(SpeakingUiState.showingResult);
    unawaited(_recordAttempt(result));
  }

  /// §13/§36/§74: Listen Again / unavailable / permission-denied / error are
  /// speech-recognition problems, not learner failures — no attempt is
  /// recorded for them at all, so they can never shorten a review interval
  /// or count against lifetime history. Good/Almost/TryAgain all record a
  /// real attempt through the same ExerciseProgressRepository every other
  /// exercise type uses (§60/§72/§73): Good is correct, Almost/TryAgain are
  /// both "needs reinforcement" — Almost is never treated as Good.
  Future<void> _recordAttempt(SpeakingResult result) async {
    final progress = _progress;
    if (progress == null) return;
    final bool? isCorrect = switch (result.outcome) {
      SpeakingOutcome.good => true,
      SpeakingOutcome.almost || SpeakingOutcome.tryAgain => false,
      SpeakingOutcome.listenAgain ||
      SpeakingOutcome.unavailable ||
      SpeakingOutcome.permissionDenied ||
      SpeakingOutcome.error =>
        null,
    };
    if (isCorrect == null) return;

    try {
      await progress.recordAttempt(PracticeAttempt(
        exerciseId: exerciseId,
        lessonId: lessonId,
        isCorrect: isCorrect,
        attemptedAt: DateTime.now(),
      ));
    } catch (e) {
      if (kDebugMode) debugPrint('[SPEECH] Progress write failed (non-fatal): $e');
    }
  }

  void _setState(SpeakingUiState next) {
    _state = next;
    notifyListeners();
  }

  @override
  void dispose() {
    _stateSub?.cancel();
    _resultsSub?.cancel();
    // Leaving the screen mid-attempt must not leave the microphone open, or the
    // shared recognizer stays "listening" and ignores the next screen's mic tap.
    if (_speech.state == SpeechRecognitionState.listening || _speech.state == SpeechRecognitionState.processing) {
      unawaited(_speech.cancel());
    }
    super.dispose();
  }
}
