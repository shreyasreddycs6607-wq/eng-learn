import 'package:flutter/material.dart';
import 'tap_throttle.dart';

class PrimaryButton extends StatefulWidget {
  final String label;
  final VoidCallback? onPressed;

  const PrimaryButton({super.key, required this.label, required this.onPressed});

  @override
  State<PrimaryButton> createState() => _PrimaryButtonState();
}

class _PrimaryButtonState extends State<PrimaryButton> with TapThrottle {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(onPressed: throttled(widget.onPressed), child: Text(widget.label)),
    );
  }
}
