import 'package:flutter/material.dart';
import 'progress_indicator.dart';

/// Back button + lesson progress, shared by Lesson/Exercise/Speak screens
/// so back navigation and progress placement stay consistent everywhere.
class LessonHeader extends StatelessWidget {
  final int current;
  final int total;

  const LessonHeader({super.key, required this.current, required this.total});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.of(context).pop(),
        ),
        Expanded(child: LessonProgressBar(current: current, total: total)),
      ],
    );
  }
}
