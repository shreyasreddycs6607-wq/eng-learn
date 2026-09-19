import 'dart:async';

import 'package:flutter/material.dart';
import '../../core/services/app_services.dart';
import '../../core/theme/app_theme.dart';
import '../../models/lesson.dart';
import '../../models/lesson_content.dart';
import '../../widgets/audio_player_button.dart';
import '../../widgets/audio_speed_control.dart';
import '../../widgets/lesson_header.dart';
import '../../widgets/primary_button.dart';
import '../../widgets/soft_card.dart';
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

  String _typeLabel(ContentType type) => switch (type) {
        ContentType.word => 'Word',
        ContentType.sentence => 'Sentence',
        ContentType.pattern => 'Pattern',
        ContentType.example => 'Example',
      };

  @override
  Widget build(BuildContext context) {
    final content = widget.lesson.contents[_index];
    final text = Theme.of(context).textTheme;
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.screen),
          child: Column(
            children: [
              LessonHeader(current: _index + 1, total: widget.lesson.contents.length),
              Expanded(
                child: Center(
                  child: SingleChildScrollView(
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 220),
                      child: Column(
                        key: ValueKey(_index),
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                            decoration: BoxDecoration(color: AppColors.accentSoft, borderRadius: BorderRadius.circular(20)),
                            child: Text(
                              _typeLabel(content.type),
                              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.almost, letterSpacing: 0.4),
                            ),
                          ),
                          const SizedBox(height: 18),
                          SizedBox(
                            width: double.infinity,
                            child: SoftCard(
                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                              child: Column(
                                children: [
                                  Text(content.kannadaText, style: text.displayMedium, textAlign: TextAlign.center),
                                  const SizedBox(height: 16),
                                  Container(
                                    width: 48,
                                    height: 4,
                                    decoration: BoxDecoration(color: AppColors.accent, borderRadius: BorderRadius.circular(2)),
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    content.englishText,
                                    style: text.headlineMedium?.copyWith(color: AppColors.primary),
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 28),
                          AudioPlayerButton(audioPath: content.englishAudio, label: 'English pronunciation', size: 84),
                          if (appServices.audio.hasAudio(content.englishAudio)) ...[
                            const SizedBox(height: 16),
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
              ),
              const SizedBox(height: 12),
              PrimaryButton(label: 'Continue', onPressed: _next),
            ],
          ),
        ),
      ),
    );
  }
}
