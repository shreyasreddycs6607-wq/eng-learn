import 'package:flutter/material.dart';
import '../core/theme/app_theme.dart';

class LessonCompleteCard extends StatelessWidget {
  final int correct;
  final int total;

  const LessonCompleteCard({super.key, required this.correct, required this.total});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Text('🎉', style: TextStyle(fontSize: 56)),
        const SizedBox(height: 16),
        Text('Lesson Complete!', style: Theme.of(context).textTheme.headlineMedium),
        const SizedBox(height: 8),
        Text('Great job ❤️', style: Theme.of(context).textTheme.bodyLarge),
        const SizedBox(height: 20),
        Text('$correct / $total', style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: AppColors.primary)),
      ],
    );
  }
}
