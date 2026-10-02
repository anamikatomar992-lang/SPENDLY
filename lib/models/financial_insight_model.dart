import 'package:flutter/material.dart';

/// Categories of rule-based financial insights
enum InsightType {
  achievement,
  warning,
  alert,
  info,
}

/// A personalized, actionable financial insight generated dynamically from user transactions
class FinancialInsight {
  final String id;
  final String title;
  final String message;
  final IconData icon;
  final Color color;
  final InsightType type;
  final double? metricValue;
  final String? badgeText;

  const FinancialInsight({
    required this.id,
    required this.title,
    required this.message,
    required this.icon,
    required this.color,
    required this.type,
    this.metricValue,
    this.badgeText,
  });
}
