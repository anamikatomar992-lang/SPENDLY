import 'package:flutter/material.dart';
import 'category_model.dart';
import 'transaction_model.dart';

/// Precomputed financial analytics summary for a specific timeframe or date range
class FinancialSummary {
  final double totalIncome;
  final double totalExpense;
  final int totalTransactionCount;
  final int incomeTransactionCount;
  final int expenseTransactionCount;
  final double averageDailyExpense;
  final CategoryModel? topExpenseCategory;
  final double topExpenseAmount;
  final Map<CategoryModel, double> categoryBreakdown;
  final DateTimeRange? dateRange;

  const FinancialSummary({
    required this.totalIncome,
    required this.totalExpense,
    required this.totalTransactionCount,
    required this.incomeTransactionCount,
    required this.expenseTransactionCount,
    required this.averageDailyExpense,
    required this.topExpenseCategory,
    required this.topExpenseAmount,
    required this.categoryBreakdown,
    this.dateRange,
  });

  /// Net balance (Cash Flow = Inflow - Outflow)
  double get netBalance => totalIncome - totalExpense;

  /// Whether user is running at a financial deficit (spending > income)
  bool get isDeficit => netBalance < 0;

  /// Accurate savings percentage calculation, handling zero/negative income gracefully
  double get savingsRate {
    if (totalIncome <= 0) return 0.0;
    if (netBalance <= 0) return 0.0;
    final rate = (netBalance / totalIncome) * 100.0;
    return rate.clamp(0.0, 100.0);
  }

  /// Percentage of total expenses represented by the top category
  double get topCategoryPercentage {
    if (totalExpense <= 0 || topExpenseAmount <= 0) return 0.0;
    return ((topExpenseAmount / totalExpense) * 100.0).clamp(0.0, 100.0);
  }

  /// Factory constructor to compute financial intelligence metrics from raw transactions
  factory FinancialSummary.fromTransactions({
    required List<TransactionModel> transactions,
    required List<CategoryModel> allCategories,
    DateTimeRange? dateRange,
  }) {
    if (transactions.isEmpty) {
      return FinancialSummary(
        totalIncome: 0.0,
        totalExpense: 0.0,
        totalTransactionCount: 0,
        incomeTransactionCount: 0,
        expenseTransactionCount: 0,
        averageDailyExpense: 0.0,
        topExpenseCategory: null,
        topExpenseAmount: 0.0,
        categoryBreakdown: const {},
        dateRange: dateRange,
      );
    }

    double income = 0.0;
    double expense = 0.0;
    int incomeCount = 0;
    int expenseCount = 0;

    final Map<String, double> categoryTotals = {};

    for (final tx in transactions) {
      if (tx.isIncome) {
        income += tx.amount;
        incomeCount++;
      } else {
        expense += tx.amount;
        expenseCount++;
        final catId = tx.categoryId.toLowerCase();
        categoryTotals[catId] = (categoryTotals[catId] ?? 0.0) + tx.amount;
      }
    }

    // Resolve CategoryModel for each breakdown entry
    final Map<CategoryModel, double> resolvedBreakdown = {};
    CategoryModel? topCat;
    double topAmount = 0.0;

    final sortedEntries = categoryTotals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    for (final entry in sortedEntries) {
      final category = CategoryModel.findById(entry.key, allCategories);
      resolvedBreakdown[category] = entry.value;

      if (entry.value > topAmount) {
        topAmount = entry.value;
        topCat = category;
      }
    }

    // Calculate days for daily average
    int days = 1;
    if (dateRange != null) {
      days = dateRange.duration.inDays.clamp(1, 3650);
    } else {
      // Find difference between earliest and latest transaction
      final dates = transactions.map((t) => t.date).toList()..sort();
      if (dates.length > 1) {
        days = dates.last.difference(dates.first).inDays.clamp(1, 3650);
      }
    }

    final avgDaily = expense / days;

    return FinancialSummary(
      totalIncome: income,
      totalExpense: expense,
      totalTransactionCount: transactions.length,
      incomeTransactionCount: incomeCount,
      expenseTransactionCount: expenseCount,
      averageDailyExpense: avgDaily,
      topExpenseCategory: topCat,
      topExpenseAmount: topAmount,
      categoryBreakdown: resolvedBreakdown,
      dateRange: dateRange,
    );
  }
}
