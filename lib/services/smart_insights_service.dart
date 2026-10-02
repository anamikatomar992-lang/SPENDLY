import 'package:flutter/material.dart';
import '../models/financial_insight_model.dart';
import '../models/financial_summary_model.dart';
import '../models/monthly_data_point.dart';
import '../theme/app_colors.dart';

/// Pure, deterministic service generating personalized financial insights and warnings
class SmartInsightsService {
  SmartInsightsService._();

  static List<FinancialInsight> generateInsights({
    required FinancialSummary currentMonthSummary,
    required MonthOverMonthComparison momComparison,
    required BudgetUtilizationAnalytics budgetUtilization,
  }) {
    final List<FinancialInsight> insights = [];

    // Rule 1: Month-over-Month Spending Velocity
    if (momComparison.hasEnoughHistory) {
      final changePct = momComparison.expenseChangePercentage;
      final changeAmt = momComparison.expenseChangeAmount;

      if (changePct > 8.0) {
        insights.add(
          FinancialInsight(
            id: 'mom_spending_increase',
            title: 'Spending Increased (+${changePct.toStringAsFixed(1)}%)',
            message:
                'You have spent \$${changeAmt.abs().toStringAsFixed(0)} more than last month. Review high-frequency purchases to stay on target.',
            icon: Icons.trending_up_rounded,
            color: AppColors.expenseCoral,
            type: InsightType.warning,
            badgeText: '+${changePct.toStringAsFixed(1)}%',
          ),
        );
      } else if (changePct < -8.0) {
        insights.add(
          FinancialInsight(
            id: 'mom_spending_decrease',
            title: 'Spending Reduced (-${changePct.abs().toStringAsFixed(1)}%)',
            message:
                'Great discipline! You have spent \$${changeAmt.abs().toStringAsFixed(0)} less than last month.',
            icon: Icons.trending_down_rounded,
            color: AppColors.emeraldDark,
            type: InsightType.achievement,
            badgeText: '-${changePct.abs().toStringAsFixed(1)}%',
          ),
        );
      }
    }

    // Rule 2: Budget Utilization & Burn Rate Alert
    if (budgetUtilization.isExceeded) {
      final excess = budgetUtilization.budgetSpent - budgetUtilization.budgetLimit;
      insights.add(
        FinancialInsight(
          id: 'budget_exceeded',
          title: 'Monthly Budget Exceeded',
          message:
              'You have exceeded your \$${budgetUtilization.budgetLimit.toStringAsFixed(0)} limit by \$${excess.toStringAsFixed(0)}. Limit non-essential purchases.',
          icon: Icons.warning_amber_rounded,
          color: AppColors.expenseCoral,
          type: InsightType.alert,
          badgeText: 'Over Budget',
        ),
      );
    } else if (budgetUtilization.isPacingAhead) {
      insights.add(
        FinancialInsight(
          id: 'budget_velocity_warning',
          title: 'High Spending Velocity',
          message:
              'You have consumed ${budgetUtilization.utilizationPercentage.toStringAsFixed(0)}% of your monthly budget, pacing ahead of schedule.',
          icon: Icons.speed_rounded,
          color: AppColors.warningAmber,
          type: InsightType.warning,
          badgeText: '${budgetUtilization.utilizationPercentage.toStringAsFixed(0)}% Used',
        ),
      );
    } else if (budgetUtilization.utilizationPercentage > 0) {
      insights.add(
        FinancialInsight(
          id: 'budget_on_track',
          title: 'Healthy Budget Pacing',
          message:
              'You are pacing within your planned spending target. Safe daily allowance is \$${budgetUtilization.safeDailyRemainingSpend.toStringAsFixed(0)}/day.',
          icon: Icons.check_circle_outline_rounded,
          color: AppColors.emeraldDark,
          type: InsightType.achievement,
          badgeText: 'On Track',
        ),
      );
    }

    // Rule 3: Category Dominance Concentration Risk
    final topCategory = currentMonthSummary.topExpenseCategory;
    final topPercentage = currentMonthSummary.topCategoryPercentage;
    final topAmount = currentMonthSummary.topExpenseAmount;

    if (topCategory != null && topPercentage >= 35.0 && topAmount > 0) {
      insights.add(
        FinancialInsight(
          id: 'category_concentration_${topCategory.id}',
          title: 'Heavy ${topCategory.name} Spending (${topPercentage.toStringAsFixed(0)}%)',
          message:
              '${topCategory.name} accounts for ${topPercentage.toStringAsFixed(1)}% of your monthly outflows (\$${topAmount.toStringAsFixed(0)}). Consider rebalancing.',
          icon: topCategory.icon,
          color: topCategory.color,
          type: InsightType.warning,
          badgeText: '${topPercentage.toStringAsFixed(0)}% of Total',
        ),
      );
    }

    // Rule 4: Savings Rate Momentum or Zero Income Alert
    if (currentMonthSummary.totalIncome > 0 && currentMonthSummary.savingsRate >= 20.0) {
      insights.add(
        FinancialInsight(
          id: 'savings_rate_healthy',
          title: 'Strong Savings Rate (${currentMonthSummary.savingsRate.toStringAsFixed(1)}%)',
          message:
              'You are saving ${currentMonthSummary.savingsRate.toStringAsFixed(1)}% of your incoming cash flow this month. Excellent financial cushion!',
          icon: Icons.savings_rounded,
          color: AppColors.emeraldDark,
          type: InsightType.achievement,
          badgeText: '${currentMonthSummary.savingsRate.toStringAsFixed(0)}% Saved',
        ),
      );
    } else if (currentMonthSummary.totalIncome <= 0 && currentMonthSummary.totalExpense > 0) {
      insights.add(
        FinancialInsight(
          id: 'zero_income_deficit',
          title: 'Zero Income Logged',
          message:
              'You have recorded \$${currentMonthSummary.totalExpense.toStringAsFixed(0)} in expenses without corresponding income this month. Net cash flow is in a deficit.',
          icon: Icons.account_balance_wallet_outlined,
          color: AppColors.warningAmber,
          type: InsightType.info,
          badgeText: 'Deficit',
        ),
      );
    }

    // Rule 5: Fallback Baseline Insight for Fresh or Minimal Data
    if (insights.isEmpty) {
      insights.add(
        const FinancialInsight(
          id: 'spending_intelligence_active',
          title: 'Spending Intelligence Active',
          message:
              'Spendly analyzes your transaction habits over time to discover personalized savings opportunities and budget velocity alerts.',
          icon: Icons.auto_awesome_rounded,
          color: AppColors.primaryNavy,
          type: InsightType.info,
          badgeText: 'Smart Assistant',
        ),
      );
    }

    return insights;
  }
}
