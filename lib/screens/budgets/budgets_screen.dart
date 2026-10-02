import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/transaction_provider.dart';
import '../../theme/app_colors.dart';
import '../../utils/currency_formatter.dart';
import '../../widgets/category_icon_badge.dart';
import '../../widgets/custom_card.dart';

/// Budgets Screen tracking category spending limits and warnings
class BudgetsScreen extends StatelessWidget {
  const BudgetsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final txProvider = context.watch<TransactionProvider>();
    final breakdown = txProvider.categoryExpenseBreakdown;

    return Scaffold(
      backgroundColor: AppColors.backgroundCanvas,
      appBar: AppBar(
        title: const Text('Budgets & Limits'),
        actions: [
          IconButton(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Budget editing will be activated in Phase 4.'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            icon: const Icon(Icons.add_circle_outline_rounded, color: AppColors.primaryNavy),
            tooltip: 'Add Budget Limit',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        physics: const BouncingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Overall Monthly Budget Card
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
                        'Total Monthly Limit',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                      ),
                      Text(
                        CurrencyFormatter.format(txProvider.budgetLimit),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: AppColors.primaryNavy,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      value: txProvider.budgetProgressPercentage,
                      minHeight: 10,
                      backgroundColor: AppColors.surfaceMuted,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        txProvider.isBudgetExceeded
                            ? AppColors.expenseCoral
                            : txProvider.isBudgetNearLimit
                                ? AppColors.warningAmber
                                : AppColors.emeraldGreen,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Spent: ${CurrencyFormatter.format(txProvider.budgetConsumed)}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      Text(
                        'Remaining: ${CurrencyFormatter.format(txProvider.budgetRemaining)}',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: txProvider.isBudgetExceeded
                              ? AppColors.expenseCoral
                              : AppColors.emeraldDark,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            Text(
              'Category Allocations',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
            ),
            const SizedBox(height: 12),

            // Category Limit Items
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: txProvider.allCategories.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final cat = txProvider.allCategories[index];
                final spent = breakdown[cat] ?? 0.0;
                // Sample baseline limit for display
                final double mockLimit = (index + 1) * 75.0;
                final double progress = (spent / mockLimit).clamp(0.0, 1.0);
                final bool isWarning = progress >= 0.75;

                return CustomCard(
                  padding: const EdgeInsets.all(16),
                  backgroundColor: AppColors.surfaceWhite,
                  child: Column(
                    children: [
                      Row(
                        children: [
                          CategoryIconBadge(category: cat, size: 38, iconSize: 18),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  cat.name,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '${CurrencyFormatter.format(spent)} of ${CurrencyFormatter.format(mockLimit)}',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Text(
                            '${(progress * 100).toStringAsFixed(0)}%',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: isWarning ? AppColors.warningAmber : AppColors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: LinearProgressIndicator(
                          value: progress,
                          minHeight: 6,
                          backgroundColor: AppColors.surfaceMuted,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            isWarning ? AppColors.warningAmber : cat.color,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
            const SizedBox(height: 36),
          ],
        ),
      ),
    );
  }
}
