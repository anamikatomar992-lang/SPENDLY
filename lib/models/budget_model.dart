/// Budget limit for a specific category or overall month
class BudgetModel {
  final String id;
  final String? categoryId; // null represents overall monthly budget
  final double limitAmount;
  final int month;
  final int year;

  const BudgetModel({
    required this.id,
    this.categoryId,
    required this.limitAmount,
    required this.month,
    required this.year,
  });

  bool get isOverall => categoryId == null;

  BudgetModel copyWith({
    String? id,
    String? categoryId,
    double? limitAmount,
    int? month,
    int? year,
  }) {
    return BudgetModel(
      id: id ?? this.id,
      categoryId: categoryId ?? this.categoryId,
      limitAmount: limitAmount ?? this.limitAmount,
      month: month ?? this.month,
      year: year ?? this.year,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'categoryId': categoryId,
      'limitAmount': limitAmount,
      'month': month,
      'year': year,
    };
  }

  Map<String, dynamic> toJson() => toMap();

  factory BudgetModel.fromJson(Map<String, dynamic> json) => BudgetModel.fromMap(json);

  factory BudgetModel.fromMap(Map<String, dynamic> map) {
    return BudgetModel(
      id: map['id'] as String? ?? 'budget_overall',
      categoryId: map['categoryId'] as String?,
      limitAmount: (map['limitAmount'] as num?)?.toDouble() ?? 2000.0,
      month: map['month'] as int? ?? DateTime.now().month,
      year: map['year'] as int? ?? DateTime.now().year,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BudgetModel &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}
