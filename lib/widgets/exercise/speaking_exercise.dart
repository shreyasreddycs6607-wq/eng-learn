import 'package:flutter/material.dart';
import '../../core/services/app_services.dart';
import '../../core/theme/app_theme.dart';
import '../../models/exercise.dart';
import '../../models/exercise_answer.dart';
import '../../models/speaking_outcome.dart';
import '../../models/speaking_result.dart';
import '../../services/speaking_controller.dart';
import '../icon_badge.dart';
import '../microphone_button.dart';
import '../primary_button.dart';
import '../secondary_button.dart';
import '../soft_card.dart';

/// Listen, then speak — evaluated locally by SpeakingController/SpeakingEvaluator
/// where offline recognition is available. Never a hard dependency: if the
/// engine is unavailable, denied, or fails, this falls back to the honest
/// "I repeated it" self-confirmation (never claims pronunciation was checked).
class SpeakingExercise extends StatefulWidget {
  final Exercise exercise;
  final ExerciseAnswer? submittedAnswer;
  final ValueChanged<ExerciseAnswer> onSubmit;

  /// Tests inject a controller directly instead of building one from the
  /// app-wide speech singleton.
  final SpeakingController? controller;

  const SpeakingExercise({
    super.key,
    required this.exercise,
    required this.submittedAnswer,
    required this.onSubmit,
    this.controller,
  });

  @override
  State<SpeakingExercise> createState() => _SpeakingExerciseState();
}

class _SpeakingExerciseState extends State<SpeakingExercise> {
  late final SpeakingController _controller;
  late final bool _ownsController;

  String get _expectedText => switch (widget.exercise.answer) {
        TextAnswer(value: final v) => v,
        _ => throw StateError('Speaking exercise must use TextAnswer.'),
      };

  @override
  void initState() {
    super.initState();
    final injected = widget.controller;
    _ownsController = injected == null;
    _controller = injected ??
        SpeakingController(
          speech: appServices.speech,
          exerciseId: widget.exercise.id,
          lessonId: widget.exercise.lessonId,
          expectedText: _expectedText,
          progressRepository: appServices.exerciseProgress,
        );
    _controller.addListener(_onControllerChanged);
    _controller.checkAvailability();
  }

  void _onControllerChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _controller.removeListener(_onControllerChanged);
    if (_ownsController) _controller.dispose();
    super.dispose();
  }

  void _toggleMic() {
    if (_controller.state == SpeakingUiState.listening) {
      _controller.stopSpeaking();
    } else {
      _controller.startSpeaking();
    }
  }

  void _submitGood() => widget.onSubmit(TextAnswer(value: _expectedText));

  void _submitHonestFallback() {
    _controller.confirmWithoutRecognition();
    _submitGood();
  }

  void _submitAsAttempted(String recognizedText) {
    // Recorded honestly as what was actually recognized — incorrect if it
    // doesn't match, per Phase 7 progress semantics (Almost/TryAgain are
    // "incorrect / needs reinforcement", never silently upgraded to correct).
    widget.onSubmit(TextAnswer(value: recognizedText));
  }

  @override
  Widget build(BuildContext context) {
    if (widget.submittedAnswer != null) {
      return const Center(child: IconBadge(icon: Icons.check_rounded, size: 72, background: AppColors.correctSoft, foreground: AppColors.correct));
    }

    final state = _controller.state;
    if (state == SpeakingUiState.unavailable || state == SpeakingUiState.permissionDenied) {
      return _buildFallback(context, state);
    }

    if (state == SpeakingUiState.showingResult) {
      return _buildResult(context, _controller.lastResult!);
    }

    return _scroll(MicrophoneButton(state: state, onTap: _toggleMic));
  }

  /// Centered, and scrollable if the room left by the prompt is small.
  Widget _scroll(Widget child) => Center(child: SingleChildScrollView(child: child));

  Widget _buildFallback(BuildContext context, SpeakingUiState state) {
    final text = Theme.of(context).textTheme;
    final message = state == SpeakingUiState.unavailable
        ? "Speech recognition isn't available on this device."
        : 'Microphone access is needed for speaking practice.';
    return _scroll(
      Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const IconBadge(icon: Icons.mic_off_rounded, size: 64, background: AppColors.accentSoft, foreground: AppColors.almost),
          const SizedBox(height: 14),
          Text(message, textAlign: TextAlign.center, style: text.bodyLarge),
          const SizedBox(height: 6),
          Text('You can still listen and repeat.', textAlign: TextAlign.center, style: text.bodyMedium),
          const SizedBox(height: 22),
          Semantics(
            label: 'I repeated it',
            child: PrimaryButton(label: "I repeated it", onPressed: _submitHonestFallback),
          ),
        ],
      ),
    );
  }

  Widget _buildResult(BuildContext context, SpeakingResult result) {
    final text = Theme.of(context).textTheme;
    switch (result.outcome) {
      case SpeakingOutcome.good:
        return _scroll(
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const IconBadge(icon: Icons.check_rounded, size: 72, background: AppColors.correct, foreground: Colors.white),
              const SizedBox(height: 14),
              Text('Good! Nice speaking.', style: text.headlineSmall?.copyWith(color: AppColors.correct)),
              const SizedBox(height: 22),
              PrimaryButton(label: 'Continue', onPressed: _submitGood, color: AppColors.correct),
            ],
          ),
        );
      case SpeakingOutcome.almost:
      case SpeakingOutcome.tryAgain:
        final almost = result.outcome == SpeakingOutcome.almost;
        return _scroll(
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                almost ? 'Almost!' : 'Not quite.',
                textAlign: TextAlign.center,
                style: text.headlineSmall?.copyWith(color: almost ? AppColors.almost : AppColors.incorrect),
              ),
              const SizedBox(height: 12),
              SoftCard(
                shadow: false,
                color: almost ? AppColors.almostSoft : AppColors.incorrectSoft,
                borderColor: (almost ? AppColors.almost : AppColors.incorrect).withValues(alpha: 0.3),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('You said: \u201c${result.recognizedText}\u201d', style: text.bodyMedium),
                    const SizedBox(height: 6),
                    Text('Try saying: \u201c${result.expectedText}\u201d', style: text.titleMedium),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              Semantics(
                label: 'Try again',
                child: PrimaryButton(label: 'Try Again', icon: Icons.refresh_rounded, onPressed: _controller.retry),
              ),
              const SizedBox(height: 8),
              SecondaryButton(
                label: 'Continue anyway',
                onPressed: () => _submitAsAttempted(result.recognizedText),
              ),
            ],
          ),
        );
      case SpeakingOutcome.listenAgain:
      case SpeakingOutcome.error:
        return _scroll(
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const IconBadge(icon: Icons.hearing_rounded, size: 64, background: AppColors.accentSoft, foreground: AppColors.almost),
              const SizedBox(height: 14),
              Text("I couldn't understand that.", textAlign: TextAlign.center, style: text.titleLarge),
              const SizedBox(height: 4),
              Text('Try again or listen again.', textAlign: TextAlign.center, style: text.bodyMedium),
              const SizedBox(height: 20),
              Semantics(
                label: 'Try again',
                child: PrimaryButton(label: 'Try Again', icon: Icons.refresh_rounded, onPressed: _controller.retry),
              ),
              const SizedBox(height: 8),
              SecondaryButton(label: "I repeated it instead", onPressed: _submitHonestFallback),
            ],
          ),
        );
      case SpeakingOutcome.unavailable:
      case SpeakingOutcome.permissionDenied:
        return _buildFallback(
          context,
          result.outcome == SpeakingOutcome.unavailable ? SpeakingUiState.unavailable : SpeakingUiState.permissionDenied,
        );
    }
  }
}
