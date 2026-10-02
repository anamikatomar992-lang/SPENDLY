import 'package:flutter/material.dart';

/// Supported expense and income category representations
class CategoryModel {
  final String id;
  final String name;
  final IconData icon;
  final Color color;
  final bool isDefault;

  const CategoryModel({
    required this.id,
    required this.name,
    required this.icon,
    required this.color,
    this.isDefault = true,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'iconCodePoint': icon.codePoint,
      'iconFontFamily': icon.fontFamily,
      'iconFontPackage': icon.fontPackage,
      'colorValue': color.toARGB32(),
      'isDefault': isDefault,
    };
  }

  Map<String, dynamic> toJson() => toMap();

  factory CategoryModel.fromJson(Map<String, dynamic> json) => CategoryModel.fromMap(json);

  factory CategoryModel.fromMap(Map<String, dynamic> map) {
    final id = map['id'] as String? ?? 'other';
    final name = map['name'] as String? ?? 'Custom Category';
    final isDefault = map['isDefault'] as bool? ?? false;

    // If it's a known default category, reuse its official constant
    if (isDefault) {
      final defaultCat = findById(id);
      if (defaultCat.id != 'other' || id == 'other') {
        return defaultCat;
      }
    }

    // Custom or modified category: reconstruct icon and color
    final iconCodePoint = map['iconCodePoint'] as int?;
    final colorVal = map['colorValue'] as int? ?? 0xFF64748B;

    IconData resolvedIcon = Icons.category_rounded;
    if (iconCodePoint != null) {
      for (final ic in availableIcons) {
        if (ic.codePoint == iconCodePoint) {
          resolvedIcon = ic;
          break;
        }
      }
    }

    return CategoryModel(
      id: id,
      name: name,
      icon: resolvedIcon,
      color: Color(colorVal),
      isDefault: isDefault,
    );
  }

  CategoryModel copyWith({
    String? id,
    String? name,
    IconData? icon,
    Color? color,
    bool? isDefault,
  }) {
    return CategoryModel(
      id: id ?? this.id,
      name: name ?? this.name,
      icon: icon ?? this.icon,
      color: color ?? this.color,
      isDefault: isDefault ?? this.isDefault,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CategoryModel &&
          runtimeType == other.runtimeType &&
          id.toLowerCase() == other.id.toLowerCase();

  @override
  int get hashCode => id.toLowerCase().hashCode;

  // Validation
  static String? validateName(String? val, [List<CategoryModel>? existingCategories, String? editingId]) {
    if (val == null || val.trim().isEmpty) {
      return 'Please enter a category name';
    }
    if (val.trim().length < 2) {
      return 'Name must be at least 2 characters';
    }
    if (val.trim().length > 30) {
      return 'Name cannot exceed 30 characters';
    }
    if (existingCategories != null) {
      final lower = val.trim().toLowerCase();
      final duplicate = existingCategories.any(
        (cat) => cat.name.toLowerCase() == lower && cat.id != editingId,
      );
      if (duplicate) {
        return 'A category with this name already exists';
      }
    }
    return null;
  }

  // Pre-configured official categories
  static const CategoryModel food = CategoryModel(
    id: 'food',
    name: 'Food',
    icon: Icons.restaurant_rounded,
    color: Color(0xFFF97316), // Warm Orange
  );

  static const CategoryModel transportation = CategoryModel(
    id: 'transportation',
    name: 'Transportation',
    icon: Icons.directions_car_filled_rounded,
    color: Color(0xFF0284C7), // Blue
  );

  static const CategoryModel shopping = CategoryModel(
    id: 'shopping',
    name: 'Shopping',
    icon: Icons.shopping_bag_rounded,
    color: Color(0xFFEC4899), // Pink
  );

  static const CategoryModel education = CategoryModel(
    id: 'education',
    name: 'Education',
    icon: Icons.school_rounded,
    color: Color(0xFF8B5CF6), // Purple
  );

  static const CategoryModel entertainment = CategoryModel(
    id: 'entertainment',
    name: 'Entertainment',
    icon: Icons.movie_creation_rounded,
    color: Color(0xFFA855F7), // Violet
  );

  static const CategoryModel health = CategoryModel(
    id: 'health',
    name: 'Health',
    icon: Icons.medical_services_rounded,
    color: Color(0xFF10B981), // Emerald
  );

  static const CategoryModel bills = CategoryModel(
    id: 'bills',
    name: 'Bills',
    icon: Icons.receipt_long_rounded,
    color: Color(0xFFEF4444), // Crimson
  );

  static const CategoryModel travel = CategoryModel(
    id: 'travel',
    name: 'Travel',
    icon: Icons.flight_takeoff_rounded,
    color: Color(0xFF14B8A6), // Teal
  );

  static const CategoryModel other = CategoryModel(
    id: 'other',
    name: 'Other',
    icon: Icons.category_rounded,
    color: Color(0xFF64748B), // Slate
  );

  static const CategoryModel salary = CategoryModel(
    id: 'salary',
    name: 'Salary / Income',
    icon: Icons.account_balance_wallet_rounded,
    color: Color(0xFF059669), // Green
  );

  static const List<CategoryModel> defaultCategories = [
    food,
    transportation,
    shopping,
    education,
    entertainment,
    health,
    bills,
    travel,
    other,
  ];

  static List<CategoryModel> customRegistry = [];

  static CategoryModel findById(String id, [List<CategoryModel>? customList]) {
    if (id.toLowerCase() == salary.id.toLowerCase()) return salary;

    final list = customList ?? customRegistry;
    for (final cat in list) {
      if (cat.id.toLowerCase() == id.toLowerCase()) return cat;
    }

    return defaultCategories.firstWhere(
      (cat) => cat.id.toLowerCase() == id.toLowerCase(),
      orElse: () => other,
    );
  }

  // Curated modern icon options for custom categories
  static const List<IconData> availableIcons = [
    Icons.restaurant_rounded,
    Icons.local_cafe_rounded,
    Icons.fastfood_rounded,
    Icons.shopping_bag_rounded,
    Icons.shopping_cart_rounded,
    Icons.directions_car_filled_rounded,
    Icons.flight_takeoff_rounded,
    Icons.train_rounded,
    Icons.sports_esports_rounded,
    Icons.fitness_center_rounded,
    Icons.pets_rounded,
    Icons.computer_rounded,
    Icons.phone_iphone_rounded,
    Icons.home_rounded,
    Icons.school_rounded,
    Icons.book_rounded,
    Icons.medical_services_rounded,
    Icons.receipt_long_rounded,
    Icons.card_giftcard_rounded,
    Icons.subscriptions_rounded,
    Icons.savings_rounded,
    Icons.work_rounded,
    Icons.music_note_rounded,
    Icons.build_rounded,
  ];

  // Curated palette of modern finance colors
  static const List<Color> availableColors = [
    Color(0xFFF97316), // Warm Orange
    Color(0xFF0284C7), // Cerulean Blue
    Color(0xFFEC4899), // Pink
    Color(0xFF8B5CF6), // Purple
    Color(0xFFA855F7), // Violet
    Color(0xFF10B981), // Emerald Green
    Color(0xFFEF4444), // Crimson Red
    Color(0xFF14B8A6), // Teal
    Color(0xFF06B6D4), // Cyan
    Color(0xFFEAB308), // Amber / Gold
    Color(0xFF6366F1), // Indigo
    Color(0xFF64748B), // Slate Grey
  ];
}
