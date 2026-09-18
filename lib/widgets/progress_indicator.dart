import 'package:flutter/material.dart';
import '../core/theme/app_theme.dart';

/// Simple "step X of N" bar used on the lesson/practice screens.
class LessonProgressBar extends StatelessWidget {
  final int current;
  final int total;

  const LessonProgressBar({super.key, required this.current, required this.total});

  @override
  Widget build(BuildContext context) {
    final fraction = total == 0 ? 0.0 : current / total;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
            value: fraction.clamp(0.0, 1.0),
            minHeight: 10,
            backgroundColor: AppColors.primary.withValues(alpha: 0.15),
            valueColor: const AlwaysStoppedAnimation(AppColors.primary),
          ),
        ),
        const SizedBox(height: 6),
        Text('$current / $total', style: Theme.of(context).textTheme.bodyMedium),
      ],
    );
  }
}
