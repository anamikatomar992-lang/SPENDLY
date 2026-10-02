import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// Reusable modern card component with subtle border and elevation
class CustomCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? margin;
  final Color? backgroundColor;
  final Gradient? gradient;
  final double borderRadius;
  final VoidCallback? onTap;
  final Border? border;
  final List<BoxShadow>? customShadow;

  const CustomCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.margin,
    this.backgroundColor,
    this.gradient,
    this.borderRadius = 20,
    this.onTap,
    this.border,
    this.customShadow,
  });

  @override
  Widget build(BuildContext context) {
    Widget content = Container(
      padding: padding,
      decoration: BoxDecoration(
        color: gradient == null ? (backgroundColor ?? AppColors.surfaceWhite) : null,
        gradient: gradient,
        borderRadius: BorderRadius.circular(borderRadius),
        border: border ?? Border.all(color: AppColors.borderSubtle, width: 1),
        boxShadow: customShadow ?? AppColors.cardShadow,
      ),
      child: child,
    );

    if (onTap != null) {
      return Container(
        margin: margin,
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(borderRadius),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(borderRadius),
            child: content,
          ),
        ),
      );
    }

    if (margin != null) {
      return Padding(
        padding: margin!,
        child: content,
      );
    }

    return content;
  }
}
