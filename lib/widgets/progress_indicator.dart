import 'package:flutter/material.dart';
import '../core/theme/app_theme.dart';

/// "Step X of N" bar used on the lesson/practice/conversation screens. Animates
/// smoothly between steps; the "X / N" label stays for clarity.
class LessonProgressBar extends StatelessWidget {
  final int current;
  final int total;

  const LessonProgressBar({super.key, required this.current, required this.total});

  @override
  Widget build(BuildContext context) {
    final fraction = (total == 0 ? 0.0 : current / total).clamp(0.0, 1.0);
    return Row(
      children: [
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: TweenAnimationBuilder<double>(
              tween: Tween(end: fraction),
              duration: const Duration(milliseconds: 350),
              curve: Curves.easeOutCubic,
              builder: (context, value, _) => LinearProgressIndicator(
                value: value,
                minHeight: 12,
                backgroundColor: AppColors.primarySoft,
                valueColor: const AlwaysStoppedAnimation(AppColors.primary),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Text('$current / $total', style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700)),
      ],
    );
  }
}
