import 'package:flutter/material.dart';
import '../core/theme/app_theme.dart';

/// An icon on a soft coloured disc — used for feedback, categories and empty states.
class IconBadge extends StatelessWidget {
  final IconData icon;
  final double size;
  final Color background;
  final Color foreground;

  const IconBadge({
    super.key,
    required this.icon,
    this.size = 48,
    this.background = AppColors.primarySoft,
    this.foreground = AppColors.primary,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: background, shape: BoxShape.circle),
      child: Icon(icon, color: foreground, size: size * 0.5),
    );
  }
}
