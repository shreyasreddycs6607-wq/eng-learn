import 'package:flutter/foundation.dart';
import '../data/repositories/exercise_progress_repository.dart';
import '../models/conversation.dart';
import '../models/exercise.dart';
import '../models/exercise_answer.dart';
import '../models/exercise_result.dart';
import '../models/speaking_outcome.dart';
import 'practice_controller.dart';
import 'speaking_controller.dart';

/// Which part of a turn the learner is on. [line] is a listen-and-continue
/// turn spoken by someone else; learner turns are [choose] a reply, then
/// [speak] it.
enum TurnStep { line, choose, speak }

/// pending = waiting for the learner; retry = one incorrect evaluated
/// attempt, a retry is on offer; correct / revealed = the step is finished
/// and the learner only needs to continue (revealed = the answer was shown
/// after the last allowed attempt, or after recognition kept failing).
enum StepOutcome { pending, correct, retry, revealed }

/// Explicit per-turn retry state — never inferred from widget rebuilds or
/// button labels. Reset every time the turn (or the step within it) changes.
class ConversationTurnState {
  final TurnStep step;
  final int evaluatedAttempts;
  final StepOutcome outcome;

  /// "Listen Again" results in a row — recognition trouble, not learner
  /// failure, so they never count toward [evaluatedAttempts].
  final int recognitionFailures;

  const ConversationTurnState({
    required this.step,
    this.evaluatedAttempts = 0,
    this.outcome = StepOutcome.pending,
    this.recognitionFailures = 0,
  });

  bool get awaitingRetry => outcome == StepOutcome.retry;
  bool get completed => outcome == StepOutcome.correct || outcome == StepOutcome.revealed;

  ConversationTurnState copyWith({int? evaluatedAttempts, StepOutcome? outcome, int? recognitionFailures}) => ConversationTurnState(
        step: step,
        evaluatedAttempts: evaluatedAttempts ?? this.evaluatedAttempts,
        outcome: outcome ?? this.outcome,
        recognitionFailures: recognitionFailures ?? this.recognitionFailures,
      );
}

/// The Real-Life Practice engine. It owns turn order and the retry contract
/// only; every answer is checked and recorded by the existing engines:
/// the choose step is a one-exercise [PracticeController] (AnswerChecker +
/// one Phase 8 attempt per submission) and the speak step is a
/// [SpeakingController] (SpeakingEvaluator + one attempt per evaluated
/// result; Listen Again records nothing).
///
/// Retry contract: correct advances; the first incorrect choice/speech
/// attempt offers one retry; the second reveals the answer and moves on
/// (a wrong reply also skips the speak step). At most 2 evaluated attempts
/// per step, so the learner is never trapped.
class ConversationController extends ChangeNotifier {
  static const maxAttempts = 2;

  /// After this many Listen Agains in a row, the learner may continue
  /// without a recognised attempt (mic trouble must never block progress).
  static const maxRecognitionFailures = 3;

  final Conversation conversation;
  final Map<String, Exercise> _exercises;
  final ExerciseProgressRepository? _progress;
  final SpeakingController Function(Exercise) _speakingFactory;

  int _turnIndex = 0;
  bool _finished = false;
  ConversationTurnState _state = const ConversationTurnState(step: TurnStep.line);
  PracticeController? _choice;
  SpeakingController? _speaking;
  Exercise? _speakExercise;
  Object? _handledSpeechResult;
  final Set<int> _reinforceTurns = {};

  ConversationController({
    required this.conversation,
    required Map<String, Exercise> exercises,
    required SpeakingController Function(Exercise) speakingFactory,
    ExerciseProgressRepository? progressRepository,
  })  : _exercises = exercises,
        _speakingFactory = speakingFactory,
        _progress = progressRepository {
    _enterTurn(0);
  }

  ConversationTurn get turn => conversation.turns[_turnIndex];
  int get turnIndex => _turnIndex;
  int get totalTurns => conversation.turns.length;
  bool get finished => _finished;
  ConversationTurnState get state => _state;

  /// Learner turns whose answer had to be revealed — they come back through
  /// Today's Revision via the normal attempt records.
  int get reinforcementCount => _reinforceTurns.length;

  Exercise? get choiceExercise => _choice?.session.currentExercise;
  ExerciseResult? get choiceResult => _choice?.session.currentResult;
  Exercise? get speakExercise => _speakExercise;
  SpeakingController? get speaking => _speaking;

  void _enterTurn(int index) {
    _turnIndex = index;
    _disposeSpeaking();
    _choice?.dispose();
    _choice = null;

    final t = conversation.turns[index];
    final choose = t.isLearner && t.responseExerciseIds.length == 2 ? _exercises[t.responseExerciseIds[0]] : null;
    if (choose == null) {
      // A non-learner turn — or a learner turn whose exercise is missing,
      // which must degrade to listen-and-continue rather than crash.
      _state = const ConversationTurnState(step: TurnStep.line);
    } else {
      _choice = PracticeController(exercises: [choose], progressRepository: _progress)..startSession();
      _state = const ConversationTurnState(step: TurnStep.choose);
    }
  }

  /// The learner picked a reply. A second call before [retry] (a double tap)
  /// is ignored, so each submission is evaluated and recorded exactly once.
  void submitChoice(ExerciseAnswer answer) {
    if (_state.step != TurnStep.choose || _state.outcome != StepOutcome.pending) return;
    final result = _choice!.submitAnswer(answer);
    if (result == null) return;
    _applyEvaluation(result.isCorrect);
  }

  /// One evaluated attempt: correct finishes the step, the first miss offers
  /// a retry, the second reveals the answer. Only correct/incorrect attempts
  /// pass through here — recognition failures do not.
  void _applyEvaluation(bool isCorrect) {
    final attempts = _state.evaluatedAttempts + 1;
    final outcome = isCorrect
        ? StepOutcome.correct
        : attempts < maxAttempts
            ? StepOutcome.retry
            : StepOutcome.revealed;
    if (outcome == StepOutcome.revealed) _reinforceTurns.add(_turnIndex);
    _state = _state.copyWith(evaluatedAttempts: attempts, outcome: outcome);
    notifyListeners();
  }

  /// Offer the retry after an incorrect first attempt (or another go after
  /// Listen Again). Never changes the attempt count.
  Future<void> retry() async {
    if (_state.step == TurnStep.choose && _state.awaitingRetry) {
      _choice!.restartSession();
      _state = _state.copyWith(outcome: StepOutcome.pending);
      notifyListeners();
    } else if (_state.step == TurnStep.speak && !_state.completed) {
      _state = _state.copyWith(outcome: StepOutcome.pending);
      notifyListeners();
      await _speaking?.retry();
    }
  }

  /// Move on: line -> next turn; correct choice -> speak step; anything else
  /// that has finished -> next turn.
  void continueTurn() {
    if (_state.step != TurnStep.line && !_state.completed) return;
    if (_state.step == TurnStep.choose && _state.outcome == StepOutcome.correct) {
      _enterSpeak();
    } else if (_turnIndex + 1 >= totalTurns) {
      _finished = true;
      _disposeSpeaking();
      notifyListeners();
    } else {
      _enterTurn(_turnIndex + 1);
      notifyListeners();
    }
  }

  void _enterSpeak() {
    final exercise = _exercises[turn.responseExerciseIds[1]];
    if (exercise == null) {
      // Missing speaking exercise: the reply itself was already answered.
      _state = const ConversationTurnState(step: TurnStep.speak, outcome: StepOutcome.revealed);
      notifyListeners();
      return;
    }
    _speakExercise = exercise;
    _state = const ConversationTurnState(step: TurnStep.speak);
    _handledSpeechResult = null;
    _speaking = _speakingFactory(exercise)
      ..addListener(_onSpeakingChanged)
      ..checkAvailability();
    notifyListeners();
  }

  void _onSpeakingChanged() {
    final controller = _speaking;
    final result = controller?.lastResult;
    final fresh = controller != null &&
        controller.state == SpeakingUiState.showingResult &&
        result != null &&
        !identical(result, _handledSpeechResult) &&
        _state.step == TurnStep.speak &&
        _state.outcome == StepOutcome.pending;
    if (fresh) {
      _handledSpeechResult = result;
      switch (result.outcome) {
        case SpeakingOutcome.good:
          _applyEvaluation(true);
          return;
        case SpeakingOutcome.almost:
        case SpeakingOutcome.tryAgain:
          _applyEvaluation(false);
          return;
        case SpeakingOutcome.listenAgain:
        case SpeakingOutcome.error:
          _state = _state.copyWith(recognitionFailures: _state.recognitionFailures + 1);
        case SpeakingOutcome.unavailable:
        case SpeakingOutcome.permissionDenied:
          break; // the UI shows the honest "I repeated it" fallback
      }
    }
    notifyListeners();
  }

  /// Recognition kept failing: show the target and let the learner continue.
  /// Not counted against them (no attempt was evaluated, none is recorded).
  void continueWithoutRecognition() {
    if (_state.step != TurnStep.speak || _state.recognitionFailures < maxRecognitionFailures) return;
    _state = _state.copyWith(outcome: StepOutcome.revealed);
    notifyListeners();
  }

  void _disposeSpeaking() {
    _speaking?.removeListener(_onSpeakingChanged);
    _speaking?.dispose();
    _speaking = null;
  }

  @override
  void dispose() {
    _disposeSpeaking();
    _choice?.dispose();
    super.dispose();
  }
}
