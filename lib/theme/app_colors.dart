import 'package:flutter/material.dart';

/// Centralized color definitions for Spendly Design System
class AppColors {
  AppColors._();

  // Primary Navy Tones
  static const Color primaryNavy = Color(0xFF0F172A);
  static const Color navyMedium = Color(0xFF1E293B);
  static const Color navyLight = Color(0xFF334155);

  // Emerald Green Tones (Income / Positive / Accent)
  static const Color emeraldGreen = Color(0xFF10B981);
  static const Color emeraldDark = Color(0xFF059669);
  static const Color emeraldLight = Color(0xFFD1FAE5);
  static const Color emeraldBackground = Color(0xFFECFDF5);

  // Alert & Expense Tones (Expenses / Negative / Alerts)
  static const Color expenseCoral = Color(0xFFEF4444);
  static const Color expenseLight = Color(0xFFFEE2E2);
  static const Color expenseBackground = Color(0xFFFEF2F2);

  // Warning & Neutral Accents
  static const Color warningAmber = Color(0xFFF59E0B);
  static const Color warningLight = Color(0xFFFEF3C7);
  static const Color infoBlue = Color(0xFF3B82F6);
  static const Color infoLight = Color(0xFFEFF6FF);

  // Backgrounds & Surface Canvas
  static const Color backgroundCanvas = Color(0xFFF8FAFC);
  static const Color surfaceWhite = Color(0xFFFFFFFF);
  static const Color surfaceMuted = Color(0xFFF1F5F9);

  // Text Colors
  static const Color textPrimary = Color(0xFF0F172A);
  static const Color textSecondary = Color(0xFF64748B);
  static const Color textTertiary = Color(0xFF94A3B8);
  static const Color textInverse = Color(0xFFFFFFFF);

  // Dividers & Outlines
  static const Color borderLight = Color(0xFFE2E8F0);
  static const Color borderSubtle = Color(0xFFF1F5F9);

  // Shadows
  static const List<BoxShadow> cardShadow = [
    BoxShadow(
      color: Color(0x080F172A),
      blurRadius: 16,
      spreadRadius: 0,
      offset: Offset(0, 4),
    ),
    BoxShadow(
      color: Color(0x040F172A),
      blurRadius: 4,
      spreadRadius: 0,
      offset: Offset(0, 1),
    ),
  ];

  static const List<BoxShadow> heroCardShadow = [
    BoxShadow(
      color: Color(0x250F172A),
      blurRadius: 24,
      spreadRadius: 0,
      offset: Offset(0, 8),
    ),
  ];
}
