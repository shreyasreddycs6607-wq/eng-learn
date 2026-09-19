import 'package:flutter/material.dart';
import '../core/theme/app_theme.dart';

/// The app's one card surface: white paper, fine warm border, a very soft
/// shadow. Tappable when [onTap] is given.
class SoftCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  final Color color;
  final Color? borderColor;
  final bool shadow;

  const SoftCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(20),
    this.onTap,
    this.color = AppColors.surface,
    this.borderColor,
    this.shadow = true,
  });

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(AppSpacing.radiusCard);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: color,
        borderRadius: radius,
        border: Border.all(color: borderColor ?? AppColors.border),
        boxShadow: shadow
            ? const [BoxShadow(color: Color(0x100E3B33), blurRadius: 20, offset: Offset(0, 8))]
            : null,
      ),
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          borderRadius: radius,
          onTap: onTap,
          child: Padding(padding: padding, child: child),
        ),
      ),
    );
  }
}
