import 'category_model.dart';

enum TransactionType {
  expense,
  income;

  String get label => this == TransactionType.expense ? 'Expense' : 'Income';
}

enum PaymentMethod {
  card('Credit/Debit Card'),
  cash('Cash'),
  bankTransfer('Bank Transfer'),
  upi('UPI / Digital Wallet');

  final String label;
  const PaymentMethod(this.label);

  static PaymentMethod fromString(String? val) {
    if (val == null) return PaymentMethod.card;
    return PaymentMethod.values.firstWhere(
      (e) => e.name.toLowerCase() == val.toLowerCase() || e.label.toLowerCase() == val.toLowerCase(),
      orElse: () => PaymentMethod.card,
    );
  }
}

enum TransactionSortOrder {
  dateDescending('Date: Newest First'),
  dateAscending('Date: Oldest First'),
  amountDescending('Amount: Highest First'),
  amountAscending('Amount: Lowest First');

  final String label;
  const TransactionSortOrder(this.label);
}

class TransactionModel {
  final String id;
  final String title;
  final double amount;
  final DateTime date;
  final String categoryId;
  final TransactionType type;
  final PaymentMethod paymentMethod;
  final String? note;
  final DateTime updatedAt;
  final bool isSample;
  final bool isDeleted;

  TransactionModel({
    required this.id,
    required this.title,
    required this.amount,
    required DateTime date,
    required this.categoryId,
    required this.type,
    this.paymentMethod = PaymentMethod.card,
    this.note,
    DateTime? updatedAt,
    this.isSample = false,
    this.isDeleted = false,
  })  : date = date.toUtc(),
        updatedAt = (updatedAt ?? date).toUtc();

  bool get isExpense => type == TransactionType.expense;
  bool get isIncome => type == TransactionType.income;

  CategoryModel get category => CategoryModel.findById(categoryId);

  // Validation helpers
  static String? validateTitle(String? val) {
    if (val == null || val.trim().isEmpty) {
      return 'Please enter a transaction title';
    }
    if (val.trim().length > 60) {
      return 'Title cannot exceed 60 characters';
    }
    return null;
  }

  static String? validateAmount(String? val) {
    if (val == null || val.trim().isEmpty) {
      return 'Please enter an amount';
    }
    final parsed = double.tryParse(val.trim());
    if (parsed == null) {
      return 'Please enter a valid numeric amount';
    }
    if (parsed <= 0) {
      return 'Amount must be greater than zero';
    }
    if (parsed > 100000000) {
      return 'Amount exceeds maximum supported limit';
    }
    return null;
  }

  static String? validateDate(DateTime? val) {
    if (val == null) {
      return 'Please select a date';
    }
    final now = DateTime.now();
    // Allow up to 1 year in future or 10 years in the past
    if (val.isAfter(now.add(const Duration(days: 366)))) {
      return 'Date cannot be more than 1 year in the future';
    }
    return null;
  }

  TransactionModel copyWith({
    String? id,
    String? title,
    double? amount,
    DateTime? date,
    String? categoryId,
    TransactionType? type,
    PaymentMethod? paymentMethod,
    String? note,
    DateTime? updatedAt,
    bool? isSample,
    bool? isDeleted,
  }) {
    return TransactionModel(
      id: id ?? this.id,
      title: title ?? this.title,
      amount: amount ?? this.amount,
      date: date ?? this.date,
      categoryId: categoryId ?? this.categoryId,
      type: type ?? this.type,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      note: note ?? this.note,
      updatedAt: updatedAt ?? this.updatedAt,
      isSample: isSample ?? this.isSample,
      isDeleted: isDeleted ?? this.isDeleted,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'amount': amount,
      'date': date.toUtc().toIso8601String(),
      'categoryId': categoryId,
      'type': type.name,
      'paymentMethod': paymentMethod.name,
      'note': note,
      'updatedAt': updatedAt.toUtc().toIso8601String(),
      'isSample': isSample,
      'isDeleted': isDeleted,
    };
  }

  Map<String, dynamic> toJson() => toMap();

  factory TransactionModel.fromJson(Map<String, dynamic> json) => TransactionModel.fromMap(json);

  factory TransactionModel.fromMap(Map<String, dynamic> map) {
    final date = map['date'] != null
        ? (DateTime.tryParse(map['date'] as String)?.toUtc() ?? DateTime.now().toUtc())
        : DateTime.now().toUtc();
    final updatedAt = map['updatedAt'] != null
        ? (DateTime.tryParse(map['updatedAt'] as String)?.toUtc() ?? date)
        : date;

    return TransactionModel(
      id: map['id'] as String,
      title: map['title'] as String? ?? 'Untitled Transaction',
      amount: (map['amount'] as num?)?.toDouble() ?? 0.0,
      date: date,
      categoryId: map['categoryId'] as String? ?? CategoryModel.other.id,
      type: (map['type'] as String?)?.toLowerCase() == 'income'
          ? TransactionType.income
          : TransactionType.expense,
      paymentMethod: PaymentMethod.fromString(map['paymentMethod'] as String?),
      note: map['note'] as String?,
      updatedAt: updatedAt,
      isSample: map['isSample'] as bool? ?? false,
      isDeleted: map['isDeleted'] as bool? ?? false,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TransactionModel &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}
