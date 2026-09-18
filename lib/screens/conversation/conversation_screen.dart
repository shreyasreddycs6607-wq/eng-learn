import 'package:flutter/material.dart';
import '../../core/services/app_services.dart';
import '../../models/conversation.dart';
import '../../models/exercise_answer.dart';
import '../../models/feedback_type.dart';
import '../../models/speaking_outcome.dart';
import '../../services/conversation_controller.dart';
import '../../services/speaking_controller.dart';
import '../../widgets/audio_player_button.dart';
import '../../widgets/audio_speed_control.dart';
import '../../widgets/exercise/exercise_view.dart';
import '../../widgets/feedback_card.dart';
import '../../widgets/lesson_header.dart';
import '../../widgets/microphone_button.dart';
import '../../widgets/primary_button.dart';
import '../../widgets/secondary_button.dart';

/// One guided mini-conversation: situation -> turns -> complete. All checking,
/// speaking evaluation and progress recording happen in ConversationController
/// (which reuses the Phase 6/7/8 engines); this screen only renders its state.
class ConversationScreen extends StatefulWidget {
  final Conversation conversation;

  const ConversationScreen({super.key, required this.conversation});

  @override
  State<ConversationScreen> createState() => _ConversationScreenState();
}

class _ConversationScreenState extends State<ConversationScreen> {
  ConversationController? _controller;
  bool _started = false;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    appServices.audio.stop();
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final all = await appServices.exercises.loadAll();
      final wanted = widget.conversation.responseExerciseIds.toSet();
      final controller = ConversationController(
        conversation: widget.conversation,
        exercises: {for (final e in all.where((e) => wanted.contains(e.id))) e.id: e},
        progressRepository: appServices.exerciseProgress,
        speakingFactory: (exercise) => SpeakingController(
          speech: appServices.speech,
          exerciseId: exercise.id,
          lessonId: exercise.lessonId,
          expectedText: (exercise.answer as TextAnswer).value,
          progressRepository: appServices.exerciseProgress,
        ),
      );
      if (!mounted) {
        controller.dispose();
        return;
      }
      setState(() => _controller = controller);
    } catch (_) {
      if (mounted) setState(() => _failed = true);
    }
  }

  void _next(ConversationController c) {
    appServices.audio.stop();
    c.continueTurn();
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;
    if (_failed) {
      return _messageScaffold(context, title: "Couldn't load this conversation", body: 'Please go back and try again.', button: 'Back', onPressed: () => Navigator.of(context).pop());
    }
    if (controller == null) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    if (!_started) return _intro(context);

    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) => controller.finished ? _complete(context, controller) : _turnScreen(context, controller),
    );
  }

  Widget _intro(BuildContext context) {
    final c = widget.conversation;
    return _messageScaffold(
      context,
      title: c.title,
      body: '${c.kannadaSituation}\n\n${c.situation}',
      button: 'Start',
      onPressed: () => setState(() => _started = true),
    );
  }

  Widget _complete(BuildContext context, ConversationController c) {
    final said = widget.conversation.turns.where((t) => t.isLearner).map((t) => '• ${t.englishText}').join('\n');
    final revisit = c.reinforcementCount > 0 ? '\n\nA few sentences will come back in Today’s Revision.' : '';
    return _messageScaffold(
      context,
      title: 'Conversation Complete!',
      body: 'You practiced:\n$said$revisit',
      button: 'Done',
      onPressed: () => Navigator.of(context).pop(),
      secondary: SecondaryButton(
        label: 'Practice Again',
        onPressed: () => Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => ConversationScreen(conversation: widget.conversation)),
        ),
      ),
    );
  }

  Widget _messageScaffold(BuildContext context,
      {required String title, required String body, required String button, required VoidCallback onPressed, Widget? secondary}) {
    return Scaffold(
      appBar: AppBar(),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              Expanded(
                child: Center(
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(title, style: Theme.of(context).textTheme.displayMedium, textAlign: TextAlign.center),
                        const SizedBox(height: 16),
                        Text(body, style: Theme.of(context).textTheme.bodyLarge, textAlign: TextAlign.center),
                      ],
                    ),
                  ),
                ),
              ),
              PrimaryButton(label: button, onPressed: onPressed),
              if (secondary != null) ...[const SizedBox(height: 12), secondary],
            ],
          ),
        ),
      ),
    );
  }

  Widget _turnScreen(BuildContext context, ConversationController c) {
    final Widget body = switch (c.state.step) {
      TurnStep.line => _lineStep(context, c),
      TurnStep.choose => _chooseStep(context, c),
      TurnStep.speak => _speakStep(context, c),
    };
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              LessonHeader(current: c.turnIndex + 1, total: c.totalTurns),
              const SizedBox(height: 16),
              Expanded(child: body),
            ],
          ),
        ),
      ),
    );
  }

  /// A line spoken by someone else: listen, then continue.
  Widget _lineStep(BuildContext context, ConversationController c) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(child: SingleChildScrollView(child: _bubble(context, c.turn))),
        PrimaryButton(label: 'Continue', onPressed: () => _next(c)),
      ],
    );
  }

  Widget _chooseStep(BuildContext context, ConversationController c) {
    final exercise = c.choiceExercise!;
    final result = c.choiceResult;
    final previous = c.turnIndex > 0 ? widget.conversation.turns[c.turnIndex - 1] : null;
    final revealed = c.state.outcome == StepOutcome.revealed;
    final retry = c.state.awaitingRetry;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (previous != null && !previous.isLearner) _bubble(context, previous),
        const SizedBox(height: 16),
        Text(exercise.kannadaText ?? '', style: Theme.of(context).textTheme.headlineMedium),
        const SizedBox(height: 4),
        Text('What do you say?', style: Theme.of(context).textTheme.bodyMedium),
        const SizedBox(height: 16),
        Expanded(
          child: KeyedSubtree(
            // A new key per attempt clears the previously picked option on retry.
            key: ValueKey('${exercise.id}-${c.state.evaluatedAttempts}'),
            child: buildExerciseView(
              exercise: exercise,
              submittedAnswer: result?.submittedAnswer,
              onSubmit: c.submitChoice,
            ),
          ),
        ),
        if (revealed && c.turn.audioPath != null) Center(child: AudioPlayerButton(audioPath: c.turn.audioPath, label: 'answer audio', size: 56)),
        if (result != null)
          FeedbackCard(
            feedbackType: result.feedbackType,
            correctAnswer: result.correctAnswerText,
            buttonLabel: retry ? 'Try Again' : 'Continue',
            onContinue: retry ? c.retry : () => _next(c),
          ),
      ],
    );
  }

  Widget _speakStep(BuildContext context, ConversationController c) {
    final state = c.state;
    final speaking = c.speaking;
    final result = speaking?.lastResult;
    final target = c.turn;

    Widget action;
    if (state.outcome == StepOutcome.correct) {
      action = FeedbackCard(feedbackType: FeedbackType.correct, correctAnswer: target.englishText, onContinue: () => _next(c));
    } else if (state.outcome == StepOutcome.retry || (state.outcome == StepOutcome.revealed && state.evaluatedAttempts > 0)) {
      final retry = state.awaitingRetry;
      action = FeedbackCard(
        feedbackType: result?.outcome == SpeakingOutcome.almost ? FeedbackType.almost : FeedbackType.wrong,
        correctAnswer: target.englishText,
        explanation: (result?.recognizedText ?? '').isEmpty ? null : 'You said: “${result!.recognizedText}”',
        buttonLabel: retry ? 'Try Again' : 'Continue',
        onContinue: retry ? c.retry : () => _next(c),
      );
    } else if (state.outcome == StepOutcome.revealed) {
      // Recognition kept failing — never the learner's fault, just move on.
      action = _plainAction(context, "That's okay. Listen once more, then continue.", 'Continue', () => _next(c));
    } else if (speaking == null) {
      action = const SizedBox.shrink();
    } else if (speaking.state == SpeakingUiState.unavailable || speaking.state == SpeakingUiState.permissionDenied) {
      action = _plainAction(
        context,
        speaking.state == SpeakingUiState.unavailable
            ? "Speech recognition isn't available on this device. You can still listen and repeat."
            : 'Microphone access is needed for speaking practice. You can still listen and repeat.',
        'I repeated it',
        speaking.confirmWithoutRecognition,
      );
    } else if (speaking.state == SpeakingUiState.showingResult) {
      // Only an unusable transcript can be showing while the step is pending.
      action = Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text("I couldn't hear that clearly.\nListen again and try once more.", textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodyLarge),
          const SizedBox(height: 16),
          PrimaryButton(label: '\u{1F3A4} Try Again', onPressed: c.retry),
          if (state.recognitionFailures >= ConversationController.maxRecognitionFailures) ...[
            const SizedBox(height: 8),
            SecondaryButton(label: 'Continue', onPressed: c.continueWithoutRecognition),
          ],
        ],
      );
    } else {
      action = Center(
        child: MicrophoneButton(
          state: speaking.state,
          onTap: () => speaking.state == SpeakingUiState.listening ? speaking.stopSpeaking() : speaking.startSpeaking(),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Say this:', style: Theme.of(context).textTheme.bodyMedium),
                const SizedBox(height: 8),
                _bubble(context, target),
                if (target.audioPath != null) ...[const SizedBox(height: 8), const AudioSpeedControl()],
              ],
            ),
          ),
        ),
        action,
      ],
    );
  }

  Widget _plainAction(BuildContext context, String message, String label, VoidCallback onPressed) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(message, textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodyMedium),
        const SizedBox(height: 16),
        PrimaryButton(label: label, onPressed: onPressed),
      ],
    );
  }

  /// Speaker, English line (with Listen), and its Kannada meaning.
  Widget _bubble(BuildContext context, ConversationTurn turn) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(speakerLabels[turn.speaker] ?? '', style: Theme.of(context).textTheme.bodyMedium),
                  const SizedBox(height: 4),
                  Text(turn.englishText, style: Theme.of(context).textTheme.headlineMedium),
                  const SizedBox(height: 4),
                  Text(turn.kannadaText, style: Theme.of(context).textTheme.bodyLarge),
                ],
              ),
            ),
            if (turn.audioPath != null) AudioPlayerButton(audioPath: turn.audioPath, label: 'audio', size: 56),
          ],
        ),
      ),
    );
  }
}
