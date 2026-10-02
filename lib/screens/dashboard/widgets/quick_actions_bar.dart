import 'package:flutter/material.dart';
import '../../../theme/app_colors.dart';

/// Horizontal Quick Actions bar for instant financial logging
class QuickActionsBar extends StatelessWidget {
  final VoidCallback onAddExpense;
  final VoidCallback onAddIncome;
  final VoidCallback onSetBudget;

  const QuickActionsBar({
    super.key,
    required this.onAddExpense,
    required this.onAddIncome,
    required this.onSetBudget,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _ActionButton(
            label: 'Add Expense',
            icon: Icons.remove_circle_outline_rounded,
            color: AppColors.expenseCoral,
            bgColor: AppColors.expenseLight.withValues(alpha: 0.7),
            onTap: onAddExpense,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _ActionButton(
            label: 'Add Income',
            icon: Icons.add_circle_outline_rounded,
            color: AppColors.emeraldDark,
            bgColor: AppColors.emeraldLight.withValues(alpha: 0.7),
            onTap: onAddIncome,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _ActionButton(
            label: 'Set Budget',
            icon: Icons.tune_rounded,
            color: AppColors.primaryNavy,
            bgColor: AppColors.surfaceMuted,
            onTap: onSetBudget,
          ),
        ),
      ],
    );
  }
}

class _ActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final Color bgColor;
  final VoidCallback onTap;

  const _ActionButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.bgColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: bgColor,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 20, color: color),
              const SizedBox(height: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
