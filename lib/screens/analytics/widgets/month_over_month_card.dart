import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/transaction_provider.dart';
import '../../../theme/app_colors.dart';
import '../../../utils/currency_formatter.dart';
import '../../../widgets/custom_card.dart';

/// Month-over-Month (MoM) spending comparison card with percentage delta indicators
class MonthOverMonthCard extends StatelessWidget {
  const MonthOverMonthCard({super.key});

  @override
  Widget build(BuildContext context) {
    final txProvider = context.watch<TransactionProvider>();
    final mom = txProvider.monthOverMonthComparison;
    final current = mom.currentMonth;
    final previous = mom.previousMonth;

    return CustomCard(
      padding: const EdgeInsets.all(20),
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
                      'Month-over-Month Pace',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      previous != null
                          ? '${previous.monthLabel} vs ${current.monthLabel}'
                          : '${current.monthLabel} (Awaiting Prior History)',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              if (mom.hasEnoughHistory)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: mom.isSpendingIncreased
                        ? AppColors.expenseCoral.withValues(alpha: 0.12)
                        : AppColors.emeraldLight.withValues(alpha: 0.7),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        mom.isSpendingIncreased
                            ? Icons.arrow_upward_rounded
                            : Icons.arrow_downward_rounded,
                        size: 13,
                        color: mom.isSpendingIncreased
                            ? AppColors.expenseCoral
                            : AppColors.emeraldDark,
                      ),
                      const SizedBox(width: 3),
                      Text(
                        '${mom.expenseChangePercentage.abs().toStringAsFixed(1)}%',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: mom.isSpendingIncreased
                              ? AppColors.expenseCoral
                              : AppColors.emeraldDark,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),

          if (!mom.hasEnoughHistory)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.surfaceMuted,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.info_outline_rounded,
                    size: 18,
                    color: AppColors.textTertiary,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Spendly is tracking ${current.monthLabel} data. Month-over-month comparisons will unlock automatically next month.',
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.textSecondary,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            )
          else ...[
            // Current vs Prior comparative metrics
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${previous!.monthLabel} Spending',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: AppColors.textTertiary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        CurrencyFormatter.format(previous.expense, showDecimals: false),
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(width: 1, height: 32, color: AppColors.borderLight),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${current.monthLabel} Spending',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: AppColors.textTertiary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        CurrencyFormatter.format(current.expense, showDecimals: false),
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: mom.isSpendingIncreased
                              ? AppColors.expenseCoral
                              : AppColors.emeraldDark,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(width: 1, height: 32, color: AppColors.borderLight),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Net Delta',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: AppColors.textTertiary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${mom.isSpendingIncreased ? '+' : '-'}${CurrencyFormatter.format(mom.expenseChangeAmount.abs(), showDecimals: false)}',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: mom.isSpendingIncreased
                              ? AppColors.expenseCoral
                              : AppColors.emeraldDark,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Narrative summary message
            Text(
              mom.isSpendingIncreased
                  ? 'Outflows have increased by ${mom.expenseChangePercentage.toStringAsFixed(1)}% compared to last month. Keep an eye on non-essential expenses.'
                  : 'Spending is down by ${mom.expenseChangePercentage.abs().toStringAsFixed(1)}% compared to last month. Great job retaining capital!',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: mom.isSpendingIncreased
                    ? AppColors.textSecondary
                    : AppColors.emeraldDark,
                height: 1.35,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
