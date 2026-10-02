import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/transaction_model.dart';
import '../providers/auth_provider.dart';
import '../providers/transaction_provider.dart';
import '../theme/app_colors.dart';
import 'analytics/analytics_screen.dart';
import 'budgets/budgets_screen.dart';
import 'dashboard/dashboard_screen.dart';
import 'profile/profile_screen.dart';
import 'transactions/transactions_screen.dart';
import 'transactions/widgets/add_transaction_dialog.dart';

/// Root navigation shell with modern bottom navigation bar and Quick Add FAB
class NavigationShell extends StatefulWidget {
  const NavigationShell({super.key});

  @override
  State<NavigationShell> createState() => _NavigationShellState();
}

class _NavigationShellState extends State<NavigationShell> {
  int _currentIndex = 0;

  void _onTabSelected(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  void _openAddTransaction({TransactionType type = TransactionType.expense}) {
    AddTransactionDialog.show(context, initialType: type);
  }

  @override
  Widget build(BuildContext context) {
    final authUser = context.watch<AuthProvider>().user;
    final txProvider = context.read<TransactionProvider>();

    if (authUser?.uid != txProvider.currentUserId) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          txProvider.setUserId(authUser?.uid);
        }
      });
    }
    final List<Widget> pages = [
      DashboardScreen(
        onNavigateToTransactions: () => _onTabSelected(1),
        onQuickAddExpense: () => _openAddTransaction(type: TransactionType.expense),
        onQuickAddIncome: () => _openAddTransaction(type: TransactionType.income),
        onSetBudget: () => _onTabSelected(3),
      ),
      TransactionsScreen(
        onAddTransaction: () => _openAddTransaction(),
      ),
      const AnalyticsScreen(),
      const BudgetsScreen(),
      const ProfileScreen(),
    ];

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: pages,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openAddTransaction(),
        backgroundColor: AppColors.primaryNavy,
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        child: const Icon(Icons.add_rounded, size: 28, color: Colors.white),
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: AppColors.surfaceWhite,
          border: Border(
            top: BorderSide(color: AppColors.borderSubtle, width: 1),
          ),
          boxShadow: [
            BoxShadow(
              color: Color(0x080F172A),
              blurRadius: 16,
              offset: Offset(0, -4),
            ),
          ],
        ),
        child: SafeArea(
          child: NavigationBar(
            selectedIndex: _currentIndex,
            onDestinationSelected: _onTabSelected,
            backgroundColor: AppColors.surfaceWhite,
            surfaceTintColor: Colors.transparent,
            indicatorColor: AppColors.primaryNavy.withValues(alpha: 0.08),
            labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
            destinations: const [
              NavigationDestination(
                icon: Icon(Icons.dashboard_outlined),
                selectedIcon: Icon(Icons.dashboard_rounded, color: AppColors.primaryNavy),
                label: 'Dashboard',
              ),
              NavigationDestination(
                icon: Icon(Icons.receipt_long_outlined),
                selectedIcon: Icon(Icons.receipt_long_rounded, color: AppColors.primaryNavy),
                label: 'History',
              ),
              NavigationDestination(
                icon: Icon(Icons.insights_outlined),
                selectedIcon: Icon(Icons.insights_rounded, color: AppColors.primaryNavy),
                label: 'Analytics',
              ),
              NavigationDestination(
                icon: Icon(Icons.pie_chart_outline_rounded),
                selectedIcon: Icon(Icons.pie_chart_rounded, color: AppColors.primaryNavy),
                label: 'Budgets',
              ),
              NavigationDestination(
                icon: Icon(Icons.person_outline_rounded),
                selectedIcon: Icon(Icons.person_rounded, color: AppColors.primaryNavy),
                label: 'Profile',
              ),
            ],
          ),
        ),
      ),
    );
  }
}
