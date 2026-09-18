import 'package:flutter/material.dart';
import 'tap_throttle.dart';

/// Lower-emphasis action next to a PrimaryButton (e.g. "My Progress", "Review Lesson").
class SecondaryButton extends StatefulWidget {
  final String label;
  final VoidCallback? onPressed;

  const SecondaryButton({super.key, required this.label, required this.onPressed});

  @override
  State<SecondaryButton> createState() => _SecondaryButtonState();
}

class _SecondaryButtonState extends State<SecondaryButton> with TapThrottle {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton(onPressed: throttled(widget.onPressed), child: Text(widget.label)),
    );
  }
}
