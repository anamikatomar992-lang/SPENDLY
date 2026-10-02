import 'package:flutter/material.dart';
import '../../../theme/app_colors.dart';
import '../../../utils/currency_formatter.dart';
import '../../../widgets/custom_card.dart';

/// Monthly Budget Progress tracking card with dynamic warnings and remaining indicator
class BudgetProgressCard extends StatelessWidget {
  final double budgetLimit;
  final double budgetConsumed;
  final double budgetRemaining;
  final double progressPercentage;
  final bool isNearLimit;
  final bool isExceeded;

  const BudgetProgressCard({
    super.key,
    required this.budgetLimit,
    required this.budgetConsumed,
    required this.budgetRemaining,
    required this.progressPercentage,
    required this.isNearLimit,
    required this.isExceeded,
  });

  @override
  Widget build(BuildContext context) {
    Color progressColor;
    String statusBadgeText;
    Color statusBadgeBg;
    Color statusBadgeTextColor;

    if (isExceeded) {
      progressColor = AppColors.expenseCoral;
      statusBadgeText = 'Exceeded';
      statusBadgeBg = AppColors.expenseLight;
      statusBadgeTextColor = AppColors.expenseCoral;
    } else if (isNearLimit) {
      progressColor = AppColors.warningAmber;
      statusBadgeText = 'Approaching Limit';
      statusBadgeBg = AppColors.warningLight;
      statusBadgeTextColor = const Color(0xFFB45309);
    } else {
      progressColor = AppColors.emeraldGreen;
      statusBadgeText = 'On Track';
      statusBadgeBg = AppColors.emeraldLight.withValues(alpha: 0.6);
      statusBadgeTextColor = AppColors.emeraldDark;
    }

    final percentageDisplay = (progressPercentage * 100).toStringAsFixed(0);

    return CustomCard(
      padding: const EdgeInsets.all(18),
      backgroundColor: AppColors.surfaceWhite,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: progressColor.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.pie_chart_outline_rounded,
                      size: 16,
                      color: progressColor,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Monthly Budget',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: statusBadgeBg,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  statusBadgeText,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: statusBadgeTextColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${CurrencyFormatter.format(budgetConsumed)} of ${CurrencyFormatter.format(budgetLimit)}',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
              ),
              Text(
                '$percentageDisplay%',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: progressColor,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          // Animated / Clean Linear Progress
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: progressPercentage,
              minHeight: 10,
              backgroundColor: AppColors.surfaceMuted,
              valueColor: AlwaysStoppedAnimation<Color>(progressColor),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  isExceeded ? 'Overspent by' : 'Remaining to spend',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                ),
              ),
              Text(
                isExceeded
                    ? CurrencyFormatter.format(budgetConsumed - budgetLimit)
                    : CurrencyFormatter.format(budgetRemaining),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: isExceeded ? AppColors.expenseCoral : AppColors.emeraldDark,
                    ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
