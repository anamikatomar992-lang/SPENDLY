/// Aggregated monthly metric snapshot for multi-month trends and charts
class MonthlyDataPoint {
  final int year;
  final int month;
  final String monthLabel;
  final double income;
  final double expense;

  const MonthlyDataPoint({
    required this.year,
    required this.month,
    required this.monthLabel,
    required this.income,
    required this.expense,
  });

  double get netSavings => income - expense;

  double get savingsRate {
    if (income <= 0 || netSavings <= 0) return 0.0;
    return (netSavings / income * 100.0).clamp(0.0, 100.0);
  }

  bool get isDeficit => netSavings < 0;

  DateTime get dateTime => DateTime(year, month, 1);
}

/// Month-over-month comparison analysis
class MonthOverMonthComparison {
  final MonthlyDataPoint currentMonth;
  final MonthlyDataPoint? previousMonth;

  const MonthOverMonthComparison({
    required this.currentMonth,
    this.previousMonth,
  });

  /// Absolute currency change in expenses between this month and last month
  double get expenseChangeAmount {
    if (previousMonth == null) return 0.0;
    return currentMonth.expense - previousMonth!.expense;
  }

  /// Percentage change in spending compared to previous month
  double get expenseChangePercentage {
    if (previousMonth == null || previousMonth!.expense <= 0) return 0.0;
    return ((currentMonth.expense - previousMonth!.expense) / previousMonth!.expense) * 100.0;
  }

  /// Whether current month's spending increased compared to previous month
  bool get isSpendingIncreased => expenseChangeAmount > 0;

  /// Absolute change in income
  double get incomeChangeAmount {
    if (previousMonth == null) return 0.0;
    return currentMonth.income - previousMonth!.income;
  }

  /// Whether sufficient historical data exists for month-over-month comparisons
  bool get hasEnoughHistory =>
      previousMonth != null && (previousMonth!.expense > 0 || previousMonth!.income > 0);
}

/// Budget consumption velocity and burn rate analysis
class BudgetUtilizationAnalytics {
  final double budgetLimit;
  final double budgetSpent;
  final int daysPassedInMonth;
  final int totalDaysInMonth;

  const BudgetUtilizationAnalytics({
    required this.budgetLimit,
    required this.budgetSpent,
    required this.daysPassedInMonth,
    required this.totalDaysInMonth,
  });

  /// Percentage of monthly budget consumed so far
  double get utilizationPercentage {
    if (budgetLimit <= 0) return 0.0;
    return (budgetSpent / budgetLimit * 100.0).clamp(0.0, 500.0);
  }

  /// Expected percentage based on days elapsed in the month (linear budget line)
  double get expectedUtilizationPercentage {
    if (totalDaysInMonth <= 0) return 0.0;
    return (daysPassedInMonth / totalDaysInMonth * 100.0).clamp(0.0, 100.0);
  }

  /// Whether spending burn rate is pacing ahead of schedule (over 5% ahead of linear rate)
  bool get isPacingAhead => utilizationPercentage > (expectedUtilizationPercentage + 5.0);

  /// Whether the user has exceeded their monthly budget limit
  bool get isExceeded => budgetSpent > budgetLimit;

  /// Current average spending burn rate per elapsed day
  double get currentDailyBurnRate {
    if (daysPassedInMonth <= 0) return 0.0;
    return budgetSpent / daysPassedInMonth;
  }

  /// Maximum recommended daily spend for remaining days to remain within budget
  double get safeDailyRemainingSpend {
    final remainingDays = totalDaysInMonth - daysPassedInMonth;
    if (remainingDays <= 0) return 0.0;
    final remainingBudget = (budgetLimit - budgetSpent).clamp(0.0, double.infinity);
    return remainingBudget / remainingDays;
  }
}
