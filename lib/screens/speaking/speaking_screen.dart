import 'package:flutter/material.dart';
import '../../core/services/app_services.dart';
import '../../core/theme/app_theme.dart';
import '../../models/lesson.dart';
import '../../models/lesson_content.dart';
import '../../widgets/audio_player_button.dart';
import '../../widgets/audio_speed_control.dart';
import '../../widgets/back_circle_button.dart';
import '../../widgets/icon_badge.dart';
import '../../widgets/primary_button.dart';
import '../../widgets/soft_card.dart';
import '../lesson/lesson_complete_screen.dart';

/// UI-only — Phase 5/6 do not implement speech recognition, so this never
/// pretends to evaluate pronunciation. "I repeated it" is an honest
/// self-confirmation, not a graded attempt.
class SpeakingScreen extends StatefulWidget {
  final Lesson lesson;
  final int correct;
  final int incorrect;
  final int total;

  const SpeakingScreen({
    super.key,
    required this.lesson,
    required this.correct,
    required this.incorrect,
    required this.total,
  });

  @override
  State<SpeakingScreen> createState() => _SpeakingScreenState();
}

class _SpeakingScreenState extends State<SpeakingScreen> {
  bool _repeated = false;

  // Prefer the lesson's example sentence for speaking practice; fall back
  // to the last word if the lesson has no sentence-type content yet.
  LessonContent get _target {
    final sentences = widget.lesson.contents.where((c) => c.type == ContentType.sentence);
    return sentences.isNotEmpty ? sentences.last : widget.lesson.contents.last;
  }

  String get _sentence => _target.englishText;
  String? get _audioPath => _target.englishAudio;

  @override
  void dispose() {
    appServices.audio.stop();
    super.dispose();
  }

  void _continue() {
    appServices.audio.stop();
    // Complete is a terminal screen — drop Lesson/Exercise/Speak from the
    // stack so a hardware back press from it goes straight to Home.
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (_) => LessonCompleteScreen(
          lesson: widget.lesson,
          correct: widget.correct,
          incorrect: widget.incorrect,
          total: widget.total,
        ),
      ),
      (route) => route.isFirst,
    );
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.screen),
          child: Column(
            children: [
              Row(
                children: [
                  BackCircleButton(
                    onPressed: () {
                      appServices.audio.stop();
                      Navigator.of(context).pop();
                    },
                  ),
                ],
              ),
              Expanded(
                child: Center(
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('Say:', style: text.titleMedium?.copyWith(color: AppColors.textSecondary)),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: SoftCard(
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
                            child: Column(
                              children: [
                                Text(_sentence, style: text.headlineMedium?.copyWith(color: AppColors.primary), textAlign: TextAlign.center),
                                const SizedBox(height: 8),
                                Text(_target.kannadaText, style: text.bodyLarge?.copyWith(color: AppColors.textSecondary), textAlign: TextAlign.center),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        AudioPlayerButton(audioPath: _audioPath, label: 'sentence', size: 84),
                        if (appServices.audio.hasAudio(_audioPath)) ...[
                          const SizedBox(height: 16),
                          const AudioSpeedControl(),
                        ],
                        const SizedBox(height: 28),
                        if (_repeated) ...[
                          const IconBadge(icon: Icons.check_rounded, size: 72, background: AppColors.correct, foreground: Colors.white),
                          const SizedBox(height: 12),
                          Text('Good!', style: text.headlineSmall?.copyWith(color: AppColors.correct)),
                        ] else ...[
                          PrimaryButton(label: "I repeated it", icon: Icons.record_voice_over_rounded, onPressed: () => setState(() => _repeated = true)),
                          const SizedBox(height: 12),
                          Text('Repeat the sentence aloud.', style: text.bodyMedium),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
              if (_repeated)
                PrimaryButton(label: 'Continue', onPressed: _continue)
              else
                const SizedBox(height: 60),
            ],
          ),
        ),
      ),
    );
  }
}
