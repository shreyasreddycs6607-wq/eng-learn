import 'package:flutter/material.dart';
import '../core/theme/app_theme.dart';
import 'icon_badge.dart';
import 'primary_button.dart';

/// A calm full-screen message with one obvious action: intros, empty states,
/// errors and "complete" screens all use this, so they look and behave alike.
class MessageView extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final Color iconBackground;
  final String title;
  final String? body;
  final String primaryLabel;
  final VoidCallback onPrimary;
  final Widget? secondary;

  const MessageView({
    super.key,
    required this.icon,
    this.iconColor = AppColors.primary,
    this.iconBackground = AppColors.primarySoft,
    required this.title,
    this.body,
    required this.primaryLabel,
    required this.onPrimary,
    this.secondary,
  });

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(AppSpacing.screen, 0, AppSpacing.screen, AppSpacing.screen),
          child: Column(
            children: [
              Expanded(
                child: Center(
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconBadge(icon: icon, size: 96, background: iconBackground, foreground: iconColor),
                        const SizedBox(height: 28),
                        Text(title, style: text.headlineMedium, textAlign: TextAlign.center),
                        if (body != null) ...[
                          const SizedBox(height: 14),
                          Text(body!, style: text.bodyLarge?.copyWith(color: AppColors.textSecondary), textAlign: TextAlign.center),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
              PrimaryButton(label: primaryLabel, onPressed: onPrimary),
              if (secondary != null) ...[const SizedBox(height: 12), secondary!],
            ],
          ),
        ),
      ),
    );
  }
}
