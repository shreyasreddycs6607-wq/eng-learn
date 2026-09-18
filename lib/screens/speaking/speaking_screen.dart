import 'package:flutter/material.dart';
import '../../core/services/app_services.dart';
import '../../core/theme/app_theme.dart';
import '../../models/lesson.dart';
import '../../models/lesson_content.dart';
import '../../widgets/audio_player_button.dart';
import '../../widgets/audio_speed_control.dart';
import '../../widgets/primary_button.dart';
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
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_rounded),
                    onPressed: () {
                      appServices.audio.stop();
                      Navigator.of(context).pop();
                    },
                  ),
                ],
              ),
              const Spacer(),
              Text('Say:', style: Theme.of(context).textTheme.bodyLarge),
              const SizedBox(height: 16),
              Text(_sentence, style: Theme.of(context).textTheme.headlineMedium, textAlign: TextAlign.center),
              const SizedBox(height: 32),
              AudioPlayerButton(audioPath: _audioPath, label: 'sentence'),
              if (_audioPath != null) ...[
                const SizedBox(height: 12),
                const AudioSpeedControl(),
              ],
              const SizedBox(height: 28),
              if (_repeated)
                const Icon(Icons.check_circle_rounded, color: AppColors.correct, size: 56)
              else
                PrimaryButton(label: "I repeated it", onPressed: () => setState(() => _repeated = true)),
              const SizedBox(height: 12),
              Text(_repeated ? 'Good!' : 'Repeat the sentence aloud.', style: Theme.of(context).textTheme.bodyMedium),
              const Spacer(),
              if (_repeated)
                PrimaryButton(label: 'Continue', onPressed: _continue)
              else
                const SizedBox(height: 64),
            ],
          ),
        ),
      ),
    );
  }
}
