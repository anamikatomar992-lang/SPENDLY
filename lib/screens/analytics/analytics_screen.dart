import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart';
import '../../providers/transaction_provider.dart';
import '../../theme/app_colors.dart';
import '../../utils/currency_formatter.dart';
import '../../utils/date_helpers.dart';
import '../../widgets/custom_card.dart';
import 'widgets/income_expense_bar_chart.dart';
import 'widgets/month_over_month_card.dart';
import 'widgets/budget_utilization_card.dart';
import 'widgets/smart_insights_card.dart';

/// Advanced Financial Analytics & Intelligence Screen
class AnalyticsScreen extends StatelessWidget {
  const AnalyticsScreen({super.key});

  Future<void> _selectCustomDateRange(BuildContext context, TransactionProvider txProvider) async {
    final now = DateTime.now();
    final initialRange = txProvider.customDateRange ??
        DateTimeRange(
          start: DateTime(now.year, now.month, 1),
          end: now,
        );

    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      initialDateRange: initialRange,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primaryNavy,
              onPrimary: Colors.white,
              surface: AppColors.surfaceWhite,
              onSurface: AppColors.textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      txProvider.setTimeframe(AnalyticsTimeframe.custom, picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    final txProvider = context.watch<TransactionProvider>();
    final summary = txProvider.analyticsSummary;
    final breakdown = summary.categoryBreakdown;
    final totalExpense = summary.totalExpense;

    return Scaffold(
      backgroundColor: AppColors.backgroundCanvas,
      appBar: AppBar(
        title: const Text('Financial Analytics'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        physics: const BouncingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Timeframe Selector Chips
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _TimeframeChip(
                    label: 'This Month',
                    isSelected: txProvider.selectedTimeframe == AnalyticsTimeframe.thisMonth,
                    onTap: () => txProvider.setTimeframe(AnalyticsTimeframe.thisMonth),
                  ),
                  const SizedBox(width: 8),
                  _TimeframeChip(
                    label: 'Last Month',
                    isSelected: txProvider.selectedTimeframe == AnalyticsTimeframe.lastMonth,
                    onTap: () => txProvider.setTimeframe(AnalyticsTimeframe.lastMonth),
                  ),
                  const SizedBox(width: 8),
                  _TimeframeChip(
                    label: 'All Time',
                    isSelected: txProvider.selectedTimeframe == AnalyticsTimeframe.allTime,
                    onTap: () => txProvider.setTimeframe(AnalyticsTimeframe.allTime),
                  ),
                  const SizedBox(width: 8),
                  _TimeframeChip(
                    label: txProvider.selectedTimeframe == AnalyticsTimeframe.custom &&
                            txProvider.customDateRange != null
                        ? '${DateHelpers.formatShort(txProvider.customDateRange!.start)} - ${DateHelpers.formatShort(txProvider.customDateRange!.end)}'
                        : 'Custom Range',
                    icon: Icons.calendar_today_rounded,
                    isSelected: txProvider.selectedTimeframe == AnalyticsTimeframe.custom,
                    onTap: () => _selectCustomDateRange(context, txProvider),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Cash Flow Summary Card
            CustomCard(
              padding: const EdgeInsets.all(20),
              backgroundColor: AppColors.surfaceWhite,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Net Cash Flow',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: summary.isDeficit
                              ? AppColors.expenseCoral.withValues(alpha: 0.12)
                              : AppColors.emeraldLight.withValues(alpha: 0.7),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          summary.isDeficit
                              ? 'Deficit'
                              : 'Savings Rate: ${summary.savingsRate.toStringAsFixed(1)}%',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: summary.isDeficit
                                ? AppColors.expenseCoral
                                : AppColors.emeraldDark,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _StatColumn(
                        label: 'Total Inflow',
                        amount: summary.totalIncome,
                        color: AppColors.emeraldDark,
                      ),
                      Container(width: 1, height: 36, color: AppColors.borderLight),
                      _StatColumn(
                        label: 'Total Outflow',
                        amount: summary.totalExpense,
                        color: AppColors.expenseCoral,
                      ),
                      Container(width: 1, height: 36, color: AppColors.borderLight),
                      _StatColumn(
                        label: 'Net Balance',
                        amount: summary.netBalance,
                        color: summary.isDeficit
                            ? AppColors.expenseCoral
                            : AppColors.primaryNavy,
                        isNegativeAllowed: true,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Financial Intelligence Highlight Cards (Row)
            Row(
              children: [
                // Daily Average Expense
                Expanded(
                  child: CustomCard(
                    padding: const EdgeInsets.all(16),
                    backgroundColor: AppColors.surfaceWhite,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: AppColors.surfaceMuted,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(
                                Icons.trending_down_rounded,
                                size: 16,
                                color: AppColors.textSecondary,
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Text(
                              'Daily Avg',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textTertiary,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Text(
                          CurrencyFormatter.format(summary.averageDailyExpense),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${summary.expenseTransactionCount} expenses',
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),

                // Top Spending Category
                Expanded(
                  child: CustomCard(
                    padding: const EdgeInsets.all(16),
                    backgroundColor: AppColors.surfaceWhite,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: summary.topExpenseCategory != null
                                    ? summary.topExpenseCategory!.color.withValues(alpha: 0.15)
                                    : AppColors.surfaceMuted,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                summary.topExpenseCategory?.icon ?? Icons.category_rounded,
                                size: 16,
                                color: summary.topExpenseCategory?.color ?? AppColors.textSecondary,
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Text(
                              'Top Category',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textTertiary,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Text(
                          summary.topExpenseCategory?.name ?? 'None',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          summary.topExpenseCategory != null
                              ? '${summary.topCategoryPercentage.toStringAsFixed(0)}% • ${CurrencyFormatter.format(summary.topExpenseAmount)}'
                              : 'No data',
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Income vs Expense Multi-Month Grouped Bar Chart
            const IncomeExpenseBarChart(),
            const SizedBox(height: 16),

            // Month-over-Month Comparison
            const MonthOverMonthCard(),
            const SizedBox(height: 16),

            // Budget Burn Velocity Analysis
            const BudgetUtilizationCard(),
            const SizedBox(height: 20),

            // Category Expense Breakdown Section
            Text(
              'Category Spending Distribution',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
            ),
            const SizedBox(height: 12),
            CustomCard(
              padding: const EdgeInsets.all(20),
              backgroundColor: AppColors.surfaceWhite,
              child: breakdown.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 24),
                        child: Column(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: const BoxDecoration(
                                color: AppColors.surfaceMuted,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.pie_chart_outline_rounded,
                                color: AppColors.textTertiary,
                                size: 32,
                              ),
                            ),
                            const SizedBox(height: 12),
                            const Text(
                              'No Expense Data Available',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              'No expenses were recorded for this selected timeframe.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 12,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  : Column(
                      children: [
                        SizedBox(
                          height: 190,
                          child: PieChart(
                            PieChartData(
                              sectionsSpace: 3,
                              centerSpaceRadius: 42,
                              sections: breakdown.entries.map((entry) {
                                final pct = totalExpense > 0
                                    ? (entry.value / totalExpense) * 100
                                    : 0.0;
                                return PieChartSectionData(
                                  color: entry.key.color,
                                  value: entry.value,
                                  title: '${pct.toStringAsFixed(0)}%',
                                  radius: 46,
                                  titleStyle: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                  ),
                                );
                              }).toList(),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        const Divider(color: AppColors.borderSubtle),
                        const SizedBox(height: 12),

                        // Category Legend & Breakdown List
                        ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: breakdown.entries.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 10),
                          itemBuilder: (context, index) {
                            final item = breakdown.entries.elementAt(index);
                            final cat = item.key;
                            final amount = item.value;
                            final pct = totalExpense > 0
                                ? (amount / totalExpense) * 100
                                : 0.0;

                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      width: 28,
                                      height: 28,
                                      decoration: BoxDecoration(
                                        color: cat.color.withValues(alpha: 0.15),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Icon(cat.icon, size: 14, color: cat.color),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Text(
                                        cat.name,
                                        style: const TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                          color: AppColors.textPrimary,
                                        ),
                                      ),
                                    ),
                                    Text(
                                      '${pct.toStringAsFixed(1)}% • ${CurrencyFormatter.format(amount)}',
                                      style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.textPrimary,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(4),
                                  child: LinearProgressIndicator(
                                    value: (pct / 100.0).clamp(0.0, 1.0),
                                    minHeight: 5,
                                    backgroundColor: AppColors.surfaceMuted,
                                    valueColor: AlwaysStoppedAnimation<Color>(cat.color),
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                      ],
                    ),
            ),
            const SizedBox(height: 24),

            // Smart Financial Intelligence & Dynamic Insights
            const SmartInsightsCard(),
            const SizedBox(height: 36),
          ],
        ),
      ),
    );
  }
}

class _TimeframeChip extends StatelessWidget {
  final String label;
  final IconData? icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _TimeframeChip({
    required this.label,
    this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primaryNavy : AppColors.surfaceWhite,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppColors.primaryNavy : AppColors.borderLight,
            width: 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.primaryNavy.withValues(alpha: 0.15),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  )
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                size: 14,
                color: isSelected ? Colors.white : AppColors.textSecondary,
              ),
              const SizedBox(width: 6),
            ],
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? Colors.white : AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatColumn extends StatelessWidget {
  final String label;
  final double amount;
  final Color color;
  final bool isNegativeAllowed;

  const _StatColumn({
    required this.label,
    required this.amount,
    required this.color,
    this.isNegativeAllowed = false,
  });

  @override
  Widget build(BuildContext context) {
    final prefix = isNegativeAllowed && amount < 0 ? '-' : '';
    final absAmount = amount.abs();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: AppColors.textTertiary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '$prefix${CurrencyFormatter.format(absAmount, showDecimals: false)}',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
      ],
    );
  }
}
