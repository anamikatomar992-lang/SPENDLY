import 'package:flutter/material.dart';
import 'app_colors.dart';

/// Clean typography hierarchy adhering to Material 3 type scales
class AppTypography {
  AppTypography._();

  static const String fontFamily = 'Roboto'; // System default fallback with clean geometry

  static TextTheme textTheme = const TextTheme(
    displayLarge: TextStyle(
      fontSize: 34,
      fontWeight: FontWeight.w700,
      color: AppColors.textPrimary,
      letterSpacing: -0.5,
    ),
    headlineLarge: TextStyle(
      fontSize: 28,
      fontWeight: FontWeight.w700,
      color: AppColors.textPrimary,
      letterSpacing: -0.5,
    ),
    headlineMedium: TextStyle(
      fontSize: 22,
      fontWeight: FontWeight.w600,
      color: AppColors.textPrimary,
      letterSpacing: -0.2,
    ),
    titleLarge: TextStyle(
      fontSize: 18,
      fontWeight: FontWeight.w600,
      color: AppColors.textPrimary,
    ),
    titleMedium: TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.w600,
      color: AppColors.textPrimary,
    ),
    titleSmall: TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.w600,
      color: AppColors.textPrimary,
    ),
    bodyLarge: TextStyle(
      fontSize: 15,
      fontWeight: FontWeight.w400,
      color: AppColors.textPrimary,
      height: 1.4,
    ),
    bodyMedium: TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.w400,
      color: AppColors.textSecondary,
      height: 1.4,
    ),
    bodySmall: TextStyle(
      fontSize: 12,
      fontWeight: FontWeight.w400,
      color: AppColors.textSecondary,
    ),
    labelLarge: TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.w600,
      color: AppColors.textPrimary,
      letterSpacing: 0.2,
    ),
    labelMedium: TextStyle(
      fontSize: 12,
      fontWeight: FontWeight.w500,
      color: AppColors.textSecondary,
      letterSpacing: 0.2,
    ),
    labelSmall: TextStyle(
      fontSize: 11,
      fontWeight: FontWeight.w600,
      color: AppColors.textTertiary,
      letterSpacing: 0.5,
    ),
  );
}
