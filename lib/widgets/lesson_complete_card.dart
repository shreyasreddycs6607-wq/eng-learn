import 'package:flutter/material.dart';
import '../core/theme/app_theme.dart';

/// The celebration at the end of a lesson: a score ring that fills in, and a
/// warm Kannada "well done" — never a grade, always encouraging.
class LessonCompleteCard extends StatelessWidget {
  final int correct;
  final int total;

  const LessonCompleteCard({super.key, required this.correct, required this.total});

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final fraction = total == 0 ? 1.0 : (correct / total).clamp(0.0, 1.0);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 168,
          height: 168,
          child: Stack(
            alignment: Alignment.center,
            children: [
              SizedBox.expand(
                child: TweenAnimationBuilder<double>(
                  tween: Tween(end: fraction),
                  duration: const Duration(milliseconds: 900),
                  curve: Curves.easeOutCubic,
                  builder: (context, value, _) => CircularProgressIndicator(
                    value: value,
                    strokeWidth: 14,
                    strokeCap: StrokeCap.round,
                    backgroundColor: AppColors.primarySoft,
                    valueColor: const AlwaysStoppedAnimation(AppColors.primary),
                  ),
                ),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('$correct / $total', style: const TextStyle(fontSize: 38, fontWeight: FontWeight.w800, height: 1.2, color: AppColors.primary)),
                  Text('correct', style: text.bodyMedium),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 28),
        Text('Lesson Complete!', style: text.headlineMedium, textAlign: TextAlign.center),
        const SizedBox(height: 8),
        Text('ಚೆನ್ನಾಗಿ ಮಾಡಿದ್ದೀರಿ!', style: text.headlineSmall?.copyWith(color: AppColors.primary), textAlign: TextAlign.center),
        const SizedBox(height: 4),
        Text('Great job', style: text.bodyMedium),
      ],
    );
  }
}
