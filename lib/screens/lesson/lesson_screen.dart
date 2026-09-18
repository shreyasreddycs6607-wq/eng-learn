import 'dart:async';

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
  bool _leaving = false;

  @override
  void dispose() {
    appServices.audio.stop();
    super.dispose();
  }

  void _next() {
    if (_leaving) return;
    unawaited(appServices.audio.stop());
    if (_index < widget.lesson.contents.length - 1) {
      setState(() => _index++);
      return;
    }
    _leaving = true;
    Navigator.of(context)
        .push(MaterialPageRoute(builder: (_) => PracticeScreen(lesson: widget.lesson)))
        .then((_) => _leaving = false); // coming back (Back from Practice) re-enables Continue
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
              Expanded(
                child: Center(
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(content.kannadaText, style: Theme.of(context).textTheme.displayMedium, textAlign: TextAlign.center),
                        const SizedBox(height: 16),
                        Text(content.englishText, style: Theme.of(context).textTheme.headlineMedium, textAlign: TextAlign.center),
                        const SizedBox(height: 32),
                        AudioPlayerButton(audioPath: content.englishAudio, label: 'English pronunciation'),
                        if (appServices.audio.hasAudio(content.englishAudio)) ...[
                          const SizedBox(height: 12),
                          const AudioSpeedControl(),
                        ],
                        if (appServices.audio.hasAudio(content.teluguAudio)) ...[
                          const SizedBox(height: 16),
                          AudioPlayerButton(audioPath: content.teluguAudio, label: 'Telugu explanation', showLabel: true),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
              PrimaryButton(label: 'Continue', onPressed: _next),
            ],
          ),
        ),
      ),
    );
  }
}
