import 'package:flutter/material.dart';
import '../core/theme/app_theme.dart';

/// The one back button used on every full-screen flow: a white circle with a
/// fine border, big enough to hit easily.
class BackCircleButton extends StatelessWidget {
  final VoidCallback? onPressed;

  const BackCircleButton({super.key, this.onPressed});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back_rounded),
      tooltip: 'Back',
      style: IconButton.styleFrom(
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.textPrimary,
        minimumSize: const Size(48, 48),
        side: const BorderSide(color: AppColors.border),
      ),
      onPressed: onPressed ?? () => Navigator.of(context).pop(),
    );
  }
}
