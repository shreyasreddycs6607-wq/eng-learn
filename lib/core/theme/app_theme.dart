import 'package:flutter/material.dart';

/// Small, calm design system: large type, high contrast, rounded shapes,
/// big touch targets. Intentionally has no dark mode / typography scale
/// beyond what's used — add only if a real screen needs it.
class AppColors {
  static const primary = Color(0xFF2E7D6B);
  static const background = Color(0xFFFAF7F0);
  static const surface = Colors.white;
  static const textPrimary = Color(0xFF1F2A28);
  static const textSecondary = Color(0xFF5C6A66);
  static const correct = Color(0xFF2E7D32);
  static const incorrect = Color(0xFFC62828);
  static const almost = Color(0xFFB8860B);
}

class AppTheme {
  static ThemeData get light {
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: AppColors.background,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primary,
        surface: AppColors.surface,
      ),
      textTheme: const TextTheme(
        displayMedium: TextStyle(fontSize: 40, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
        headlineMedium: TextStyle(fontSize: 28, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
        bodyLarge: TextStyle(fontSize: 20, color: AppColors.textPrimary),
        bodyMedium: TextStyle(fontSize: 17, color: AppColors.textSecondary),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          minimumSize: const Size.fromHeight(64),
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          textStyle: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        ),
      ),
      cardTheme: CardThemeData(
        color: AppColors.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size.fromHeight(60),
          foregroundColor: AppColors.textPrimary,
          textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
          side: const BorderSide(color: AppColors.primary, width: 2),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
      ),
    );
  }
}
