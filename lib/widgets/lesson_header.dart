import 'package:flutter/material.dart';
import 'back_circle_button.dart';
import 'progress_indicator.dart';

/// Back button + progress, shared by Lesson/Exercise/Speak/Conversation screens
/// so back navigation and progress placement stay consistent everywhere.
class LessonHeader extends StatelessWidget {
  final int current;
  final int total;

  const LessonHeader({super.key, required this.current, required this.total});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const BackCircleButton(),
        const SizedBox(width: 14),
        Expanded(child: LessonProgressBar(current: current, total: total)),
      ],
    );
  }
}
