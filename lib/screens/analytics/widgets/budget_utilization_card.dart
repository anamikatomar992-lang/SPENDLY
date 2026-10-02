import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/transaction_provider.dart';
import '../../../theme/app_colors.dart';
import '../../../utils/currency_formatter.dart';
import '../../../widgets/custom_card.dart';

/// Budget burn rate velocity and daily allowance intelligence card
class BudgetUtilizationCard extends StatelessWidget {
  const BudgetUtilizationCard({super.key});

  @override
  Widget build(BuildContext context) {
    final txProvider = context.watch<TransactionProvider>();
    final analytics = txProvider.budgetUtilization;

    final isExceeded = analytics.isExceeded;
    final isPacingAhead = analytics.isPacingAhead;

    final badgeColor = isExceeded
        ? AppColors.expenseCoral
        : (isPacingAhead ? AppColors.warningAmber : AppColors.emeraldDark);

    final badgeBg = isExceeded
        ? AppColors.expenseCoral.withValues(alpha: 0.12)
        : (isPacingAhead
            ? AppColors.warningAmber.withValues(alpha: 0.12)
            : AppColors.emeraldLight.withValues(alpha: 0.7));

    final badgeText = isExceeded
        ? 'Over Budget'
        : (isPacingAhead ? 'Pacing Ahead' : 'Pacing On Track');

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
                      'Budget Burn Velocity',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Day ${analytics.daysPassedInMonth} of ${analytics.totalDaysInMonth} (${analytics.expectedUtilizationPercentage.toStringAsFixed(0)}% elapsed)',
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
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: badgeBg,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  badgeText,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: badgeColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Progress bar with burn rate
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${analytics.utilizationPercentage.toStringAsFixed(0)}% consumed',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: badgeColor,
                ),
              ),
              Text(
                '${CurrencyFormatter.format(analytics.budgetSpent, showDecimals: false)} / ${CurrencyFormatter.format(analytics.budgetLimit, showDecimals: false)}',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: (analytics.utilizationPercentage / 100.0).clamp(0.0, 1.0),
              minHeight: 8,
              backgroundColor: AppColors.surfaceMuted,
              valueColor: AlwaysStoppedAnimation<Color>(badgeColor),
            ),
          ),
          const SizedBox(height: 16),

          // Daily Allowance Breakdown
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceMuted,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Current Daily Burn',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textTertiary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${CurrencyFormatter.format(analytics.currentDailyBurnRate, showDecimals: false)}/day',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceMuted,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Safe Remaining Target',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textTertiary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${CurrencyFormatter.format(analytics.safeDailyRemainingSpend, showDecimals: false)}/day',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: analytics.safeDailyRemainingSpend > 0
                              ? AppColors.emeraldDark
                              : AppColors.expenseCoral,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
