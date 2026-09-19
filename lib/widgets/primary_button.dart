import 'package:flutter/material.dart';
import 'tap_throttle.dart';

/// The one obvious action on a screen. [color] lets feedback tint it
/// (green for correct, etc.); [icon] adds a leading glyph; [foregroundColor]
/// is for buttons on a coloured surface (e.g. white on the Home hero card).
class PrimaryButton extends StatefulWidget {
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final Color? color;
  final Color? foregroundColor;

  const PrimaryButton({super.key, required this.label, required this.onPressed, this.icon, this.color, this.foregroundColor});

  @override
  State<PrimaryButton> createState() => _PrimaryButtonState();
}

class _PrimaryButtonState extends State<PrimaryButton> with TapThrottle {
  @override
  Widget build(BuildContext context) {
    final label = Text(widget.label, textAlign: TextAlign.center);
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: throttled(widget.onPressed),
        style: widget.color == null && widget.foregroundColor == null
            ? null
            : ElevatedButton.styleFrom(backgroundColor: widget.color, foregroundColor: widget.foregroundColor),
        child: widget.icon == null
            ? label
            : Row(
                mainAxisSize: MainAxisSize.min,
                children: [Icon(widget.icon, size: 24), const SizedBox(width: 10), Flexible(child: label)],
              ),
      ),
    );
  }
}
