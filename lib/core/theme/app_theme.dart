import 'package:flutter/material.dart';

/// The app's palette. Warm ivory paper, a deep teal for actions, saffron for
/// warmth and highlights. Text colours keep a contrast ratio well above 4.5:1
/// on the ivory/white surfaces (large, legible text matters for an adult learner).
class AppColors {
  // Brand
  static const primary = Color(0xFF0E6B5C);
  static const primaryDark = Color(0xFF094A40);
  static const primarySoft = Color(0xFFDDF0EC);
  static const accent = Color(0xFFF0A03A);
  static const accentSoft = Color(0xFFFFF0D6);

  // Surfaces
  static const background = Color(0xFFFBF7F0);
  static const surface = Colors.white;
  static const border = Color(0xFFE9E1D3);

  // Text
  static const textPrimary = Color(0xFF1C2B29);
  static const textSecondary = Color(0xFF5E6E6B);

  // Feedback
  static const correct = Color(0xFF2E8B57);
  static const correctSoft = Color(0xFFE3F4EA);
  static const incorrect = Color(0xFFD64545);
  static const incorrectSoft = Color(0xFFFBE7E7);
  static const almost = Color(0xFFC9861A);
  static const almostSoft = Color(0xFFFFF1D9);
}

/// Spacing and shape tokens, so every screen uses the same rhythm.
class AppSpacing {
  static const screen = 24.0;
  static const radiusCard = 24.0;
  static const radiusControl = 18.0;
}

class AppTheme {
  /// Kannada vowel signs and English ascenders need generous line height, or
  /// tight boxes clip them — every style sets one.
  static TextTheme get _text => const TextTheme(
        displayLarge: TextStyle(fontSize: 44, fontWeight: FontWeight.w700, height: 1.3, color: AppColors.textPrimary),
        displayMedium: TextStyle(fontSize: 38, fontWeight: FontWeight.w700, height: 1.3, color: AppColors.textPrimary),
        displaySmall: TextStyle(fontSize: 32, fontWeight: FontWeight.w700, height: 1.3, color: AppColors.textPrimary),
        headlineMedium: TextStyle(fontSize: 28, fontWeight: FontWeight.w700, height: 1.35, color: AppColors.textPrimary),
        headlineSmall: TextStyle(fontSize: 24, fontWeight: FontWeight.w700, height: 1.35, color: AppColors.textPrimary),
        titleLarge: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, height: 1.35, color: AppColors.textPrimary),
        titleMedium: TextStyle(fontSize: 19, fontWeight: FontWeight.w600, height: 1.4, color: AppColors.textPrimary),
        bodyLarge: TextStyle(fontSize: 20, height: 1.45, color: AppColors.textPrimary),
        bodyMedium: TextStyle(fontSize: 17, height: 1.45, color: AppColors.textSecondary),
        labelLarge: TextStyle(fontSize: 19, fontWeight: FontWeight.w700, height: 1.3),
      );

  static ThemeData get light {
    final scheme = ColorScheme.fromSeed(seedColor: AppColors.primary).copyWith(
      primary: AppColors.primary,
      onPrimary: Colors.white,
      primaryContainer: AppColors.primarySoft,
      onPrimaryContainer: AppColors.primaryDark,
      secondary: AppColors.accent,
      secondaryContainer: AppColors.accentSoft,
      surface: AppColors.surface,
      onSurface: AppColors.textPrimary,
      outline: AppColors.border,
      error: AppColors.incorrect,
    );

    final controlShape = RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSpacing.radiusControl));

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: AppColors.background,
      textTheme: _text,
      splashFactory: InkSparkle.splashFactory,
      pageTransitionsTheme: const PageTransitionsTheme(builders: {
        TargetPlatform.android: FadeForwardsPageTransitionsBuilder(),
      }),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.background,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        foregroundColor: AppColors.textPrimary,
        titleTextStyle: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          minimumSize: const Size.fromHeight(60),
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          disabledBackgroundColor: AppColors.border,
          disabledForegroundColor: AppColors.textSecondary,
          elevation: 0,
          textStyle: const TextStyle(fontSize: 19, fontWeight: FontWeight.w700, letterSpacing: 0.3),
          shape: controlShape,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size.fromHeight(60),
          foregroundColor: AppColors.primary,
          backgroundColor: AppColors.surface,
          textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
          side: const BorderSide(color: AppColors.border, width: 2),
          shape: controlShape,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primary,
          textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
        ),
      ),
      cardTheme: CardThemeData(
        color: AppColors.surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusCard),
          side: const BorderSide(color: AppColors.border),
        ),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((s) => s.contains(WidgetState.selected) ? Colors.white : AppColors.textSecondary),
        trackColor: WidgetStateProperty.resolveWith((s) => s.contains(WidgetState.selected) ? AppColors.primary : AppColors.border),
        trackOutlineColor: const WidgetStatePropertyAll(Colors.transparent),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.textPrimary,
        contentTextStyle: const TextStyle(fontSize: 16, color: Colors.white, height: 1.4),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      dividerTheme: const DividerThemeData(color: AppColors.border, space: 1, thickness: 1),
    );
  }
}
