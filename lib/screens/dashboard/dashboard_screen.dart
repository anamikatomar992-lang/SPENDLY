import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/transaction_provider.dart';
import '../../theme/app_colors.dart';
import '../../utils/date_helpers.dart';
import '../../widgets/error_view.dart';
import 'widgets/balance_card.dart';
import 'widgets/income_expense_summary.dart';
import 'widgets/budget_progress_card.dart';
import 'widgets/spending_trend_card.dart';
import 'widgets/quick_actions_bar.dart';
import 'widgets/recent_transactions_section.dart';
import '../transactions/widgets/add_transaction_dialog.dart';

/// Main Financial Dashboard Screen for Spendly
class DashboardScreen extends StatelessWidget {
  final VoidCallback onNavigateToTransactions;
  final VoidCallback onQuickAddExpense;
  final VoidCallback onQuickAddIncome;
  final VoidCallback onSetBudget;

  const DashboardScreen({
    super.key,
    required this.onNavigateToTransactions,
    required this.onQuickAddExpense,
    required this.onQuickAddIncome,
    required this.onSetBudget,
  });

  String _getTimeGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) {
      return 'Good morning';
    } else if (hour < 17) {
      return 'Good afternoon';
    } else {
      return 'Good evening';
    }
  }

  @override
  Widget build(BuildContext context) {
    final txProvider = context.watch<TransactionProvider>();

    if (txProvider.isLoading) {
      return const Scaffold(
        backgroundColor: AppColors.backgroundCanvas,
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryNavy),
                strokeWidth: 3,
              ),
              SizedBox(height: 16),
              Text(
                'Syncing financial intelligence...',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (txProvider.errorMessage != null) {
      return Scaffold(
        backgroundColor: AppColors.backgroundCanvas,
        body: ErrorView(
          message: txProvider.errorMessage!,
          onRetry: () => txProvider.loadTransactions(),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.backgroundCanvas,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundCanvas,
        elevation: 0,
        titleSpacing: 20,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _getTimeGreeting(),
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: AppColors.textSecondary,
                letterSpacing: 0.2,
              ),
            ),
            const SizedBox(height: 2),
            const Text(
              'Alex Morgan',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.surfaceWhite,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.borderLight, width: 1),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.calendar_today_rounded,
                  size: 13,
                  color: AppColors.primaryNavy,
                ),
                const SizedBox(width: 6),
                Text(
                  DateHelpers.formatMonthYear(),
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primaryNavy,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => txProvider.loadTransactions(),
        color: AppColors.primaryNavy,
        backgroundColor: AppColors.surfaceWhite,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(
            parent: BouncingScrollPhysics(),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Hero Total Balance Card
              BalanceCard(
                totalBalance: txProvider.totalBalance,
                monthlySavings: txProvider.monthlySavings,
                savingsPercentage: txProvider.monthlySavingsPercentage,
                isVisible: txProvider.isBalanceVisible,
                onToggleVisibility: txProvider.toggleBalanceVisibility,
              ),
              const SizedBox(height: 14),

              // Side-by-side Monthly Income & Expense Cards
              IncomeExpenseSummary(
                income: txProvider.monthlyIncome,
                expense: txProvider.monthlyExpense,
                isVisible: txProvider.isBalanceVisible,
              ),
              const SizedBox(height: 14),

              // Quick Action Shortcuts Bar
              QuickActionsBar(
                onAddExpense: onQuickAddExpense,
                onAddIncome: onQuickAddIncome,
                onSetBudget: onSetBudget,
              ),
              const SizedBox(height: 14),

              // Monthly Budget Progress Indicator
              BudgetProgressCard(
                budgetLimit: txProvider.budgetLimit,
                budgetConsumed: txProvider.budgetConsumed,
                budgetRemaining: txProvider.budgetRemaining,
                progressPercentage: txProvider.budgetProgressPercentage,
                isNearLimit: txProvider.isBudgetNearLimit,
                isExceeded: txProvider.isBudgetExceeded,
              ),
              const SizedBox(height: 14),

              // 7-day Spending Overview Mini-Chart
              SpendingTrendCard(
                transactions: txProvider.transactions,
              ),
              const SizedBox(height: 20),

              // Recent Transactions Section
              RecentTransactionsSection(
                transactions: txProvider.recentTransactions,
                onSeeAll: onNavigateToTransactions,
                onTransactionTap: (tx) {
                  AddTransactionDialog.show(context, initialTransaction: tx);
                },
              ),
              const SizedBox(height: 36),
            ],
          ),
        ),
      ),
    );
  }
}
