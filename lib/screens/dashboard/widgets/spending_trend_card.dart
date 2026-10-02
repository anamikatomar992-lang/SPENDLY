import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../../../models/transaction_model.dart';
import '../../../theme/app_colors.dart';
import '../../../utils/currency_formatter.dart';
import '../../../widgets/custom_card.dart';

/// Monthly spending overview mini-chart showing daily expense trends
class SpendingTrendCard extends StatelessWidget {
  final List<TransactionModel> transactions;

  const SpendingTrendCard({
    super.key,
    required this.transactions,
  });

  @override
  Widget build(BuildContext context) {
    // Aggregate expenses for the last 7 days from actual transaction data
    final now = DateTime.now();
    final List<DateTime> last7Days = List.generate(7, (i) {
      final d = now.subtract(Duration(days: 6 - i));
      return DateTime(d.year, d.month, d.day);
    });

    final Map<DateTime, double> dailyExpenses = {
      for (final day in last7Days) day: 0.0,
    };

    for (final tx in transactions.where((t) => t.isExpense)) {
      final txDate = DateTime(tx.date.year, tx.date.month, tx.date.day);
      if (dailyExpenses.containsKey(txDate)) {
        dailyExpenses[txDate] = (dailyExpenses[txDate] ?? 0.0) + tx.amount;
      }
    }

    final double maxExpense = dailyExpenses.values.fold(50.0, (max, v) => v > max ? v : max);

    final List<BarChartGroupData> barGroups = [];
    int index = 0;
    for (final day in last7Days) {
      final amount = dailyExpenses[day] ?? 0.0;
      final isToday = index == 6;

      barGroups.add(
        BarChartGroupData(
          x: index,
          barRods: [
            BarChartRodData(
              toY: amount,
              color: isToday ? AppColors.emeraldGreen : AppColors.primaryNavy.withValues(alpha: 0.85),
              width: 14,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
              backDrawRodData: BackgroundBarChartRodData(
                show: true,
                toY: maxExpense * 1.15,
                color: AppColors.surfaceMuted,
              ),
            ),
          ],
        ),
      );
      index++;
    }

    final total7DaySpend = dailyExpenses.values.fold(0.0, (sum, v) => sum + v);

    return CustomCard(
      padding: const EdgeInsets.all(18),
      backgroundColor: AppColors.surfaceWhite,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Spending Overview',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Past 7 days trajectory',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: AppColors.textTertiary,
                          ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.surfaceMuted,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.borderLight, width: 1),
                ),
                child: Text(
                  CurrencyFormatter.format(total7DaySpend),
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primaryNavy,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 120,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: maxExpense * 1.15,
                barTouchData: BarTouchData(
                  enabled: true,
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipColor: (_) => AppColors.primaryNavy,
                    tooltipPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    tooltipMargin: 8,
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      final day = last7Days[group.x.toInt()];
                      final formattedDate = DateFormat('E, d MMM').format(day);
                      return BarTooltipItem(
                        '$formattedDate\n${CurrencyFormatter.format(rod.toY)}',
                        const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 11,
                        ),
                      );
                    },
                  ),
                ),
                titlesData: FlTitlesData(
                  show: true,
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 22,
                      getTitlesWidget: (value, meta) {
                        final i = value.toInt();
                        if (i < 0 || i >= last7Days.length) return const SizedBox.shrink();
                        final day = last7Days[i];
                        final isToday = i == 6;
                        return Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text(
                            isToday ? 'Today' : DateFormat('E').format(day).substring(0, 1),
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: isToday ? FontWeight.w700 : FontWeight.w500,
                              color: isToday ? AppColors.emeraldDark : AppColors.textTertiary,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                gridData: const FlGridData(show: false),
                borderData: FlBorderData(show: false),
                barGroups: barGroups,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
