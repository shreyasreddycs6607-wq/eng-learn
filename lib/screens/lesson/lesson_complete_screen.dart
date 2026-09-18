import 'package:flutter/material.dart';
import '../../core/services/app_services.dart';
import '../../models/lesson.dart';
import '../../widgets/lesson_complete_card.dart';
import '../../widgets/primary_button.dart';
import '../../widgets/secondary_button.dart';
import '../home/home_screen.dart';
import 'lesson_screen.dart';

class LessonCompleteScreen extends StatefulWidget {
  final Lesson lesson;
  final int correct;
  final int incorrect;
  final int total;

  const LessonCompleteScreen({
    super.key,
    required this.lesson,
    required this.correct,
    required this.incorrect,
    required this.total,
  });

  @override
  State<LessonCompleteScreen> createState() => _LessonCompleteScreenState();
}

class _LessonCompleteScreenState extends State<LessonCompleteScreen> {
  @override
  void initState() {
    super.initState();
    appServices.progress.completeLesson(
      lessonId: widget.lesson.id,
      correctInPass: widget.correct,
      incorrectInPass: widget.incorrect,
    );
  }

  void _goHome() {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const HomeScreen()),
      (route) => false,
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
              const Spacer(),
              LessonCompleteCard(correct: widget.correct, total: widget.total),
              const Spacer(),
              PrimaryButton(label: 'Continue', onPressed: _goHome),
              const SizedBox(height: 12),
              SecondaryButton(
                label: 'Review Lesson',
                onPressed: () => Navigator.of(context).pushReplacement(
                  MaterialPageRoute(builder: (_) => LessonScreen(lesson: widget.lesson)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
