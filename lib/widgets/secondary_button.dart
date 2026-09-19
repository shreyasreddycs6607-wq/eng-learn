import 'package:flutter/material.dart';
import 'tap_throttle.dart';

/// Lower-emphasis action next to a PrimaryButton (e.g. "Practice Again", "Change time").
class SecondaryButton extends StatefulWidget {
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;

  const SecondaryButton({super.key, required this.label, required this.onPressed, this.icon});

  @override
  State<SecondaryButton> createState() => _SecondaryButtonState();
}

class _SecondaryButtonState extends State<SecondaryButton> with TapThrottle {
  @override
  Widget build(BuildContext context) {
    final label = Text(widget.label, textAlign: TextAlign.center);
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton(
        onPressed: throttled(widget.onPressed),
        child: widget.icon == null
            ? label
            : Row(
                mainAxisSize: MainAxisSize.min,
                children: [Icon(widget.icon, size: 22), const SizedBox(width: 10), Flexible(child: label)],
              ),
      ),
    );
  }
}
