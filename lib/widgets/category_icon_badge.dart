import 'package:flutter/material.dart';
import '../models/category_model.dart';

/// Clean circular/squircle icon badge with dynamic category color and soft tinted background
class CategoryIconBadge extends StatelessWidget {
  final CategoryModel category;
  final double size;
  final double iconSize;

  const CategoryIconBadge({
    super.key,
    required this.category,
    this.size = 44,
    this.iconSize = 22,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: category.color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(size * 0.32),
      ),
      child: Center(
        child: Icon(
          category.icon,
          size: iconSize,
          color: category.color,
        ),
      ),
    );
  }
}
