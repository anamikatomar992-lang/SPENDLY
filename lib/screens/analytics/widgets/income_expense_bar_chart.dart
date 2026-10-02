import 'dart:math';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart';
import '../../../providers/transaction_provider.dart';
import '../../../theme/app_colors.dart';
import '../../../utils/currency_formatter.dart';
import '../../../widgets/custom_card.dart';

/// Interactive Grouped Bar Chart displaying Income vs Expense trends over selectable months
class IncomeExpenseBarChart extends StatefulWidget {
  const IncomeExpenseBarChart({super.key});

  @override
  State<IncomeExpenseBarChart> createState() => _IncomeExpenseBarChartState();
}

class _IncomeExpenseBarChartState extends State<IncomeExpenseBarChart> {
  int _touchedGroupIndex = -1;

  @override
  Widget build(BuildContext context) {
    final txProvider = context.watch<TransactionProvider>();
    final monthlyData = txProvider.historicalMonthlyData;
    final selectedMonths = txProvider.trendPeriodMonths;

    // Calculate maximum value to determine dynamic chart ceiling
    double maxVal = 0.0;
    for (final dp in monthlyData) {
      maxVal = max(maxVal, max(dp.income, dp.expense));
    }
    // Safe fallback ceiling if all values are 0
    final chartMaxY = maxVal > 0 ? (maxVal * 1.25) : 500.0;

    final hasData = monthlyData.any((dp) => dp.income > 0 || dp.expense > 0);

    return CustomCard(
      padding: const EdgeInsets.all(20),
      backgroundColor: AppColors.surfaceWhite,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with Title and Period Chips
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Income vs Expense',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                  ),
                  const SizedBox(height: 2),
                  const Text(
                    'Multi-month cash flow trends',
                    style: TextStyle(
                      fontSize: 11,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
              // Period Selector Chips (3M, 6M, 12M)
              Container(
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  color: AppColors.surfaceMuted,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _PeriodSelectorPill(
                      label: '3M',
                      isSelected: selectedMonths == 3,
                      onTap: () => txProvider.setTrendPeriod(3),
                    ),
                    _PeriodSelectorPill(
                      label: '6M',
                      isSelected: selectedMonths == 6,
                      onTap: () => txProvider.setTrendPeriod(6),
                    ),
                    _PeriodSelectorPill(
                      label: '1Y',
                      isSelected: selectedMonths == 12,
                      onTap: () => txProvider.setTrendPeriod(12),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Legend
          Row(
            children: [
              const _ChartLegendItem(
                color: AppColors.emeraldDark,
                label: 'Income',
              ),
              const SizedBox(width: 16),
              const _ChartLegendItem(
                color: AppColors.expenseCoral,
                label: 'Expense',
              ),
              const Spacer(),
              if (hasData)
                const Text(
                  'Tap bars for details',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textTertiary,
                    fontStyle: FontStyle.italic,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 20),

          // Bar Chart Canvas or Empty State
          if (!hasData)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 36),
              child: Center(
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: const BoxDecoration(
                        color: AppColors.surfaceMuted,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.bar_chart_rounded,
                        color: AppColors.textTertiary,
                        size: 32,
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'No Trend History Yet',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Add transactions across multiple months to reveal cash flow trends.',
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
          else
            SizedBox(
              height: 200,
              child: BarChart(
                BarChartData(
                  maxY: chartMaxY,
                  minY: 0,
                  alignment: BarChartAlignment.spaceAround,
                  barTouchData: BarTouchData(
                    enabled: true,
                    touchTooltipData: BarTouchTooltipData(
                      getTooltipColor: (_) => AppColors.primaryNavy,
                      tooltipRoundedRadius: 8,
                      tooltipPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      getTooltipItem: (group, groupIndex, rod, rodIndex) {
                        final point = monthlyData[group.x.toInt()];
                        final isIncome = rodIndex == 0;
                        final label = isIncome ? 'Income' : 'Expense';
                        final amount = isIncome ? point.income : point.expense;
                        return BarTooltipItem(
                          '${point.monthLabel}\n$label: ${CurrencyFormatter.format(amount)}',
                          const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        );
                      },
                    ),
                    touchCallback: (FlTouchEvent event, barTouchResponse) {
                      setState(() {
                        if (!event.isInterestedForInteractions ||
                            barTouchResponse == null ||
                            barTouchResponse.spot == null) {
                          _touchedGroupIndex = -1;
                          return;
                        }
                        _touchedGroupIndex = barTouchResponse.spot!.touchedBarGroupIndex;
                      });
                    },
                  ),
                  titlesData: FlTitlesData(
                    show: true,
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 34,
                        getTitlesWidget: (value, meta) {
                          if (value == 0 || value == chartMaxY) return const SizedBox.shrink();
                          if (value >= 1000) {
                            return Text(
                              '\$${(value / 1000).toStringAsFixed(0)}k',
                              style: const TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textTertiary,
                              ),
                            );
                          }
                          return Text(
                            '\$${value.toInt()}',
                            style: const TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textTertiary,
                            ),
                          );
                        },
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 26,
                        getTitlesWidget: (value, meta) {
                          final index = value.toInt();
                          if (index < 0 || index >= monthlyData.length) {
                            return const SizedBox.shrink();
                          }
                          final isSelected = index == _touchedGroupIndex;
                          return Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              monthlyData[index].monthLabel,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                                color: isSelected
                                    ? AppColors.primaryNavy
                                    : AppColors.textSecondary,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    horizontalInterval: chartMaxY / 4,
                    getDrawingHorizontalLine: (value) => const FlLine(
                      color: AppColors.borderSubtle,
                      strokeWidth: 1,
                      dashArray: [4, 4],
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  barGroups: List.generate(monthlyData.length, (index) {
                    final dp = monthlyData[index];
                    final isHighlighted = index == _touchedGroupIndex;
                    return BarChartGroupData(
                      x: index,
                      barRods: [
                        // Inflow Bar
                        BarChartRodData(
                          toY: dp.income,
                          color: AppColors.emeraldDark,
                          width: monthlyData.length > 6 ? 9 : 14,
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                          backDrawRodData: BackgroundBarChartRodData(
                            show: true,
                            toY: chartMaxY,
                            color: AppColors.surfaceMuted.withValues(alpha: 0.4),
                          ),
                        ),
                        // Outflow Bar
                        BarChartRodData(
                          toY: dp.expense,
                          color: AppColors.expenseCoral,
                          width: monthlyData.length > 6 ? 9 : 14,
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                          backDrawRodData: BackgroundBarChartRodData(
                            show: true,
                            toY: chartMaxY,
                            color: AppColors.surfaceMuted.withValues(alpha: 0.4),
                          ),
                        ),
                      ],
                      showingTooltipIndicators: isHighlighted ? [0, 1] : [],
                    );
                  }),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _PeriodSelectorPill extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _PeriodSelectorPill({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.surfaceWhite : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 3,
                    offset: const Offset(0, 1),
                  ),
                ]
              : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            color: isSelected ? AppColors.primaryNavy : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}

class _ChartLegendItem extends StatelessWidget {
  final Color color;
  final String label;

  const _ChartLegendItem({
    required this.color,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}
