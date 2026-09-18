import 'package:flutter/material.dart';
import '../../core/services/app_services.dart';
import '../../models/lesson.dart';
import '../../widgets/audio_player_button.dart';
import '../../widgets/audio_speed_control.dart';
import '../../widgets/lesson_header.dart';
import '../../widgets/primary_button.dart';
import '../practice/practice_screen.dart';

class LessonScreen extends StatefulWidget {
  final Lesson lesson;

  const LessonScreen({super.key, required this.lesson});

  @override
  State<LessonScreen> createState() => _LessonScreenState();
}

class _LessonScreenState extends State<LessonScreen> {
  int _index = 0;

  @override
  void dispose() {
    appServices.audio.stop();
    super.dispose();
  }

  Future<void> _next() async {
    await appServices.audio.stop();
    if (_index < widget.lesson.contents.length - 1) {
      setState(() => _index++);
      return;
    }
    await appServices.progress.setCurrentLesson(widget.lesson.id);
    if (!mounted) return;
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => PracticeScreen(lesson: widget.lesson)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final content = widget.lesson.contents[_index];
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              LessonHeader(current: _index + 1, total: widget.lesson.contents.length),
              const Spacer(),
              Text(content.kannadaText, style: Theme.of(context).textTheme.displayMedium, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              Text(content.englishText, style: Theme.of(context).textTheme.headlineMedium, textAlign: TextAlign.center),
              const SizedBox(height: 32),
              AudioPlayerButton(audioPath: content.englishAudio, label: 'English pronunciation'),
              if (content.englishAudio != null) ...[
                const SizedBox(height: 12),
                const AudioSpeedControl(),
              ],
              if (content.teluguAudio != null) ...[
                const SizedBox(height: 16),
                AudioPlayerButton(audioPath: content.teluguAudio, label: 'Telugu explanation', showLabel: true),
              ],
              const Spacer(),
              PrimaryButton(label: 'Continue', onPressed: _next),
            ],
          ),
        ),
      ),
    );
  }
}
