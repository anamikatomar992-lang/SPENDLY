import 'package:flutter/material.dart';
import '../../../theme/app_colors.dart';
import '../../../utils/currency_formatter.dart';
import '../../../widgets/custom_card.dart';

/// Side-by-side Monthly Income & Expense indicator cards
class IncomeExpenseSummary extends StatelessWidget {
  final double income;
  final double expense;
  final bool isVisible;

  const IncomeExpenseSummary({
    super.key,
    required this.income,
    required this.expense,
    required this.isVisible,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Income Card
        Expanded(
          child: CustomCard(
            padding: const EdgeInsets.all(16),
            backgroundColor: AppColors.surfaceWhite,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Income',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: AppColors.textSecondary,
                          ),
                    ),
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: AppColors.emeraldLight.withValues(alpha: 0.5),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.arrow_downward_rounded,
                        size: 14,
                        color: AppColors.emeraldDark,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  isVisible ? CurrencyFormatter.format(income) : '••••',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: AppColors.emeraldDark,
                        letterSpacing: -0.3,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Current Month',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: AppColors.textTertiary,
                      ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 14),
        // Expense Card
        Expanded(
          child: CustomCard(
            padding: const EdgeInsets.all(16),
            backgroundColor: AppColors.surfaceWhite,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Expenses',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: AppColors.textSecondary,
                          ),
                    ),
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: AppColors.expenseLight.withValues(alpha: 0.6),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.arrow_upward_rounded,
                        size: 14,
                        color: AppColors.expenseCoral,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  isVisible ? CurrencyFormatter.format(expense) : '••••',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: AppColors.expenseCoral,
                        letterSpacing: -0.3,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Current Month',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: AppColors.textTertiary,
                      ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
