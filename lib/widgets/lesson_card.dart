import 'package:flutter/material.dart';
import '../core/theme/app_theme.dart';
import '../models/lesson.dart';

class LessonCard extends StatelessWidget {
  final Lesson lesson;
  final bool completed;
  final VoidCallback onTap;

  const LessonCard({super.key, required this.lesson, required this.completed, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Icon(
                completed ? Icons.check_circle_rounded : Icons.play_circle_fill_rounded,
                color: AppColors.primary,
                size: 40,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(lesson.kannadaTitle, style: Theme.of(context).textTheme.headlineMedium),
                    Text(lesson.title, style: Theme.of(context).textTheme.bodyMedium),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
